<?php

namespace Kivou\Services;

use Kivou\Repositories\UserRepository;
use Kivou\Models\User;

class AuthService
{
    public function __construct(private UserRepository $users = new UserRepository()) {}

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
        return $this->users->create($email, $hash, trim($name), $phone ? trim($phone) : null);
    }
}
