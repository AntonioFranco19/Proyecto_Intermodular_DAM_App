-- =====================================================
-- Base de datos: Pizzería App (TFG DAM)
-- Compatible con MySQL 8.0
-- Sustituye al init.sql anterior (sql/init.sql)
-- =====================================================
SET NAMES utf8mb4;
CREATE DATABASE IF NOT EXISTS app_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE app_db;

-- Borrar en orden inverso a las claves foráneas
DROP VIEW IF EXISTS v_pedidos_resumen;
DROP TABLE IF EXISTS pedido_detalle;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS cupones;
DROP TABLE IF EXISTS producto_ingredientes;
DROP TABLE IF EXISTS producto_precios;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS ingredientes;
DROP TABLE IF EXISTS categorias;
DROP TABLE IF EXISTS usuarios;

-- -----------------------------------------------------
-- Tabla: usuarios
-- Clientes y administradores. El rol decide la vista de la app.
-- password_hash: de momento en texto plano (pendiente de cambiar a bcrypt).
-- -----------------------------------------------------
CREATE TABLE usuarios (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL,
    email          VARCHAR(150) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    telefono       VARCHAR(20),
    direccion      VARCHAR(255),
    rol            ENUM('cliente', 'admin') NOT NULL DEFAULT 'cliente',
    activo         BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_alta     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------
-- Tabla: categorias (Pizzas, Bebidas, Postres...)
-- -----------------------------------------------------
CREATE TABLE categorias (
    id      INT AUTO_INCREMENT PRIMARY KEY,
    nombre  VARCHAR(50) NOT NULL UNIQUE,
    orden   INT NOT NULL DEFAULT 0
);

-- -----------------------------------------------------
-- Tabla: ingredientes
-- -----------------------------------------------------
CREATE TABLE ingredientes (
    id      INT AUTO_INCREMENT PRIMARY KEY,
    nombre  VARCHAR(80) NOT NULL UNIQUE
);

-- -----------------------------------------------------
-- Tabla: productos
-- stock NULL = sin control de stock (por ejemplo, pizzas hechas al momento)
-- -----------------------------------------------------
CREATE TABLE productos (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    categoria_id  INT NOT NULL,
    nombre        VARCHAR(150) NOT NULL,
    descripcion   VARCHAR(500),
    imagen_url    VARCHAR(255),
    stock         INT NULL CHECK (stock IS NULL OR stock >= 0),
    activo        BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_productos_categoria
        FOREIGN KEY (categoria_id) REFERENCES categorias(id)
);

-- -----------------------------------------------------
-- Tabla: producto_precios
-- Un producto tiene un precio por tamaño.
-- Las bebidas y postres usan el tamaño 'unica'.
-- -----------------------------------------------------
CREATE TABLE producto_precios (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    producto_id  INT NOT NULL,
    tamano       ENUM('individual', 'mediana', 'familiar', 'unica') NOT NULL,
    precio       DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
    UNIQUE KEY uq_producto_tamano (producto_id, tamano),
    CONSTRAINT fk_precios_producto
        FOREIGN KEY (producto_id) REFERENCES productos(id)
        ON DELETE CASCADE
);

-- -----------------------------------------------------
-- Tabla: producto_ingredientes (relación N:M)
-- -----------------------------------------------------
CREATE TABLE producto_ingredientes (
    producto_id    INT NOT NULL,
    ingrediente_id INT NOT NULL,
    PRIMARY KEY (producto_id, ingrediente_id),
    CONSTRAINT fk_pi_producto
        FOREIGN KEY (producto_id) REFERENCES productos(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_pi_ingrediente
        FOREIGN KEY (ingrediente_id) REFERENCES ingredientes(id)
);

-- -----------------------------------------------------
-- Tabla: cupones
-- tipo 'porcentaje': valor es un % (1-100)
-- tipo 'importe_fijo': valor es una cantidad en euros
-- usos_maximos NULL = sin límite
-- -----------------------------------------------------
CREATE TABLE cupones (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    codigo          VARCHAR(30) NOT NULL UNIQUE,
    tipo            ENUM('porcentaje', 'importe_fijo') NOT NULL,
    valor           DECIMAL(10,2) NOT NULL CHECK (valor > 0),
    pedido_minimo   DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (pedido_minimo >= 0),
    fecha_caducidad DATE NULL,
    usos_maximos    INT NULL CHECK (usos_maximos IS NULL OR usos_maximos > 0),
    usos_actuales   INT NOT NULL DEFAULT 0 CHECK (usos_actuales >= 0),
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_cupon_porcentaje
        CHECK (tipo <> 'porcentaje' OR valor <= 100)
);

-- -----------------------------------------------------
-- Tabla: pedidos
-- subtotal = suma de líneas; descuento = cupón aplicado; total = subtotal - descuento
-- direccion_entrega obligatoria solo en pedidos a domicilio
-- -----------------------------------------------------
CREATE TABLE pedidos (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id         INT NOT NULL,
    cupon_id           INT NULL,
    fecha              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado             ENUM('pendiente', 'en_preparacion', 'listo', 'entregado', 'cancelado')
                       NOT NULL DEFAULT 'pendiente',
    tipo_entrega       ENUM('recogida', 'domicilio') NOT NULL,
    direccion_entrega  VARCHAR(255) NULL,
    metodo_pago        ENUM('efectivo', 'tarjeta') NOT NULL,
    pagado             BOOLEAN NOT NULL DEFAULT FALSE,
    subtotal           DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
    descuento          DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (descuento >= 0),
    total              DECIMAL(10,2) NOT NULL CHECK (total >= 0),
    notas              VARCHAR(500),
    CONSTRAINT chk_pedido_total CHECK (total = subtotal - descuento),
    CONSTRAINT chk_pedido_descuento CHECK (descuento <= subtotal),
    CONSTRAINT chk_pedido_domicilio
        CHECK (tipo_entrega = 'recogida' OR direccion_entrega IS NOT NULL),
    CONSTRAINT fk_pedidos_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    CONSTRAINT fk_pedidos_cupon
        FOREIGN KEY (cupon_id) REFERENCES cupones(id)
);

-- -----------------------------------------------------
-- Tabla: pedido_detalle (líneas del pedido)
-- precio_unitario se copia del precio en el momento de la compra
-- -----------------------------------------------------
CREATE TABLE pedido_detalle (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id        INT NOT NULL,
    producto_id      INT NOT NULL,
    tamano           ENUM('individual', 'mediana', 'familiar', 'unica') NOT NULL,
    cantidad         INT NOT NULL CHECK (cantidad > 0),
    precio_unitario  DECIMAL(10,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal         DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    CONSTRAINT fk_detalle_pedido
        FOREIGN KEY (pedido_id) REFERENCES pedidos(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_detalle_producto
        FOREIGN KEY (producto_id) REFERENCES productos(id)
);

-- Índices para las consultas más habituales del panel de administración
CREATE INDEX idx_pedidos_estado ON pedidos (estado);
CREATE INDEX idx_pedidos_fecha ON pedidos (fecha);

-- -----------------------------------------------------
-- Datos de ejemplo
-- Contraseñas de desarrollo en texto plano (pendiente de bcrypt):
--   admin@pizzeria.com   -> admin1234
--   clientes             -> cliente1234
-- -----------------------------------------------------
INSERT INTO usuarios (nombre, email, password_hash, telefono, direccion, rol) VALUES
    ('Administrador', 'admin@pizzeria.com',
     'admin1234',
     '600000000', NULL, 'admin'),
    ('Ana García', 'ana.garcia@example.com',
     'cliente1234',
     '611111111', 'Calle Real 5, Lorca', 'cliente'),
    ('Luis Martínez', 'luis.martinez@example.com',
     'cliente1234',
     '622222222', 'Avenida del Mar 20, Lorca', 'cliente'),
    ('Marta López', 'marta.lopez@example.com',
     'cliente1234',
     '633333333', NULL, 'cliente');

INSERT INTO categorias (nombre, orden) VALUES
    ('Pizzas', 1),
    ('Bebidas', 2),
    ('Postres', 3);

INSERT INTO ingredientes (nombre) VALUES
    ('Tomate'), ('Mozzarella'), ('Albahaca'), ('Salsa barbacoa'), ('Pollo'),
    ('Bacon'), ('Cebolla'), ('Jamón York'), ('Piña'), ('Queso azul'),
    ('Queso parmesano'), ('Queso cheddar');

INSERT INTO productos (categoria_id, nombre, descripcion, stock) VALUES
    (1, 'Margarita',     'Tomate, mozzarella y albahaca fresca', NULL),
    (1, 'Barbacoa',      'Salsa barbacoa, pollo, bacon, cebolla y mozzarella', NULL),
    (1, 'Hawaiana',      'Tomate, mozzarella, jamón York y piña', NULL),
    (1, 'Cuatro Quesos', 'Mozzarella, queso azul, parmesano y cheddar', NULL),
    (2, 'Coca-Cola 33cl', 'Refresco de cola', 48),
    (2, 'Agua 50cl',      'Agua mineral', 60),
    (2, 'Cerveza 33cl',   'Cerveza rubia', 36),
    (3, 'Tiramisú',       'Postre italiano con mascarpone', 12),
    (3, 'Brownie',        'Brownie de chocolate con nueces', 12);

INSERT INTO producto_precios (producto_id, tamano, precio) VALUES
    (1, 'individual', 6.50),  (1, 'mediana', 9.50),  (1, 'familiar', 13.50),
    (2, 'individual', 7.50),  (2, 'mediana', 10.90), (2, 'familiar', 15.50),
    (3, 'individual', 7.00),  (3, 'mediana', 10.50), (3, 'familiar', 14.90),
    (4, 'individual', 7.90),  (4, 'mediana', 11.50), (4, 'familiar', 16.50),
    (5, 'unica', 2.20),
    (6, 'unica', 1.50),
    (7, 'unica', 2.50),
    (8, 'unica', 4.50),
    (9, 'unica', 4.00);

INSERT INTO producto_ingredientes (producto_id, ingrediente_id) VALUES
    (1, 1), (1, 2), (1, 3),
    (2, 2), (2, 4), (2, 5), (2, 6), (2, 7),
    (3, 1), (3, 2), (3, 8), (3, 9),
    (4, 2), (4, 10), (4, 11), (4, 12);

INSERT INTO cupones (codigo, tipo, valor, pedido_minimo, fecha_caducidad, usos_maximos, usos_actuales, activo) VALUES
    ('BIENVENIDA10', 'porcentaje',    10.00, 15.00, '2026-12-31', 100,  1, TRUE),
    ('VERANO5',      'importe_fijo',   5.00, 20.00, '2026-08-31', 50,   0, FALSE);

INSERT INTO pedidos (usuario_id, cupon_id, fecha, estado, tipo_entrega, direccion_entrega,
                     metodo_pago, pagado, subtotal, descuento, total) VALUES
    (2, NULL, '2026-10-10 13:10:00', 'entregado', 'recogida', NULL,
     'tarjeta', TRUE, 13.90, 0.00, 13.90),
    (3, 1,    '2026-10-15 21:05:00', 'en_preparacion', 'domicilio', 'Avenida del Mar 20, Lorca',
     'efectivo', FALSE, 20.00, 2.00, 18.00);

INSERT INTO pedido_detalle (pedido_id, producto_id, tamano, cantidad, precio_unitario) VALUES
    (1, 1, 'mediana',  1,  9.50),
    (1, 5, 'unica',    2,  2.20),
    (2, 2, 'familiar', 1, 15.50),
    (2, 8, 'unica',    1,  4.50);

-- -----------------------------------------------------
-- Vista para el listado de pedidos del panel de administración
-- -----------------------------------------------------
CREATE VIEW v_pedidos_resumen AS
SELECT p.id,
       p.fecha,
       p.estado,
       p.tipo_entrega,
       p.metodo_pago,
       p.pagado,
       u.nombre AS cliente,
       p.subtotal,
       p.descuento,
       p.total
FROM pedidos p
JOIN usuarios u ON u.id = p.usuario_id
ORDER BY p.id;