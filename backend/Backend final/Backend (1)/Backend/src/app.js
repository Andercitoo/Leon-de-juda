const express = require('express');
const cors = require('cors');
require('dotenv').config();
process.env.DATABASE_URL = "postgres://postgres:@D70646634@localhost:5432/leondejuda";
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

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Backend León de Judá activo en http://localhost:${PORT}`);
});

module.exports = app;