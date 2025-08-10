<?php

namespace Kivou\Support;

class Request
{
    public static function json(): array
    {
        $input = file_get_contents('php://input');
        $data = json_decode($input, true);
        if ($data === null && json_last_error() !== JSON_ERROR_NONE) {
            Response::error('INVALID_JSON', 'Invalid JSON body');
        }
        return $data ?: [];
    }

    public static function require(array $body, array $fields): void
    {
        foreach ($fields as $f) {
            if (!isset($body[$f]) || $body[$f] === '') {
                Response::error('MISSING_FIELD', 'Field ' . $f . ' is required');
            }
        }
    }
}
