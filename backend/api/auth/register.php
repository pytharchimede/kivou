<?php
require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('METHOD_NOT_ALLOWED', 'Use POST', 405);
}
$body = get_json_body();
require_fields($body, ['email', 'password', 'name']);

try {
    $auth = new \Kivou\Services\AuthService();
    $u = $auth->register($body['email'], $body['password'], $body['name'], $body['phone'] ?? null);
    $now = time();
    $token = issue_token([
        'sub' => $u->id,
        'id' => $u->id,
        'email' => $u->email,
        'iat' => $now,
        'exp' => $now + 90 * 24 * 60 * 60,
    ]);
    json_ok(['user' => $u->json(), 'token' => $token], 201);
} catch (\RuntimeException $e) {
    if ($e->getMessage() === 'EMAIL_TAKEN') {
        json_error('EMAIL_TAKEN', 'Email already in use', 409);
    }
    json_error('REGISTER_ERROR', $e->getMessage(), 400);
}
