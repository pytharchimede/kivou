<?php

namespace Kivou\Services;

class PushService
{
    // Optional legacy server key (HTTP legacy API)
    private ?string $serverKey;
    // HTTP v1 service account settings
    private ?array $serviceAccount;
    private ?string $projectId;
    private static ?array $tokenCache = null; // ['access_token'=>..., 'expires_at'=>timestamp]
    private bool $debug = false;

    public function __construct(?string $serverKey = null)
    {
        // Legacy key from env (optional)
        $key = $serverKey ?? getenv('FCM_SERVER_KEY') ?: '';
        $this->serverKey = $key !== '' ? $key : null;

        // Load service account for HTTP v1
        $sa = null;
        $saJson = getenv('FIREBASE_SA_JSON') ?: '';
        $saPath = getenv('FIREBASE_SA_PATH') ?: '';
        if ($saJson !== '') {
            $decoded = json_decode($saJson, true);
            if (is_array($decoded) && isset($decoded['private_key'])) {
                $sa = $decoded;
            }
        } elseif ($saPath !== '') {
            // Supporte chemin relatif depuis le dossier backend
            $base = dirname(__DIR__, 2);
            $candidate = $saPath;
            if (!preg_match('/^([A-Za-z]:\\\\|\\\\|\/)?.*/', $saPath)) {
                $candidate = $base . DIRECTORY_SEPARATOR . $saPath;
            }
            if (is_file($candidate)) {
                $content = file_get_contents($candidate);
                $decoded = $content ? json_decode($content, true) : null;
                if (is_array($decoded) && isset($decoded['private_key'])) {
                    $sa = $decoded;
                }
            }
        } else {
            // Fallback to backend/env/firebase_sa.json if exists
            $defaultPath = dirname(__DIR__, 2) . DIRECTORY_SEPARATOR . 'env' . DIRECTORY_SEPARATOR . 'firebase_sa.json';
            if (is_file($defaultPath)) {
                $content = file_get_contents($defaultPath);
                $decoded = $content ? json_decode($content, true) : null;
                if (is_array($decoded) && isset($decoded['private_key'])) {
                    $sa = $decoded;
                }
            }
        }
        $this->serviceAccount = $sa;
        $this->projectId = getenv('FIREBASE_PROJECT_ID') ?: ($sa['project_id'] ?? null);
        $dbg = getenv('PUSH_DEBUG') ?: getenv('FCM_DEBUG') ?: '';
        $this->debug = in_array(strtolower((string)$dbg), ['1', 'true', 'yes', 'on'], true);
    }

    private function useLegacy(): bool
    {
        return !empty($this->serverKey);
    }

    private function useV1(): bool
    {
        return is_array($this->serviceAccount) && !empty($this->projectId);
    }

    public function isConfigured(): bool
    {
        return $this->useLegacy() || $this->useV1();
    }

    public function sendToTokens(array $tokens, string $title, string $body, array $data = []): bool
    {
        $tokens = array_values(array_unique(array_filter($tokens)));
        if (empty($tokens)) return false;
        if ($this->useLegacy()) {
            return $this->sendLegacy($tokens, $title, $body, $data);
        }
        if ($this->useV1()) {
            return $this->sendV1($tokens, $title, $body, $data);
        }
        return false;
    }

    private function sendLegacy(array $tokens, string $title, string $body, array $data): bool
    {
        $endpoint = 'https://fcm.googleapis.com/fcm/send';
        $payload = [
            'registration_ids' => $tokens,
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => $data,
            'android' => [
                'priority' => 'high',
            ],
        ];

        $ch = curl_init($endpoint);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/json',
            'Authorization: key=' . $this->serverKey,
        ]);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload, JSON_UNESCAPED_UNICODE));
        $resp = curl_exec($ch);
        $err = curl_error($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($this->debug || $code < 200 || $code >= 300) {
            $this->debugLog('[LEGACY] HTTP ' . $code . ' err=' . $err . ' body=' . substr((string)$resp, 0, 2000));
        }
        return $err === '' && $code >= 200 && $code < 300;
    }

    private function sendV1(array $tokens, string $title, string $body, array $data): bool
    {
        $accessToken = $this->getAccessToken();
        if (!$accessToken) return false;
        $okAny = false;
        $endpoint = 'https://fcm.googleapis.com/v1/projects/' . $this->projectId . '/messages:send';
        foreach ($tokens as $token) {
            $payload = [
                'message' => [
                    'token' => $token,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => array_map(fn($v) => (string)$v, $data),
                    'android' => [
                        'priority' => 'HIGH',
                    ],
                ],
            ];
            $ch = curl_init($endpoint);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json',
                'Authorization: Bearer ' . $accessToken,
            ]);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload, JSON_UNESCAPED_UNICODE));
            $resp = curl_exec($ch);
            $err = curl_error($ch);
            $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            if ($this->debug || $code < 200 || $code >= 300) {
                $this->debugLog('[V1] HTTP ' . $code . ' err=' . $err . ' body=' . substr((string)$resp, 0, 2000));
            }
            if ($err === '' && $code >= 200 && $code < 300) {
                $okAny = true;
            }
        }
        return $okAny;
    }

    private function getAccessToken(): ?string
    {
        if (!$this->useV1()) return null;
        $now = time();
        if (self::$tokenCache && ($now + 60) < (self::$tokenCache['expires_at'] ?? 0)) {
            return self::$tokenCache['access_token'];
        }

        $sa = $this->serviceAccount;
        $privateKey = $sa['private_key'] ?? null;
        $clientEmail = $sa['client_email'] ?? null;
        if (!$privateKey || !$clientEmail) return null;

        $tokenUrl = 'https://oauth2.googleapis.com/token';
        $scope = 'https://www.googleapis.com/auth/firebase.messaging';

        $header = ['alg' => 'RS256', 'typ' => 'JWT'];
        $claims = [
            'iss' => $clientEmail,
            'scope' => $scope,
            'aud' => $tokenUrl,
            'iat' => $now,
            'exp' => $now + 3600,
        ];
        $jwt = $this->jwtEncode($header, $claims, $privateKey);
        if (!$jwt) return null;

        $postFields = http_build_query([
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]);

        $ch = curl_init($tokenUrl);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/x-www-form-urlencoded']);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $postFields);
        $resp = curl_exec($ch);
        $err = curl_error($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        if ($this->debug || $code < 200 || $code >= 300) {
            $this->debugLog('[OAUTH] HTTP ' . $code . ' err=' . $err . ' body=' . substr((string)$resp, 0, 2000));
        }
        if ($err !== '' || $code < 200 || $code >= 300) return null;
        $json = json_decode($resp, true);
        if (!is_array($json) || empty($json['access_token'])) return null;
        $accessToken = $json['access_token'];
        $expiresIn = (int)($json['expires_in'] ?? 3600);
        self::$tokenCache = [
            'access_token' => $accessToken,
            'expires_at' => $now + max(60, $expiresIn - 60),
        ];
        return $accessToken;
    }

    private function jwtEncode(array $header, array $claims, string $privateKeyPem): ?string
    {
        $enc = fn($arr) => rtrim(strtr(base64_encode(json_encode($arr, JSON_UNESCAPED_SLASHES)), '+/', '-_'), '=');
        $segments = [$enc($header), $enc($claims)];
        $signingInput = implode('.', $segments);
        // Normaliser la clé: certains hôtes stockent les \n littéraux
        $pem = $privateKeyPem;
        if (strpos($pem, "\\n") !== false) {
            $pem = str_replace("\\n", "\n", $pem);
        }
        // Obtenir une ressource clé privée sans bruit d'erreur
        $pkey = @openssl_pkey_get_private($pem);
        if ($pkey === false) {
            // Tente avec fins de ligne normalisées CRLF->LF
            $pem2 = str_replace(["\r\n", "\r"], "\n", $pem);
            $pkey = @openssl_pkey_get_private($pem2);
            if ($pkey === false) return null;
        }
        $signature = '';
        $ok = @openssl_sign($signingInput, $signature, $pkey, OPENSSL_ALGO_SHA256);
        if (!$ok) return null;
        $sig = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');
        return $signingInput . '.' . $sig;
    }

    public function sendToUser(int $userId, string $title, string $body, array $data = []): bool
    {
        $pdo = \db();
        $st = $pdo->prepare('SELECT token FROM device_tokens WHERE user_id = ?');
        $st->execute([$userId]);
        $tokens = array_map(fn($r) => $r['token'], $st->fetchAll(\PDO::FETCH_ASSOC));
        if (empty($tokens)) return false;
        return $this->sendToTokens($tokens, $title, $body, $data);
    }

    private function debugLog(string $line): void
    {
        try {
            $base = dirname(__DIR__, 2);
            $dir = $base . DIRECTORY_SEPARATOR . 'logs';
            if (!is_dir($dir)) @mkdir($dir, 0755, true);
            $file = $dir . DIRECTORY_SEPARATOR . 'push.log';
            @file_put_contents($file, '[' . date('c') . "] " . $line . "\n", FILE_APPEND);
        } catch (\Throwable $e) {
            // Fallback vers error_log
            @error_log('[KivouPush] ' . $line);
        }
    }
}
