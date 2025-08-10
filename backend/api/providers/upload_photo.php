<?php
require_once __DIR__ . '/../../config.php';

$UPLOAD_DIR = __DIR__ . '/../../uploads/';
if (!is_dir($UPLOAD_DIR)) {
    mkdir($UPLOAD_DIR, 0775, true);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('METHOD_NOT_ALLOWED', 'Use POST', 405);
}

if (!isset($_FILES['file'])) {
    json_error('NO_FILE', 'No file uploaded');
}
$file = $_FILES['file'];
if ($file['error'] !== UPLOAD_ERR_OK) {
    json_error('UPLOAD_ERROR', 'Error code: ' . $file['error']);
}

$ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
$allowed = ['jpg', 'jpeg', 'png', 'webp'];
if (!in_array($ext, $allowed)) {
    json_error('INVALID_EXT', 'Allowed: jpg,jpeg,png,webp');
}

$filename = 'prov_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $ext;
$dest = $UPLOAD_DIR . $filename;
if (!move_uploaded_file($file['tmp_name'], $dest)) {
    json_error('MOVE_FAILED', 'Could not move file');
}

// Optionally link to provider record if provider_id is present
if (isset($_POST['provider_id'])) {
    $pid = intval($_POST['provider_id']);
    $url = '/kivou/backend/uploads/' . $filename; // public path under https://fidest.ci
    $stmt = db()->prepare('UPDATE service_providers SET photo_url=? WHERE id=?');
    $stmt->execute([$url, $pid]);
}

json_ok(['filename' => $filename, 'url' => '/kivou/backend/uploads/' . $filename]);
