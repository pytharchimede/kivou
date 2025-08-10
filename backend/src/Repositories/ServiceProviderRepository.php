<?php

namespace Kivou\Repositories;

use Kivou\Support\Database;
use Kivou\Models\ServiceProvider;
use PDO;

class ServiceProviderRepository
{
    private PDO $pdo;
    public function __construct()
    {
        $this->pdo = Database::pdo();
    }

    public function list(array $filters = []): array
    {
        $sql = 'SELECT id,name,email,phone,photo_url,description,categories,rating,reviews_count,price_per_hour,latitude,longitude,gallery,available_days,working_start,working_end,is_available FROM service_providers';
        $where = [];
        $params = [];
        if (!empty($filters['category']) && strtolower($filters['category']) !== 'tous') {
            $where[] = 'FIND_IN_SET(?, REPLACE(categories, ", ", ","))';
            $params[] = $filters['category'];
        }
        if (isset($filters['minRating'])) {
            $where[] = 'rating >= ?';
            $params[] = (float)$filters['minRating'];
        }
        if (!empty($filters['q'])) {
            $where[] = '(LOWER(name) LIKE ? OR LOWER(description) LIKE ? OR LOWER(categories) LIKE ?)';
            $q = '%' . strtolower($filters['q']) . '%';
            $params[] = $q;
            $params[] = $q;
            $params[] = $q;
        }
        if ($where) $sql .= ' WHERE ' . implode(' AND ', $where);
        $sql .= ' ORDER BY rating DESC, reviews_count DESC LIMIT 200';
        $st = $this->pdo->prepare($sql);
        $st->execute($params);
        $rows = $st->fetchAll();
        return array_map(fn($r) => ServiceProvider::fromRow($r), $rows);
    }

    public function create(array $d): int
    {
        $st = $this->pdo->prepare('INSERT INTO service_providers (name,email,phone,photo_url,description,categories,rating,reviews_count,price_per_hour,latitude,longitude,gallery,available_days,working_start,working_end,is_available) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)');
        $name = trim($d['name'] ?? 'Prestataire');
        $email = trim($d['email'] ?? '');
        $phone = trim($d['phone'] ?? '');
        $photo = $d['photo_url'] ?? null;
        $desc = $d['description'] ?? '';
        $cats = $d['categories'] ?? '';
        if (is_array($cats)) $cats = implode(', ', array_map('trim', $cats));
        $price = (float)($d['price_per_hour'] ?? 100);
        $lat = isset($d['latitude']) ? (float)$d['latitude'] : 5.35;
        $lng = isset($d['longitude']) ? (float)$d['longitude'] : -4.02;
        $gallery = is_array($d['gallery'] ?? null) ? implode(',', $d['gallery']) : ($d['gallery'] ?? '');
        $days = is_array($d['available_days'] ?? null) ? implode(',', $d['available_days']) : ($d['available_days'] ?? 'Mon,Tue,Wed,Thu,Fri');
        $start = $d['working_start'] ?? '08:00';
        $end = $d['working_end'] ?? '18:00';
        $avail = isset($d['is_available']) ? ((int)$d['is_available'] ? 1 : 0) : 1;
        $st->execute([$name, $email, $phone, $photo, $desc, $cats, 0, 0, $price, $lat, $lng, $gallery, $days, $start, $end, $avail]);
        return (int)$this->pdo->lastInsertId();
    }
}
