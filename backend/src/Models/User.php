<?php

namespace Kivou\Models;

class User
{
    public int $id;
    public string $email;
    public string $name;
    public ?string $phone;
    public ?string $avatarUrl;
    public ?string $passwordHash = null; // interne, non exposé

    public static function fromRow(array $r): self
    {
        $u = new self();
        $u->id = (int)$r['id'];
        $u->email = $r['email'];
        $u->name = $r['name'];
        $u->phone = $r['phone'] ?? null;
        $u->avatarUrl = $r['avatar_url'] ?? null;
        if (isset($r['password_hash'])) $u->passwordHash = $r['password_hash'];
        return $u;
    }

    public function json(): array
    {
        return [
            'id' => $this->id,
            'email' => $this->email,
            'name' => $this->name,
            'phone' => $this->phone,
            'avatar_url' => $this->avatarUrl,
        ];
    }
}
