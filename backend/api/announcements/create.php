<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();
$userId = (int)($claims['id'] ?? 0);

$body = get_json_body();
require_fields($body, ['type', 'author_role', 'title']);
$type = trim((string)$body['type']); // request|offer
$authorRole = trim((string)$body['author_role']); // client|provider
if (!in_array($type, ['request', 'offer'], true)) json_error('BAD_REQUEST', 'type invalide');
if (!in_array($authorRole, ['client', 'provider'], true)) json_error('BAD_REQUEST', 'author_role invalide');

$providerId = isset($body['provider_id']) ? (int)$body['provider_id'] : null;
if ($authorRole === 'provider' && (!$providerId || $providerId <= 0)) {
    json_error('BAD_REQUEST', 'provider_id requis pour author_role=provider');
}
$title = trim((string)$body['title']);
$description = isset($body['description']) ? trim((string)$body['description']) : '';
$price = isset($body['price']) ? (float)$body['price'] : null;
$images = isset($body['images']) && is_array($body['images']) ? json_encode($body['images']) : json_encode([]);

// Sécurité: vérifier que le user est bien owner du provider si author_role=provider
if ($authorRole === 'provider') {
    $chk = db()->prepare('SELECT 1 FROM service_providers WHERE id = :id AND owner_user_id = :u');
    $chk->execute([':id' => $providerId, ':u' => $userId]);
    if (!$chk->fetchColumn()) json_error('FORBIDDEN', 'Vous n\'êtes pas propriétaire de ce prestataire', 403);
}

$ins = db()->prepare('INSERT INTO announcements(author_user_id,author_role,provider_id,type,title,description,price,images) VALUES (:u,:ar,:pid,:t,:ti,:d,:p,:img)');
$ins->execute([
    ':u' => $userId,
    ':ar' => $authorRole,
    ':pid' => $providerId,
    ':t' => $type,
    ':ti' => $title,
    ':d' => $description,
    ':p' => $price,
    ':img' => $images,
]);
$id = (int)db()->lastInsertId();

json_ok(['id' => $id]);
