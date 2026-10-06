-- ========================================================
-- Migration 002: mess_item_categories + mess_items.category_id
-- Apply on an existing ecuisine_mess database that still has
-- mess_items.category VARCHAR:
--   mysql -u root ecuisine_mess < database/migrations/002_mess_item_categories.sql
-- Fresh installs: use schema.sql + seed.sql (already normalized).
-- ========================================================

USE `ecuisine_mess`;

CREATE TABLE IF NOT EXISTS `mess_item_categories` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `category_code` VARCHAR(50) NOT NULL UNIQUE,
    `category_name` VARCHAR(100) NOT NULL,
    `sort_order` INT DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO `mess_item_categories` (`category_code`, `category_name`, `sort_order`, `is_active`) VALUES
('CAT-MAIN', 'Main', 1, 1),
('CAT-SIDE', 'Side', 2, 1),
('CAT-BREAD', 'Bread', 3, 1),
('CAT-BEV', 'Beverage', 4, 1),
('CAT-DESSERT', 'Dessert', 5, 1)
ON DUPLICATE KEY UPDATE
  `category_name` = VALUES(`category_name`),
  `sort_order` = VALUES(`sort_order`);

-- Add category_id if missing
SET @col_exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ecuisine_mess'
    AND TABLE_NAME = 'mess_items'
    AND COLUMN_NAME = 'category_id'
);

SET @sql := IF(@col_exists = 0,
  'ALTER TABLE `mess_items` ADD COLUMN `category_id` INT NULL AFTER `item_name`',
  'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Backfill from legacy VARCHAR category when present
SET @legacy := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'ecuisine_mess'
    AND TABLE_NAME = 'mess_items'
    AND COLUMN_NAME = 'category'
);

SET @sql := IF(@legacy > 0,
  'UPDATE mess_items i
   JOIN mess_item_categories c ON c.category_name = i.category
   SET i.category_id = c.id
   WHERE i.category_id IS NULL',
  'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Drop FK if re-running, then add
SET @fk := (
  SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = 'ecuisine_mess'
    AND TABLE_NAME = 'mess_items'
    AND CONSTRAINT_NAME = 'fk_mi_category'
);
SET @sql := IF(@fk = 0,
  'ALTER TABLE `mess_items` ADD CONSTRAINT `fk_mi_category` FOREIGN KEY (`category_id`) REFERENCES `mess_item_categories`(`id`) ON DELETE SET NULL',
  'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Drop legacy category column
SET @sql := IF(@legacy > 0,
  'ALTER TABLE `mess_items` DROP COLUMN `category`',
  'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
