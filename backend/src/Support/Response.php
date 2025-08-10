<?php

namespace Kivou\Support;

class Response
{
    public static function ok($data, int $code = 200): void
    {
        // Ensure JSON header in case config headers were not sent
        if (!headers_sent()) {
            header('Content-Type: application/json; charset=utf-8');
        }
        http_response_code($code);
        echo json_encode(['ok' => true, 'data' => $data]);
        exit();
    }
    public static function error(string $code, string $message, int $status = 400): void
    {
        // Ensure JSON header in case config headers were not sent
        if (!headers_sent()) {
            header('Content-Type: application/json; charset=utf-8');
        }
        http_response_code($status);
        echo json_encode(['ok' => false, 'error' => $code, 'message' => $message]);
        exit();
    }
}
