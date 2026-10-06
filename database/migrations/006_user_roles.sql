-- ========================================================
-- Migration 006: mess_users role column
-- ========================================================

USE `ecuisine_mess`;

ALTER TABLE `mess_users` 
ADD COLUMN IF NOT EXISTS `role` VARCHAR(20) NOT NULL DEFAULT 'counter' COMMENT 'admin, supervisor, counter' AFTER `display_name`;

UPDATE `mess_users` SET `role` = 'admin' WHERE `username` = 'admin';
