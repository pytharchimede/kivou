-- Annonces (Demandes/Offres) et épinglage messages

CREATE TABLE IF NOT EXISTS announcements (
  id INT AUTO_INCREMENT PRIMARY KEY,
  author_user_id INT NOT NULL,
  author_role ENUM('client','provider') NOT NULL,
  provider_id INT DEFAULT NULL,
  type ENUM('request','offer') NOT NULL,
  title VARCHAR(190) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) DEFAULT NULL,
  images TEXT, -- JSON array of URLs
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ann_author_user FOREIGN KEY (author_user_id) REFERENCES users(id),
  CONSTRAINT fk_ann_provider FOREIGN KEY (provider_id) REFERENCES service_providers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Ajout du flag d'épinglage sur messages (si non présent)
ALTER TABLE chat_messages
  ADD COLUMN IF NOT EXISTS is_pinned TINYINT(1) NOT NULL DEFAULT 0;
-- Migration Annonces (Ads) + épinglage dans le chat
-- Date: 2025-08-12
-- Objectif: ajouter les tables d'annonces et permettre d'épingler une annonce dans une conversation
-- Compatible MySQL 8+ (utilise ADD COLUMN IF NOT EXISTS)

-- 1) Table principale des annonces
CREATE TABLE IF NOT EXISTS ads (
  id INT AUTO_INCREMENT PRIMARY KEY,
  author_user_id INT NOT NULL,
  author_type ENUM('client','provider') NOT NULL DEFAULT 'client',
  provider_id INT DEFAULT NULL,
  kind ENUM('request','offer') NOT NULL, -- request = demande, offer = offre
  title VARCHAR(180) NOT NULL,
  description TEXT NULL,
  image_url VARCHAR(255) DEFAULT NULL, -- image principale (miniature)
  amount DECIMAL(12,2) DEFAULT NULL,
  currency CHAR(3) NOT NULL DEFAULT 'XOF',
  category VARCHAR(64) DEFAULT NULL,
  lat DECIMAL(10,7) DEFAULT NULL,
  lng DECIMAL(10,7) DEFAULT NULL,
  status ENUM('active','closed','archived') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_ads_author FOREIGN KEY (author_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_ads_provider FOREIGN KEY (provider_id) REFERENCES service_providers(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX IF NOT EXISTS idx_ads_author ON ads(author_user_id);
CREATE INDEX IF NOT EXISTS idx_ads_provider ON ads(provider_id);
CREATE INDEX IF NOT EXISTS idx_ads_kind ON ads(kind);
CREATE INDEX IF NOT EXISTS idx_ads_status ON ads(status);
CREATE INDEX IF NOT EXISTS idx_ads_category ON ads(category);
CREATE INDEX IF NOT EXISTS idx_ads_created ON ads(created_at);

-- 2) Table des images multiples d'une annonce (optionnel mais recommandé)
CREATE TABLE IF NOT EXISTS ad_images (
  id INT AUTO_INCREMENT PRIMARY KEY,
  ad_id INT NOT NULL,
  url VARCHAR(255) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ad_images_ad FOREIGN KEY (ad_id) REFERENCES ads(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX IF NOT EXISTS idx_ad_images_ad ON ad_images(ad_id);
CREATE INDEX IF NOT EXISTS idx_ad_images_order ON ad_images(ad_id, sort_order);

-- 3) Ajouts pour le chat: information d'annonce épinglée dans une conversation
-- NOTE: nécessite que la table chat_conversations existe (voir schema_chat.sql)
ALTER TABLE chat_conversations
  ADD COLUMN IF NOT EXISTS pinned_ad_id INT NULL AFTER provider_id,
  ADD COLUMN IF NOT EXISTS pinned_text TEXT NULL AFTER pinned_ad_id,
  ADD COLUMN IF NOT EXISTS pinned_image_url VARCHAR(255) NULL AFTER pinned_text,
  ADD COLUMN IF NOT EXISTS pinned_at DATETIME NULL AFTER pinned_image_url;

-- Contrainte et index pour l'annonce épinglée
ALTER TABLE chat_conversations
  ADD CONSTRAINT IF NOT EXISTS fk_chat_conv_pinned_ad
    FOREIGN KEY (pinned_ad_id) REFERENCES ads(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_chat_conv_pinned_at ON chat_conversations(pinned_at);

-- Fin de la migration
