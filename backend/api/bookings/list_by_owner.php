<?php
require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_error('METHOD_NOT_ALLOWED', 'Use GET', 405);
}

$claims = require_auth();
$ownerId = (int)$claims['sub'];

$pdo = db();
$st = $pdo->prepare('SELECT b.id,b.user_id,b.provider_id,b.service_category,b.service_description,b.scheduled_at,b.duration,b.total_price,b.status,b.created_at,
                            u.name AS user_name, u.phone AS user_phone, u.avatar_url AS user_avatar_url,
                            sp.name AS provider_name
                     FROM bookings b
                     JOIN service_providers sp ON sp.id=b.provider_id
                     JOIN users u ON u.id=b.user_id
                     WHERE sp.owner_user_id=?
                     ORDER BY b.id DESC LIMIT 200');
$st->execute([$ownerId]);
$rows = $st->fetchAll();
$data = array_map(function ($r) {
    return [
        'id' => (int)$r['id'],
        'user_id' => (int)$r['user_id'],
        'provider_id' => (int)$r['provider_id'],
        'service_category' => $r['service_category'],
        'service_description' => $r['service_description'],
        'scheduled_at' => $r['scheduled_at'],
        'duration' => (float)$r['duration'],
        'total_price' => (float)$r['total_price'],
        'status' => $r['status'],
        'created_at' => $r['created_at'],
        'user_name' => $r['user_name'] ?? null,
        'user_phone' => $r['user_phone'] ?? null,
        'provider_name' => $r['provider_name'] ?? null,
        'user_avatar_url' => $r['user_avatar_url'] ?? null,
    ];
}, $rows);
json_ok($data);
