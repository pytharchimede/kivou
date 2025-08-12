<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);
$pdo = db();
$st = $pdo->prepare('SELECT id, token, platform, created_at FROM device_tokens WHERE user_id=? ORDER BY id DESC');
$st->execute([$userId]);
json_ok($st->fetchAll(PDO::FETCH_ASSOC));
