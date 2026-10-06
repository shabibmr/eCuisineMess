-- ========================================================
-- Migration 004: mess_uoms + mess_items.uom_id (drop unit)
-- Safe for existing UUID schema (after 003).
-- ========================================================

USE `ecuisine_mess`;

CREATE TABLE IF NOT EXISTS `mess_uoms` (
    `id` CHAR(36) NOT NULL PRIMARY KEY,
    `uom_name` VARCHAR(50) NOT NULL,
    `sort_order` INT DEFAULT 0,
    `is_active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_uom_name` (`uom_name`)
) ENGINE=InnoDB;

INSERT INTO `mess_uoms` (`id`, `uom_name`, `sort_order`, `is_active`) VALUES
('a8000001-0000-4000-8000-000000000001', 'Piece', 1, 1),
('a8000001-0000-4000-8000-000000000002', 'Nos', 2, 1),
('a8000001-0000-4000-8000-000000000003', 'Grams', 3, 1),
('a8000001-0000-4000-8000-000000000004', 'Litres', 4, 1),
('a8000001-0000-4000-8000-000000000005', 'MilliLitres', 5, 1),
('a8000001-0000-4000-8000-000000000006', 'Plate', 6, 1),
('a8000001-0000-4000-8000-000000000007', 'Bowl', 7, 1),
('a8000001-0000-4000-8000-000000000008', 'Cup', 8, 1),
('a8000001-0000-4000-8000-000000000009', 'Glass', 9, 1)
ON DUPLICATE KEY UPDATE `sort_order`=VALUES(`sort_order`);

-- Add uom_id if missing
SET @has_uom_id := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'mess_items'
    AND COLUMN_NAME = 'uom_id'
);

SET @sql := IF(
  @has_uom_id = 0,
  'ALTER TABLE `mess_items` ADD COLUMN `uom_id` CHAR(36) NULL AFTER `category_id`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Backfill from legacy unit string when present
SET @has_unit := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'mess_items'
    AND COLUMN_NAME = 'unit'
);

SET @sql := IF(
  @has_unit > 0,
  'UPDATE mess_items i
     LEFT JOIN mess_uoms u ON u.uom_name = i.unit
     SET i.uom_id = COALESCE(u.id, ''a8000001-0000-4000-8000-000000000002'')
     WHERE i.uom_id IS NULL',
  'UPDATE mess_items SET uom_id = ''a8000001-0000-4000-8000-000000000002'' WHERE uom_id IS NULL'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Ensure NOT NULL
ALTER TABLE `mess_items` MODIFY COLUMN `uom_id` CHAR(36) NOT NULL;

-- Add FK if missing
SET @has_fk := (
  SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'mess_items'
    AND CONSTRAINT_NAME = 'fk_mi_uom'
);

SET @sql := IF(
  @has_fk = 0,
  'ALTER TABLE `mess_items` ADD CONSTRAINT `fk_mi_uom` FOREIGN KEY (`uom_id`) REFERENCES `mess_uoms`(`id`) ON DELETE RESTRICT',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Drop legacy unit column if present
SET @has_unit := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'mess_items'
    AND COLUMN_NAME = 'unit'
);

SET @sql := IF(
  @has_unit > 0,
  'ALTER TABLE `mess_items` DROP COLUMN `unit`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
