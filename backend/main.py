import os
import time

import mysql.connector
from fastapi import FastAPI, HTTPException

app = FastAPI(title="API Tienda", version="1.0.0")

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "mysql"),
    "port": int(os.getenv("DB_PORT", "3306")),
    "user": os.getenv("DB_USER", "app_user"),
    "password": os.getenv("DB_PASSWORD", "app_password"),
    "database": os.getenv("DB_NAME", "app_db"),
}


def get_connection(retries: int = 30, delay: int = 2):
    """Conecta con MySQL, reintentando por si la base de datos aún no está lista."""
    for attempt in range(retries):
        try:
            return mysql.connector.connect(**DB_CONFIG)
        except mysql.connector.Error:
            if attempt == retries - 1:
                raise
            time.sleep(delay)


def consultar(sql: str, params: tuple = ()):
    conn = get_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(sql, params)
        return cursor.fetchall()
    finally:
        conn.close()


@app.get("/")
def raiz():
    return {"mensaje": "API Tienda funcionando"}


@app.get("/clientes")
def listar_clientes():
    return consultar(
        "SELECT id, nombre, email, ciudad, fecha_alta FROM clientes ORDER BY id"
    )


@app.get("/clientes/{cliente_id}")
def obtener_cliente(cliente_id: int):
    resultado = consultar(
        "SELECT id, nombre, email, ciudad, fecha_alta FROM clientes WHERE id = %s",
        (cliente_id,),
    )
    if not resultado:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return resultado[0]


@app.get("/productos")
def listar_productos():
    return consultar(
        "SELECT id, nombre, categoria, precio, stock FROM productos ORDER BY id"
    )


@app.get("/pedidos")
def listar_pedidos():
    return consultar(
        """
        SELECT p.id, p.fecha, p.estado, c.nombre AS cliente,
               COALESCE(SUM(d.cantidad * d.precio_unitario), 0) AS total
        FROM pedidos p
        JOIN clientes c ON c.id = p.cliente_id
        LEFT JOIN pedido_detalle d ON d.pedido_id = p.id
        GROUP BY p.id, p.fecha, p.estado, c.nombre
        ORDER BY p.id
        """
    )