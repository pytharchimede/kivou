<?php

namespace Kivou\Models;

class Review
{
    public int $id;
    public int $bookingId;
    public int $userId;
    public int $providerId;
    public float $rating;
    public ?string $comment;
    public ?string $photos;

    public static function fromRow(array $r): self
    {
        $v = new self();
        $v->id = (int)$r['id'];
        $v->bookingId = (int)$r['booking_id'];
        $v->userId = (int)$r['user_id'];
        $v->providerId = (int)$r['provider_id'];
        $v->rating = (float)$r['rating'];
        $v->comment = $r['comment'] ?? null;
        $v->photos = $r['photos'] ?? null;
        return $v;
    }

    public function json(): array
    {
        return [
            'id' => $this->id,
            'booking_id' => $this->bookingId,
            'user_id' => $this->userId,
            'provider_id' => $this->providerId,
            'rating' => $this->rating,
            'comment' => $this->comment,
            'photos' => $this->photos,
        ];
    }
}
