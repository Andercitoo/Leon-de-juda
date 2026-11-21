const pool = require('../config/db');

const PedidoModel = {
  /**
   * Reserva atómica de stock (RN-V01).
   * Bloqueo pesimista SELECT ... FOR UPDATE dentro de una transacción ACID:
   * si dos conductores compran la última unidad a la vez, el segundo recibe 409.
   */
  async crearPedidoConBloqueo({ id_usuario, modalidad_entrega, costoEnvioDomicilio, montoMinEnvio, items }) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      let subtotalTotal = 0;
      const detallesProcesados = [];

      // Orden fijo por id para evitar interbloqueos entre transacciones concurrentes
      const ordenados = [...items].sort((a, b) => a.id_repuesto - b.id_repuesto);

      for (const item of ordenados) {
        const { id_repuesto, cantidad } = item;

        const repRes = await client.query(
          `SELECT id_repuesto, nombre, precio_unitario, stock_disponible
           FROM repuesto
           WHERE id_repuesto = $1
           FOR UPDATE;`,
          [id_repuesto]
        );

        if (repRes.rows.length === 0) {
          throw { status: 404, message: `Repuesto con ID ${id_repuesto} no existe.` };
        }

        const repuesto = repRes.rows[0];
        const stockActual = parseInt(repuesto.stock_disponible, 10);

        if (stockActual < cantidad) {
          throw {
            status: 409,
            message: stockActual === 0
              ? `'${repuesto.nombre}' se acaba de agotar.`
              : `Stock insuficiente para '${repuesto.nombre}'. Disponibles: ${stockActual}, solicitados: ${cantidad}.`,
          };
        }

        await client.query(
          `UPDATE repuesto
           SET stock_disponible = stock_disponible - $1,
               stock_bloqueado  = stock_bloqueado + $1
           WHERE id_repuesto = $2;`,
          [cantidad, id_repuesto]
        );

        const subtotal = Number(repuesto.precio_unitario) * cantidad;
        subtotalTotal += subtotal;
        detallesProcesados.push({ id_repuesto, nombre: repuesto.nombre, cantidad, subtotal });
      }

      // RN-P01 con precios reales de BD
      let modalidad = modalidad_entrega;
      if (modalidad === 'Delivery' && subtotalTotal < montoMinEnvio) {
        modalidad = 'Recojo en tienda';
      }
      const costoEnvio = modalidad === 'Delivery' ? costoEnvioDomicilio : 0;
      const totalPagar = subtotalTotal + costoEnvio;

      const resPedido = await client.query(
        `INSERT INTO pedido (id_usuario, modalidad_entrega, costo_envio, total_pagar, estado_pedido, expira_reserva)
         VALUES ($1, $2, $3, $4, 'Pendiente', NOW() + INTERVAL '15 minutes')
         RETURNING *;`,
        [id_usuario, modalidad, costoEnvio, totalPagar]
      );
      const nuevoPedido = resPedido.rows[0];

      for (const det of detallesProcesados) {
        await client.query(
          `INSERT INTO detalle_pedido (id_pedido, id_repuesto, cantidad, subtotal)
           VALUES ($1, $2, $3, $4);`,
          [nuevoPedido.id_pedido, det.id_repuesto, det.cantidad, det.subtotal]
        );
      }

      await client.query('COMMIT');
      return { nuevoPedido, subtotal: subtotalTotal, detalles: detallesProcesados };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },

  /**
   * RN-V01: libera el stock de pedidos 'Pendiente' cuya reserva de 15 min expiró.
   */
  async liberarReservasExpiradas() {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const expirados = await client.query(
        `UPDATE pedido SET estado_pedido = 'Expirado'
         WHERE estado_pedido = 'Pendiente' AND expira_reserva IS NOT NULL AND expira_reserva < NOW()
         RETURNING id_pedido;`
      );
      if (expirados.rowCount > 0) {
        const ids = expirados.rows.map((r) => r.id_pedido);
        await client.query(
          `UPDATE repuesto r
           SET stock_disponible = r.stock_disponible + d.cant,
               stock_bloqueado  = GREATEST(r.stock_bloqueado - d.cant, 0)
           FROM (SELECT id_repuesto, SUM(cantidad) AS cant
                 FROM detalle_pedido WHERE id_pedido = ANY($1::int[])
                 GROUP BY id_repuesto) d
           WHERE r.id_repuesto = d.id_repuesto;`,
          [ids]
        );
      }
      await client.query('COMMIT');
      return expirados.rowCount;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  },
};

module.exports = PedidoModel;
