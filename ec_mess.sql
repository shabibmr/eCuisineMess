-- MariaDB dump 10.19  Distrib 10.4.22-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: ecuisine_mess
-- ------------------------------------------------------
-- Server version	10.4.22-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `mess_bill_items`
--

DROP TABLE IF EXISTS `mess_bill_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mess_bill_items` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `bill_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` decimal(10,2) DEFAULT 1.00,
  `unit_price` decimal(10,2) DEFAULT 0.00,
  `total_price` decimal(10,2) DEFAULT 0.00,
  PRIMARY KEY (`id`),
  KEY `fk_mbi_bill` (`bill_id`),
  CONSTRAINT `fk_mbi_bill` FOREIGN KEY (`bill_id`) REFERENCES `mess_bills` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mess_bill_items`
--

LOCK TABLES `mess_bill_items` WRITE;
/*!40000 ALTER TABLE `mess_bill_items` DISABLE KEYS */;
INSERT INTO `mess_bill_items` VALUES ('8607568a-c0a0-11f1-9bef-2811a8e4ac59','a6000001-0000-4000-8000-000000000001','a2000001-0000-4000-8000-000000000001','Steamed Idli (3 pcs)',1.00,0.00,0.00),('86075a74-c0a0-11f1-9bef-2811a8e4ac59','a6000001-0000-4000-8000-000000000001','a2000001-0000-4000-8000-000000000002','Medu Vada (1 pc)',1.00,0.00,0.00),('86075b92-c0a0-11f1-9bef-2811a8e4ac59','a6000001-0000-4000-8000-000000000001','a2000001-0000-4000-8000-000000000003','Coconut Chutney & Sambar',1.00,0.00,0.00),('86075c30-c0a0-11f1-9bef-2811a8e4ac59','a6000001-0000-4000-8000-000000000001','a2000001-0000-4000-8000-000000000004','Filter Coffee / Tea',1.00,0.00,0.00),('86075cc5-c0a0-11f1-9bef-2811a8e4ac59','a6000001-0000-4000-8000-000000000002','a2000001-0000-4000-8000-000000000001','Steamed Idli (3 pcs)',1.00,0.00,0.00),('86075d62-c0a0-11f1-9bef-2811a8e4ac59','a6000001-0000-4000-8000-000000000002','a2000001-0000-4000-8000-000000000004','Filter Coffee / Tea',1.00,0.00,0.00);
/*!40000 ALTER TABLE `mess_bill_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mess_bills`
--

DROP TABLE IF EXISTS `mess_bills`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mess_bills` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `bill_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token_number` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. B-0012, L-0042, D-0015',
  `bill_date` date NOT NULL,
  `bill_time` time NOT NULL,
  `member_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cuisine_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `meal_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'BREAKFAST, LUNCH, DINNER',
  `total_amount` decimal(10,2) DEFAULT 0.00,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'SERVED' COMMENT 'SERVED, CANCELLED',
  `is_override` tinyint(1) DEFAULT 0,
  `override_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `override_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cancelled_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cancel_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cancelled_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `bill_number` (`bill_number`),
  KEY `fk_mb_cuisine` (`cuisine_id`),
  KEY `idx_bill_date_meal` (`bill_date`,`meal_type`),
  KEY `idx_member_date_meal` (`member_id`,`bill_date`,`meal_type`),
  CONSTRAINT `fk_mb_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `mess_cuisines` (`id`),
  CONSTRAINT `fk_mb_member` FOREIGN KEY (`member_id`) REFERENCES `mess_members` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mess_bills`
--

LOCK TABLES `mess_bills` WRITE;
/*!40000 ALTER TABLE `mess_bills` DISABLE KEYS */;
INSERT INTO `mess_bills` VALUES ('a6000001-0000-4000-8000-000000000001','B-20261005-0001','B-0001','2026-10-12','08:15:00','a4000001-0000-4000-8000-000000000001','a3000001-0000-4000-8000-000000000001','BREAKFAST',0.00,'CANCELLED',0,NULL,NULL,'Administrator','Customer cancellation / duplicate','2026-10-12 01:58:35','2026-10-05 09:38:26'),('a6000001-0000-4000-8000-000000000002','B-20261005-0002','B-0002','2026-10-12','08:22:00','a4000001-0000-4000-8000-000000000003','a3000001-0000-4000-8000-000000000002','BREAKFAST',0.00,'CANCELLED',0,NULL,NULL,'Administrator','Customer cancellation / duplicate','2026-10-12 01:58:40','2026-10-05 09:38:26');
/*!40000 ALTER TABLE `mess_bills` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mess_cuisine_items`
--

DROP TABLE IF EXISTS `mess_cuisine_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mess_cuisine_items` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cuisine_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `default_qty` decimal(10,2) DEFAULT 1.00,
  `sort_order` int(11) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cuisine_item` (`cuisine_id`,`item_id`),
  KEY `fk_mci_item` (`item_id`),
  CONSTRAINT `fk_mci_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `mess_cuisines` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mci_item` FOREIGN KEY (`item_id`) REFERENCES `mess_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mess_cuisine_items`
--

LOCK TABLES `mess_cuisine_items` WRITE;
/*!40000 ALTER TABLE `mess_cuisine_items` DISABLE KEYS */;
INSERT INTO `mess_cuisine_items` VALUES ('03bb1727-7bb2-47e7-8b3a-a150bf026253','a3000001-0000-4000-8000-000000000003','a2000001-0000-4000-8000-000000000013',1.00,2),('2eb0e868-6315-43c8-82ce-80da89baae4a','b46395c5-2fc8-45df-90f0-fcdd4e20fefe','8d3ecef3-2e03-4f7a-a04f-8181bc61d82c',1.00,1),('5c528db6-1012-4684-96d0-292dfcf5a8b0','a3000001-0000-4000-8000-000000000003','a2000001-0000-4000-8000-000000000011',1.00,0),('7b378895-da9d-4e2f-bd8d-08e5b34d2b5c','a3000001-0000-4000-8000-000000000003','a2000001-0000-4000-8000-000000000012',1.00,1),('86028707-c0a0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000001','a2000001-0000-4000-8000-000000000001',1.00,1),('86028aa6-c0a0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000001','a2000001-0000-4000-8000-000000000002',1.00,2),('86028be9-c0a0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000001','a2000001-0000-4000-8000-000000000003',1.00,3),('86028cdd-c0a0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000001','a2000001-0000-4000-8000-000000000004',1.00,4),('86028dc8-c0a0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000002','a2000001-0000-4000-8000-000000000008',1.00,1),('86028eb3-c0a0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000002','a2000001-0000-4000-8000-000000000009',1.00,2),('86028f69-c0a0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000002','a2000001-0000-4000-8000-000000000010',1.00,3),('86029270-c0a0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000004','a2000001-0000-4000-8000-000000000014',1.00,1),('8602932d-c0a0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000004','a2000001-0000-4000-8000-000000000015',1.00,2),('860293f9-c0a0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000004','a2000001-0000-4000-8000-000000000016',1.00,3),('860294c6-c0a0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000005','a2000001-0000-4000-8000-000000000017',1.00,1),('86029597-c0a0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000005','a2000001-0000-4000-8000-000000000018',1.00,2),('bc54cc7e-78b4-453d-b2c5-a81097c82b6b','b46395c5-2fc8-45df-90f0-fcdd4e20fefe','dca4d7a0-58b8-4447-b331-4b5f866c8278',1.00,0);
/*!40000 ALTER TABLE `mess_cuisine_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mess_cuisines`
--

DROP TABLE IF EXISTS `mess_cuisines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mess_cuisines` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cuisine_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cuisine_name` (`cuisine_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mess_cuisines`
--

LOCK TABLES `mess_cuisines` WRITE;
/*!40000 ALTER TABLE `mess_cuisines` DISABLE KEYS */;
INSERT INTO `mess_cuisines` VALUES ('a3000001-0000-4000-8000-000000000001','South Indian','Traditional South Indian meals, idlis, dosas & rice',1,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('a3000001-0000-4000-8000-000000000002','North Indian','Curries, tandoor breads, dal and aromatic basmati rice',1,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('a3000001-0000-4000-8000-000000000003','Arabic-2','Authentic Arabic Mandi, grilled meats, toum & fresh salads',1,'2026-10-05 09:38:26','2026-10-08 22:30:43'),('a3000001-0000-4000-8000-000000000004','Continental','Steaks, soups, pasta and grilled vegetable platters',1,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('a3000001-0000-4000-8000-000000000005','Kerala Special','Malabar parottas, coconut curries and seafood dishes',1,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('b46395c5-2fc8-45df-90f0-fcdd4e20fefe','Philipino',NULL,1,'2026-10-11 20:18:22','2026-10-11 20:18:22');
/*!40000 ALTER TABLE `mess_cuisines` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mess_daily_menu_items`
--

DROP TABLE IF EXISTS `mess_daily_menu_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mess_daily_menu_items` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `menu_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` decimal(10,2) DEFAULT 1.00,
  `notes` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_mdmi_menu` (`menu_id`),
  KEY `fk_mdmi_item` (`item_id`),
  CONSTRAINT `fk_mdmi_item` FOREIGN KEY (`item_id`) REFERENCES `mess_items` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_mdmi_menu` FOREIGN KEY (`menu_id`) REFERENCES `mess_daily_menus` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mess_daily_menu_items`
--

LOCK TABLES `mess_daily_menu_items` WRITE;
/*!40000 ALTER TABLE `mess_daily_menu_items` DISABLE KEYS */;
INSERT INTO `mess_daily_menu_items` VALUES ('86059ccf-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000001','a2000001-0000-4000-8000-000000000001',1.00,NULL),('8605a030-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000001','a2000001-0000-4000-8000-000000000002',1.00,NULL),('8605a17d-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000001','a2000001-0000-4000-8000-000000000003',1.00,NULL),('8605a260-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000001','a2000001-0000-4000-8000-000000000004',1.00,NULL),('8605a338-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000002','a2000001-0000-4000-8000-000000000005',1.00,NULL),('8605a414-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000002','a2000001-0000-4000-8000-000000000006',1.00,NULL),('8605a4ca-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000002','a2000001-0000-4000-8000-000000000007',1.00,NULL),('8605a582-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000003','a2000001-0000-4000-8000-000000000001',1.00,NULL),('8605a647-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000003','a2000001-0000-4000-8000-000000000003',1.00,NULL),('8605a70a-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000003','a2000001-0000-4000-8000-000000000004',1.00,NULL),('8605a7da-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000004','a2000001-0000-4000-8000-000000000008',1.00,NULL),('8605a8bd-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000004','a2000001-0000-4000-8000-000000000009',1.00,NULL),('8605a99f-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000004','a2000001-0000-4000-8000-000000000010',1.00,NULL),('8605aa76-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000004','a2000001-0000-4000-8000-000000000007',1.00,NULL),('8605ab4e-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000005','a2000001-0000-4000-8000-000000000011',1.00,NULL),('8605ac3a-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000005','a2000001-0000-4000-8000-000000000012',1.00,NULL),('8605ad30-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000005','a2000001-0000-4000-8000-000000000013',1.00,NULL),('8605ae08-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000006','a2000001-0000-4000-8000-000000000014',1.00,NULL),('8605aeed-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000006','a2000001-0000-4000-8000-000000000015',1.00,NULL),('8605afde-c0a0-11f1-9bef-2811a8e4ac59','a5000001-0000-4000-8000-000000000006','a2000001-0000-4000-8000-000000000016',1.00,NULL);
/*!40000 ALTER TABLE `mess_daily_menu_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mess_daily_menus`
--

DROP TABLE IF EXISTS `mess_daily_menus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mess_daily_menus` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `menu_date` date NOT NULL,
  `cuisine_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `meal_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'BREAKFAST, LUNCH, DINNER',
  `is_locked` tinyint(1) DEFAULT 0,
  `notes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_daily_menu` (`menu_date`,`cuisine_id`,`meal_type`),
  KEY `fk_mdm_cuisine` (`cuisine_id`),
  CONSTRAINT `fk_mdm_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `mess_cuisines` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mess_daily_menus`
--

LOCK TABLES `mess_daily_menus` WRITE;
/*!40000 ALTER TABLE `mess_daily_menus` DISABLE KEYS */;
INSERT INTO `mess_daily_menus` VALUES ('a5000001-0000-4000-8000-000000000001','2026-10-12','a3000001-0000-4000-8000-000000000001','BREAKFAST',0,'Morning South Indian breakfast setup','2026-10-05 09:38:26','2026-10-11 20:05:48'),('a5000001-0000-4000-8000-000000000002','2026-10-12','a3000001-0000-4000-8000-000000000001','LUNCH',0,'South Indian Meals with Biryani option','2026-10-05 09:38:26','2026-10-11 20:05:48'),('a5000001-0000-4000-8000-000000000003','2026-10-12','a3000001-0000-4000-8000-000000000001','DINNER',0,'Light dinner','2026-10-05 09:38:26','2026-10-11 20:05:48'),('a5000001-0000-4000-8000-000000000004','2026-10-12','a3000001-0000-4000-8000-000000000002','LUNCH',0,'North Indian combo with Paneer Butter Masala','2026-10-05 09:38:26','2026-10-11 20:05:48'),('a5000001-0000-4000-8000-000000000005','2026-10-12','a3000001-0000-4000-8000-000000000003','LUNCH',0,'Chicken Mandi Platter','2026-10-05 09:38:26','2026-10-11 20:05:48'),('a5000001-0000-4000-8000-000000000006','2026-10-12','a3000001-0000-4000-8000-000000000004','LUNCH',0,'Continental Herb Roast','2026-10-05 09:38:26','2026-10-11 20:05:48');
/*!40000 ALTER TABLE `mess_daily_menus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mess_item_categories`
--

DROP TABLE IF EXISTS `mess_item_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mess_item_categories` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_category_name` (`category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mess_item_categories`
--

LOCK TABLES `mess_item_categories` WRITE;
/*!40000 ALTER TABLE `mess_item_categories` DISABLE KEYS */;
INSERT INTO `mess_item_categories` VALUES ('2d66a404-97e9-4ef2-9f0b-4be5ba84526c','cat2',6,1,'2026-10-05 09:40:31','2026-10-05 09:40:31'),('a1000001-0000-4000-8000-000000000001','Main2',1,1,'2026-10-05 09:38:26','2026-10-08 22:31:36'),('a1000001-0000-4000-8000-000000000002','Side',2,1,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('a1000001-0000-4000-8000-000000000003','Bread',3,1,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('a1000001-0000-4000-8000-000000000004','Beverage',4,1,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('a1000001-0000-4000-8000-000000000005','Dessert',5,1,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('dfd8dcf5-1aed-43df-b2cf-96e76b86b8d3','ShellVerify-1363-upd',98,1,'2026-10-05 10:55:11','2026-10-05 10:55:11');
/*!40000 ALTER TABLE `mess_item_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mess_items`
--

DROP TABLE IF EXISTS `mess_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mess_items` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `uom_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `fk_mi_category` (`category_id`),
  KEY `fk_mi_uom` (`uom_id`),
  CONSTRAINT `fk_mi_category` FOREIGN KEY (`category_id`) REFERENCES `mess_item_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_mi_uom` FOREIGN KEY (`uom_id`) REFERENCES `mess_uoms` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mess_items`
--

LOCK TABLES `mess_items` WRITE;
/*!40000 ALTER TABLE `mess_items` DISABLE KEYS */;
INSERT INTO `mess_items` VALUES ('8d3ecef3-2e03-4f7a-a04f-8181bc61d82c','monog','a1000001-0000-4000-8000-000000000001','a8000001-0000-4000-8000-000000000002',1,'2026-10-11 20:19:52','2026-10-11 20:19:52'),('a2000001-0000-4000-8000-000000000001','Steamed Idli (3 pcs)','a1000001-0000-4000-8000-000000000001','a8000001-0000-4000-8000-000000000006',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000002','Medu Vada (1 pc)','a1000001-0000-4000-8000-000000000002','a8000001-0000-4000-8000-000000000002',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000003','Coconut Chutney & Sambar','a1000001-0000-4000-8000-000000000002','a8000001-0000-4000-8000-000000000007',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000004','Filter Coffee / Tea','a1000001-0000-4000-8000-000000000004','a8000001-0000-4000-8000-000000000008',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000005','Hyderabadi Chicken Biryani','a1000001-0000-4000-8000-000000000001','a8000001-0000-4000-8000-000000000006',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000006','Mirchi Ka Salan & Raita','a1000001-0000-4000-8000-000000000002','a8000001-0000-4000-8000-000000000007',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000007','Gulab Jamun (2 pcs)','a1000001-0000-4000-8000-000000000005','a8000001-0000-4000-8000-000000000007',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000008','Paneer Butter Masala','a1000001-0000-4000-8000-000000000001','a8000001-0000-4000-8000-000000000007',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000009','Tandoori Roti (2 pcs)','a1000001-0000-4000-8000-000000000003','a8000001-0000-4000-8000-000000000006',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000010','Jeera Rice & Dal Tadka','a1000001-0000-4000-8000-000000000001','a8000001-0000-4000-8000-000000000006',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000011','Arabic Chicken Mandi Rice','a1000001-0000-4000-8000-000000000001','a8000001-0000-4000-8000-000000000006',1,'2026-10-05 09:38:26','2026-10-08 22:31:26'),('a2000001-0000-4000-8000-000000000012','Arabic Garlic Paste (Toum) & Dakkous','a1000001-0000-4000-8000-000000000002','a8000001-0000-4000-8000-000000000007',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000013','Fattoush Salad','a1000001-0000-4000-8000-000000000002','a8000001-0000-4000-8000-000000000007',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000014','Grilled Chicken Breast & Herb Veggies','a1000001-0000-4000-8000-000000000001','a8000001-0000-4000-8000-000000000006',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000015','Cream of Mushroom Soup','a1000001-0000-4000-8000-000000000002','a8000001-0000-4000-8000-000000000007',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000016','Garlic Bread (2 pcs)','a1000001-0000-4000-8000-000000000003','a8000001-0000-4000-8000-000000000006',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000017','Kerala Parotta (2 pcs)','a1000001-0000-4000-8000-000000000003','a8000001-0000-4000-8000-000000000006',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('a2000001-0000-4000-8000-000000000018','Chicken Pepper Roast','a1000001-0000-4000-8000-000000000001','a8000001-0000-4000-8000-000000000006',1,'2026-10-05 09:38:26','2026-10-05 11:22:07'),('dca4d7a0-58b8-4447-b331-4b5f866c8278','Andherm','a1000001-0000-4000-8000-000000000002','a8000001-0000-4000-8000-000000000006',1,'2026-10-11 20:18:45','2026-10-11 20:18:45');
/*!40000 ALTER TABLE `mess_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mess_meal_times`
--

DROP TABLE IF EXISTS `mess_meal_times`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mess_meal_times` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cuisine_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `meal_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'BREAKFAST, LUNCH, DINNER',
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_cuisine_meal` (`cuisine_id`,`meal_type`),
  CONSTRAINT `fk_mmt_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `mess_cuisines` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mess_meal_times`
--

LOCK TABLES `mess_meal_times` WRITE;
/*!40000 ALTER TABLE `mess_meal_times` DISABLE KEYS */;
INSERT INTO `mess_meal_times` VALUES ('7e145308-6834-4930-aee9-66191594ad5e','b46395c5-2fc8-45df-90f0-fcdd4e20fefe','BREAKFAST','Breakfast','07:00:00','10:00:00',1,'2026-10-11 20:18:22'),('a28be00e-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000003','BREAKFAST','Breakfast','07:00:00','11:30:00',1,'2026-10-05 11:33:46'),('a28be2c9-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000003','LUNCH','Lunch','12:00:00','15:00:00',1,'2026-10-05 11:33:46'),('a28be3a2-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000003','DINNER','Dinner','00:00:00','02:00:00',1,'2026-10-05 11:33:46'),('a28be4d8-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000004','BREAKFAST','Breakfast','07:00:00','10:00:00',1,'2026-10-05 11:33:46'),('a28be599-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000004','LUNCH','Lunch','12:00:00','15:00:00',1,'2026-10-05 11:33:46'),('a28be636-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000004','DINNER','Dinner','19:00:00','22:00:00',1,'2026-10-05 11:33:46'),('a28be74f-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000005','BREAKFAST','Breakfast','07:00:00','10:00:00',1,'2026-10-05 11:33:46'),('a28be83d-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000005','LUNCH','Lunch','12:00:00','15:00:00',1,'2026-10-05 11:33:46'),('a28be8e0-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000005','DINNER','Dinner','19:00:00','22:00:00',1,'2026-10-05 11:33:46'),('a28be9f8-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000002','BREAKFAST','Breakfast','07:00:00','10:00:00',1,'2026-10-05 11:33:46'),('a28beb02-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000002','LUNCH','Lunch','12:00:00','15:00:00',1,'2026-10-05 11:33:46'),('a28bebc7-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000002','DINNER','Dinner','19:00:00','22:00:00',1,'2026-10-05 11:33:46'),('a28bed8c-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000001','BREAKFAST','Breakfast','07:00:00','10:00:00',1,'2026-10-05 11:33:46'),('a28beecf-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000001','LUNCH','Lunch','12:00:00','15:00:00',1,'2026-10-05 11:33:46'),('a28bef9b-c0b0-11f1-9bef-2811a8e4ac59','a3000001-0000-4000-8000-000000000001','DINNER','Dinner','19:00:00','22:00:00',1,'2026-10-05 11:33:46'),('c5558fe9-0ba8-4170-b782-e39c2b987dde','b46395c5-2fc8-45df-90f0-fcdd4e20fefe','DINNER','Dinner','19:00:00','22:00:00',1,'2026-10-11 20:18:22'),('f360684a-5a62-4687-9982-5dabb2fdeef9','b46395c5-2fc8-45df-90f0-fcdd4e20fefe','LUNCH','Lunch','12:00:00','15:00:00',1,'2026-10-11 20:18:22');
/*!40000 ALTER TABLE `mess_meal_times` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mess_members`
--

DROP TABLE IF EXISTS `mess_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mess_members` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `rfid_tag` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cuisine_id` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `validity_start` date NOT NULL,
  `validity_end` date NOT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'ACTIVE' COMMENT 'ACTIVE, EXPIRED, SUSPENDED',
  `photo_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `rfid_tag` (`rfid_tag`),
  KEY `fk_mm_cuisine` (`cuisine_id`),
  KEY `idx_rfid` (`rfid_tag`),
  CONSTRAINT `fk_mm_cuisine` FOREIGN KEY (`cuisine_id`) REFERENCES `mess_cuisines` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mess_members`
--

LOCK TABLES `mess_members` WRITE;
/*!40000 ALTER TABLE `mess_members` DISABLE KEYS */;
INSERT INTO `mess_members` VALUES ('01c0778a-e2c2-47b3-8934-4c90a785b887','Counter Test Member','TAP-65694ed4','+971501112233',NULL,'a3000001-0000-4000-8000-000000000003','2026-10-01','2026-10-26','ACTIVE',NULL,'2026-10-06 15:40:24','2026-10-06 15:40:24'),('0d201231-2991-411d-b25c-d5c75e5bb001','Counter Test Member','TAP-2930b956','+971501112233',NULL,'a3000001-0000-4000-8000-000000000003','2026-10-07','2026-11-01','ACTIVE',NULL,'2026-10-11 20:05:07','2026-10-11 20:05:07'),('2ac4e4be-03e1-4ced-bed7-8e6aa9d179f5','Counter Test Member','TAP-9ae484bd','+971501112233',NULL,'a3000001-0000-4000-8000-000000000003','2026-10-07','2026-11-01','ACTIVE',NULL,'2026-10-11 20:04:11','2026-10-11 20:04:11'),('63e49bb1-b83b-441e-b1f2-4e2d1f366ce4','Cancel Test Member','CANCELTEST-817e6204',NULL,NULL,'a3000001-0000-4000-8000-000000000001','2026-10-04','2026-10-29','ACTIVE',NULL,'2026-10-08 23:38:31','2026-10-08 23:38:31'),('640a7163-c3a8-4c46-8032-9f5e3811f37b','Counter Test Member','TAP-3f3b1d71','+971501112233',NULL,'a3000001-0000-4000-8000-000000000003','2026-10-03','2026-10-28','ACTIVE',NULL,'2026-10-07 22:00:24','2026-10-07 22:00:24'),('6a1a8a52-a1c3-4523-917e-1730d26b7cbb','Cancel Test Member','CANCELTEST-7a4c5dde',NULL,NULL,'a3000001-0000-4000-8000-000000000001','2026-10-07','2026-11-01','ACTIVE',NULL,'2026-10-11 20:05:10','2026-10-11 20:05:10'),('74e6c1e9-a3e2-4bea-b146-a3876f0b6680','Cancel Test Member','CANCELTEST-27398184',NULL,NULL,'a3000001-0000-4000-8000-000000000001','2026-10-01','2026-10-26','ACTIVE',NULL,'2026-10-06 15:14:30','2026-10-06 15:14:30'),('7c1298d5-74db-4ddc-abe3-bb6d5c114e35','Counter Test Member','TAP-0caa8ed9','+971501112233',NULL,'a3000001-0000-4000-8000-000000000003','2026-10-01','2026-10-26','ACTIVE',NULL,'2026-10-06 15:14:27','2026-10-06 15:14:27'),('83ebe26d-8d7d-42ae-b37d-8b634a8b9b68','Counter Test Member','TAP-887a9e78','+971501112233',NULL,'a3000001-0000-4000-8000-000000000003','2026-10-01','2026-10-26','ACTIVE',NULL,'2026-10-06 15:40:36','2026-10-06 15:40:36'),('89d4cdba-1da1-4dec-9c63-b8cb21d019c0','Cancel Test Member','CANCELTEST-e0db22db',NULL,NULL,'a3000001-0000-4000-8000-000000000001','2026-10-07','2026-11-01','ACTIVE',NULL,'2026-10-11 20:04:13','2026-10-11 20:04:13'),('8bf4d20b-1f92-4d2d-abc1-bbae7fd8ad66','Counter Test Member','TAP-65875048','+971501112233',NULL,'a3000001-0000-4000-8000-000000000003','2026-09-30','2026-10-25','ACTIVE',NULL,'2026-10-05 12:02:16','2026-10-05 12:02:16'),('8c2b412c-2327-47b0-9298-aa77041fd433','Cancel Test Member','CANCELTEST-9aaeeb38',NULL,NULL,'a3000001-0000-4000-8000-000000000001','2026-10-01','2026-10-26','ACTIVE',NULL,'2026-10-06 15:40:38','2026-10-06 15:40:38'),('a4000001-0000-4000-8000-000000000001','Ravi Kumar','E280116060000204','+971-50-1234567','ravi.k@example.com','a3000001-0000-4000-8000-000000000001','2026-01-01','2026-12-31','ACTIVE',NULL,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('a4000001-0000-4000-8000-000000000002','Fatima Al Zarooni','E280116060000205','+971-50-2345678','fatima.z@example.com','a3000001-0000-4000-8000-000000000003','2026-01-01','2026-12-31','ACTIVE',NULL,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('a4000001-0000-4000-8000-000000000003','Priya Sharma','E280116060000206','+971-50-3456789','priya.s@example.com','a3000001-0000-4000-8000-000000000002','2026-01-01','2026-12-31','ACTIVE',NULL,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('a4000001-0000-4000-8000-000000000004','John Mitchell','E280116060000207','+971-50-4567890','john.m@example.com','a3000001-0000-4000-8000-000000000004','2026-01-01','2026-12-31','ACTIVE',NULL,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('a4000001-0000-4000-8000-000000000005','Ananya Nair','123456','+971-50-5678901','ananya.n@example.com','a3000001-0000-4000-8000-000000000005','2026-01-01','2026-12-31','ACTIVE',NULL,'2026-10-05 09:38:26','2026-10-11 20:26:25'),('a4000001-0000-4000-8000-000000000006','Ahmed Hassan (Expired)','E280116060000209','+971-50-6789012','ahmed.h@example.com','a3000001-0000-4000-8000-000000000003','2025-01-01','2025-12-31','ACTIVE',NULL,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('a4000001-0000-4000-8000-000000000007','Suresh Menon','E280116060000210','+971-50-7890123','suresh.m@example.com','a3000001-0000-4000-8000-000000000001','2026-01-01','2026-12-31','ACTIVE',NULL,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('a4000001-0000-4000-8000-000000000008','Tariq Mansoor (Suspended)','E280116060000211','+971-50-8901234','tariq.m@example.com','a3000001-0000-4000-8000-000000000003','2026-01-01','2026-12-31','SUSPENDED',NULL,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('a4000001-0000-4000-8000-000000000009','Pooja Verma','E280116060000212','+971-50-9012345','pooja.v@example.com','a3000001-0000-4000-8000-000000000002','2026-01-01','2026-12-31','ACTIVE',NULL,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('a4000001-0000-4000-8000-000000000010','Alexandre Dubois','E280116060000213','+971-50-0123456','alex.d@example.com','a3000001-0000-4000-8000-000000000004','2026-01-01','2026-12-31','ACTIVE',NULL,'2026-10-05 09:38:26','2026-10-05 09:38:26'),('c7e99bdd-a327-43a6-83aa-246c4002be5b','Counter Test Member','TAP-36218c01','+971501112233',NULL,'a3000001-0000-4000-8000-000000000003','2026-09-30','2026-10-25','ACTIVE',NULL,'2026-10-05 12:01:34','2026-10-05 12:01:34'),('d68b4828-f392-4e10-a5ed-18b95c74a0a3','Cancel Test Member','CANCELTEST-0e05a44f',NULL,NULL,'a3000001-0000-4000-8000-000000000001','2026-10-01','2026-10-26','ACTIVE',NULL,'2026-10-06 15:40:26','2026-10-06 15:40:26'),('d80c32bb-df84-4573-a7b5-2e5788a26ac9','Cancel Test Member','CANCELTEST-16058f87',NULL,NULL,'a3000001-0000-4000-8000-000000000001','2026-10-03','2026-10-28','ACTIVE',NULL,'2026-10-07 22:00:26','2026-10-07 22:00:26'),('dc11f5d9-a27a-4a72-a1dc-039bd3ac5ecf','Counter Test Member','TAP-e50b5e54','+971501112233',NULL,'a3000001-0000-4000-8000-000000000003','2026-10-01','2026-10-26','ACTIVE',NULL,'2026-10-06 15:40:33','2026-10-06 15:40:33'),('f05c4998-5bd5-4491-b542-d64754c97433','Counter Test Member','TAP-53a45be1','+971501112233',NULL,'a3000001-0000-4000-8000-000000000003','2026-10-04','2026-10-29','ACTIVE',NULL,'2026-10-08 23:38:22','2026-10-08 23:38:22');
/*!40000 ALTER TABLE `mess_members` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mess_organizations`
--

DROP TABLE IF EXISTS `mess_organizations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mess_organizations` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `org_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `trn` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_to_print` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address_to_print_arabic` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `currency` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'AED',
  `phone` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_person` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `website` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_org_name` (`org_name`),
  KEY `idx_org_trn` (`trn`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mess_organizations`
--

LOCK TABLES `mess_organizations` WRITE;
/*!40000 ALTER TABLE `mess_organizations` DISABLE KEYS */;
INSERT INTO `mess_organizations` VALUES ('e0000001-0000-4000-8000-000000000001','DIT UAE','100200300400003','Dubai Investment Park, Dubai, UAE','DIT UAE CATERING & SERVICES LLC
Dubai Investment Park 1, P.O. Box 12345, Dubai, UAE','دي آي تي لخدمات التموين ذ.م.م
مجمع دبي للاستثمار 1، ص.ب 12345، دبي، الإمارات','AED','+971 4 123 4567','catering@dituae.com','Mess Supervisor',NULL,NULL,1,'2026-10-05 09:38:26','2026-10-05 09:38:26');
/*!40000 ALTER TABLE `mess_organizations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mess_uoms`
--

DROP TABLE IF EXISTS `mess_uoms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mess_uoms` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `uom_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uom_name` (`uom_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mess_uoms`
--

LOCK TABLES `mess_uoms` WRITE;
/*!40000 ALTER TABLE `mess_uoms` DISABLE KEYS */;
INSERT INTO `mess_uoms` VALUES ('a8000001-0000-4000-8000-000000000001','Piece',1,1,'2026-10-05 11:22:07'),('a8000001-0000-4000-8000-000000000002','Nos',2,1,'2026-10-05 11:22:07'),('a8000001-0000-4000-8000-000000000003','Grams',3,1,'2026-10-05 11:22:07'),('a8000001-0000-4000-8000-000000000004','Litres',4,1,'2026-10-05 11:22:07'),('a8000001-0000-4000-8000-000000000005','MilliLitres',5,1,'2026-10-05 11:22:07'),('a8000001-0000-4000-8000-000000000006','Plate',6,1,'2026-10-05 11:22:07'),('a8000001-0000-4000-8000-000000000007','Bowl',7,1,'2026-10-05 11:22:07'),('a8000001-0000-4000-8000-000000000008','Cup',8,1,'2026-10-05 11:22:07'),('a8000001-0000-4000-8000-000000000009','Glass',9,1,'2026-10-05 11:22:07');
/*!40000 ALTER TABLE `mess_uoms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mess_user_sessions`
--

DROP TABLE IF EXISTS `mess_user_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mess_user_sessions` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `token` (`token`),
  KEY `fk_mus_user` (`user_id`),
  KEY `idx_session_token` (`token`),
  KEY `idx_session_expires` (`expires_at`),
  CONSTRAINT `fk_mus_user` FOREIGN KEY (`user_id`) REFERENCES `mess_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mess_user_sessions`
--

LOCK TABLES `mess_user_sessions` WRITE;
/*!40000 ALTER TABLE `mess_user_sessions` DISABLE KEYS */;
INSERT INTO `mess_user_sessions` VALUES ('0b4d193c-a3d9-4372-a854-d862a74632f1','a7000001-0000-4000-8000-000000000001','c081837348835b1e89c36301bbb38c78cf8c2388d06a9eecea51bf092535ccaf','2026-10-12 18:17:31','2026-10-05 12:47:31'),('1852abef-61f5-40d6-82e1-5fb44aacd2e1','a7000001-0000-4000-8000-000000000001','d840c3dc98ba82159bbe6f0d876b0c8a0826754ed6a12cb7dfcaba3633f5f023','2026-10-15 03:30:23','2026-10-07 22:00:23'),('238456f0-ed8c-415b-b716-0a5744c30006','a7000001-0000-4000-8000-000000000001','ec605406b0c16aac1df90d6dbb7b1e796ef476dcf4827493f247906cf1061310','2026-10-12 17:06:17','2026-10-05 11:36:17'),('25fb5c3c-13c0-4240-a0a5-607e94ba5760','a7000001-0000-4000-8000-000000000001','edeefbecc0891b28c9fb185674d569c33c7892c914113c28803d52c4f4d0687e','2026-10-19 01:35:58','2026-10-11 20:05:58'),('28c34f61-e036-4090-933e-33d7facae716','a7000001-0000-4000-8000-000000000001','132d8adbcd204f1ff54d16b53e6e7305d73fd93dca0e7042d34dbf548e0994cc','2026-10-12 17:09:03','2026-10-05 11:39:03'),('30e27957-788c-4818-a9d6-2e7051c7ced5','a7000001-0000-4000-8000-000000000001','5c42496ea2e60b0c96d47a7f82e6cdd6550fa79fba00e9477bda31399dc3d288','2026-10-12 18:25:30','2026-10-05 12:55:30'),('41c64fcd-c748-4d5a-a0c0-c8f8395b28c5','a7000001-0000-4000-8000-000000000001','f1e44c9cd32a13a6e39bde8797192c65a40b52e5b6174e168141afc35f9ee7b1','2026-10-12 17:47:34','2026-10-05 12:17:34'),('4cc21932-093f-418f-b0f3-06522099d08d','a7000001-0000-4000-8000-000000000001','55bd0c62b0ab6699ad00d885b55e3f5fee4c15cf3571c779c12bf74ced9f2662','2026-10-12 17:20:43','2026-10-05 11:50:43'),('5122e349-7163-4745-bd18-88d86ecc2d5d','a7000001-0000-4000-8000-000000000001','a3ffd1673175bb89b07d4abee08d1aa37c10af8f8b0f2349a24f08ecaa808ab5','2026-10-12 18:18:25','2026-10-05 12:48:25'),('54410b04-ec7c-4c8e-a5e8-db0135e32a1d','a7000001-0000-4000-8000-000000000001','93173b737bc0dcc6087b425d02e3d4df08b3ac92681ce59daad868dacd36ba35','2026-10-12 18:15:28','2026-10-05 12:45:28'),('5a5071c0-4a31-46e0-86f9-2b9c8bcae3ce','a7000001-0000-4000-8000-000000000001','b83fc3fa895b9ade37c9faf277b3a591319bd53e2e203b912c2aa75522cfd793','2026-10-12 17:48:18','2026-10-05 12:18:18'),('6bb100a3-9fd2-4613-b345-bf5cb7bd2397','a7000001-0000-4000-8000-000000000001','17b552c702567e1ab039d0b3607063c723dc5a75499a37602f59b7b1986ff673','2026-10-12 16:47:51','2026-10-05 11:17:51'),('6c754a17-55da-44d0-8528-f44362caf262','a7000001-0000-4000-8000-000000000001','2010fa824e65907077fb3554616f9ebd0935fe9b1ebf4f12847951dc078a3378','2026-10-12 17:32:34','2026-10-05 12:02:34'),('6e86aeea-d0e3-49e9-b40b-94d2e81c93cd','a7000001-0000-4000-8000-000000000001','24fd7e0b63ff429f22c30d6067960cc93673bcafec15e03fde4d6dcc6bd9a97e','2026-10-12 16:48:18','2026-10-05 11:18:18'),('6fbb97e4-b014-4d6d-a69f-34a60d714ab5','a7000001-0000-4000-8000-000000000001','377bd26399f197f1d5a84cf9d6399c9f6bbfcbfef3787880c210c44c2ee344a8','2026-10-13 21:10:24','2026-10-06 15:40:24'),('70b9b500-5bbe-4a3e-afa2-b2d986dbb90a','a7000001-0000-4000-8000-000000000001','2d1b97e96571c88e00ed695850ca244c7d6d91800997ca808ef9249b25dfab59','2026-10-12 17:28:28','2026-10-05 11:58:28'),('7abf3a95-5689-4672-bb41-4ff2fc550c85','a7000001-0000-4000-8000-000000000001','4690a470889f1bafc1de74f27350ad583998c61dab3ef832b90c081fb998d4a4','2026-10-12 17:34:45','2026-10-05 12:04:45'),('7c241e20-c53a-4c13-8ee6-6aa68893a521','a7000001-0000-4000-8000-000000000001','1d4421bfd82a3680d2f413a0ffd890e4f4ae75c837c95bc41a6ee40e010085e0','2026-10-15 03:32:34','2026-10-07 22:02:34'),('7d17388d-b8de-4acb-b555-1d06ab5d9c81','a7000001-0000-4000-8000-000000000001','2e34a247b0d098dd96641f80755d7282b1ed5b7a63d85323093d105fde55cfbc','2026-10-19 01:34:10','2026-10-11 20:04:10'),('8363918e-29e0-4ca6-8804-02acb2255e2c','a7000001-0000-4000-8000-000000000001','1fdddf95a941a9bc6c81084f0d2f443b01c088d62c8d908623aa54c1cb8e9c54','2026-10-16 05:08:19','2026-10-08 23:38:19'),('86de52c0-2b8f-4dd0-83dc-0a86a3b0ab3e','a7000001-0000-4000-8000-000000000001','1d4c3e75fd3c94ceb8da6387a480948986aafcb2a2adb4636ac38712b754f6cf','2026-10-12 16:25:10','2026-10-05 10:55:11'),('87fec10c-98f9-4ff5-ad0c-7723280a59fb','a7000001-0000-4000-8000-000000000001','31f7500ed819c6abf9b18f80e6817a05bfe9da394c84f540ee6a3facf2e1960c','2026-10-12 17:29:31','2026-10-05 11:59:31'),('8901c3bf-ce7e-4c7a-af01-83a019fd6a3b','a7000001-0000-4000-8000-000000000001','7819e114fad401f528b5581d0c17e3ebe36d29bfb8815f2b1791980905afd385','2026-10-15 03:33:38','2026-10-07 22:03:38'),('89eecf38-51dd-4c9e-b627-7077e4a1bca4','a7000001-0000-4000-8000-000000000001','948f156cea4a3ebceff7e11639eeee4759579ae7ec8ad4e633da1da257d16cb3','2026-10-13 21:10:32','2026-10-06 15:40:32'),('8a1ee169-4e4f-40bc-86d6-7406642e83a6','a7000001-0000-4000-8000-000000000001','6c4ce9948acaca4840d1fced8f7f7779e11cbf20f04dcb67e35b0c1cbf205288','2026-10-12 18:14:28','2026-10-05 12:44:28'),('8ccbb621-9c4e-47f5-8a90-f284757d32f5','a7000001-0000-4000-8000-000000000001','05b07d5be0a8ab43456333908aff6169029c57cba65c04c3adaea1096fb5e6e5','2026-10-12 17:45:22','2026-10-05 12:15:22'),('94d82974-3b73-47ce-9a7a-cb00fb84507f','a7000001-0000-4000-8000-000000000001','d2d7e802c906f5dfea0895961afcf7116c8c878912aecf8fb4f29ce59c01c860','2026-10-12 18:10:40','2026-10-05 12:40:40'),('a03a449d-8d9e-4722-b2cc-74c835746a96','a7000001-0000-4000-8000-000000000001','0720962b9dc8d83fe5f9e5db016cfe8221c7a0e8c0a3250acaa8aee7de97ff24','2026-10-12 18:17:54','2026-10-05 12:47:54'),('ba06ec27-1f57-408b-b074-3317e8e8e022','a7000001-0000-4000-8000-000000000001','6f17d8cb505252b05900f026eeed20274404da0abd7748474487d608a9eca30e','2026-10-12 17:32:16','2026-10-05 12:02:16'),('c002422b-5bc9-4cd1-bc68-bfba584f1dd5','a7000001-0000-4000-8000-000000000001','559d2f8b38a5e8f79d9d6b5cd1c3245d713c6b9241e2d005f37703c216b89931','2026-10-12 17:46:43','2026-10-05 12:16:43'),('c146c5a5-0b37-4f27-9544-f2640c1804c1','a7000001-0000-4000-8000-000000000001','6103931faebde71fde48ad14337209cfe021161985c785b12c2f49dcbf78bc8b','2026-10-12 18:19:19','2026-10-05 12:49:19'),('c1b3d96a-5fc8-451b-96d0-93204ce22096','a7000001-0000-4000-8000-000000000001','fb985dd54a79e6318ad831f8ed445d76a101c90752a1d082618bf016d6de63e9','2026-10-12 15:10:21','2026-10-05 09:40:21'),('c26e6dd6-fd90-4c55-9f8f-e9b8f790bdc6','a7000001-0000-4000-8000-000000000001','cf7f13036537c9f5913e3b232d892620b1a4625930cf9d3613ace663ce9e0eb1','2026-10-19 18:36:51','2026-10-12 13:06:51'),('c5caf2b5-777a-4ec9-84eb-9b57c1e199e9','a7000001-0000-4000-8000-000000000001','f7111864a5ffb32ed751c10e8e40afb6adcb8cfebaa50e7febdb111b97e12f01','2026-10-12 17:36:00','2026-10-05 12:06:00'),('c6ccdba2-fad5-4905-a325-c7af70cfe7fd','a7000001-0000-4000-8000-000000000001','4ea054484d8664b37ac9e443bb5e0a1ae9ffe1be287c784f36cf2b8cc6c4cc2f','2026-10-13 21:10:36','2026-10-06 15:40:36'),('cc8aa431-1b52-4c89-9b3f-ed1458487115','a7000001-0000-4000-8000-000000000001','3c5e4082524047c58efb94c7b949d17702a3250062d6532915124ad785e99332','2026-10-12 17:31:34','2026-10-05 12:01:34'),('cf3724a1-5db7-4d06-94aa-d6596f51a939','a7000001-0000-4000-8000-000000000001','01e6f97f2bda6b72da8f9fa2089b7d3a33e2042656c80bea68722bebd52b9a63','2026-10-19 02:07:29','2026-10-11 20:37:29'),('dd0275db-6a57-4ec2-ae0d-cf431c3ac95c','a7000001-0000-4000-8000-000000000001','6ce6a64220ebebf601ad3f53cfb189342282b40f970c8df7498757a25422ba61','2026-10-13 20:44:27','2026-10-06 15:14:27'),('dd31c671-985b-4ca7-9fda-cf0a845a3303','a7000001-0000-4000-8000-000000000001','e859c64917e2cf252c54875d808fb7104fd62672e9da14d0c7782e4aa5012d18','2026-10-12 17:34:15','2026-10-05 12:04:15'),('ebd9b335-be2b-465d-ade8-864b59aedba6','a7000001-0000-4000-8000-000000000001','880734eafd97db1184550dbdd41157ceb74f3cde24367a30fe64aeff2df23318','2026-10-12 17:22:02','2026-10-05 11:52:02'),('f2cee592-a7e2-47bb-88a9-8a758bed2ba6','a7000001-0000-4000-8000-000000000001','923268e364e09e8193e48089305fb560ea6c42886e517d8b1890210a723df8f7','2026-10-19 01:35:07','2026-10-11 20:05:07');
/*!40000 ALTER TABLE `mess_user_sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mess_users`
--

DROP TABLE IF EXISTS `mess_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `mess_users` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `display_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'counter',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mess_users`
--

LOCK TABLES `mess_users` WRITE;
/*!40000 ALTER TABLE `mess_users` DISABLE KEYS */;
INSERT INTO `mess_users` VALUES ('a7000001-0000-4000-8000-000000000001','admin','$2b$12$EFGKCcXkjHNvfOpJUK8gLeODDxpDmaFevnavQS6H3/i18CKGPodYK','Administrator','admin',1,'2026-10-05 09:38:26','2026-10-05 11:56:39');
/*!40000 ALTER TABLE `mess_users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-14  0:48:00
