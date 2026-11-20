const db = require('../config/db');

const RepuestoModel = {
  async findAll({ marca, categoria, busqueda }) {
    let query = `
      SELECT id_repuesto, nombre, marca, categoria_averia, precio_unitario, stock_disponible, stock_bloqueado
      FROM repuesto
      WHERE 1=1
    `;
    const params = [];

    if (marca && marca !== 'Todas') {
      params.push(marca);
      query += ` AND marca = $${params.length}`;
    }

    if (categoria && categoria !== 'Todas') {
      params.push(categoria);
      query += ` AND categoria_averia = $${params.length}`;
    }

    if (busqueda) {
      params.push(`%${busqueda}%`);
      query += ` AND nombre ILIKE $${params.length}`;
    }

    query += ` ORDER BY id_repuesto ASC;`;

    const res = await db.query(query, params);
    return res.rows;
  }
};

module.exports = RepuestoModel;