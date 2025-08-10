<?php

namespace Kivou\Models;

class Booking
{
    public int $id;
    public int $userId;
    public int $providerId;
    public string $serviceCategory;
    public ?string $serviceDescription;
    public string $scheduledAt; // 'Y-m-d H:i:s'
    public float $duration;
    public float $totalPrice;
    public string $status;
    public ?string $completedAt;

    public static function fromRow(array $r): self
    {
        $b = new self();
        $b->id = (int)$r['id'];
        $b->userId = (int)$r['user_id'];
        $b->providerId = (int)$r['provider_id'];
        $b->serviceCategory = $r['service_category'];
        $b->serviceDescription = $r['service_description'] ?? null;
        $b->scheduledAt = $r['scheduled_at'];
        $b->duration = (float)$r['duration'];
        $b->totalPrice = (float)$r['total_price'];
        $b->status = $r['status'];
        $b->completedAt = $r['completed_at'] ?? null;
        return $b;
    }

    public function json(): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->userId,
            'provider_id' => $this->providerId,
            'service_category' => $this->serviceCategory,
            'service_description' => $this->serviceDescription,
            'scheduled_at' => $this->scheduledAt,
            'duration' => $this->duration,
            'total_price' => $this->totalPrice,
            'status' => $this->status,
            'completed_at' => $this->completedAt,
        ];
    }
}
