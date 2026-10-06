-- ========================================================
-- Migration 005: meal time windows become PER CUISINE
--   mess_meal_times gains cuisine_id (NOT NULL, FK -> mess_cuisines, CASCADE)
--   UNIQUE (cuisine_id, meal_type) replaces UNIQUE (meal_type)
--   Defaults per cuisine: Breakfast 07:00-10:00, Lunch 12:00-15:00, Dinner 19:00-22:00
-- Safe to re-run. Existing global rows are replaced by per-cuisine rows.
-- ========================================================

USE `ecuisine_mess`;

-- 1. Add cuisine_id (nullable while backfilling)
SET @has_col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mess_meal_times' AND COLUMN_NAME = 'cuisine_id'
);
SET @sql := IF(@has_col = 0,
  'ALTER TABLE `mess_meal_times` ADD COLUMN `cuisine_id` CHAR(36) NULL AFTER `id`',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2. Drop the old global UNIQUE (meal_type) -- the auto-named index on meal_type
SET @old_idx := (
  SELECT INDEX_NAME FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mess_meal_times'
    AND COLUMN_NAME = 'meal_type' AND NON_UNIQUE = 0
    AND INDEX_NAME <> 'uk_cuisine_meal'
    AND (SELECT COUNT(*) FROM information_schema.STATISTICS s2
         WHERE s2.TABLE_SCHEMA = DATABASE() AND s2.TABLE_NAME = 'mess_meal_times'
           AND s2.INDEX_NAME = STATISTICS.INDEX_NAME) = 1
  LIMIT 1
);
SET @sql := IF(@old_idx IS NOT NULL,
  CONCAT('ALTER TABLE `mess_meal_times` DROP INDEX `', @old_idx, '`'),
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3. Remove legacy global rows (no cuisine) and create 3 windows per cuisine
DELETE FROM `mess_meal_times` WHERE `cuisine_id` IS NULL;

INSERT INTO `mess_meal_times` (`id`, `cuisine_id`, `meal_type`, `name`, `start_time`, `end_time`, `is_active`)
SELECT UUID(), c.`id`, m.`meal_type`, m.`name`, m.`start_time`, m.`end_time`, 1
FROM `mess_cuisines` c
JOIN (
    SELECT 'BREAKFAST' AS meal_type, 'Breakfast' AS name, '07:00:00' AS start_time, '10:00:00' AS end_time
    UNION ALL SELECT 'LUNCH',  'Lunch',  '12:00:00', '15:00:00'
    UNION ALL SELECT 'DINNER', 'Dinner', '19:00:00', '22:00:00'
) m
WHERE NOT EXISTS (
    SELECT 1 FROM `mess_meal_times` t WHERE t.`cuisine_id` = c.`id` AND t.`meal_type` = m.`meal_type`
);

-- 4. Constrain
ALTER TABLE `mess_meal_times` MODIFY COLUMN `cuisine_id` CHAR(36) NOT NULL;

SET @has_fk := (
  SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mess_meal_times' AND CONSTRAINT_NAME = 'fk_mmt_cuisine'
);
SET @sql := IF(@has_fk = 0,
  'ALTER TABLE `mess_meal_times` ADD CONSTRAINT `fk_mmt_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `mess_cuisines`(`id`) ON DELETE CASCADE',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_uk := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'mess_meal_times' AND INDEX_NAME = 'uk_cuisine_meal'
);
SET @sql := IF(@has_uk = 0,
  'ALTER TABLE `mess_meal_times` ADD UNIQUE KEY `uk_cuisine_meal` (`cuisine_id`, `meal_type`)',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
