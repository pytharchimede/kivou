<?php

namespace Kivou\Repositories;

use Kivou\Support\Database;
use Kivou\Models\Booking;
use PDO;

class BookingRepository
{
    private PDO $pdo;
    public function __construct()
    {
        $this->pdo = Database::pdo();
    }

    public function create(array $d): int
    {
        $st = $this->pdo->prepare('INSERT INTO bookings(user_id, provider_id, service_category, service_description, scheduled_at, duration, total_price, status) VALUES (?,?,?,?,?,?,?,?)');
        $st->execute([
            (int)$d['user_id'],
            (int)$d['provider_id'],
            $d['service_category'],
            $d['service_description'] ?? null,
            $d['scheduled_at'],
            (float)$d['duration'],
            (float)$d['total_price'],
            'pending'
        ]);
        return (int)$this->pdo->lastInsertId();
    }

    public function listByUser(int $userId): array
    {
        $st = $this->pdo->prepare('SELECT * FROM bookings WHERE user_id=? ORDER BY created_at DESC LIMIT 200');
        $st->execute([$userId]);
        $rows = $st->fetchAll();
        return array_map(fn($r) => Booking::fromRow($r), $rows);
    }
}
