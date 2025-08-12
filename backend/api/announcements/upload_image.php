<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();

if (!isset($_FILES['file'])) {
    if (isset($_FILES['image'])) $_FILES['file'] = $_FILES['image'];
}
if (!isset($_FILES['file'])) json_error('BAD_REQUEST', 'Aucun fichier');

$dir = __DIR__ . '/../../uploads/announcements';
if (!is_dir($dir)) @mkdir($dir, 0775, true);
$fname = uniqid('ann_', true) . '_' . preg_replace('/[^a-zA-Z0-9._-]/', '_', $_FILES['file']['name']);
$path = $dir . '/' . $fname;
if (!move_uploaded_file($_FILES['file']['tmp_name'], $path)) {
    json_error('UPLOAD_FAILED', 'Impossible d\'uploader');
}
$url = '/kivou/backend/uploads/announcements/' . $fname;
json_ok(['url' => $url]);
