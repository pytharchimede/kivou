<?php

namespace Kivou\Support;

class Autoload
{
    public static function register(): void
    {
        spl_autoload_register(function ($class) {
            $prefixes = ['Kivou\\', 'App\\'];
            foreach ($prefixes as $prefix) {
                if (strpos($class, $prefix) === 0) {
                    $relative = substr($class, strlen($prefix));
                    $path = dirname(__DIR__) . DIRECTORY_SEPARATOR . str_replace('\\', DIRECTORY_SEPARATOR, $relative) . '.php';
                    if (file_exists($path)) {
                        require_once $path;
                        return;
                    }
                }
            }
        });
    }
}
