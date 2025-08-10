<?php
require_once __DIR__ . '/../../config.php';

// Very simple protection with a key. Set KIVOU_SEED_KEY in env for production.
$providedKey = $_GET['key'] ?? '';
$expectedKey = getenv('KIVOU_SEED_KEY') ?: 'kivou_dev_seed';
if ($providedKey !== $expectedKey) {
    json_error('FORBIDDEN', 'Invalid or missing key', 403);
}

$pdo = \Kivou\Support\Database::pdo();
@set_time_limit(20);
@ignore_user_abort(true);
$start = microtime(true);

// If data already exists and not forced, skip
$existing = (int)$pdo->query('SELECT COUNT(*) FROM service_providers')->fetchColumn();
$force = isset($_GET['force']) && (string)$_GET['force'] === '1';
if ($existing > 0 && !$force) {
    json_ok(['skipped' => true, 'existing' => $existing]);
}

if ($force && $existing > 0) {
    // Fast cleanup with FK checks off to avoid delays
    $pdo->exec('SET FOREIGN_KEY_CHECKS=0');
    $pdo->exec('TRUNCATE TABLE service_providers');
    $pdo->exec('SET FOREIGN_KEY_CHECKS=1');
}

$n = isset($_GET['n']) ? max(1, (int)$_GET['n']) : 60;

mt_srand(42);
$categoriesPool = ['Plomberie', 'Électricité', 'Ménage', 'Jardinage', 'Peinture', 'Menuiserie', 'Climatisation', 'Serrurerie', 'Déménagement', 'Informatique'];
$namesPool = ['Alpha', 'Bravo', 'Charlie', 'Delta', 'Echo', 'Foxtrot', 'Gamma', 'Hector', 'Ivan', 'Juliet', 'Kilo', 'Lima', 'Mike', 'Nina', 'Oscar', 'Papa', 'Quebec', 'Romeo', 'Sierra', 'Tango', 'Uniform', 'Victor', 'Whisky', 'Xray', 'Yankee', 'Zulu'];
$baseLat = 5.35; // Abidjan approx
$baseLng = -4.02;

$st = $pdo->prepare('INSERT INTO service_providers (name,email,phone,photo_url,description,categories,rating,reviews_count,price_per_hour,latitude,longitude,gallery,available_days,working_start,working_end,is_available) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)');

$inserted = 0;
$pdo->beginTransaction();
for ($i = 1; $i <= $n; $i++) {
    $catCount = 1 + (mt_rand(0, 100) < 50 ? 1 : 0); // 1 or 2 categories
    $cats = [];
    while (count($cats) < $catCount) {
        $c = $categoriesPool[mt_rand(0, count($categoriesPool) - 1)];
        if (!in_array($c, $cats, true)) $cats[] = $c;
    }
    $catStr = implode(', ', $cats);

    $name = $cats[0] . ' ' . $namesPool[$i % count($namesPool)] . ' #' . str_pad((string)$i, 2, '0', STR_PAD_LEFT);
    $email = 'pro' . $i . '@kivou.local';
    $phone = '+225 07' . str_pad((string)mt_rand(10000000, 99999999), 8, '0', STR_PAD_LEFT);
    $photo = null; // Can be set later via upload endpoint
    $desc = 'Prestataire professionnel en ' . $catStr . '. Intervention rapide et de qualité.';
    $rating = round(mt_rand(35, 50) / 10, 1); // 3.5 - 5.0
    $reviews = mt_rand(5, 120);
    $price = round(mt_rand(50, 200) * 1.0, 2);
    $lat = $baseLat + (mt_rand(-300, 300) / 10000);
    $lng = $baseLng + (mt_rand(-300, 300) / 10000);
    $gallery = '';
    $days = 'Mon,Tue,Wed,Thu,Fri' . (mt_rand(0, 1) ? ',Sat' : '');
    $start = '08:00';
    $end = '18:00';
    $avail = 1;

    $st->execute([$name, $email, $phone, $photo, $desc, $catStr, $rating, $reviews, $price, $lat, $lng, $gallery, $days, $start, $end, $avail]);
    $inserted++;
}
$pdo->commit();

$total = (int)$pdo->query('SELECT COUNT(*) FROM service_providers')->fetchColumn();
$elapsed = (int)round((microtime(true) - $start) * 1000);
json_ok(['inserted' => $inserted, 'total' => $total, 'elapsed_ms' => $elapsed]);
