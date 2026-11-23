-- =====================================================
-- schema.sql  |  León de Judá  |  PostgreSQL
-- Uso: psql -U postgres -d leondejuda -f schema.sql
-- Basado en la Figura 19 (modelo físico ER) del documento
-- =====================================================

DROP TABLE IF EXISTS detalle_pedido    CASCADE;
DROP TABLE IF EXISTS auxilio_mecanico  CASCADE;
DROP TABLE IF EXISTS pedido            CASCADE;
DROP TABLE IF EXISTS repuesto          CASCADE;
DROP TABLE IF EXISTS usuario           CASCADE;

-- 1. USUARIO (RN-S01: DNI 8 dígitos, placa 6 caracteres, SOAT vigente)
CREATE TABLE usuario (
    id_usuario     SERIAL PRIMARY KEY,
    dni            VARCHAR(8)   NOT NULL UNIQUE CHECK (dni ~ '^[0-9]{8}$'),
    nombre         VARCHAR(80)  NOT NULL,
    telefono       VARCHAR(9)   NOT NULL CHECK (telefono ~ '^[0-9]{9}$'),
    placa_vehiculo VARCHAR(6)   NOT NULL UNIQUE CHECK (char_length(placa_vehiculo) = 6),
    modelo_moto    VARCHAR(40)  NOT NULL,
    soat_vigente   BOOLEAN      NOT NULL DEFAULT FALSE,
    password_hash  VARCHAR(255) NOT NULL
);

-- 2. REPUESTO (RN-V01: stock_disponible y stock_bloqueado)
CREATE TABLE repuesto (
    id_repuesto      SERIAL PRIMARY KEY,
    nombre           VARCHAR(100)  NOT NULL,
    marca            VARCHAR(30)   NOT NULL,
    categoria_averia VARCHAR(40)   NOT NULL,
    precio_unitario  NUMERIC(8,2)  NOT NULL CHECK (precio_unitario > 0),
    stock_disponible INT           NOT NULL DEFAULT 0 CHECK (stock_disponible >= 0),
    stock_bloqueado  INT           NOT NULL DEFAULT 0 CHECK (stock_bloqueado  >= 0)
);

-- 3. PEDIDO (RN-P01 envío desde S/ 30.00; RN-V01 reserva de 15 min en expira_reserva)
CREATE TABLE pedido (
    id_pedido         SERIAL PRIMARY KEY,
    id_usuario        INT           NOT NULL REFERENCES usuario(id_usuario),
    modalidad_entrega VARCHAR(20)   NOT NULL
                      CHECK (modalidad_entrega IN ('Delivery', 'Recojo en tienda')),
    costo_envio       NUMERIC(6,2)  NOT NULL DEFAULT 0 CHECK (costo_envio >= 0),
    total_pagar       NUMERIC(8,2)  NOT NULL CHECK (total_pagar >= 0),
    estado_pedido     VARCHAR(20)   NOT NULL DEFAULT 'Pendiente'
                      CHECK (estado_pedido IN ('Pendiente', 'Confirmado', 'Pagado', 'Cancelado', 'Expirado')),
    expira_reserva    TIMESTAMP
);

-- 4. DETALLE_PEDIDO
CREATE TABLE detalle_pedido (
    id_detalle  SERIAL PRIMARY KEY,
    id_pedido   INT           NOT NULL REFERENCES pedido(id_pedido) ON DELETE CASCADE,
    id_repuesto INT           NOT NULL REFERENCES repuesto(id_repuesto),
    cantidad    INT           NOT NULL CHECK (cantidad > 0),
    subtotal    NUMERIC(8,2)  NOT NULL CHECK (subtotal >= 0)
);

-- 5. AUXILIO_MECANICO (estados según PATCH /api/auxilios/:id; RN-R01 radio <= 3.5 km)
CREATE TABLE auxilio_mecanico (
    id_auxilio       SERIAL PRIMARY KEY,
    id_usuario       INT           NOT NULL REFERENCES usuario(id_usuario),
    latitud          NUMERIC(9,6)  NOT NULL,
    longitud         NUMERIC(9,6)  NOT NULL,
    distancia_km     NUMERIC(4,2)  NOT NULL CHECK (distancia_km >= 0 AND distancia_km <= 3.50),
    tipo_falla       VARCHAR(50)   NOT NULL,
    referencia       VARCHAR(150),
    estado_auxilio   VARCHAR(20)   NOT NULL DEFAULT 'Pendiente'
                     CHECK (estado_auxilio IN ('Pendiente', 'En camino', 'Finalizado'))
);

-- RN-R03: solo 1 auxilio "En camino" a la vez (un único técnico)
CREATE UNIQUE INDEX uq_un_auxilio_en_camino
    ON auxilio_mecanico ((1)) WHERE estado_auxilio = 'En camino';

-- Índices de rendimiento (RNF-01 < 200 ms)
CREATE INDEX idx_repuesto_marca_categoria ON repuesto (marca, categoria_averia);
CREATE INDEX idx_pedido_usuario           ON pedido (id_usuario);
CREATE INDEX idx_pedido_expira            ON pedido (expira_reserva) WHERE estado_pedido = 'Pendiente';
CREATE INDEX idx_detalle_pedido           ON detalle_pedido (id_pedido);
CREATE INDEX idx_auxilio_estado           ON auxilio_mecanico (estado_auxilio);
