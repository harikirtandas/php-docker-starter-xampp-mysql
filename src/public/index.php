<?php

declare(strict_types=1);

// indice simple: lista los directorios semanaN/ que existan en el docroot.
// sin dependencia de MySQL, cada semana es una carpeta con sus propios .php sueltos.

$semanas = glob(__DIR__ . '/semana*', GLOB_ONLYDIR);
sort($semanas);
?>
<!doctype html>
<html lang="es">
<head>
    <meta charset="utf-8">
    <title>Indice</title>
</head>
<body>
    <h1>Indice</h1>

    <?php if (empty($semanas)): ?>
        <p>Todavia no hay carpetas semanaN/ en src/public. Crealas con <code>make semana N=1</code>.</p>
    <?php else: ?>
        <ul>
            <?php foreach ($semanas as $semana): ?>
                <?php $nombre = basename($semana); ?>
                <li><a href="<?= htmlspecialchars($nombre) ?>/"><?= htmlspecialchars($nombre) ?></a></li>
            <?php endforeach; ?>
        </ul>
    <?php endif; ?>
</body>
</html>
