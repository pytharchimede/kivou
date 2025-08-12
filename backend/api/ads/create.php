<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);
$body = get_json_body();
require_fields($body, ['kind', 'title']);

$kind = strtolower(trim((string)$body['kind'])); // request|offer
if (!in_array($kind, ['request', 'offer'], true)) {
    json_error('BAD_REQUEST', 'kind must be request or offer', 400);
}
$title = trim((string)$body['title']);
if ($title === '') json_error('BAD_REQUEST', 'title is required', 400);
$description = isset($body['description']) ? trim((string)$body['description']) : null;
$imageUrl = isset($body['image_url']) ? trim((string)$body['image_url']) : null;
$amount = isset($body['amount']) ? (float)$body['amount'] : null;
$currency = isset($body['currency']) ? strtoupper(trim((string)$body['currency'])) : 'XOF';
$category = isset($body['category']) ? trim((string)$body['category']) : null;
$lat = isset($body['lat']) ? (float)$body['lat'] : null;
$lng = isset($body['lng']) ? (float)$body['lng'] : null;
$authorType = isset($body['author_type']) ? strtolower(trim((string)$body['author_type'])) : 'client'; // client|provider
if (!in_array($authorType, ['client', 'provider'], true)) $authorType = 'client';
$providerId = isset($body['provider_id']) ? (int)$body['provider_id'] : null;

// Si publication en tant que provider, vérifier ownership
if ($authorType === 'provider') {
    if (!$providerId) json_error('BAD_REQUEST', 'provider_id requis pour author_type=provider', 400);
    $st = db()->prepare('SELECT owner_user_id FROM service_providers WHERE id=?');
    $st->execute([$providerId]);
    $row = $st->fetch(PDO::FETCH_ASSOC);
    if (!$row) json_error('BAD_REQUEST', 'Prestataire introuvable', 400);
    if ((int)($row['owner_user_id'] ?? 0) !== $userId) {
        json_error('FORBIDDEN', 'Vous n\'êtes pas propriétaire de ce prestataire', 403);
    }
}

$ins = db()->prepare('INSERT INTO ads(author_user_id,author_type,provider_id,kind,title,description,image_url,amount,currency,category,lat,lng,status) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,\'active\')');
$ins->execute([$userId, $authorType, $providerId, $kind, $title, $description, $imageUrl, $amount, $currency, $category, $lat, $lng]);
$id = (int)db()->lastInsertId();

$ad = db()->prepare('SELECT * FROM ads WHERE id=?');
$ad->execute([$id]);
$row = $ad->fetch(PDO::FETCH_ASSOC);

json_ok([
    'id' => (int)$row['id'],
    'author_user_id' => (int)$row['author_user_id'],
    'author_type' => $row['author_type'],
    'provider_id' => $row['provider_id'] !== null ? (int)$row['provider_id'] : null,
    'kind' => $row['kind'],
    'title' => (string)$row['title'],
    'description' => (string)($row['description'] ?? ''),
    'image_url' => (string)($row['image_url'] ?? ''),
    'amount' => isset($row['amount']) ? (float)$row['amount'] : null,
    'currency' => (string)($row['currency'] ?? 'XOF'),
    'category' => (string)($row['category'] ?? ''),
    'lat' => isset($row['lat']) ? (float)$row['lat'] : null,
    'lng' => isset($row['lng']) ? (float)$row['lng'] : null,
    'status' => (string)$row['status'],
    'created_at' => date('c', strtotime($row['created_at'])),
    'updated_at' => date('c', strtotime($row['updated_at'])),
]);
