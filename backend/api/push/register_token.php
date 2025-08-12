<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? $claims['sub'] ?? 0);
if ($userId <= 0) json_error('UNAUTHORIZED', 'User not authenticated', 401);

$body = get_json_body();
require_fields($body, ['token', 'platform']);

$token = trim((string)$body['token']);
$platform = strtolower(trim((string)$body['platform']));
if ($token === '' || !in_array($platform, ['android', 'ios'], true)) {
    json_error('BAD_REQUEST', 'Invalid token/platform');
}

$pdo = db();
$pdo->exec('CREATE TABLE IF NOT EXISTS device_tokens (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  token VARCHAR(255) NOT NULL,
  platform VARCHAR(20) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_token (token),
  INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

// Upsert by token
$st = $pdo->prepare('INSERT INTO device_tokens(user_id, token, platform) VALUES (?,?,?)
  ON DUPLICATE KEY UPDATE user_id=VALUES(user_id), platform=VALUES(platform), created_at=CURRENT_TIMESTAMP');
$st->execute([$userId, $token, $platform]);

json_ok(['ok' => true]);
