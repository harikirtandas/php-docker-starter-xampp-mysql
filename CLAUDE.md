# php-docker-starter-xampp-mysql

Esta plantilla es una variante de `php-docker-starter-apache-mysql` pensada para
instructivos (materias, cursos, tutoriales) que asumen XAMPP con carpetas sueltas
de archivos `.php` dentro de `htdocs/`. La tabla de equivalencias en `README.md` es
la traduccion entre ese tipo de instructivo y los comandos de este repo.
Diferencias respecto al starter original:

- **PHP 8.2 en vez de 8.4**: `docker/Dockerfile` usa `php:8.2-apache` para acercarse
  a la version que suele traer XAMPP (mas vieja que la ultima estable). Las
  extensiones (`pdo_mysql`, `mysqli`, `zip`) se mantienen igual que en el starter.
- **Sin front controller**: `src/public/.htaccess` no tiene el bloque
  `mod_rewrite`. Este flujo trabaja con archivos `.php` sueltos servidos directo
  (`src/public/semana5/ejercicio1.php`), no con un router que centralice todo en
  `index.php`.
- **Sin Composer ni MVC**: no hay `composer.json` ni autoload. El codigo es PHP
  plano, igual que en el starter, pero sin la expectativa de agregar una capa de
  framework.
- **`.env` versionado**: a diferencia del starter (donde `.env` esta gitignoreado
  porque puede tener secretos reales), aca viaja commiteado junto con el codigo —
  no hay secretos, y la idea es que cualquiera que clone el repo tenga la config
  lista sin pasos manuales.
- **Puerto 80 en vez de 8080**: `APP_PORT=80` en el `.env` para que la URL sea
  `http://localhost` igual que en un instructivo pensado para XAMPP (sin puerto
  explicito).
- **Contenido organizado por carpetas**: `src/public/semanaN/` es la unidad de
  trabajo (equivalente a `htdocs/semanaN` en XAMPP). `make semana N=6` crea la
  carpeta con un `index.php` minimo. Es solo una convencion de nombre en el
  `Makefile`: renombrar el target `semana:` alcanza para adaptarlo a otra
  terminologia ("practico", "modulo").
- **`make ip`**: imprime la IP LAN de la Mac para acceder desde un celular u otro
  dispositivo que no resuelve `localhost`. Utilidad tipica cuando el proyecto que
  se sirve va a ser consumido por una app movil en la misma red.

Lo que se mantiene igual que el starter (ver contexto original mas abajo): stack de
un solo contenedor `*-apache` con mod_php (mismo enfoque, solo cambia la version de
PHP), `src/` versionado, docroot en `src/public`, credenciales de MySQL inyectadas
como `environment:` en `docker-compose.yml` (no `.env` dentro de `src/`),
`src/app/db.php` con PDO opcional (si el instructivo ensena `mysqli_connect()` se
usa eso directo, sin pasar por este archivo), y el flujo de `docker/mysql/init/`
para sumar tablas sin perder datos (`make db-import FILE=...`) vs. `make fresh`
(que recrea el volumen y borra todo).

## Contexto heredado del starter

- Stack de un solo contenedor: `php:8.2-apache` con mod_php (no PHP-FPM, no Nginx
  separado). Para un proyecto plano sin framework no hace falta el desacople que si
  tiene sentido en `laravel-docker-starter-ngxMsql`.
- `src/` **esta versionado** (no gitignoreado): no hay `composer create-project` que lo
  regenere, el codigo PHP plano es el proyecto en si.
- Docroot en `src/public` (lo que expone Apache); codigo privado (helpers, conexion a
  DB) va en `src/app`, fuera del docroot.
- Las credenciales de MySQL se inyectan como `environment:` del servicio `app` en
  `docker-compose.yml`, no en un `.env` dentro de `src/`. `src/app/db.php` las lee con
  `getenv()` (no `$_ENV`, que depende de `variables_order` en `php.ini`).
- El schema de `docker/mysql/init/` solo corre en el primer arranque del volumen
  `mysql-data` (comportamiento estandar de `docker-entrypoint-initdb.d`). Para
  reaplicarlo hace falta recrear el volumen: `make fresh` (borra los datos
  existentes). Para sumar tablas/columnas nuevas SIN perder datos: agregar el `.sql`
  numerado en `docker/mysql/init/` y aplicarlo a la base ya corriendo con
  `make db-import FILE=docker/mysql/init/0N-nombre.sql` (no espera a un `fresh`).
  Por defecto `docker/mysql/init/` esta vacio (solo `.gitkeep`): la base de datos es
  opcional hasta que algun ejercicio la necesite.
- Todo comando (composer, php, lo que sea) corre via `docker compose exec app ...` o
  `make shell`. No hay PHP instalado en el host a proposito.
- El Dockerfile **no agrega `USER`**: Apache necesita arrancar como root para poder
  bindear el puerto 80, y el propio proceso maestro baja los workers a `www-data`
  solo. Los build args `UID`/`GID` remapean `www-data` (via `usermod`/`groupmod`) en
  vez de crear un usuario nuevo, porque `www-data` ya existe en la imagen base.
