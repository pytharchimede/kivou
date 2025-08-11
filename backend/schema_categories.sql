-- Table des catégories de services
CREATE TABLE IF NOT EXISTS service_categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Données initiales (optionnel)
INSERT INTO service_categories (name) VALUES
('Plomberie'),('Électricité'),('Ménage'),('Jardinage'),('Peinture'),('Menuiserie'),('Climatisation'),('Serrurerie'),('Déménagement'),('Informatique'),('Coiffure')
ON DUPLICATE KEY UPDATE name=VALUES(name);
