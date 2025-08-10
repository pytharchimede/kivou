<?php

namespace Kivou\Services;

use Kivou\Repositories\UserRepository;
use Kivou\Models\User;

class AuthService
{
    private UserRepository $users;

    public function __construct(?UserRepository $users = null)
    {
        $this->users = $users ?: new UserRepository();
    }

    public function login(string $email, string $password): User
    {
        $email = strtolower(trim($email));
        $u = $this->users->findByEmail($email);
        if (!$u || !$u->passwordHash || !password_verify($password, $u->passwordHash)) {
            throw new \RuntimeException('INVALID_CREDENTIALS');
        }
        return $u;
    }

    public function register(string $email, string $password, string $name, ?string $phone): User
    {
        $email = strtolower(trim($email));
        if ($this->users->emailExists($email)) {
            throw new \RuntimeException('EMAIL_TAKEN');
        }
        $hash = password_hash($password, PASSWORD_BCRYPT);
        try {
            return $this->users->create($email, $hash, trim($name), $phone ? trim($phone) : null);
        } catch (\PDOException $e) {
            // Duplicate email or constraint violation safety net
            $msg = $e->getMessage();
            if (stripos($msg, 'duplicate') !== false || stripos($msg, '1062') !== false) {
                throw new \RuntimeException('EMAIL_TAKEN');
            }
            throw new \RuntimeException('REGISTER_FAILED');
        }
    }
}
