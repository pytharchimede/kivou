<?php

namespace Kivou\Support;

use PDO;
use PDOException;

class Database
{
    private static ?PDO $pdo = null;

    public static function connect(string $host, string $db, string $user, string $pass): void
    {
        if (self::$pdo) return;
        $dsn = "mysql:host={$host};dbname={$db};charset=utf8mb4";
        try {
            self::$pdo = new PDO($dsn, $user, $pass, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['ok' => false, 'error' => 'DB_CONNECTION_FAILED', 'message' => $e->getMessage()]);
            exit();
        }
    }

    public static function pdo(): PDO
    {
        if (!self::$pdo) {
            http_response_code(500);
            echo json_encode(['ok' => false, 'error' => 'DB_NOT_CONNECTED', 'message' => 'Call Database::connect first']);
            exit();
        }
        return self::$pdo;
    }
}
