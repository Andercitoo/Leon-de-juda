const { pool } = require('../config/db');

const PedidoModel = {
  async crearPedidoConBloqueo({ id_usuario, modalidad_entrega, costo_envio, items }) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN'); // Transacción ACID

      let subtotalTotal = 0;
      const detallesProcesados = [];

      // 1. Bloqueo pesimista y verificación de stock (RN-V01)
      for (const item of items) {
        const id_repuesto = parseInt(item.id_repuesto, 10);
        const cantidad = parseInt(item.cantidad, 10);

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
            message: `Stock insuficiente para '${repuesto.nombre}'. Disponibles: ${stockActual}, Solicitados: ${cantidad}.`
          };
        }

        // Descuenta disponible y aumenta stock bloqueado
        await client.query(
          `UPDATE repuesto 
           SET stock_disponible = stock_disponible - $1,
               stock_bloqueado = COALESCE(stock_bloqueado, 0) + $1
           WHERE id_repuesto = $2;`,
          [cantidad, id_repuesto]
        );

        const precioUnit = Number(repuesto.precio_unitario);
        const subtotal = precioUnit * cantidad;
        subtotalTotal += subtotal;

        detallesProcesados.push({
          id_repuesto,
          cantidad,
          subtotal
        });
      }

      const totalPagar = subtotalTotal + Number(costo_envio);

      // 2. Insertar cabecera con estado inicial 'Pendiente' y reserva de 15 minutos (RN-V01)
      const queryPedido = `
        INSERT INTO pedido (id_usuario, modalidad_entrega, costo_envio, total_pagar, estado_pedido, expira_reserva)
        VALUES ($1, $2, $3, $4, 'Pendiente', NOW() + INTERVAL '15 minutes')
        RETURNING *;
      `;
      const resPedido = await client.query(queryPedido, [
        id_usuario,
        modalidad_entrega,
        costo_envio,
        totalPagar
      ]);
      const nuevoPedido = resPedido.rows[0];

      // 3. Insertar detalle_pedido
      for (const det of detallesProcesados) {
        await client.query(
          `INSERT INTO detalle_pedido (id_pedido, id_repuesto, cantidad, subtotal)
           VALUES ($1, $2, $3, $4);`,
          [nuevoPedido.id_pedido, det.id_repuesto, det.cantidad, det.subtotal]
        );
      }

      await client.query('COMMIT');
      return { nuevoPedido, totalPagar, detalles: detallesProcesados };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
};

module.exports = PedidoModel;