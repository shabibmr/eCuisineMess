-- ========================================================
-- eCuisine Mess Module Seed Data (UUID ids, no *_code)
-- ========================================================

USE `ecuisine_mess`;

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

-- 1. Item Categories
INSERT INTO `mess_item_categories` (`id`, `category_name`, `sort_order`, `is_active`) VALUES
(@cat_main, 'Main', 1, 1),
(@cat_side, 'Side', 2, 1),
(@cat_bread, 'Bread', 3, 1),
(@cat_bev, 'Beverage', 4, 1),
(@cat_dessert, 'Dessert', 5, 1)
ON DUPLICATE KEY UPDATE `sort_order`=VALUES(`sort_order`);

-- 3. Units of Measure
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

-- 4. Items
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

-- 4b. Meal Times per cuisine (Breakfast 07:00-10:00, Lunch 12:00-15:00, Dinner 19:00-22:00)
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

-- 5. Cuisine Items Mapping
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

-- 6. Members
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

-- 7. Daily Menus for Today
INSERT INTO `mess_daily_menus` (`id`, `menu_date`, `cuisine_id`, `meal_type`, `is_locked`, `notes`) VALUES
(@menu_1, CURDATE(), @cui_si, 'BREAKFAST', 0, 'Morning South Indian breakfast setup'),
(@menu_2, CURDATE(), @cui_si, 'LUNCH', 0, 'South Indian Meals with Biryani option'),
(@menu_3, CURDATE(), @cui_si, 'DINNER', 0, 'Light dinner'),
(@menu_4, CURDATE(), @cui_ni, 'LUNCH', 0, 'North Indian combo with Paneer Butter Masala'),
(@menu_5, CURDATE(), @cui_ar, 'LUNCH', 0, 'Chicken Mandi Platter'),
(@menu_6, CURDATE(), @cui_co, 'LUNCH', 0, 'Continental Herb Roast')
ON DUPLICATE KEY UPDATE `notes`=VALUES(`notes`);

-- 8. Daily Menu Items
INSERT INTO `mess_daily_menu_items` (`id`, `menu_id`, `item_id`, `quantity`) VALUES
(UUID(), @menu_1, @itm_01, 1.00), (UUID(), @menu_1, @itm_02, 1.00), (UUID(), @menu_1, @itm_03, 1.00), (UUID(), @menu_1, @itm_04, 1.00),
(UUID(), @menu_2, @itm_05, 1.00), (UUID(), @menu_2, @itm_06, 1.00), (UUID(), @menu_2, @itm_07, 1.00),
(UUID(), @menu_3, @itm_01, 1.00), (UUID(), @menu_3, @itm_03, 1.00), (UUID(), @menu_3, @itm_04, 1.00),
(UUID(), @menu_4, @itm_08, 1.00), (UUID(), @menu_4, @itm_09, 1.00), (UUID(), @menu_4, @itm_10, 1.00), (UUID(), @menu_4, @itm_07, 1.00),
(UUID(), @menu_5, @itm_11, 1.00), (UUID(), @menu_5, @itm_12, 1.00), (UUID(), @menu_5, @itm_13, 1.00),
(UUID(), @menu_6, @itm_14, 1.00), (UUID(), @menu_6, @itm_15, 1.00), (UUID(), @menu_6, @itm_16, 1.00)
ON DUPLICATE KEY UPDATE `quantity`=VALUES(`quantity`);

-- 9. Sample bills
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

-- 10. App user (password: admin123)
INSERT INTO `mess_users` (`id`, `username`, `password_hash`, `display_name`, `role`, `is_active`) VALUES
(@user_admin, 'admin', '$2b$12$EFGKCcXkjHNvfOpJUK8gLeODDxpDmaFevnavQS6H3/i18CKGPodYK', 'Administrator', 'admin', 1)
ON DUPLICATE KEY UPDATE `display_name`=VALUES(`display_name`), `password_hash`=VALUES(`password_hash`), `role`='admin';
