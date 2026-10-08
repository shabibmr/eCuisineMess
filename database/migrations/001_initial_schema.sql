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

-- 14. Organizations Master
CREATE TABLE IF NOT EXISTS `mess_organizations` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `org_name` VARCHAR(150) NOT NULL,
    `trn` VARCHAR(50) NULL COMMENT 'Tax Registration Number (UAE VAT)',
    `address` TEXT NULL,
    `address_to_print` TEXT NULL COMMENT 'Company header address (English) for reports and slips',
    `address_to_print_arabic` TEXT NULL COMMENT 'Company header address (Arabic) for bilingual reports and slips',
    `currency` VARCHAR(10) NOT NULL DEFAULT 'AED' COMMENT 'Default reporting/slip currency code (e.g. AED)',
    `phone` VARCHAR(30) NULL,
    `email` VARCHAR(100) NULL,
    `contact_person` VARCHAR(100) NULL,
    `website` VARCHAR(150) NULL,
    `notes` VARCHAR(255) NULL,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_org_name` (`org_name`),
    INDEX `idx_org_trn` (`trn`)
) ENGINE=InnoDB;

-- ========================================================
-- Seed Data (Initial Configuration, Masters & Demo Data)
-- ========================================================

-- Fixed UUIDs for reproducible seeds
-- Categories
SET @cat_main     = 'a1000001-0000-4000-8000-000000000001';
SET @cat_side     = 'a1000001-0000-4000-8000-000000000002';
SET @cat_bread    = 'a1000001-0000-4000-8000-000000000003';
SET @cat_bev      = 'a1000001-0000-4000-8000-000000000004';
SET @cat_dessert  = 'a1000001-0000-4000-8000-000000000005';

-- UOMs
SET @uom_piece = 'a8000001-0000-4000-8000-000000000001';
SET @uom_nos   = 'a8000001-0000-4000-8000-000000000002';
SET @uom_grams = 'a8000001-0000-4000-8000-000000000003';
SET @uom_litres = 'a8000001-0000-4000-8000-000000000004';
SET @uom_ml    = 'a8000001-0000-4000-8000-000000000005';
SET @uom_plate = 'a8000001-0000-4000-8000-000000000006';
SET @uom_bowl  = 'a8000001-0000-4000-8000-000000000007';
SET @uom_cup   = 'a8000001-0000-4000-8000-000000000008';
SET @uom_glass = 'a8000001-0000-4000-8000-000000000009';

-- Items
SET @itm_01 = 'a2000001-0000-4000-8000-000000000001';
SET @itm_02 = 'a2000001-0000-4000-8000-000000000002';
SET @itm_03 = 'a2000001-0000-4000-8000-000000000003';
SET @itm_04 = 'a2000001-0000-4000-8000-000000000004';
SET @itm_05 = 'a2000001-0000-4000-8000-000000000005';
SET @itm_06 = 'a2000001-0000-4000-8000-000000000006';
SET @itm_07 = 'a2000001-0000-4000-8000-000000000007';
SET @itm_08 = 'a2000001-0000-4000-8000-000000000008';
SET @itm_09 = 'a2000001-0000-4000-8000-000000000009';
SET @itm_10 = 'a2000001-0000-4000-8000-000000000010';
SET @itm_11 = 'a2000001-0000-4000-8000-000000000011';
SET @itm_12 = 'a2000001-0000-4000-8000-000000000012';
SET @itm_13 = 'a2000001-0000-4000-8000-000000000013';
SET @itm_14 = 'a2000001-0000-4000-8000-000000000014';
SET @itm_15 = 'a2000001-0000-4000-8000-000000000015';
SET @itm_16 = 'a2000001-0000-4000-8000-000000000016';
SET @itm_17 = 'a2000001-0000-4000-8000-000000000017';
SET @itm_18 = 'a2000001-0000-4000-8000-000000000018';

-- Cuisines
SET @cui_si = 'a3000001-0000-4000-8000-000000000001';
SET @cui_ni = 'a3000001-0000-4000-8000-000000000002';
SET @cui_ar = 'a3000001-0000-4000-8000-000000000003';
SET @cui_co = 'a3000001-0000-4000-8000-000000000004';
SET @cui_kl = 'a3000001-0000-4000-8000-000000000005';

-- Members
SET @mem_01 = 'a4000001-0000-4000-8000-000000000001';
SET @mem_02 = 'a4000001-0000-4000-8000-000000000002';
SET @mem_03 = 'a4000001-0000-4000-8000-000000000003';
SET @mem_04 = 'a4000001-0000-4000-8000-000000000004';
SET @mem_05 = 'a4000001-0000-4000-8000-000000000005';
SET @mem_06 = 'a4000001-0000-4000-8000-000000000006';
SET @mem_07 = 'a4000001-0000-4000-8000-000000000007';
SET @mem_08 = 'a4000001-0000-4000-8000-000000000008';
SET @mem_09 = 'a4000001-0000-4000-8000-000000000009';
SET @mem_10 = 'a4000001-0000-4000-8000-000000000010';

-- Menus / bills / user
SET @menu_1 = 'a5000001-0000-4000-8000-000000000001';
SET @menu_2 = 'a5000001-0000-4000-8000-000000000002';
SET @menu_3 = 'a5000001-0000-4000-8000-000000000003';
SET @menu_4 = 'a5000001-0000-4000-8000-000000000004';
SET @menu_5 = 'a5000001-0000-4000-8000-000000000005';
SET @menu_6 = 'a5000001-0000-4000-8000-000000000006';
SET @bill_1 = 'a6000001-0000-4000-8000-000000000001';
SET @bill_2 = 'a6000001-0000-4000-8000-000000000002';
SET @user_admin = 'a7000001-0000-4000-8000-000000000001';
SET @org_dit = 'e0000001-0000-4000-8000-000000000001';

-- 1. Item Categories
INSERT INTO `mess_item_categories` (`id`, `category_name`, `sort_order`, `is_active`) VALUES
(@cat_main, 'Main', 1, 1),
(@cat_side, 'Side', 2, 1),
(@cat_bread, 'Bread', 3, 1),
(@cat_bev, 'Beverage', 4, 1),
(@cat_dessert, 'Dessert', 5, 1)
ON DUPLICATE KEY UPDATE `sort_order`=VALUES(`sort_order`);

-- 2. Units of Measure
INSERT INTO `mess_uoms` (`id`, `uom_name`, `sort_order`, `is_active`) VALUES
(@uom_piece, 'Piece', 1, 1),
(@uom_nos, 'Nos', 2, 1),
(@uom_grams, 'Grams', 3, 1),
(@uom_litres, 'Litres', 4, 1),
(@uom_ml, 'MilliLitres', 5, 1),
(@uom_plate, 'Plate', 6, 1),
(@uom_bowl, 'Bowl', 7, 1),
(@uom_cup, 'Cup', 8, 1),
(@uom_glass, 'Glass', 9, 1)
ON DUPLICATE KEY UPDATE `sort_order`=VALUES(`sort_order`);

-- 3. Items
INSERT INTO `mess_items` (`id`, `item_name`, `category_id`, `uom_id`, `is_active`) VALUES
(@itm_01, 'Steamed Idli (3 pcs)', @cat_main, @uom_plate, 1),
(@itm_02, 'Medu Vada (1 pc)', @cat_side, @uom_nos, 1),
(@itm_03, 'Coconut Chutney & Sambar', @cat_side, @uom_bowl, 1),
(@itm_04, 'Filter Coffee / Tea', @cat_bev, @uom_cup, 1),
(@itm_05, 'Hyderabadi Chicken Biryani', @cat_main, @uom_plate, 1),
(@itm_06, 'Mirchi Ka Salan & Raita', @cat_side, @uom_bowl, 1),
(@itm_07, 'Gulab Jamun (2 pcs)', @cat_dessert, @uom_bowl, 1),
(@itm_08, 'Paneer Butter Masala', @cat_main, @uom_bowl, 1),
(@itm_09, 'Tandoori Roti (2 pcs)', @cat_bread, @uom_plate, 1),
(@itm_10, 'Jeera Rice & Dal Tadka', @cat_main, @uom_plate, 1),
(@itm_11, 'Arabic Chicken Mandi Rice', @cat_main, @uom_plate, 1),
(@itm_12, 'Arabic Garlic Paste (Toum) & Dakkous', @cat_side, @uom_bowl, 1),
(@itm_13, 'Fattoush Salad', @cat_side, @uom_bowl, 1),
(@itm_14, 'Grilled Chicken Breast & Herb Veggies', @cat_main, @uom_plate, 1),
(@itm_15, 'Cream of Mushroom Soup', @cat_side, @uom_bowl, 1),
(@itm_16, 'Garlic Bread (2 pcs)', @cat_bread, @uom_plate, 1),
(@itm_17, 'Kerala Parotta (2 pcs)', @cat_bread, @uom_plate, 1),
(@itm_18, 'Chicken Pepper Roast', @cat_main, @uom_plate, 1)
ON DUPLICATE KEY UPDATE `item_name`=VALUES(`item_name`), `category_id`=VALUES(`category_id`), `uom_id`=VALUES(`uom_id`);

-- 4. Cuisines
INSERT INTO `mess_cuisines` (`id`, `cuisine_name`, `description`, `is_active`) VALUES
(@cui_si, 'South Indian', 'Traditional South Indian meals, idlis, dosas & rice', 1),
(@cui_ni, 'North Indian', 'Curries, tandoor breads, dal and aromatic basmati rice', 1),
(@cui_ar, 'Arabic', 'Authentic Arabic Mandi, grilled meats, toum & fresh salads', 1),
(@cui_co, 'Continental', 'Steaks, soups, pasta and grilled vegetable platters', 1),
(@cui_kl, 'Kerala Special', 'Malabar parottas, coconut curries and seafood dishes', 1)
ON DUPLICATE KEY UPDATE `description`=VALUES(`description`);

-- 5. Meal Times per cuisine (Breakfast 07:00-10:00, Lunch 12:00-15:00, Dinner 19:00-22:00)
INSERT INTO `mess_meal_times` (`id`, `cuisine_id`, `meal_type`, `name`, `start_time`, `end_time`, `is_active`) VALUES
('a0000001-0000-4000-8000-000000000011', @cui_si, 'BREAKFAST', 'Breakfast', '07:00:00', '10:00:00', 1),
('a0000001-0000-4000-8000-000000000012', @cui_si, 'LUNCH',     'Lunch',     '12:00:00', '15:00:00', 1),
('a0000001-0000-4000-8000-000000000013', @cui_si, 'DINNER',    'Dinner',    '19:00:00', '22:00:00', 1),
('a0000001-0000-4000-8000-000000000021', @cui_ni, 'BREAKFAST', 'Breakfast', '07:00:00', '10:00:00', 1),
('a0000001-0000-4000-8000-000000000022', @cui_ni, 'LUNCH',     'Lunch',     '12:00:00', '15:00:00', 1),
('a0000001-0000-4000-8000-000000000023', @cui_ni, 'DINNER',    'Dinner',    '19:00:00', '22:00:00', 1),
('a0000001-0000-4000-8000-000000000031', @cui_ar, 'BREAKFAST', 'Breakfast', '07:00:00', '10:00:00', 1),
('a0000001-0000-4000-8000-000000000032', @cui_ar, 'LUNCH',     'Lunch',     '12:00:00', '15:00:00', 1),
('a0000001-0000-4000-8000-000000000033', @cui_ar, 'DINNER',    'Dinner',    '19:00:00', '22:00:00', 1),
('a0000001-0000-4000-8000-000000000041', @cui_co, 'BREAKFAST', 'Breakfast', '07:00:00', '10:00:00', 1),
('a0000001-0000-4000-8000-000000000042', @cui_co, 'LUNCH',     'Lunch',     '12:00:00', '15:00:00', 1),
('a0000001-0000-4000-8000-000000000043', @cui_co, 'DINNER',    'Dinner',    '19:00:00', '22:00:00', 1),
('a0000001-0000-4000-8000-000000000051', @cui_kl, 'BREAKFAST', 'Breakfast', '07:00:00', '10:00:00', 1),
('a0000001-0000-4000-8000-000000000052', @cui_kl, 'LUNCH',     'Lunch',     '12:00:00', '15:00:00', 1),
('a0000001-0000-4000-8000-000000000053', @cui_kl, 'DINNER',    'Dinner',    '19:00:00', '22:00:00', 1)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `start_time`=VALUES(`start_time`), `end_time`=VALUES(`end_time`);

-- 6. Cuisine Items Mapping
INSERT INTO `mess_cuisine_items` (`id`, `cuisine_id`, `item_id`, `default_qty`, `sort_order`) VALUES
(UUID(), @cui_si, @itm_01, 1.00, 1),
(UUID(), @cui_si, @itm_02, 1.00, 2),
(UUID(), @cui_si, @itm_03, 1.00, 3),
(UUID(), @cui_si, @itm_04, 1.00, 4),
(UUID(), @cui_ni, @itm_08, 1.00, 1),
(UUID(), @cui_ni, @itm_09, 1.00, 2),
(UUID(), @cui_ni, @itm_10, 1.00, 3),
(UUID(), @cui_ar, @itm_11, 1.00, 1),
(UUID(), @cui_ar, @itm_12, 1.00, 2),
(UUID(), @cui_ar, @itm_13, 1.00, 3),
(UUID(), @cui_co, @itm_14, 1.00, 1),
(UUID(), @cui_co, @itm_15, 1.00, 2),
(UUID(), @cui_co, @itm_16, 1.00, 3),
(UUID(), @cui_kl, @itm_17, 1.00, 1),
(UUID(), @cui_kl, @itm_18, 1.00, 2)
ON DUPLICATE KEY UPDATE `default_qty`=VALUES(`default_qty`);

-- 7. Members
INSERT INTO `mess_members` (`id`, `name`, `rfid_tag`, `phone`, `email`, `cuisine_id`, `validity_start`, `validity_end`, `status`) VALUES
(@mem_01, 'Ravi Kumar', 'E280116060000204', '+971-50-1234567', 'ravi.k@example.com', @cui_si, '2026-01-01', '2026-12-31', 'ACTIVE'),
(@mem_02, 'Fatima Al Zarooni', 'E280116060000205', '+971-50-2345678', 'fatima.z@example.com', @cui_ar, '2026-01-01', '2026-12-31', 'ACTIVE'),
(@mem_03, 'Priya Sharma', 'E280116060000206', '+971-50-3456789', 'priya.s@example.com', @cui_ni, '2026-01-01', '2026-12-31', 'ACTIVE'),
(@mem_04, 'John Mitchell', 'E280116060000207', '+971-50-4567890', 'john.m@example.com', @cui_co, '2026-01-01', '2026-12-31', 'ACTIVE'),
(@mem_05, 'Ananya Nair', 'E280116060000208', '+971-50-5678901', 'ananya.n@example.com', @cui_kl, '2026-01-01', '2026-12-31', 'ACTIVE'),
(@mem_06, 'Ahmed Hassan (Expired)', 'E280116060000209', '+971-50-6789012', 'ahmed.h@example.com', @cui_ar, '2025-01-01', '2025-12-31', 'ACTIVE'),
(@mem_07, 'Suresh Menon', 'E280116060000210', '+971-50-7890123', 'suresh.m@example.com', @cui_si, '2026-01-01', '2026-12-31', 'ACTIVE'),
(@mem_08, 'Tariq Mansoor (Suspended)', 'E280116060000211', '+971-50-8901234', 'tariq.m@example.com', @cui_ar, '2026-01-01', '2026-12-31', 'SUSPENDED'),
(@mem_09, 'Pooja Verma', 'E280116060000212', '+971-50-9012345', 'pooja.v@example.com', @cui_ni, '2026-01-01', '2026-12-31', 'ACTIVE'),
(@mem_10, 'Alexandre Dubois', 'E280116060000213', '+971-50-0123456', 'alex.d@example.com', @cui_co, '2026-01-01', '2026-12-31', 'ACTIVE')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `rfid_tag`=VALUES(`rfid_tag`), `cuisine_id`=VALUES(`cuisine_id`);

-- 8. Daily Menus for Today
INSERT INTO `mess_daily_menus` (`id`, `menu_date`, `cuisine_id`, `meal_type`, `is_locked`, `notes`) VALUES
(@menu_1, CURDATE(), @cui_si, 'BREAKFAST', 0, 'Morning South Indian breakfast setup'),
(@menu_2, CURDATE(), @cui_si, 'LUNCH', 0, 'South Indian Meals with Biryani option'),
(@menu_3, CURDATE(), @cui_si, 'DINNER', 0, 'Light dinner'),
(@menu_4, CURDATE(), @cui_ni, 'LUNCH', 0, 'North Indian combo with Paneer Butter Masala'),
(@menu_5, CURDATE(), @cui_ar, 'LUNCH', 0, 'Chicken Mandi Platter'),
(@menu_6, CURDATE(), @cui_co, 'LUNCH', 0, 'Continental Herb Roast')
ON DUPLICATE KEY UPDATE `notes`=VALUES(`notes`);

-- 9. Daily Menu Items
INSERT INTO `mess_daily_menu_items` (`id`, `menu_id`, `item_id`, `quantity`) VALUES
(UUID(), @menu_1, @itm_01, 1.00), (UUID(), @menu_1, @itm_02, 1.00), (UUID(), @menu_1, @itm_03, 1.00), (UUID(), @menu_1, @itm_04, 1.00),
(UUID(), @menu_2, @itm_05, 1.00), (UUID(), @menu_2, @itm_06, 1.00), (UUID(), @menu_2, @itm_07, 1.00),
(UUID(), @menu_3, @itm_01, 1.00), (UUID(), @menu_3, @itm_03, 1.00), (UUID(), @menu_3, @itm_04, 1.00),
(UUID(), @menu_4, @itm_08, 1.00), (UUID(), @menu_4, @itm_09, 1.00), (UUID(), @menu_4, @itm_10, 1.00), (UUID(), @menu_4, @itm_07, 1.00),
(UUID(), @menu_5, @itm_11, 1.00), (UUID(), @menu_5, @itm_12, 1.00), (UUID(), @menu_5, @itm_13, 1.00),
(UUID(), @menu_6, @itm_14, 1.00), (UUID(), @menu_6, @itm_15, 1.00), (UUID(), @menu_6, @itm_16, 1.00)
ON DUPLICATE KEY UPDATE `quantity`=VALUES(`quantity`);

-- 10. Sample bills
INSERT INTO `mess_bills` (`id`, `bill_number`, `token_number`, `bill_date`, `bill_time`, `member_id`, `cuisine_id`, `meal_type`, `total_amount`, `status`) VALUES
(@bill_1, CONCAT('B-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-0001'), 'B-0001', CURDATE(), '08:15:00', @mem_01, @cui_si, 'BREAKFAST', 0.00, 'SERVED'),
(@bill_2, CONCAT('B-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-0002'), 'B-0002', CURDATE(), '08:22:00', @mem_03, @cui_ni, 'BREAKFAST', 0.00, 'SERVED')
ON DUPLICATE KEY UPDATE `token_number`=VALUES(`token_number`);

INSERT INTO `mess_bill_items` (`id`, `bill_id`, `item_id`, `item_name`, `quantity`, `unit_price`, `total_price`) VALUES
(UUID(), @bill_1, @itm_01, 'Steamed Idli (3 pcs)', 1.00, 0.00, 0.00),
(UUID(), @bill_1, @itm_02, 'Medu Vada (1 pc)', 1.00, 0.00, 0.00),
(UUID(), @bill_1, @itm_03, 'Coconut Chutney & Sambar', 1.00, 0.00, 0.00),
(UUID(), @bill_1, @itm_04, 'Filter Coffee / Tea', 1.00, 0.00, 0.00),
(UUID(), @bill_2, @itm_01, 'Steamed Idli (3 pcs)', 1.00, 0.00, 0.00),
(UUID(), @bill_2, @itm_04, 'Filter Coffee / Tea', 1.00, 0.00, 0.00)
ON DUPLICATE KEY UPDATE `quantity`=VALUES(`quantity`);

-- 11. App user (password: admin123)
INSERT INTO `mess_users` (`id`, `username`, `password_hash`, `display_name`, `role`, `is_active`) VALUES
(@user_admin, 'admin', '$2b$12$EFGKCcXkjHNvfOpJUK8gLeODDxpDmaFevnavQS6H3/i18CKGPodYK', 'Administrator', 'admin', 1)
ON DUPLICATE KEY UPDATE `display_name`=VALUES(`display_name`), `password_hash`=VALUES(`password_hash`), `role`='admin';

-- 12. Organizations
INSERT INTO `mess_organizations` (`id`, `org_name`, `trn`, `address`, `address_to_print`, `address_to_print_arabic`, `currency`, `phone`, `email`, `contact_person`, `is_active`) VALUES
(@org_dit, 'DIT UAE', '100200300400003', 'Dubai Investment Park, Dubai, UAE', 'DIT UAE CATERING & SERVICES LLC\nDubai Investment Park 1, P.O. Box 12345, Dubai, UAE', 'دي آي تي لخدمات التموين ذ.م.م\nمجمع دبي للاستثمار 1، ص.ب 12345، دبي، الإمارات', 'AED', '+971 4 123 4567', 'catering@dituae.com', 'Mess Supervisor', 1)
ON DUPLICATE KEY UPDATE `org_name`=VALUES(`org_name`), `currency`=VALUES(`currency`);


