const db = require('../config/db');

const AuxilioModel = {
  async countActivos() {
    const res = await db.query(
      `SELECT COUNT(*) FROM auxilio_mecanico WHERE estado_auxilio IN ('Pendiente', 'En camino')`
    );
    return parseInt(res.rows[0].count, 10);
  },

  async create({ id_usuario, latitud, longitud, distancia_km, tipo_falla, referencia }) {
    const query = `
      INSERT INTO auxilio_mecanico (id_usuario, latitud, longitud, distancia_km, tipo_falla, referencia, estado_auxilio)
      VALUES ($1, $2, $3, $4, $5, $6, 'Pendiente')
      RETURNING *;
    `;
    const values = [id_usuario, latitud, longitud, distancia_km, tipo_falla, referencia];
    const res = await db.query(query, values);
    return res.rows[0];
  },

  async updateEstado(id_auxilio, nuevoEstado) {
    const query = `
      UPDATE auxilio_mecanico 
      SET estado_auxilio = $1 
      WHERE id_auxilio = $2 
      RETURNING *;
    `;
    const res = await db.query(query, [nuevoEstado, id_auxilio]);
    return res.rows[0];
  }
};

module.exports = AuxilioModel;