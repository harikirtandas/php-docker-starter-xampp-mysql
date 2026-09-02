# php-docker-starter-xampp-mysql

Plantilla de GitHub para reproducir el flujo de trabajo de XAMPP (Apache + PHP +
MySQL sirviendo `htdocs/` desde un panel de control) usando Docker, sin instalar
XAMPP en la maquina. Pensada para materias, cursos o instructivos que asumen XAMPP
con carpetas sueltas de archivos `.php` (por ejemplo, una carpeta por semana o por
practico), donde conviene reproducir ese mismo flujo (`http://localhost`, archivos
`.php` sueltos sin router) en vez de adaptar cada consigna al enfoque de
`php-docker-starter-apache-mysql`.

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (o Docker Engine + Compose plugin) corriendo.
- [GitHub CLI](https://cli.github.com/) (`gh`) para crear proyectos nuevos desde la terminal. Alternativa: boton **"Use this template"** en GitHub.

## Crear un proyecto nuevo desde este template

```bash
gh repo create mi-curso --template TU_USUARIO/php-docker-starter-xampp-mysql --private --clone
cd mi-curso
make install
```

Al terminar, la app esta en **http://localhost** y Adminer en **http://localhost:8081**.

## Equivalencias con un instructivo pensado para XAMPP

Si el instructivo que estas siguiendo asume XAMPP, esta tabla traduce cada paso a lo que hay que hacer en este repo:

| Instructivo XAMPP | En este repo |
|---|---|
| Instalar XAMPP | `make install` |
| Arrancar Apache desde el panel de control | `make up` |
| `http://localhost` | `http://localhost` |
| `htdocs/` | `src/public/` |
| `htdocs/semanaN` | `src/public/semanaN` |
| phpMyAdmin | Adminer en `http://localhost:8081` |
| Puerto 80 ocupado en Mac | No aplica (Apache corre dentro del contenedor) |

## Trabajar por carpetas (semanas, practicos, lo que sea)

Cada unidad de trabajo es una carpeta con archivos `.php` sueltos dentro de
`src/public/`, servidos directo por Apache (sin front controller ni router).

```bash
make semana N=6
```

Crea `src/public/semana6/` con un `index.php` minimo adentro. La URL queda
`http://localhost/semana6/`. Es solo una convencion de nombre del target de
`Makefile`: si el instructivo usa otra palabra ("practico", "modulo", "clase"),
alcanza con copiar el bloque `semana:` y renombrarlo.

## Acceder desde el celular

El telefono no resuelve `localhost` (esa direccion siempre apunta al propio
dispositivo). Para probar la app desde el celular hay que usar la IP LAN de la Mac:

```bash
make ip
```

Esto imprime la IP de la Mac en la red local y la URL completa para abrir desde el
navegador del celular. Requisitos:

- La Mac y el celular tienen que estar conectados a la **misma red Wi-Fi**.
- Si la URL no responde, lo mas probable es que el **firewall de macOS** este
  bloqueando las conexiones entrantes a Docker. Revisar en Ajustes del Sistema ->
  Red -> Firewall, o permitir la conexion la primera vez que macOS pregunta.

## Arquitectura

Un solo contenedor de aplicacion (`php:8.2-apache`, mod_php) mas MySQL y Adminer:

| Servicio | Imagen | Rol |
|---|---|---|
| `app` | build propio, `php:8.2-apache` | Apache y PHP en el mismo proceso. Publica `APP_PORT` (default 80). |
| `mysql` | `mysql:8` | Base de datos, volumen persistente `mysql-data` + healthcheck. `app` espera a que este *healthy* antes de arrancar. Opcional: se usa solo si algun ejercicio pide base de datos. |
| `adminer` | `adminer` | Cliente web de MySQL, publica `ADMINER_PORT` (default 8081). |

`./src` se monta como bind mount en `app`: `src/public` es el docroot, `src/app` es
codigo privado fuera del docroot (por ejemplo `src/app/db.php`, opcional).

`src/` esta versionado en este repo: el contenido de cada carpeta queda commiteado
junto con el entorno, no hay que regenerar nada al clonar.

## Comandos disponibles (Makefile)

| Comando | Que hace |
|---|---|
| `make install` | Instala dependencias de Composer si hace falta, levanta los tres contenedores. Correlo una sola vez por proyecto. |
| `make up` | Levanta los contenedores en segundo plano. |
| `make down` | Apaga los contenedores. **No borra datos**: `mysql-data` es un volumen con nombre. |
| `make restart` | Reinicia los contenedores sin rebuildear. |
| `make shell` | Abre una terminal `bash` dentro del contenedor `app`. |
| `make db-shell` | Abre el cliente `mysql` conectado a la base del proyecto. |
| `make logs` | Sigue los logs de todos los servicios. |
| `make db-import FILE=dump.sql` | Aplica un `.sql` a la base ya corriendo (dump completo o cambios incrementales), sin recrear el volumen ni perder datos. |
| `make fresh` | Borra el volumen de MySQL y vuelve a levantar todo de cero (reaplica todo `docker/mysql/init/*.sql`). Pide confirmacion explicita. |
| `make semana N=6` | Crea `src/public/semanaN` con un `index.php` minimo adentro. |
| `make ip` | Imprime la IP LAN de la Mac y la URL completa para abrir desde el celular. |

## Configuracion (`.env` en la raiz, versionado)

A diferencia de `php-docker-starter-apache-mysql` (donde `.env` esta gitignoreado
porque puede tener secretos reales), en este template el `.env` **esta versionado**:
no hay secretos, y la idea es que la config viaje junto con el codigo, igual que un
XAMPP recien instalado no requiere configuracion adicional.

```bash
APP_PORT=80
ADMINER_PORT=8081
DB_DATABASE=app
DB_USERNAME=app
DB_PASSWORD=secret
```

`src/app/db.php` lee estas mismas variables con `getenv()` dentro del contenedor
`app` (docker-compose las inyecta como `environment:`), pero es opcional: si el
instructivo ensena `mysqli_connect()`, se usa directamente sin pasar por este
archivo.

## Agregar tablas nuevas sin perder datos

`docker/mysql/init/*.sql` solo corre en el primer arranque del volumen `mysql-data`
(ver tabla de arriba: `make fresh` es lo unico que los reaplica, y de paso borra
todo). Para sumar una tabla o columna a un proyecto que ya tiene datos cargados, sin
tocar lo que ya hay:

1. Guardá el archivo en `docker/mysql/init/`, con el siguiente numero de orden:
   `01-nombre-descriptivo.sql`, `02-otra-cosa.sql`, etc.
2. Aplicalo a la base que ya esta corriendo, sin pasar por `make fresh`:
   ```bash
   make db-import FILE=docker/mysql/init/01-nombre-descriptivo.sql
   ```

`make db-import` no distingue entre "restaurar un dump" y "aplicar un cambio
incremental": en los dos casos le pipea el archivo tal cual al cliente `mysql`
contra la base ya corriendo. Lo que cambia es el contenido del `.sql` — `CREATE
TABLE IF NOT EXISTS`/`ALTER TABLE` para no pisar lo que ya existe.
