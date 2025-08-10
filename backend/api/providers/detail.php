<?php
require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    json_error('METHOD_NOT_ALLOWED', 'Use GET', 405);
}

$id = isset($_GET['id']) ? intval($_GET['id']) : 0;
if ($id <= 0) {
    json_error('BAD_REQUEST', 'Missing or invalid id', 400);
}

$repo = new \Kivou\Repositories\ServiceProviderRepository();
$list = $repo->list();
foreach ($list as $p) {
    if ($p->id === $id) {
        json_ok($p->json());
    }
}
json_error('NOT_FOUND', 'Provider not found', 404);
