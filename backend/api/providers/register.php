<?php
require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('METHOD_NOT_ALLOWED', 'Use POST', 405);
}
$claims = require_auth(); // require token
$body = get_json_body();
require_fields($body, ['name', 'email', 'phone', 'categories', 'price_per_hour']);

$repo = new \Kivou\Repositories\ServiceProviderRepository();
$id = $repo->create([
    'owner_user_id' => (int)$claims['sub'],
    'name' => $body['name'],
    'email' => $body['email'],
    'phone' => $body['phone'],
    'photo_url' => $body['photo_url'] ?? null,
    'description' => $body['description'] ?? '',
    'categories' => $body['categories'],
    'price_per_hour' => $body['price_per_hour'],
    'latitude' => $body['latitude'] ?? null,
    'longitude' => $body['longitude'] ?? null,
    'gallery' => $body['gallery'] ?? null,
    'available_days' => $body['available_days'] ?? null,
    'working_start' => $body['working_start'] ?? null,
    'working_end' => $body['working_end'] ?? null,
    'is_available' => $body['is_available'] ?? 1,
]);

json_ok(['id' => (int)$id], 201);
