<?php
require_once __DIR__ . '/../../config.php';

$claims = require_auth();
$userId = (int)$claims['sub'];
$body = get_json_body();
require_fields($body, ['title']);

$pdo = db();
$st = $pdo->prepare('INSERT INTO notifications (user_id, provider_id, title, body) VALUES (?,?,?,?)');
$st->execute([$userId, isset($body['provider_id']) ? (int)$body['provider_id'] : null, $body['title'], $body['body'] ?? null]);
$id = (int)$pdo->lastInsertId();
json_ok(['id' => $id], 201);
