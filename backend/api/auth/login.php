<?php
require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('METHOD_NOT_ALLOWED', 'Use POST', 405);
}
$body = get_json_body();
require_fields($body, ['email', 'password']);

try {
    $auth = new \Kivou\Services\AuthService();
    $u = $auth->login($body['email'], $body['password']);
    $token = issue_token(['sub' => $u->id, 'email' => $u->email]);
    json_ok(['user' => $u->json(), 'token' => $token]);
} catch (\RuntimeException $e) {
    if ($e->getMessage() === 'INVALID_CREDENTIALS') {
        json_error('INVALID_CREDENTIALS', 'Email or password incorrect', 401);
    }
    json_error('AUTH_ERROR', $e->getMessage(), 400);
}
