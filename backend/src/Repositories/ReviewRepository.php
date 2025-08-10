<?php

namespace Kivou\Repositories;

use Kivou\Support\Database;
use Kivou\Models\Review;
use PDO;

class ReviewRepository
{
    private PDO $pdo;
    public function __construct()
    {
        $this->pdo = Database::pdo();
    }

    public function create(array $d): int
    {
        $st = $this->pdo->prepare('INSERT INTO reviews(booking_id, user_id, provider_id, rating, comment, photos) VALUES (?,?,?,?,?,?)');
        $st->execute([(int)$d['booking_id'], (int)$d['user_id'], (int)$d['provider_id'], (float)$d['rating'], $d['comment'] ?? null, $d['photos'] ?? null]);
        return (int)$this->pdo->lastInsertId();
    }
}
