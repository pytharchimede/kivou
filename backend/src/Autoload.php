<?php
// Simple PSR-4-like autoloader for the App namespace
spl_autoload_register(function ($class) {
    if (substr($class, 0, 4) !== 'App\\') return;
    $relative = str_replace('App\\', '', $class);
    $path = __DIR__ . '/' . str_replace('\\', '/', $relative) . '.php';
    if (file_exists($path)) require_once $path;
});
