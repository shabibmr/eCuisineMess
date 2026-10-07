-- ========================================================
-- Migration 007: mess_organizations
-- ========================================================

USE `ecuisine_mess`;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Default sample organization
INSERT INTO `mess_organizations` (`id`, `org_name`, `trn`, `address`, `address_to_print`, `address_to_print_arabic`, `currency`, `phone`, `email`, `contact_person`, `is_active`)
VALUES (
    'e0000000-0000-0000-0000-000000000001',
    'DIT UAE',
    '100200300400003',
    'Dubai Investment Park, Dubai, UAE',
    'DIT UAE CATERING & SERVICES LLC\nDubai Investment Park 1, P.O. Box 12345, Dubai, UAE',
    'دي آي تي لخدمات التموين ذ.م.م\nمجمع دبي للاستثمار 1، ص.ب 12345، دبي، الإمارات',
    'AED',
    '+971 4 123 4567',
    'catering@dituae.com',
    'Mess Supervisor',
    1
)
ON DUPLICATE KEY UPDATE `org_name` = VALUES(`org_name`);
