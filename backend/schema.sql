-- MySQL schema for KIVOU
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(190) NOT NULL,
  phone VARCHAR(64) DEFAULT NULL,
  avatar_url VARCHAR(255) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS service_providers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(190) NOT NULL,
  email VARCHAR(190) NOT NULL,
  phone VARCHAR(64) NOT NULL,
  photo_url VARCHAR(255) DEFAULT NULL,
  description TEXT,
  categories TEXT NOT NULL,
  rating DECIMAL(3,2) DEFAULT 0,
  reviews_count INT DEFAULT 0,
  price_per_hour DECIMAL(6,2) NOT NULL,
  latitude DECIMAL(10,6) NOT NULL,
  longitude DECIMAL(10,6) NOT NULL,
  gallery TEXT,
  available_days TEXT,
  working_start VARCHAR(5) DEFAULT NULL,
  working_end VARCHAR(5) DEFAULT NULL,
  is_available TINYINT(1) DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS bookings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  provider_id INT NOT NULL,
  service_category VARCHAR(190) NOT NULL,
  service_description TEXT,
  scheduled_at DATETIME NOT NULL,
  duration DECIMAL(4,2) NOT NULL,
  total_price DECIMAL(8,2) NOT NULL,
  status ENUM('pending','confirmed','inProgress','completed','cancelled') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at DATETIME DEFAULT NULL,
  payment_method VARCHAR(32) DEFAULT NULL,
  transaction_id VARCHAR(64) DEFAULT NULL,
  paid_at DATETIME DEFAULT NULL,
  amount DECIMAL(8,2) DEFAULT NULL,
  CONSTRAINT fk_bookings_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_bookings_provider FOREIGN KEY (provider_id) REFERENCES service_providers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS reviews (
  id INT AUTO_INCREMENT PRIMARY KEY,
  booking_id INT NOT NULL,
  user_id INT NOT NULL,
  provider_id INT NOT NULL,
  rating DECIMAL(3,2) NOT NULL,
  comment TEXT,
  photos TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  provider_response TEXT,
  responded_at DATETIME DEFAULT NULL,
  CONSTRAINT fk_reviews_booking FOREIGN KEY (booking_id) REFERENCES bookings(id),
  CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_reviews_provider FOREIGN KEY (provider_id) REFERENCES service_providers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Notifications persistantes
CREATE TABLE IF NOT EXISTS notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  provider_id INT DEFAULT NULL,
  title VARCHAR(190) NOT NULL,
  body TEXT,
  is_read TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_notifications_provider FOREIGN KEY (provider_id) REFERENCES service_providers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
