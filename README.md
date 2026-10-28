# Pizzería App

Aplicación para la gestión de pedidos de una pizzería, desarrollada como Trabajo de Fin de Grado del ciclo superior de Desarrollo de Aplicaciones Multiplataforma (DAM).

El proyecto combina una aplicación cliente, pensada para realizar pedidos de forma sencilla, con un panel de administración de escritorio para gestionar la carta, los pedidos y los cupones.

---

## Índice

- [Descripción](#descripción)
- [Funcionalidades](#funcionalidades)
- [Arquitectura](#arquitectura)
- [Stack tecnológico](#stack-tecnológico)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Requisitos previos](#requisitos-previos)
- [Puesta en marcha](#puesta-en-marcha)
- [API](#api)
- [Flujo de trabajo](#flujo-de-trabajo)
- [Integración continua](#integración-continua)
- [Equipo](#equipo)

---

## Descripción

El sistema permite a los clientes consultar la carta, componer su pedido, elegir un método de pago y aplicar cupones de descuento. El personal de la pizzería, desde el panel de administración, recibe los pedidos, actualiza su estado y mantiene el catálogo.

La aplicación se compone de un único cliente Flutter que, tras autenticarse, muestra la vista correspondiente al rol del usuario: **cliente** o **administrador**.

## Funcionalidades

### Vista de cliente

- Consulta del catálogo de productos
- Carrito de compra y confirmación del pedido
- Selección del método de pago
- Aplicación de cupones de descuento
- Historial de pedidos

### Vista de administración

- Listado de pedidos y cambio de estado
- Gestión de productos y stock
- Gestión de cupones
- Resumen de ventas

> El proyecto se desarrolla de forma incremental. Consulta la sección de [Flujo de trabajo](#flujo-de-trabajo) para ver el estado de cada funcionalidad.

## Arquitectura

```
┌────────────────────────┐        HTTP / JSON        ┌──────────────────┐        ┌──────────────┐
│  Cliente Flutter       │ ────────────────────────▶ │  API FastAPI     │ ─────▶ │  MySQL 8.0   │
│  (cliente / admin)     │ ◀──────────────────────── │  (Python 3.12)   │ ◀───── │              │
└────────────────────────┘                           └──────────────────┘        └──────────────┘
```

- **Frontend:** una única aplicación Flutter con dos vistas según el rol del usuario autenticado.
- **Backend:** API REST con FastAPI. Gestiona la lógica de negocio, la autenticación y el acceso a datos.
- **Base de datos:** MySQL 8.0, con el esquema definido en `sql/init.sql`.

## Stack tecnológico

### Backend

| Componente | Uso |
|---|---|
| FastAPI | Framework de la API REST |
| mysql-connector-python | Acceso a MySQL |
| PyJWT | Generación y validación de tokens de autenticación |
| bcrypt | Hash seguro de contraseñas |
| Uvicorn | Servidor ASGI |

### Base de datos

| Componente | Uso |
|---|---|
| MySQL 8.0 | Motor de base de datos relacional |
| phpMyAdmin | Administración y consulta de la base de datos en desarrollo |

### Frontend

| Componente | Uso |
|---|---|
| Flutter / Dart | Framework multiplataforma para la interfaz |
| `package:http` | Comunicación con la API |

El proyecto prioriza el uso de las librerías nativas de Flutter. Las dependencias externas se incorporan únicamente cuando su necesidad está justificada.

### Infraestructura y flujo de trabajo

| Componente | Uso |
|---|---|
| Docker y Docker Compose | Entorno de desarrollo reproducible (base de datos, API y phpMyAdmin) |
| GitHub | Control de versiones y colaboración |
| GitHub Actions | Integración continua (en configuración) |

## Estructura del repositorio

```
.
├── backend/              # API FastAPI
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/             # Aplicación Flutter
│   ├── lib/
│   ├── test/
│   ├── android/
│   └── windows/
├── sql/
│   └── init.sql          # Esquema y datos de ejemplo
├── docker-compose.yml
└── README.md
```

## Requisitos previos

- [Docker](https://docs.docker.com/get-docker/) y Docker Compose
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión compatible con `sdk: ^3.13.5`)
- Git

Para ejecutar la aplicación de escritorio en Windows se requiere Visual Studio con la carga de trabajo «Desarrollo para el escritorio con C++».

## Puesta en marcha

### 1. Base de datos y API

Desde la raíz del repositorio:

```bash
docker compose up -d --build
```

Servicios disponibles tras el arranque:

| Servicio | URL |
|---|---|
| API | http://localhost:8000 |
| Documentación interactiva (Swagger) | http://localhost:8000/docs |
| phpMyAdmin | http://localhost:8080 |

Para detener los servicios:

```bash
docker compose down
```

### 2. Frontend

```bash
cd frontend
flutter pub get
flutter run
```

Para ejecutar la versión de escritorio en Windows:

```bash
flutter run -d windows
```

> Si la app se ejecuta en un emulador de Android, la API del equipo anfitrión se alcanza en `http://10.0.2.2:8000`.

## API

Endpoints disponibles actualmente (solo lectura):

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/` | Comprobación de estado de la API |
| GET | `/clientes` | Listado de clientes |
| GET | `/clientes/{id}` | Detalle de un cliente |
| GET | `/productos` | Listado de productos |
| GET | `/pedidos` | Listado de pedidos con su total |

La documentación completa y actualizada de cada endpoint está disponible en `/docs`.

## Flujo de trabajo

El desarrollo se organiza con ramas y Pull Requests:

- `main`: versión estable del proyecto. No se escribe directamente.
- `develop`: rama de integración donde se unen las funcionalidades terminadas.
- `feature/<nombre-funcionalidad>`: una rama por funcionalidad o tarea, creada a partir de `develop`.

Proceso para cada cambio:

1. Crear una rama `feature/...` desde `develop`.
2. Desarrollar y probar los cambios en local.
3. Abrir un Pull Request hacia `develop` con una descripción clara del cambio.
4. Revisión por al menos otro integrante del equipo.
5. Integración en `develop` una vez aprobado y con los tests en verde.

Las versiones estables se pasan de `develop` a `main` mediante un Pull Request.

## Integración continua

GitHub Actions ejecutará en cada Pull Request las siguientes comprobaciones:

- **Backend:** análisis y tests de la API.
- **Frontend:** `flutter analyze` y `flutter test`.

> Estado: en configuración.

## Equipo

| Nombre | Rol |
|---|---|
| [Nombre 1] | [Rol] |
| [Nombre 2] | [Rol] |
| [Nombre 3] | [Rol] |

## Licencia

Proyecto académico desarrollado como Trabajo de Fin de Grado. Uso educativo.