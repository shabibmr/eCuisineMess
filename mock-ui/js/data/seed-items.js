/* seed-items.js - Seed data for 48 items (I001–I048) across 7 categories */

window.Mess = window.Mess || {};
window.Mess.seed = window.Mess.seed || {};

window.Mess.seed.items = [
  // Breakfast (14 items, 2 inactive)
  { id: 'I001', code: 'I001', name: 'Idli', category: 'Breakfast', unit: 'Nos', defaultQty: 2, active: true },
  { id: 'I002', code: 'I002', name: 'Plain dosa', category: 'Breakfast', unit: 'Nos', defaultQty: 1, active: true },
  { id: 'I003', code: 'I003', name: 'Masala dosa', category: 'Breakfast', unit: 'Nos', defaultQty: 1, active: true },
  { id: 'I004', code: 'I004', name: 'Ven pongal', category: 'Breakfast', unit: 'Plate', defaultQty: 1, active: true },
  { id: 'I005', code: 'I005', name: 'Rava upma', category: 'Breakfast', unit: 'Plate', defaultQty: 1, active: true },
  { id: 'I006', code: 'I006', name: 'Medu vada', category: 'Breakfast', unit: 'Nos', defaultQty: 2, active: true },
  { id: 'I007', code: 'I007', name: 'Poha', category: 'Breakfast', unit: 'Plate', defaultQty: 1, active: true },
  { id: 'I008', code: 'I008', name: 'Aloo paratha', category: 'Breakfast', unit: 'Nos', defaultQty: 2, active: true },
  { id: 'I009', code: 'I009', name: 'Appam', category: 'Breakfast', unit: 'Nos', defaultQty: 2, active: true },
  { id: 'I010', code: 'I010', name: 'Puttu', category: 'Breakfast', unit: 'Plate', defaultQty: 1, active: true },
  { id: 'I011', code: 'I011', name: 'Halwa puri', category: 'Breakfast', unit: 'Plate', defaultQty: 1, active: false }, // Inactive 1
  { id: 'I012', code: 'I012', name: 'Foul medames', category: 'Breakfast', unit: 'Bowl', defaultQty: 1, active: true },
  { id: 'I013', code: 'I013', name: 'Longganisa', category: 'Breakfast', unit: 'Plate', defaultQty: 1, active: false }, // Inactive 2
  { id: 'I014', code: 'I014', name: 'Fried egg', category: 'Breakfast', unit: 'Nos', defaultQty: 2, active: true },

  // Breads (4 items)
  { id: 'I015', code: 'I015', name: 'Chapati', category: 'Breads', unit: 'Nos', defaultQty: 3, active: true },
  { id: 'I016', code: 'I016', name: 'Tandoori naan', category: 'Breads', unit: 'Nos', defaultQty: 2, active: true },
  { id: 'I017', code: 'I017', name: 'Khubz', category: 'Breads', unit: 'Nos', defaultQty: 2, active: true },
  { id: 'I018', code: 'I018', name: 'Kerala porotta', category: 'Breads', unit: 'Nos', defaultQty: 2, active: true },

  // Rice (6 items)
  { id: 'I019', code: 'I019', name: 'Steamed rice', category: 'Rice', unit: 'Plate', defaultQty: 1, active: true },
  { id: 'I020', code: 'I020', name: 'Kerala matta rice', category: 'Rice', unit: 'Plate', defaultQty: 1, active: true },
  { id: 'I021', code: 'I021', name: 'Jeera rice', category: 'Rice', unit: 'Plate', defaultQty: 1, active: true },
  { id: 'I022', code: 'I022', name: 'Chicken biryani', category: 'Rice', unit: 'Plate', defaultQty: 1, active: true },
  { id: 'I023', code: 'I023', name: 'Chicken machboos', category: 'Rice', unit: 'Plate', defaultQty: 1, active: true },
  { id: 'I024', code: 'I024', name: 'Garlic rice', category: 'Rice', unit: 'Plate', defaultQty: 1, active: true },

  // Curries (11 items)
  { id: 'I025', code: 'I025', name: 'Sambar', category: 'Curries', unit: 'Bowl', defaultQty: 1, active: true },
  { id: 'I026', code: 'I026', name: 'Rasam', category: 'Curries', unit: 'Bowl', defaultQty: 1, active: true },
  { id: 'I027', code: 'I027', name: 'Dal tadka', category: 'Curries', unit: 'Bowl', defaultQty: 1, active: true },
  { id: 'I028', code: 'I028', name: 'Rajma', category: 'Curries', unit: 'Bowl', defaultQty: 1, active: true },
  { id: 'I029', code: 'I029', name: 'Paneer butter masala', category: 'Curries', unit: 'Bowl', defaultQty: 1, active: true },
  { id: 'I030', code: 'I030', name: 'Kadala curry', category: 'Curries', unit: 'Bowl', defaultQty: 1, active: true },
  { id: 'I031', code: 'I031', name: 'Kerala fish curry', category: 'Curries', unit: 'Bowl', defaultQty: 1, active: true },
  { id: 'I032', code: 'I032', name: 'Mutton karahi', category: 'Curries', unit: 'Bowl', defaultQty: 1, active: true },
  { id: 'I033', code: 'I033', name: 'Chicken handi', category: 'Curries', unit: 'Bowl', defaultQty: 1, active: true },
  { id: 'I034', code: 'I034', name: 'Chicken adobo', category: 'Curries', unit: 'Bowl', defaultQty: 1, active: true },
  { id: 'I035', code: 'I035', name: 'Sinigang', category: 'Curries', unit: 'Bowl', defaultQty: 1, active: true },

  // Sides (8 items)
  { id: 'I036', code: 'I036', name: 'Coconut chutney', category: 'Sides', unit: 'Cup', defaultQty: 1, active: true },
  { id: 'I037', code: 'I037', name: 'Cabbage poriyal', category: 'Sides', unit: 'Cup', defaultQty: 1, active: true },
  { id: 'I038', code: 'I038', name: 'Avial', category: 'Sides', unit: 'Cup', defaultQty: 1, active: true },
  { id: 'I039', code: 'I039', name: 'Hummus', category: 'Sides', unit: 'Cup', defaultQty: 1, active: true },
  { id: 'I040', code: 'I040', name: 'Falafel', category: 'Sides', unit: 'Nos', defaultQty: 3, active: true },
  { id: 'I041', code: 'I041', name: 'Fattoush', category: 'Sides', unit: 'Bowl', defaultQty: 1, active: true },
  { id: 'I042', code: 'I042', name: 'Pancit', category: 'Sides', unit: 'Plate', defaultQty: 1, active: true },
  { id: 'I043', code: 'I043', name: 'Raita', category: 'Sides', unit: 'Cup', defaultQty: 1, active: true },

  // Beverages (3 items)
  { id: 'I044', code: 'I044', name: 'Karak tea', category: 'Beverages', unit: 'Cup', defaultQty: 1, active: true },
  { id: 'I045', code: 'I045', name: 'Filter coffee', category: 'Beverages', unit: 'Cup', defaultQty: 1, active: true },
  { id: 'I046', code: 'I046', name: 'Laban', category: 'Beverages', unit: 'Glass', defaultQty: 1, active: true },

  // Desserts (2 items)
  { id: 'I047', code: 'I047', name: 'Gulab jamun', category: 'Desserts', unit: 'Nos', defaultQty: 2, active: true },
  { id: 'I048', code: 'I048', name: 'Fresh fruit', category: 'Desserts', unit: 'Piece', defaultQty: 1, active: true }
];
