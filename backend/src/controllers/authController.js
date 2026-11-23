const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const UsuarioModel = require('../models/usuarioModel');

const DNI_REGEX = /^[0-9]{8}$/;
const PLACA_REGEX = /^[A-Z0-9]{6}$/;

exports.registro = async (req, res) => {
  try {
    const { dni, nombre, telefono, placa_vehiculo, modelo_moto, soat_vigente, password } = req.body;

    if (!dni || !DNI_REGEX.test(dni)) {
      return res.status(400).json({ error: 'RN-S01: El DNI debe tener exactamente 8 dígitos.' });
    }

    const placaLimpia = placa_vehiculo ? placa_vehiculo.trim().toUpperCase() : '';
    if (!PLACA_REGEX.test(placaLimpia)) {
      return res.status(400).json({ error: 'RN-S01: La placa debe tener 6 caracteres alfanuméricos.' });
    }

    if (soat_vigente !== true) {
      return res.status(400).json({ error: 'RN-S01: Registro exclusivo para vehículos con SOAT vigente.' });
    }

    if (!nombre || !password) {
      return res.status(400).json({ error: 'Campos requeridos incompletos.' });
    }

    const existente = await UsuarioModel.findByDni(dni);
    if (existente) {
      return res.status(409).json({ error: 'El DNI ya se encuentra registrado.' });
    }

    const password_hash = await bcrypt.hash(password, 10);

    const nuevoUsuario = await UsuarioModel.create({
      dni,
      nombre,
      telefono: telefono || null,
      placa_vehiculo: placaLimpia,
      modelo_moto: modelo_moto || null,
      soat_vigente,
      password_hash
    });

    return res.status(201).json({
      mensaje: 'Conductor registrado con éxito.',
      usuario: nuevoUsuario
    });
  } catch (error) {
    console.error('Error en registro:', error);
    return res.status(500).json({ error: 'Error interno en el servidor.' });
  }
};

exports.login = async (req, res) => {
  try {
    const { dni, password } = req.body;
    if (!dni || !password) {
      return res.status(400).json({ error: 'DNI y contraseña obligatorios.' });
    }

    const usuario = await UsuarioModel.findByDni(dni);
    if (!usuario) {
      return res.status(401).json({ error: 'Credenciales inválidas.' });
    }

    const match = await bcrypt.compare(password, usuario.password_hash);
    if (!match) {
      return res.status(401).json({ error: 'Credenciales inválidas.' });
    }

    const token = jwt.sign(
      { id_usuario: usuario.id_usuario, dni: usuario.dni, placa: usuario.placa_vehiculo },
      process.env.JWT_SECRET,
      { expiresIn: '12h' }
    );

    return res.status(200).json({
      mensaje: 'Autenticación exitosa.',
      token,
      usuario: {
        id_usuario: usuario.id_usuario,
        nombre: usuario.nombre,
        dni: usuario.dni,
        telefono: usuario.telefono || '',
        placa_vehiculo: usuario.placa_vehiculo,
        modelo_moto: usuario.modelo_moto || 'Sin especificar',
        soat_vigente: usuario.soat_vigente ?? true
      }
    });
  } catch (error) {
    console.error('Error en login:', error);
    return res.status(500).json({ error: 'Error interno en el servidor.' });
  }
};