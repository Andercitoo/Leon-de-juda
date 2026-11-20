const pool = require('../config/db');

const obtenerCatalogo = async (req, res) => {
    try {
        const result = await pool.query('SELECT * FROM repuesto WHERE stock_disponible > 0 ORDER BY nombre ASC');
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

module.exports = { obtenerCatalogo };