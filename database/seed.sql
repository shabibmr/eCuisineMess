-- ========================================================
-- eCuisine Mess Module Seed Data
-- ========================================================

USE `ecuisine_mess`;

-- 1. Seed Meal Times
INSERT INTO `mess_meal_times` (`id`, `meal_type`, `name`, `start_time`, `end_time`, `is_active`) VALUES
(1, 'BREAKFAST', 'Breakfast Window', '06:30:00', '10:30:00', 1),
(2, 'LUNCH', 'Lunch Window', '12:00:00', '15:30:00', 1),
(3, 'DINNER', 'Dinner Window', '19:00:00', '22:30:00', 1)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `start_time`=VALUES(`start_time`), `end_time`=VALUES(`end_time`);

-- 2. Seed Items
INSERT INTO `mess_items` (`id`, `item_code`, `item_name`, `category`, `unit`, `is_active`) VALUES
(1, 'ITM-001', 'Steamed Idli (3 pcs)', 'Main', 'Plate', 1),
(2, 'ITM-002', 'Medu Vada (1 pc)', 'Side', 'Nos', 1),
(3, 'ITM-003', 'Coconut Chutney & Sambar', 'Side', 'Bowl', 1),
(4, 'ITM-004', 'Filter Coffee / Tea', 'Beverage', 'Cup', 1),
(5, 'ITM-005', 'Hyderabadi Chicken Biryani', 'Main', 'Plate', 1),
(6, 'ITM-006', 'Mirchi Ka Salan & Raita', 'Side', 'Bowl', 1),
(7, 'ITM-007', 'Gulab Jamun (2 pcs)', 'Dessert', 'Bowl', 1),
(8, 'ITM-008', 'Paneer Butter Masala', 'Main', 'Bowl', 1),
(9, 'ITM-009', 'Tandoori Roti (2 pcs)', 'Bread', 'Plate', 1),
(10, 'ITM-010', 'Jeera Rice & Dal Tadka', 'Main', 'Plate', 1),
(11, 'ITM-011', 'Arabic Chicken Mandi Rice', 'Main', 'Plate', 1),
(12, 'ITM-012', 'Arabic Garlic Paste (Toum) & Dakkous', 'Side', 'Bowl', 1),
(13, 'ITM-013', 'Fattoush Salad', 'Side', 'Bowl', 1),
(14, 'ITM-014', 'Grilled Chicken Breast & Herb Veggies', 'Main', 'Plate', 1),
(15, 'ITM-015', 'Cream of Mushroom Soup', 'Side', 'Bowl', 1),
(16, 'ITM-016', 'Garlic Bread (2 pcs)', 'Bread', 'Plate', 1),
(17, 'ITM-017', 'Kerala Parotta (2 pcs)', 'Bread', 'Plate', 1),
(18, 'ITM-018', 'Chicken Pepper Roast', 'Main', 'Plate', 1)
ON DUPLICATE KEY UPDATE `item_name`=VALUES(`item_name`);

-- 3. Seed Cuisines
INSERT INTO `mess_cuisines` (`id`, `cuisine_code`, `cuisine_name`, `description`, `is_active`) VALUES
(1, 'CUIS-SI', 'South Indian', 'Traditional South Indian meals, idlis, dosas & rice', 1),
(2, 'CUIS-NI', 'North Indian', 'Curries, tandoor breads, dal and aromatic basmati rice', 1),
(3, 'CUIS-AR', 'Arabic', 'Authentic Arabic Mandi, grilled meats, toum & fresh salads', 1),
(4, 'CUIS-CO', 'Continental', 'Steaks, soups, pasta and grilled vegetable platters', 1),
(5, 'CUIS-KL', 'Kerala Special', 'Malabar parottas, coconut curries and seafood dishes', 1)
ON DUPLICATE KEY UPDATE `cuisine_name`=VALUES(`cuisine_name`);

-- 4. Seed Cuisine Items Mapping
INSERT INTO `mess_cuisine_items` (`cuisine_id`, `item_id`, `default_qty`, `sort_order`) VALUES
-- South Indian
(1, 1, 1.00, 1),
(1, 2, 1.00, 2),
(1, 3, 1.00, 3),
(1, 4, 1.00, 4),
-- North Indian
(2, 8, 1.00, 1),
(2, 9, 1.00, 2),
(2, 10, 1.00, 3),
(2, 7, 1.00, 4),
-- Arabic
(3, 11, 1.00, 1),
(3, 12, 1.00, 2),
(3, 13, 1.00, 3),
-- Continental
(4, 14, 1.00, 1),
(4, 15, 1.00, 2),
(4, 16, 1.00, 3),
-- Kerala Special
(5, 17, 1.00, 1),
(5, 18, 1.00, 2),
(5, 4, 1.00, 3)
ON DUPLICATE KEY UPDATE `default_qty`=VALUES(`default_qty`);

-- 5. Seed Members
INSERT INTO `mess_members` (`id`, `member_code`, `name`, `rfid_tag`, `phone`, `email`, `cuisine_id`, `validity_start`, `validity_end`, `status`) VALUES
(1, 'MEM-001', 'Rahul Krishnan', 'E280116060000204', '+971-50-1234567', 'rahul.k@example.com', 1, '2026-01-01', '2026-12-31', 'ACTIVE'),
(2, 'MEM-002', 'Mohammed Al-Hashimi', 'E280116060000205', '+971-50-2345678', 'm.hashimi@example.com', 3, '2026-01-01', '2026-12-31', 'ACTIVE'),
(3, 'MEM-003', 'Amit Sharma', 'E280116060000206', '+971-50-3456789', 'amit.s@example.com', 2, '2026-01-01', '2026-12-31', 'ACTIVE'),
(4, 'MEM-004', 'John David Miller', 'E280116060000207', '+971-50-4567890', 'john.m@example.com', 4, '2026-01-01', '2026-12-31', 'ACTIVE'),
(5, 'MEM-005', 'Faisal Bin Rashid', 'E280116060000208', '+971-50-5678901', 'faisal.r@example.com', 3, '2026-01-01', '2026-12-31', 'ACTIVE'),
(6, 'MEM-006', 'Vipin Nambiar', 'E280116060000209', '+971-50-6789012', 'vipin.n@example.com', 5, '2026-01-01', '2026-12-31', 'ACTIVE'),
(7, 'MEM-007', 'Suresh Kumar (Expired Card)', 'E280116060000210', '+971-50-7890123', 'suresh.k@example.com', 1, '2025-01-01', '2025-12-31', 'EXPIRED'),
(8, 'MEM-008', 'Tariq Mansoor (Suspended)', 'E280116060000211', '+971-50-8901234', 'tariq.m@example.com', 3, '2026-01-01', '2026-12-31', 'SUSPENDED'),
(9, 'MEM-009', 'Pooja Verma', 'E280116060000212', '+971-50-9012345', 'pooja.v@example.com', 2, '2026-01-01', '2026-12-31', 'ACTIVE'),
(10, 'MEM-010', 'Alexandre Dubois', 'E280116060000213', '+971-50-0123456', 'alex.d@example.com', 4, '2026-01-01', '2026-12-31', 'ACTIVE')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `rfid_tag`=VALUES(`rfid_tag`), `cuisine_id`=VALUES(`cuisine_id`);

-- 6. Seed Daily Menus for Today
INSERT INTO `mess_daily_menus` (`id`, `menu_date`, `cuisine_id`, `meal_type`, `is_locked`, `notes`) VALUES
(1, CURDATE(), 1, 'BREAKFAST', 0, 'Morning South Indian breakfast setup'),
(2, CURDATE(), 1, 'LUNCH', 0, 'South Indian Meals with Biryani option'),
(3, CURDATE(), 1, 'DINNER', 0, 'Light dinner'),
(4, CURDATE(), 2, 'LUNCH', 0, 'North Indian combo with Paneer Butter Masala'),
(5, CURDATE(), 3, 'LUNCH', 0, 'Chicken Mandi Platter'),
(6, CURDATE(), 4, 'LUNCH', 0, 'Continental Herb Roast')
ON DUPLICATE KEY UPDATE `notes`=VALUES(`notes`);

-- 7. Seed Daily Menu Items
INSERT INTO `mess_daily_menu_items` (`menu_id`, `item_id`, `quantity`) VALUES
(1, 1, 1.00), (1, 2, 1.00), (1, 3, 1.00), (1, 4, 1.00),
(2, 5, 1.00), (2, 6, 1.00), (2, 7, 1.00),
(3, 1, 1.00), (3, 3, 1.00), (3, 4, 1.00),
(4, 8, 1.00), (4, 9, 1.00), (4, 10, 1.00), (4, 7, 1.00),
(5, 11, 1.00), (5, 12, 1.00), (5, 13, 1.00),
(6, 14, 1.00), (6, 15, 1.00), (6, 16, 1.00)
ON DUPLICATE KEY UPDATE `quantity`=VALUES(`quantity`);

-- 8. Seed sample issued bills for today
INSERT INTO `mess_bills` (`id`, `bill_number`, `token_number`, `bill_date`, `bill_time`, `member_id`, `cuisine_id`, `meal_type`, `total_amount`, `status`) VALUES
(1, CONCAT('B-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-0001'), 'B-0001', CURDATE(), '08:15:00', 1, 1, 'BREAKFAST', 0.00, 'SERVED'),
(2, CONCAT('B-', DATE_FORMAT(CURDATE(), '%Y%m%d'), '-0002'), 'B-0002', CURDATE(), '08:22:00', 3, 2, 'BREAKFAST', 0.00, 'SERVED')
ON DUPLICATE KEY UPDATE `token_number`=VALUES(`token_number`);

INSERT INTO `mess_bill_items` (`bill_id`, `item_id`, `item_name`, `quantity`, `unit_price`, `total_price`) VALUES
(1, 1, 'Steamed Idli (3 pcs)', 1.00, 0.00, 0.00),
(1, 2, 'Medu Vada (1 pc)', 1.00, 0.00, 0.00),
(1, 3, 'Coconut Chutney & Sambar', 1.00, 0.00, 0.00),
(1, 4, 'Filter Coffee / Tea', 1.00, 0.00, 0.00),
(2, 1, 'Steamed Idli (3 pcs)', 1.00, 0.00, 0.00),
(2, 4, 'Filter Coffee / Tea', 1.00, 0.00, 0.00)
ON DUPLICATE KEY UPDATE `quantity`=VALUES(`quantity`);
