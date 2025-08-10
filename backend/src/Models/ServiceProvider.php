<?php

namespace Kivou\Models;

class ServiceProvider
{
    public int $id;
    public ?int $ownerUserId = null;
    public string $name;
    public string $email;
    public string $phone;
    public ?string $photoUrl;
    public string $description;
    public array $categories = [];
    public float $rating = 0.0;
    public int $reviewsCount = 0;
    public float $pricePerHour = 0.0;
    public float $latitude = 0.0;
    public float $longitude = 0.0;
    public array $gallery = [];
    public array $availableDays = [];
    public ?string $workingStart = null;
    public ?string $workingEnd = null;
    public bool $isAvailable = true;

    public static function fromRow(array $r): self
    {
        $p = new self();
        $p->id = (int)$r['id'];
        if (isset($r['owner_user_id'])) {
            $p->ownerUserId = $r['owner_user_id'] !== null ? (int)$r['owner_user_id'] : null;
        }
        $p->name = $r['name'];
        $p->email = $r['email'];
        $p->phone = $r['phone'];
        $p->photoUrl = $r['photo_url'] ?? null;
        $p->description = $r['description'] ?? '';
        $p->categories = self::toArray($r['categories'] ?? '');
        $p->rating = (float)$r['rating'];
        $p->reviewsCount = (int)($r['reviews_count'] ?? 0);
        $p->pricePerHour = (float)$r['price_per_hour'];
        $p->latitude = (float)$r['latitude'];
        $p->longitude = (float)$r['longitude'];
        $p->gallery = self::toArray($r['gallery'] ?? '');
        $p->availableDays = self::toArray($r['available_days'] ?? '');
        $p->workingStart = $r['working_start'] ?? null;
        $p->workingEnd = $r['working_end'] ?? null;
        $p->isAvailable = (int)($r['is_available'] ?? 1) === 1;
        return $p;
    }

    public function json(): array
    {
        return [
            'id' => $this->id,
            'owner_user_id' => $this->ownerUserId,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'photo_url' => $this->photoUrl,
            'description' => $this->description,
            'categories' => $this->categories,
            'rating' => $this->rating,
            'reviews_count' => $this->reviewsCount,
            'price_per_hour' => $this->pricePerHour,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'gallery' => $this->gallery,
            'available_days' => $this->availableDays,
            'working_start' => $this->workingStart,
            'working_end' => $this->workingEnd,
            'is_available' => $this->isAvailable ? 1 : 0,
        ];
    }

    private static function toArray(string $s): array
    {
        return array_values(array_filter(array_map('trim', explode(',', $s))));
    }
}
