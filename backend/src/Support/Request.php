<?php

namespace Kivou\Support;

class Request
{
    public static function json(): array
    {
        $input = file_get_contents('php://input');
        // Handle empty body fast-path
        if ($input === false || $input === '' || $input === null) {
            // Fallback to PHP-populated $_POST if available (form-encoded)
            if (!empty($_POST)) {
                return $_POST;
            }
            return [];
        }

        // Strip UTF-8 BOM if present
        if (substr($input, 0, 3) === "\xEF\xBB\xBF") {
            $input = substr($input, 3);
        }

        $data = json_decode($input, true);
        if ($data === null && json_last_error() !== JSON_ERROR_NONE) {
            // Attempt to parse as form-encoded string if looks like key=value
            if (strpos($input, '=') !== false) {
                $arr = [];
                parse_str($input, $arr);
                if (!empty($arr)) {
                    return $arr;
                }
            }
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
