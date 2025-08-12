-- Chat schema for KIVOU (MySQL)
-- Engine/charset aligned with existing schema.sql

-- Conversations between two users, optionally linked to a service provider context
CREATE TABLE IF NOT EXISTS chat_conversations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_a_id INT NOT NULL,
  user_b_id INT NOT NULL,
  provider_id INT DEFAULT NULL, -- optional: chat context (e.g., about a provider)
  last_message TEXT,
  last_at DATETIME DEFAULT NULL,
  unread_a INT NOT NULL DEFAULT 0, -- unread count for user_a
  unread_b INT NOT NULL DEFAULT 0, -- unread count for user_b
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_chat_conv_user_a FOREIGN KEY (user_a_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_chat_conv_user_b FOREIGN KEY (user_b_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_chat_conv_provider FOREIGN KEY (provider_id) REFERENCES service_providers(id) ON DELETE SET NULL,
  CONSTRAINT uq_chat_conv_pair UNIQUE (user_a_id, user_b_id, provider_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Messages in a conversation
CREATE TABLE IF NOT EXISTS chat_messages (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  conversation_id INT NOT NULL,
  from_user_id INT NOT NULL,
  to_user_id INT NOT NULL,
  body TEXT NOT NULL,
  attachment_url VARCHAR(255) DEFAULT NULL,
  lat DECIMAL(10,7) DEFAULT NULL,
  lng DECIMAL(10,7) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  read_at DATETIME DEFAULT NULL,
  CONSTRAINT fk_chat_msg_conversation FOREIGN KEY (conversation_id) REFERENCES chat_conversations(id) ON DELETE CASCADE,
  CONSTRAINT fk_chat_msg_from FOREIGN KEY (from_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_chat_msg_to FOREIGN KEY (to_user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Useful indexes
CREATE INDEX idx_chat_conv_last_at ON chat_conversations(last_at);
CREATE INDEX idx_chat_conv_pair_lookup ON chat_conversations(user_a_id, user_b_id, provider_id);
CREATE INDEX idx_chat_msg_conv_created ON chat_messages(conversation_id, created_at);
CREATE INDEX idx_chat_msg_to_unread ON chat_messages(to_user_id, read_at);

-- Triggers to keep last_message/last_at and unread counters in sync
DELIMITER $$
CREATE TRIGGER trg_chat_msg_after_insert
AFTER INSERT ON chat_messages FOR EACH ROW
BEGIN
  -- Update conversation last message/at
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

-- Procedure to mark all messages as read for a user in a conversation
DELIMITER $$
CREATE PROCEDURE sp_chat_mark_read(IN p_conversation_id INT, IN p_user_id INT)
BEGIN
  UPDATE chat_messages
     SET read_at = NOW()
   WHERE conversation_id = p_conversation_id
     AND to_user_id = p_user_id
     AND read_at IS NULL;

  UPDATE chat_conversations
     SET unread_a = CASE WHEN user_a_id = p_user_id THEN 0 ELSE unread_a END,
         unread_b = CASE WHEN user_b_id = p_user_id THEN 0 ELSE unread_b END
   WHERE id = p_conversation_id;
END$$
DELIMITER ;
