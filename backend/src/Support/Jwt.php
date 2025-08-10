<?php

namespace Kivou\Support;

class Jwt
{
    public static function base64url_encode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
    public static function base64url_decode(string $data): string
    {
        return base64_decode(strtr($data, '-_', '+/'));
    }
    public static function sign(array $payload, string $secret, int $expSeconds = 86400): string
    {
        $header = ['alg' => 'HS256', 'typ' => 'JWT'];
        $payload['exp'] = time() + $expSeconds;
        $h = self::base64url_encode(json_encode($header));
        $p = self::base64url_encode(json_encode($payload));
        $sig = hash_hmac('sha256', "$h.$p", $secret, true);
        $s = self::base64url_encode($sig);
        return "$h.$p.$s";
    }
    public static function verify(string $token, string $secret): array
    {
        $parts = explode('.', $token);
        if (count($parts) !== 3) throw new \RuntimeException('INVALID_TOKEN');
        [$h, $p, $s] = $parts;
        $calc = self::base64url_encode(hash_hmac('sha256', "$h.$p", $secret, true));
        if (!hash_equals($calc, $s)) throw new \RuntimeException('INVALID_SIGNATURE');
        $payload = json_decode(self::base64url_decode($p), true);
        if (!$payload || !isset($payload['exp']) || $payload['exp'] < time()) throw new \RuntimeException('TOKEN_EXPIRED');
        return $payload;
    }
}
