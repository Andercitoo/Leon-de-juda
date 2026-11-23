const PedidoModel = require('../models/pedidoModel');

// Acuerdos técnicos (RN-P01): envío desde S/ 30.00 con tarifa fija S/ 6.00
const MONTO_MIN_ENVIO = 30.00;
const COSTO_ENVIO = 6.00;

// Acepta los valores de la BD ('Delivery' / 'Recojo en tienda') y los alias JSON ('DOMICILIO' / 'TIENDA')
const normalizarModalidad = (valor) => {
  const v = String(valor || '').trim().toUpperCase();
  if (v === 'DOMICILIO' || v === 'DELIVERY') return 'Delivery';
  return 'Recojo en tienda';
};

const crearPedido = async (req, res) => {
  const id_usuario = req.user.id_usuario;
  const { repuestos, modalidad_entrega } = req.body;

  if (!Array.isArray(repuestos) || repuestos.length === 0) {
    return res.status(400).json({ error: 'El pedido debe incluir al menos un repuesto.' });
  }

  const items = repuestos.map((r) => ({
    id_repuesto: parseInt(r.id_repuesto, 10),
    cantidad: parseInt(r.cantidad, 10),
    precio: Number(r.precio) || 0,
  }));

  if (items.some((i) => !Number.isInteger(i.id_repuesto) || !Number.isInteger(i.cantidad) || i.cantidad < 1)) {
    return res.status(400).json({ error: 'Cada repuesto requiere id_repuesto y una cantidad mayor a 0.' });
  }

  // RN-P01: subtotal estimado con los precios del carrito; el modelo recalcula con precios de BD
  const subtotalCliente = items.reduce((acc, i) => acc + i.cantidad * i.precio, 0);
  let modalidad = normalizarModalidad(modalidad_entrega);
  if (modalidad === 'Delivery' && subtotalCliente < MONTO_MIN_ENVIO) {
    modalidad = 'Recojo en tienda';
  }

  try {
    const { nuevoPedido, subtotal, detalles, nombreCliente } = await PedidoModel.crearPedidoConBloqueo({
      id_usuario,
      modalidad_entrega: modalidad,
      costoEnvioDomicilio: COSTO_ENVIO,
      montoMinEnvio: MONTO_MIN_ENVIO,
      items,
    });

    return res.status(201).json({
      mensaje: 'Pedido creado y stock reservado por 15 min (RN-V01).',
      modalidad_aplicada: nuevoPedido.modalidad_entrega,
      subtotal,
      detalles,
      pedido: {
        ...nuevoPedido,
        nombre_cliente: nombreCliente,
        subtotal,
        detalles,
      },
    });
  } catch (err) {
    if (err && err.status) {
      return res.status(err.status).json({ error: err.message });
    }
    console.error('Error en crearPedido:', err);
    return res.status(500).json({ error: 'Error procesando pedido: ' + (err?.message || err) });
  }
};

const listarPedidos = async (req, res) => {
  try {
    const pedidos = await PedidoModel.listarPedidosPorUsuario(req.user.id_usuario);
    return res.json(pedidos);
  } catch (err) {
    console.error('Error en listarPedidos:', err);
    return res.status(500).json({ error: 'Error al cargar los pedidos.' });
  }
};

const cambiarEstadoPedido = async (req, res) => {
  const id_pedido = Number.parseInt(req.params.id, 10);
  const estadosPorAccion = { pagar: 'Pagado', cancelar: 'Cancelado' };
  const estado = estadosPorAccion[req.params.accion];
  if (!Number.isInteger(id_pedido) || id_pedido < 1) {
    return res.status(400).json({ error: 'El código de pedido no es válido.' });
  }
  if (!estado) {
    return res.status(400).json({ error: 'La acción debe ser pagar o cancelar.' });
  }

  try {
    const pedido = await PedidoModel.actualizarEstadoPedido({
      id_pedido,
      id_usuario: req.user.id_usuario,
      estado,
    });
    return res.json({ pedido });
  } catch (err) {
    if (err?.status) return res.status(err.status).json({ error: err.message });
    console.error('Error en cambiarEstadoPedido:', err);
    return res.status(500).json({ error: 'Error al actualizar el pedido.' });
  }
};

module.exports = { crearPedido, listarPedidos, cambiarEstadoPedido };
