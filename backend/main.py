from fastapi import FastAPI, HTTPException

from db import consultar, consultar_uno

app = FastAPI(title="API Pizzería", version="1.0.0")


@app.get("/")
def raiz():
    return {"mensaje": "API Pizzería funcionando"}


@app.get("/clientes")
def listar_clientes():
    return consultar(
        """
        SELECT id, nombre, email, telefono, direccion, fecha_alta
        FROM usuarios
        WHERE rol = 'cliente'
        ORDER BY id
        """
    )


@app.get("/clientes/{cliente_id}")
def obtener_cliente(cliente_id: int):
    cliente = consultar_uno(
        """
        SELECT id, nombre, email, telefono, direccion, fecha_alta
        FROM usuarios
        WHERE id = %s AND rol = 'cliente'
        """,
        (cliente_id,),
    )
    if cliente is None:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return cliente


@app.get("/productos")
def listar_productos():
    productos = consultar(
        """
        SELECT p.id, p.nombre, p.descripcion, c.nombre AS categoria, p.stock
        FROM productos p
        JOIN categorias c ON c.id = p.categoria_id
        WHERE p.activo = TRUE
        ORDER BY c.orden, p.id
        """
    )
    precios = consultar(
        """
        SELECT pp.producto_id, pp.tamano, pp.precio
        FROM producto_precios pp
        JOIN productos p ON p.id = pp.producto_id
        WHERE p.activo = TRUE
        """
    )
    for producto in productos:
        producto["precios"] = [
            {"tamano": pr["tamano"], "precio": float(pr["precio"])}
            for pr in precios
            if pr["producto_id"] == producto["id"]
        ]
    return productos


@app.get("/pedidos")
def listar_pedidos():
    return consultar("SELECT * FROM v_pedidos_resumen")