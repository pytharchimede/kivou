<?php
require_once __DIR__ . '/../../config.php';
$claims = require_auth();

try {
    $pdo = db();
    $dbName = $pdo->query('SELECT DATABASE()')->fetchColumn();

    // Check columns lat/lng
    $colStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = :db AND TABLE_NAME = 'chat_messages'");
    $colStmt->execute([':db' => $dbName]);
    $cols = array_map(fn($r) => $r['COLUMN_NAME'], $colStmt->fetchAll(PDO::FETCH_ASSOC));

    $altered = false;
    if (!in_array('lat', $cols) || !in_array('lng', $cols)) {
        $pdo->exec("ALTER TABLE chat_messages ADD COLUMN lat DECIMAL(10,7) NULL AFTER attachment_url, ADD COLUMN lng DECIMAL(10,7) NULL AFTER lat");
        $altered = true;
    }

    // Recreate trigger to include new last_message rules
    $pdo->exec("DROP TRIGGER IF EXISTS trg_chat_msg_after_insert");
    $pdo->exec(<<<SQL
DELIMITER $$
CREATE TRIGGER trg_chat_msg_after_insert
AFTER INSERT ON chat_messages FOR EACH ROW
BEGIN
  UPDATE chat_conversations
    SET last_message = CASE 
                         WHEN (NEW.body IS NOT NULL AND CHAR_LENGTH(NEW.body) > 0) THEN NEW.body
                         WHEN (NEW.attachment_url IS NOT NULL AND CHAR_LENGTH(NEW.attachment_url) > 0) THEN '[Image]'
                         WHEN (NEW.lat IS NOT NULL AND NEW.lng IS NOT NULL) THEN '[Localisation]'
                         ELSE ''
                       END,
        last_at = NEW.created_at,
        unread_a = CASE WHEN user_a_id = NEW.to_user_id THEN unread_a + 1 ELSE unread_a END,
        unread_b = CASE WHEN user_b_id = NEW.to_user_id THEN unread_b + 1 ELSE unread_b END
  WHERE id = NEW.conversation_id;
END$$
DELIMITER ;
SQL);

    json_ok(['altered' => $altered, 'trigger' => 'updated']);
} catch (Throwable $e) {
    json_error('MIGRATE_ERROR', $e->getMessage(), 500);
}
