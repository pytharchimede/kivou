<?php

namespace Kivou\Repositories;

use Kivou\Support\Database;
use Kivou\Models\User;
use PDO;

class UserRepository
{
    private PDO $pdo;
    public function __construct()
    {
        $this->pdo = Database::pdo();
    }

    public function findByEmail(string $email): ?User
    {
        $st = $this->pdo->prepare('SELECT id, email, name, phone, avatar_url, password_hash FROM users WHERE email=? LIMIT 1');
        $st->execute([$email]);
        $row = $st->fetch();
        if (!$row) return null;
        $user = User::fromRow($row);
        return $user;
    }

    public function emailExists(string $email): bool
    {
        $st = $this->pdo->prepare('SELECT id FROM users WHERE email=?');
        $st->execute([$email]);
        return (bool)$st->fetch();
    }

    public function create(string $email, string $hash, string $name, ?string $phone): User
    {
        $st = $this->pdo->prepare('INSERT INTO users(email, password_hash, name, phone) VALUES (?,?,?,?)');
        $st->execute([$email, $hash, $name, $phone]);
        $id = (int)$this->pdo->lastInsertId();
        $u = new User();
        $u->id = $id;
        $u->email = $email;
        $u->name = $name;
        $u->phone = $phone;
        $u->avatarUrl = null;
        return $u;
    }

    public function findById(int $id): ?User
    {
        $st = $this->pdo->prepare('SELECT id, email, name, phone, avatar_url FROM users WHERE id=? LIMIT 1');
        $st->execute([$id]);
        $row = $st->fetch();
        if (!$row) return null;
        return User::fromRow($row);
    }
}
