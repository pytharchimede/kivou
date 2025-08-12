<?php
require_once __DIR__ . '/../../config.php';

// Auth requis (éviter d'exposer en public)
require_auth();

$base = dirname(__DIR__, 2);
$envPath = $base . DIRECTORY_SEPARATOR . 'env' . DIRECTORY_SEPARATOR . 'firebase_sa.json';

$saJson = getenv('FIREBASE_SA_JSON') ?: '';
$saPath = getenv('FIREBASE_SA_PATH') ?: '';
$projectId = getenv('FIREBASE_PROJECT_ID') ?: null;

$effectivePath = null;
$sa = null;

if ($saJson !== '') {
    $sa = json_decode($saJson, true);
}
if (!$sa && $saPath !== '') {
    $candidate = $saPath;
    if (!preg_match('/^([A-Za-z]:\\\\|\\\\|\/)?.*/', $saPath)) {
        $candidate = $base . DIRECTORY_SEPARATOR . $saPath;
    }
    if (is_file($candidate)) {
        $effectivePath = $candidate;
        $content = file_get_contents($candidate);
        $sa = $content ? json_decode($content, true) : null;
    }
}
if (!$sa && is_file($envPath)) {
    $effectivePath = $envPath;
    $content = file_get_contents($envPath);
    $sa = $content ? json_decode($content, true) : null;
}

if (!$projectId && is_array($sa) && isset($sa['project_id'])) {
    $projectId = (string)$sa['project_id'];
}

$hasKey = is_array($sa) && isset($sa['private_key']);

json_ok([
    'openssl' => extension_loaded('openssl'),
    'curl'    => extension_loaded('curl'),
    'project_id' => $projectId,
    'sa_source' => $saJson !== '' ? 'FIREBASE_SA_JSON' : ($saPath !== '' ? 'FIREBASE_SA_PATH' : (is_file($envPath) ? 'env/firebase_sa.json' : null)),
    'sa_path' => $effectivePath,
    'sa_loaded' => $hasKey,
]);
