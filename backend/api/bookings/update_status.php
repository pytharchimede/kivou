<?php
require_once __DIR__ . '/../../config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_error('METHOD_NOT_ALLOWED', 'Use POST', 405);
}
$claims = require_auth();
$userId = (int)$claims['sub'];
$body = get_json_body();
require_fields($body, ['booking_id', 'status']);

$bookingId = (int)$body['booking_id'];
$newStatus = strtolower(trim($body['status']));
if (!in_array($newStatus, ['confirmed', 'cancelled'], true)) {
    json_error('BAD_STATUS', 'status must be confirmed|cancelled', 400);
}

$pdo = db();
// Charger la réservation et le prestataire pour vérifier l'autorisation
$stB = $pdo->prepare('SELECT b.id,b.user_id,b.provider_id,b.status,sp.owner_user_id FROM bookings b JOIN service_providers sp ON sp.id=b.provider_id WHERE b.id=?');
$stB->execute([$bookingId]);
$bk = $stB->fetch();
if (!$bk) json_error('NOT_FOUND', 'Booking not found', 404);

// Autorisation: seul le propriétaire du prestataire peut accepter/refuser
if (empty($bk['owner_user_id']) || (int)$bk['owner_user_id'] !== $userId) {
    json_error('FORBIDDEN', 'Not allowed', 403);
}

// Mettre à jour le statut
$now = date('Y-m-d H:i:s');
$stU = $pdo->prepare('UPDATE bookings SET status=?, completed_at=CASE WHEN ?="cancelled" THEN NOW() ELSE completed_at END WHERE id=?');
$stU->execute([$newStatus, $newStatus, $bookingId]);

// Notification au demandeur (client)
try {
    $title = $newStatus === 'confirmed' ? 'Commande acceptée' : 'Commande refusée';
    $bodyMsg = $newStatus === 'confirmed'
        ? 'Votre commande #' . $bookingId . ' a été acceptée.'
        : 'Votre commande #' . $bookingId . ' a été refusée.';
    $stN = $pdo->prepare('INSERT INTO notifications (user_id, provider_id, title, body) VALUES (?,?,?,?)');
    $stN->execute([(int)$bk['user_id'], (int)$bk['provider_id'], $title, $bodyMsg]);
} catch (Throwable $e) { /* ignore */
}

json_ok(['ok' => true]);
