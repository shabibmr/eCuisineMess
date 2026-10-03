-- ========================================================
-- eCuisine Mess Module Database Schema (MariaDB / MySQL)
-- ========================================================

CREATE DATABASE IF NOT EXISTS `ecuisine_mess` 
DEFAULT CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `ecuisine_mess`;

-- 1. Meal Time Windows Master
CREATE TABLE IF NOT EXISTS `mess_meal_times` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `meal_type` VARCHAR(20) NOT NULL UNIQUE COMMENT 'BREAKFAST, LUNCH, DINNER',
    `name` VARCHAR(50) NOT NULL,
    `start_time` TIME NOT NULL,
    `end_time` TIME NOT NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 2. Items Master
CREATE TABLE IF NOT EXISTS `mess_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `item_code` VARCHAR(50) NOT NULL UNIQUE,
    `item_name` VARCHAR(150) NOT NULL,
    `category` VARCHAR(50) DEFAULT 'Main' COMMENT 'Main, Bread, Side, Beverage, Dessert',
    `unit` VARCHAR(20) DEFAULT 'Nos' COMMENT 'Nos, Plate, Bowl, Cup',
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 3. Cuisines Master
CREATE TABLE IF NOT EXISTS `mess_cuisines` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `cuisine_code` VARCHAR(50) NOT NULL UNIQUE,
    `cuisine_name` VARCHAR(100) NOT NULL,
    `description` VARCHAR(255),
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- 4. Cuisine Items Mapping (Default Entitlement)
CREATE TABLE IF NOT EXISTS `mess_cuisine_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `cuisine_id` INT NOT NULL,
    `item_id` INT NOT NULL,
    `default_qty` DECIMAL(10,2) DEFAULT 1.00,
    `sort_order` INT DEFAULT 0,
    CONSTRAINT `fk_mci_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `mess_cuisines`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_mci_item` FOREIGN KEY (`item_id`) REFERENCES `mess_items`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_cuisine_item` (`cuisine_id`, `item_id`)
) ENGINE=InnoDB;

-- 5. Members Master
CREATE TABLE IF NOT EXISTS `mess_members` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `member_code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(150) NOT NULL,
    `rfid_tag` VARCHAR(64) NOT NULL UNIQUE,
    `phone` VARCHAR(30),
    `email` VARCHAR(100),
    `cuisine_id` INT,
    `validity_start` DATE NOT NULL,
    `validity_end` DATE NOT NULL,
    `status` VARCHAR(20) DEFAULT 'ACTIVE' COMMENT 'ACTIVE, EXPIRED, SUSPENDED',
    `photo_url` VARCHAR(255),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_mm_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `mess_cuisines`(`id`) ON DELETE SET NULL,
    INDEX `idx_rfid` (`rfid_tag`)
) ENGINE=InnoDB;

-- 6. Daily Menus
CREATE TABLE IF NOT EXISTS `mess_daily_menus` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `menu_date` DATE NOT NULL,
    `cuisine_id` INT NOT NULL,
    `meal_type` VARCHAR(20) NOT NULL COMMENT 'BREAKFAST, LUNCH, DINNER',
    `is_locked` TINYINT(1) DEFAULT 0,
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_mdm_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `mess_cuisines`(`id`) ON DELETE CASCADE,
    UNIQUE KEY `uk_daily_menu` (`menu_date`, `cuisine_id`, `meal_type`)
) ENGINE=InnoDB;

-- 7. Daily Menu Items
CREATE TABLE IF NOT EXISTS `mess_daily_menu_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `menu_id` INT NOT NULL,
    `item_id` INT NOT NULL,
    `quantity` DECIMAL(10,2) DEFAULT 1.00,
    `notes` VARCHAR(255),
    CONSTRAINT `fk_mdmi_menu` FOREIGN KEY (`menu_id`) REFERENCES `mess_daily_menus`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_mdmi_item` FOREIGN KEY (`item_id`) REFERENCES `mess_items`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- 8. Bills / Issued Tokens
CREATE TABLE IF NOT EXISTS `mess_bills` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `bill_number` VARCHAR(50) NOT NULL UNIQUE,
    `token_number` VARCHAR(20) NOT NULL COMMENT 'e.g. B-0012, L-0042, D-0015',
    `bill_date` DATE NOT NULL,
    `bill_time` TIME NOT NULL,
    `member_id` INT NOT NULL,
    `cuisine_id` INT NOT NULL,
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

-- 9. Bill Items
CREATE TABLE IF NOT EXISTS `mess_bill_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `bill_id` INT NOT NULL,
    `item_id` INT NOT NULL,
    `item_name` VARCHAR(150) NOT NULL,
    `quantity` DECIMAL(10,2) DEFAULT 1.00,
    `unit_price` DECIMAL(10,2) DEFAULT 0.00,
    `total_price` DECIMAL(10,2) DEFAULT 0.00,
    CONSTRAINT `fk_mbi_bill` FOREIGN KEY (`bill_id`) REFERENCES `mess_bills`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;
