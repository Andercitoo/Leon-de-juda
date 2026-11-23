const express = require('express');
const cors = require('cors');
require('dotenv').config();
process.env.DATABASE_URL = process.env.DATABASE_URL || "postgres://postgres:123@localhost:5432/leondejuda";
process.env.JWT_SECRET = "super_secreto_arca";
process.env.RADIO_MAX_KM = 3.50;
process.env.TALLER_LAT_ORIGEN = -12.215840;
process.env.TALLER_LON_ORIGEN = -76.931420;

const authMiddleware = require('./middlewares/authMiddleware');
const authController = require('./controllers/authController');
const auxilioController = require('./controllers/auxilioController');
const repuestoController = require('./controllers/repuestoController');
const pedidoController = require('./controllers/pedidoController');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ empresa: 'León de Judá', status: 'En línea', version: '1.0.0' });
});

// Seguridad
app.post('/api/auth/registro', authController.registro);
app.post('/api/auth/login', authController.login);

// Auxilio Mecánico
app.post('/api/auxilios', authMiddleware, auxilioController.solicitarAuxilio);
app.patch('/api/auxilios/:id', authMiddleware, auxilioController.actualizarEstado);

// Catálogo y Transacciones
app.get('/api/repuestos', repuestoController.obtenerCatalogo);
app.post('/api/pedidos', authMiddleware, pedidoController.crearPedido);
app.get('/api/pedidos', authMiddleware, pedidoController.listarPedidos);
app.patch('/api/pedidos/:id/:accion', authMiddleware, pedidoController.cambiarEstadoPedido);

// RN-V01: cada minuto se libera el stock de reservas vencidas (15 min)
const PedidoModel = require('./models/pedidoModel');
setInterval(() => {
  PedidoModel.liberarReservasExpiradas()
    .then((n) => { if (n > 0) console.log(`RN-V01: ${n} reserva(s) expirada(s), stock liberado`); })
    .catch((err) => console.error('Error liberando reservas:', err.message));
}, 60 * 1000);

const PORT = process.env.PORT || 3000;
PedidoModel.habilitarEstadoPagado()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Backend León de Judá activo en http://localhost:${PORT}`);
    });
  })
  .catch((err) => {
    console.error('No se pudo preparar la base de datos para los pedidos:', err.message);
    process.exitCode = 1;
  });

module.exports = app;