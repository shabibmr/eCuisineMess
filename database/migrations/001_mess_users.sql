-- ========================================================
-- Migration 001: mess_users + mess_user_sessions
-- Apply on an existing ecuisine_mess database:
--   mysql -u root ecuisine_mess < database/migrations/001_mess_users.sql
-- For a brand-new install, use database/schema.sql + seed.sql instead
-- (those already include these tables).
-- ========================================================

USE `ecuisine_mess`;

CREATE TABLE IF NOT EXISTS `mess_users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `display_name` VARCHAR(150) NOT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `mess_user_sessions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `token` VARCHAR(64) NOT NULL UNIQUE,
    `expires_at` DATETIME NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_mus_user` FOREIGN KEY (`user_id`) REFERENCES `mess_users`(`id`) ON DELETE CASCADE,
    INDEX `idx_session_token` (`token`),
    INDEX `idx_session_expires` (`expires_at`)
) ENGINE=InnoDB;

-- Default admin / admin123 (bcrypt). Skip if username already exists.
INSERT INTO `mess_users` (`username`, `password_hash`, `display_name`, `is_active`)
SELECT 'admin', '$2b$12$EFGKCcXkjHNvfOpJUK8gLeODDxpDmaFevnavQS6H3/i18CKGPodYK', 'Administrator', 1
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `mess_users` WHERE `username` = 'admin');
