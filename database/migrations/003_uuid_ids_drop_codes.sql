-- ========================================================
-- Migration 003: UUID primary keys; drop all *_code columns
-- BREAKING — rebuilds the database from schema + seed.
--
--   mysql -u root < database/migrations/003_uuid_ids_drop_codes.sql
--
-- Or manually:
--   mysql -u root -e "DROP DATABASE IF EXISTS ecuisine_mess;"
--   mysql -u root < database/schema.sql
--   mysql -u root < database/seed.sql
-- ========================================================

DROP DATABASE IF EXISTS `ecuisine_mess`;

SOURCE D:/QtWorkspace/DIT/DITUAE/counter/Mess_Module/database/schema.sql;
SOURCE D:/QtWorkspace/DIT/DITUAE/counter/Mess_Module/database/seed.sql;
