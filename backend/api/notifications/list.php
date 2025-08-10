<?php
require_once __DIR__ . '/../../config.php';

$claims = require_auth();
$userId = (int)$claims['sub'];

$pdo = db();
$st = $pdo->prepare('SELECT id, user_id, provider_id, title, body, is_read, created_at FROM notifications WHERE user_id=? ORDER BY id DESC LIMIT 100');
$st->execute([$userId]);
$rows = $st->fetchAll();
$data = array_map(function ($r) {
    return [
        'id' => (int)$r['id'],
        'user_id' => (int)$r['user_id'],
        'provider_id' => isset($r['provider_id']) ? (int)$r['provider_id'] : null,
        'title' => $r['title'],
        'body' => $r['body'],
        'is_read' => (int)$r['is_read'] === 1,
        'created_at' => $r['created_at'],
    ];
}, $rows);
json_ok($data);
