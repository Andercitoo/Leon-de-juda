const db = require('../config/db');

const UsuarioModel = {
  async findByDni(dni) {
    const res = await db.query('SELECT * FROM usuario WHERE dni = $1', [dni]);
    return res.rows[0];
  },

  async create({ dni, nombre, telefono, placa_vehiculo, modelo_moto, soat_vigente, password_hash }) {
    const query = `
      INSERT INTO usuario (dni, nombre, telefono, placa_vehiculo, modelo_moto, soat_vigente, password_hash)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING id_usuario, dni, nombre, telefono, placa_vehiculo, modelo_moto, soat_vigente;
    `;
    const values = [
      dni,
      nombre,
      telefono || null,
      placa_vehiculo,
      modelo_moto || null,
      soat_vigente,
      password_hash
    ];
    const res = await db.query(query, values);
    return res.rows[0];
  }
};

module.exports = UsuarioModel;