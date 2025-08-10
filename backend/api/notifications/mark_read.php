<?php
require_once __DIR__ . '/../../config.php';

$claims = require_auth();
$userId = (int)$claims['sub'];
$body = get_json_body();
require_fields($body, ['id']);

$pdo = db();
$st = $pdo->prepare('UPDATE notifications SET is_read=1 WHERE id=? AND user_id=?');
$st->execute([(int)$body['id'], $userId]);
json_ok(['updated' => $st->rowCount() > 0]);
