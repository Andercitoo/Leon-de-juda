const pool = require('../config/db');

const crearPedido = async (req, res) => {
    const { id_usuario, repuestos, modalidad_entrega } = req.body;

    try {
        await pool.query('BEGIN');

        let total = 0;
        for (let item of repuestos) {
            total += (item.cantidad * item.precio);
        }

        let costo_envio = 0.00;
        let modalidad_final = modalidad_entrega;
        
        if (modalidad_entrega === 'Delivery') {
            if (total < 30.00) {
                modalidad_final = 'Recojo en tienda'; 
            } else {
                costo_envio = 5.00; 
            }
        }

        const total_pagar = total + costo_envio;

        const queryPedido = `
            INSERT INTO pedido (id_usuario, modalidad_entrega, costo_envio, total_pagar, estado_pedido, expira_reserva)
            VALUES ($1, $2, $3, $4, 'Pendiente', NOW() + INTERVAL '15 minutes') RETURNING id_pedido, expira_reserva
        `;
        const resultPedido = await pool.query(queryPedido, [id_usuario, modalidad_final, costo_envio, total_pagar]);
        const nuevoPedido = resultPedido.rows[0];

        for (let item of repuestos) {
            await pool.query('INSERT INTO detalle_pedido (id_pedido, id_repuesto, cantidad, subtotal) VALUES ($1, $2, $3, $4)', 
                [nuevoPedido.id_pedido, item.id_repuesto, item.cantidad, item.cantidad * item.precio]);
            
            await pool.query('UPDATE repuesto SET stock_disponible = stock_disponible - $1, stock_bloqueado = stock_bloqueado + $1 WHERE id_repuesto = $2', 
                [item.cantidad, item.id_repuesto]);
        }

        await pool.query('COMMIT'); 
        res.status(201).json({ 
            mensaje: 'Pedido creado y stock reservado por 15 min', 
            modalidad_aplicada: modalidad_final,
            pedido: nuevoPedido 
        });
    } catch (err) {
        await pool.query('ROLLBACK'); 
        res.status(500).json({ error: 'Error procesando pedido: ' + err.message });
    }
};

module.exports = { crearPedido };