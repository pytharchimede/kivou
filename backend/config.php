<?php
// Basic config for database and CORS
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// PSR-4 autoload
require_once __DIR__ . '/src/Support/Autoload.php';
\Kivou\Support\Autoload::register();

$DB_HOST = 'localhost';
$DB_NAME = 'fidestci_kivou_db';
$DB_USER = 'fidestci_ulrich';
$DB_PASS = '@Succes2019';

// Connect DB (via classe Database)
\Kivou\Support\Database::connect($DB_HOST, $DB_NAME, $DB_USER, $DB_PASS);

// Backward-compatible helper
function db()
{
    return \Kivou\Support\Database::pdo();
}

function json_ok($data, $code = 200)
{
    \Kivou\Support\Response::ok($data, $code);
}

function json_error($code, $message, $status = 400)
{
    \Kivou\Support\Response::error($code, $message, $status);
}

function require_fields($body, $fields)
{
    \Kivou\Support\Request::require($body, $fields);
}

function get_json_body()
{
    return \Kivou\Support\Request::json();
}

// JWT helpers
$JWT_SECRET = 'kivou_dev_secret_change_me';
function issue_token(array $claims)
{
    global $JWT_SECRET;
    return \Kivou\Support\Jwt::sign($claims, $JWT_SECRET);
}
function require_auth()
{
    global $JWT_SECRET;
    $hdr = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/^Bearer\s+(.*)$/i', $hdr, $m)) json_error('UNAUTHORIZED', 'Missing bearer token', 401);
    try {
        return \Kivou\Support\Jwt::verify($m[1], $JWT_SECRET);
    } catch (\Throwable $e) {
        json_error('UNAUTHORIZED', $e->getMessage(), 401);
    }
}
