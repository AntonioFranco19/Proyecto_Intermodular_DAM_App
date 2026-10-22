import os
import time
from contextlib import contextmanager

import mysql.connector
from mysql.connector import Error

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "mysql"),
    "port": int(os.getenv("DB_PORT", "3306")),
    "user": os.getenv("DB_USER", "app_user"),
    "password": os.getenv("DB_PASSWORD", "app_password"),
    "database": os.getenv("DB_NAME", "app_db"),
    "charset": "utf8mb4",
}


def get_connection(retries: int = 30, delay: int = 2):
    """Conecta con MySQL, reintentando por si la base de datos aún no está lista."""
    for attempt in range(retries):
        try:
            return mysql.connector.connect(**DB_CONFIG)
        except Error:
            if attempt == retries - 1:
                raise
            time.sleep(delay)


def consultar(sql: str, params: tuple = ()):
    """SELECT: devuelve una lista de diccionarios."""
    conn = get_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(sql, params)
        return cursor.fetchall()
    finally:
        conn.close()


def consultar_uno(sql: str, params: tuple = ()):
    """SELECT que devuelve una sola fila, o None si no hay resultados."""
    resultados = consultar(sql, params)
    return resultados[0] if resultados else None


def ejecutar(sql: str, params: tuple = ()):
    """INSERT, UPDATE o DELETE de una sola sentencia. Devuelve el id generado (si lo hay)."""
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute(sql, params)
        conn.commit()
        return cursor.lastrowid
    except Error:
        conn.rollback()
        raise
    finally:
        conn.close()


@contextmanager
def transaccion():
    """
    Varias sentencias que deben completarse todas o ninguna.

    Uso:
        with transaccion() as cursor:
            cursor.execute("INSERT INTO pedidos ...", (...))
            cursor.execute("INSERT INTO pedido_detalle ...", (...))
    Si algo falla dentro del bloque, se deshace todo.
    """
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        yield cursor
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()