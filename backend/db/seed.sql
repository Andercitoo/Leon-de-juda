-- =====================================================
-- seed.sql  |  Datos iniciales de prueba
-- Uso: psql -U postgres -d leondejuda -f seed.sql
-- Contraseña de todos los usuarios de prueba: Test1234
-- =====================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- bcrypt ($2a$) compatible con la librería bcrypt de Node

INSERT INTO usuario (dni, nombre, telefono, placa_vehiculo, modelo_moto, soat_vigente, password_hash) VALUES
('45871236', 'Juan Pérez Quispe',   '987654321', '1234AB', 'Bajaj RE 205',  TRUE,  crypt('Test1234', gen_salt('bf', 10))),
('70123456', 'Luis Ramos Huamán',   '976543210', '5678CD', 'TVS King 4S',   TRUE,  crypt('Test1234', gen_salt('bf', 10))),
('41236587', 'Carlos Mendoza Rojas','965432109', '9012EF', 'Bajaj Torito',  TRUE,  crypt('Test1234', gen_salt('bf', 10))),
('72589631', 'Pedro Salas Vargas',  '954321098', '3456GH', 'TVS King Deluxe', FALSE, crypt('Test1234', gen_salt('bf', 10)));

INSERT INTO repuesto (nombre, marca, categoria_averia, precio_unitario, stock_disponible, stock_bloqueado) VALUES
('Pastillas de freno delanteras', 'Bajaj', 'Frenos',      18.50, 25, 0),
('Zapatas de freno posteriores',  'TVS',   'Frenos',      22.00, 20, 0),
('Kit de embrague',               'Bajaj', 'Transmisión', 65.00, 10, 0),
('Cable de acelerador',           'TVS',   'Acelerador',  12.00, 30, 0),
('Bujía NGK',                     'Bajaj', 'Motor',        9.50, 50, 0),
('Filtro de aire',                'TVS',   'Motor',       15.00, 18, 0),
('Faro delantero LED',            'Bajaj', 'Eléctrico',   45.00,  8, 0),
('Batería 12V',                   'TVS',   'Eléctrico',   95.00,  5, 0),
('Llanta 4.00-8 con cámara',      'Bajaj', 'Llantas',     85.00, 12, 0),
('Cadena de transmisión',         'TVS',   'Transmisión', 38.00,  1, 0);

-- Pedido confirmado: 2 pastillas de freno + 1 bujía = 46.50 + envío 5.00
INSERT INTO pedido (id_usuario, modalidad_entrega, costo_envio, total_pagar, estado_pedido, expira_reserva) VALUES
(1, 'Delivery', 5.00, 51.50, 'Confirmado', NULL);
INSERT INTO detalle_pedido (id_pedido, id_repuesto, cantidad, subtotal) VALUES
(1, 1, 2, 37.00),
(1, 5, 1,  9.50);

-- Pedido pendiente con reserva de 15 min (RN-V01): 1 kit de embrague
INSERT INTO pedido (id_usuario, modalidad_entrega, costo_envio, total_pagar, estado_pedido, expira_reserva) VALUES
(2, 'Recojo en tienda', 0.00, 65.00, 'Pendiente', NOW() + INTERVAL '15 minutes');
INSERT INTO detalle_pedido (id_pedido, id_repuesto, cantidad, subtotal) VALUES
(2, 3, 1, 65.00);
UPDATE repuesto SET stock_disponible = stock_disponible - 1, stock_bloqueado = stock_bloqueado + 1
WHERE id_repuesto = 3;

-- Auxilios (coordenadas cerca del taller: -12.215840, -76.931420)
INSERT INTO auxilio_mecanico (id_usuario, latitud, longitud, distancia_km, tipo_falla, referencia, estado_auxilio) VALUES
(3, -12.222000, -76.935000, 0.80, 'Llanta ponchada',  'Frente al paradero principal', 'Finalizado'),
(1, -12.230000, -76.925000, 1.80, 'No enciende',      'Cerca al mercado',             'En camino');
