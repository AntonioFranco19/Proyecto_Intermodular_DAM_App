-- =====================================================
-- Base de datos de ejemplo: tienda online
-- Compatible con MySQL 8.0
-- =====================================================

CREATE DATABASE IF NOT EXISTS app_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE app_db;

-- Borrar tablas existentes (en orden por las claves foráneas)
DROP TABLE IF EXISTS pedido_detalle;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;

-- -----------------------------------------------------
-- Tabla: clientes
-- -----------------------------------------------------
CREATE TABLE clientes (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    email       VARCHAR(150) NOT NULL UNIQUE,
    ciudad      VARCHAR(100),
    fecha_alta  DATE NOT NULL
);

-- -----------------------------------------------------
-- Tabla: productos
-- -----------------------------------------------------
CREATE TABLE productos (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(150) NOT NULL,
    categoria   VARCHAR(50)  NOT NULL,
    precio      DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
    stock       INT NOT NULL DEFAULT 0 CHECK (stock >= 0)
);

-- -----------------------------------------------------
-- Tabla: pedidos
-- -----------------------------------------------------
CREATE TABLE pedidos (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id  INT NOT NULL,
    fecha       DATETIME NOT NULL,
    estado      ENUM('pendiente', 'enviado', 'entregado', 'cancelado') NOT NULL DEFAULT 'pendiente',
    CONSTRAINT fk_pedidos_cliente
        FOREIGN KEY (cliente_id) REFERENCES clientes(id)
        ON DELETE CASCADE
);

-- -----------------------------------------------------
-- Tabla: pedido_detalle (líneas de cada pedido)
-- -----------------------------------------------------
CREATE TABLE pedido_detalle (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id        INT NOT NULL,
    producto_id      INT NOT NULL,
    cantidad         INT NOT NULL CHECK (cantidad > 0),
    precio_unitario  DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_detalle_pedido
        FOREIGN KEY (pedido_id) REFERENCES pedidos(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_detalle_producto
        FOREIGN KEY (producto_id) REFERENCES productos(id)
);

-- -----------------------------------------------------
-- Datos de ejemplo
-- -----------------------------------------------------
INSERT INTO clientes (nombre, email, ciudad, fecha_alta) VALUES
    ('Ana García',       'ana.garcia@example.com',    'Madrid',    '2025-01-15'),
    ('Luis Martínez',    'luis.martinez@example.com', 'Barcelona', '2025-02-03'),
    ('Marta López',      'marta.lopez@example.com',   'Valencia',  '2025-03-21'),
    ('Javier Ruiz',      'javier.ruiz@example.com',   'Sevilla',   '2025-05-10'),
    ('Lucía Fernández',  'lucia.fernandez@example.com','Bilbao',   '2025-06-30');

INSERT INTO productos (nombre, categoria, precio, stock) VALUES
    ('Teclado mecánico',       'Periféricos', 89.99,  25),
    ('Ratón inalámbrico',      'Periféricos', 24.50,  60),
    ('Monitor 27" 4K',         'Monitores',   329.00, 10),
    ('Portátil 14"',           'Portátiles',  749.00,  5),
    ('Auriculares Bluetooth',  'Audio',       59.90,  40),
    ('Webcam HD 1080p',        'Periféricos', 39.95,  30);

INSERT INTO pedidos (cliente_id, fecha, estado) VALUES
    (1, '2025-07-01 10:15:00', 'entregado'),
    (2, '2025-07-05 16:40:00', 'enviado'),
    (1, '2025-08-12 09:05:00', 'pendiente'),
    (3, '2025-08-20 18:22:00', 'cancelado'),
    (4, '2025-09-02 12:00:00', 'entregado');

INSERT INTO pedido_detalle (pedido_id, producto_id, cantidad, precio_unitario) VALUES
    (1, 1, 1, 89.99),
    (1, 2, 2, 24.50),
    (2, 4, 1, 749.00),
    (3, 5, 1, 59.90),
    (3, 6, 1, 39.95),
    (4, 3, 1, 329.00),
    (5, 3, 2, 329.00),
    (5, 2, 1, 24.50);

-- -----------------------------------------------------
-- Consulta de comprobación: total por pedido
-- -----------------------------------------------------
SELECT
    p.id AS pedido,
    c.nombre AS cliente,
    p.estado,
    SUM(d.cantidad * d.precio_unitario) AS total
FROM pedidos p
JOIN clientes c       ON c.id = p.cliente_id
JOIN pedido_detalle d ON d.pedido_id = p.id
GROUP BY p.id, c.nombre, p.estado
ORDER BY p.id;