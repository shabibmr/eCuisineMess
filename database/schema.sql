-- ========================================================
-- eCuisine Mess Module Database Schema (MariaDB / MySQL)
-- Primary keys are UUID (CHAR(36)). No *_code columns.
-- ========================================================

CREATE DATABASE IF NOT EXISTS `ecuisine_mess`
DEFAULT CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE `ecuisine_mess`;

-- 1. Item Categories Master
CREATE TABLE IF NOT EXISTS `mess_item_categories` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `category_name` VARCHAR(100) NOT NULL,
    `sort_order` INT DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_category_name` (`category_name`)
) ENGINE=InnoDB;

-- 3. Units of Measure (seed-only master; no app CRUD)
CREATE TABLE IF NOT EXISTS `mess_uoms` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `uom_name` VARCHAR(50) NOT NULL,
    `sort_order` INT DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_uom_name` (`uom_name`)
) ENGINE=InnoDB;

-- 4. Items Master
CREATE TABLE IF NOT EXISTS `mess_items` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `item_name` VARCHAR(150) NOT NULL,
    `category_id` CHAR(36) NULL,
    `uom_id` CHAR(36) NOT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_mi_category` FOREIGN KEY (`category_id`) REFERENCES `mess_item_categories`(`id`) ON DELETE SET NULL,
    CONSTRAINT `fk_mi_uom` FOREIGN KEY (`uom_id`) REFERENCES `mess_uoms`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 5. Cuisines Master
CREATE TABLE IF NOT EXISTS `mess_cuisines` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `cuisine_name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255),
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_cuisine_name` (`cuisine_name`)
) ENGINE=InnoDB;

-- 5b. Meal Time Windows (per cuisine: each cuisine has its own Breakfast / Lunch / Dinner window)
-- Defaults: Breakfast 07:00-10:00, Lunch 12:00-15:00, Dinner 19:00-22:00
CREATE TABLE IF NOT EXISTS `mess_meal_times` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `cuisine_id` CHAR(36) NOT NULL,
    `meal_type` VARCHAR(20) NOT NULL COMMENT 'BREAKFAST, LUNCH, DINNER',
    `name` VARCHAR(50) NOT NULL,
    `start_time` TIME NOT NULL,
    `end_time` TIME NOT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_mmt_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `mess_cuisines`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_cuisine_meal` (`cuisine_id`, `meal_type`)
) ENGINE=InnoDB;

-- 6. Cuisine Items Mapping (Default Entitlement)
CREATE TABLE IF NOT EXISTS `mess_cuisine_items` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `cuisine_id` CHAR(36) NOT NULL,
    `item_id` CHAR(36) NOT NULL,
    `default_qty` DECIMAL(10,2) DEFAULT 1.00,
    `sort_order` INT DEFAULT 0,
    CONSTRAINT `fk_mci_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `mess_cuisines`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_mci_item` FOREIGN KEY (`item_id`) REFERENCES `mess_items`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_cuisine_item` (`cuisine_id`, `item_id`)
) ENGINE=InnoDB;

-- 7. Members Master
CREATE TABLE IF NOT EXISTS `mess_members` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `name` VARCHAR(150) NOT NULL,
    `rfid_tag` VARCHAR(64) NOT NULL UNIQUE,
    `phone` VARCHAR(30),
    `email` VARCHAR(100),
    `cuisine_id` CHAR(36),
    `validity_start` DATE NOT NULL,
    `validity_end` DATE NOT NULL,
    `status` VARCHAR(20) DEFAULT 'ACTIVE' COMMENT 'ACTIVE, EXPIRED, SUSPENDED',
    `photo_url` VARCHAR(255),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_mm_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `mess_cuisines`(`id`) ON DELETE SET NULL,
    INDEX `idx_rfid` (`rfid_tag`)
) ENGINE=InnoDB;

-- 8. Daily Menus
CREATE TABLE IF NOT EXISTS `mess_daily_menus` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `menu_date` DATE NOT NULL,
    `cuisine_id` CHAR(36) NOT NULL,
    `meal_type` VARCHAR(20) NOT NULL COMMENT 'BREAKFAST, LUNCH, DINNER',
    `is_locked` TINYINT(1) DEFAULT 0,
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_mdm_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `mess_cuisines`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_daily_menu` (`menu_date`, `cuisine_id`, `meal_type`)
) ENGINE=InnoDB;

-- 9. Daily Menu Items
CREATE TABLE IF NOT EXISTS `mess_daily_menu_items` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `menu_id` CHAR(36) NOT NULL,
    `item_id` CHAR(36) NOT NULL,
    `quantity` DECIMAL(10,2) DEFAULT 1.00,
    `notes` VARCHAR(255),
    CONSTRAINT `fk_mdmi_menu` FOREIGN KEY (`menu_id`) REFERENCES `mess_daily_menus`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_mdmi_item` FOREIGN KEY (`item_id`) REFERENCES `mess_items`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 10. Bills / Issued Tokens
-- token_number / bill_number are operational slip numbers (not master *_code columns)
CREATE TABLE IF NOT EXISTS `mess_bills` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `bill_number` VARCHAR(50) NOT NULL UNIQUE,
    `token_number` VARCHAR(20) NOT NULL COMMENT 'e.g. B-0012, L-0042, D-0015',
    `bill_date` DATE NOT NULL,
    `bill_time` TIME NOT NULL,
    `member_id` CHAR(36) NOT NULL,
    `cuisine_id` CHAR(36) NOT NULL,
    `meal_type` VARCHAR(20) NOT NULL COMMENT 'BREAKFAST, LUNCH, DINNER',
    `total_amount` DECIMAL(10,2) DEFAULT 0.00,
    `status` VARCHAR(20) DEFAULT 'SERVED' COMMENT 'SERVED, CANCELLED',
    `is_override` TINYINT(1) DEFAULT 0,
    `override_by` VARCHAR(100),
    `override_reason` VARCHAR(255),
    `cancelled_by` VARCHAR(100),
    `cancel_reason` VARCHAR(255),
    `cancelled_at` DATETIME,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_mb_member` FOREIGN KEY (`member_id`) REFERENCES `mess_members`(`id`),
    CONSTRAINT `fk_mb_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `mess_cuisines`(`id`),
    INDEX `idx_bill_date_meal` (`bill_date`, `meal_type`),
    INDEX `idx_member_date_meal` (`member_id`, `bill_date`, `meal_type`)
) ENGINE=InnoDB;

-- 11. Bill Items
CREATE TABLE IF NOT EXISTS `mess_bill_items` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `bill_id` CHAR(36) NOT NULL,
    `item_id` CHAR(36) NOT NULL,
    `item_name` VARCHAR(150) NOT NULL,
    `quantity` DECIMAL(10,2) DEFAULT 1.00,
    `unit_price` DECIMAL(10,2) DEFAULT 0.00,
    `total_price` DECIMAL(10,2) DEFAULT 0.00,
    CONSTRAINT `fk_mbi_bill` FOREIGN KEY (`bill_id`) REFERENCES `mess_bills`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 12. App Users (login)
CREATE TABLE IF NOT EXISTS `mess_users` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `display_name` VARCHAR(150) NOT NULL,
    `role` VARCHAR(20) NOT NULL DEFAULT 'counter' COMMENT 'admin, supervisor, counter',
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 13. User Sessions
CREATE TABLE IF NOT EXISTS `mess_user_sessions` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `user_id` CHAR(36) NOT NULL,
    `token` VARCHAR(64) NOT NULL UNIQUE,
    `expires_at` DATETIME NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_mus_user` FOREIGN KEY (`user_id`) REFERENCES `mess_users`(`id`) ON DELETE CASCADE,
    INDEX `idx_session_token` (`token`),
    INDEX `idx_session_expires` (`expires_at`)
) ENGINE=InnoDB;
