<?php
require_once __DIR__ . '/../../config.php';

// Auth requis
require_auth();

$base = dirname(__DIR__, 2);
$logFile = $base . DIRECTORY_SEPARATOR . 'logs' . DIRECTORY_SEPARATOR . 'push.log';

$linesParam = isset($_GET['lines']) ? (int)$_GET['lines'] : 200;
if ($linesParam <= 0) $linesParam = 200;
$clear = isset($_GET['clear']) && in_array(strtolower((string)$_GET['clear']), ['1', 'true', 'yes', 'on'], true);

if ($clear && is_file($logFile)) {
    @unlink($logFile);
    json_ok(['cleared' => true]);
}

if (!is_file($logFile)) {
    json_ok(['lines' => [], 'info' => 'No log yet']);
}

$contents = @file($logFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
if (!is_array($contents)) {
    json_ok(['lines' => [], 'info' => 'Empty or unreadable log']);
}

$tail = array_slice($contents, -$linesParam);
json_ok(['lines' => array_values($tail)]);
