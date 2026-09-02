<?php

declare(strict_types=1);

// este helper es opcional: si el instructivo que estas siguiendo ensena
// mysqli_connect(), se usa directamente en cada .php sin pasar por este
// archivo. queda disponible por si en algun ejercicio conviene PDO en su lugar.

// devuelve una conexion PDO unica (singleton estatico) a MySQL.
// las credenciales se leen con getenv() y no $_ENV porque docker-compose las
// inyecta como variables de entorno reales del proceso, no via .env
function db(): PDO
{
    static $pdo = null;

    if ($pdo === null) {
        $host = getenv('DB_HOST') ?: 'mysql';
        $port = getenv('DB_PORT') ?: '3306';
        $database = getenv('DB_DATABASE') ?: 'app';
        $username = getenv('DB_USERNAME') ?: 'app';
        $password = getenv('DB_PASSWORD') ?: 'secret';

        $dsn = "mysql:host={$host};port={$port};dbname={$database};charset=utf8mb4";

        $pdo = new PDO($dsn, $username, $password, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);
    }

    return $pdo;
}
