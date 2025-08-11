<?php
require_once __DIR__ . '/../../config.php';

use Kivou\Repositories\BookingRepository;
use Kivou\Repositories\ServiceProviderRepository;
use Kivou\Repositories\UserRepository;

$claims = null;
try {
    $claims = require_auth();
} catch (Throwable $e) { /* facultatif */
}

$userId = isset($claims['sub']) ? (int)$claims['sub'] : (int)($_GET['user_id'] ?? 0);
if ($userId <= 0) json_error('UNAUTHORIZED', 'user_id required (token or query)', 401);

$bookingRepo = new BookingRepository();
$providerRepo = new ServiceProviderRepository();
$userRepo = new UserRepository();

$items = $bookingRepo->listByUser($userId);

$out = [];
foreach ($items as $b) {
    $arr = $b->json();
    try {
        $prov = $providerRepo->findById($b->providerId);
        if ($prov) $arr['provider'] = $prov->json();
    } catch (Throwable $e) {
    }
    try {
        $usr = $userRepo->findById($b->userId);
        if ($usr) $arr['user'] = $usr->json();
    } catch (Throwable $e) {
    }
    $out[] = $arr;
}

json_ok($out);
