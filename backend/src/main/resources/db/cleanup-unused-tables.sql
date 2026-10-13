-- Database table cleanup helper for yangsheng_db.
-- Review before running. The application code currently uses every table
-- listed in the KEEP section below.

USE yangsheng_db;

-- 1) Inspect current database tables first.
SHOW TABLES;

-- 2) KEEP: tables used by the current backend/frontend and useful for PC/App launch.
-- sys_user
-- sys_role
-- sys_user_role
-- health_archive
-- health_question
-- health_questionnaire_record
-- health_indicator_record
-- tongue_observation_record
-- doctor_profile
-- consultation
-- consultation_message

-- 3) Optional cleanup candidates.
-- I did not find these names used by current code. Only run a DROP statement
-- after SHOW TABLES confirms the table really exists and you have backed up data.
--
-- DROP TABLE IF EXISTS sys_menu;
-- DROP TABLE IF EXISTS sys_permission;
-- DROP TABLE IF EXISTS sys_log;
-- DROP TABLE IF EXISTS operation_log;
-- DROP TABLE IF EXISTS login_log;
-- DROP TABLE IF EXISTS notice;
-- DROP TABLE IF EXISTS feedback;
-- DROP TABLE IF EXISTS article;
-- DROP TABLE IF EXISTS appointment;
-- DROP TABLE IF EXISTS prescription;
-- DROP TABLE IF EXISTS medicine;

-- 4) Legacy columns inside health_indicator_record.
-- Older code may have left these columns. Current code uses:
-- id, user_id, name, value, unit, recorded_at, create_time.
-- If the legacy columns exist and data has been migrated, they can be removed.
--
-- ALTER TABLE health_indicator_record DROP COLUMN indicator_type;
-- ALTER TABLE health_indicator_record DROP COLUMN indicator_name;
-- ALTER TABLE health_indicator_record DROP COLUMN indicator_value;
-- ALTER TABLE health_indicator_record DROP COLUMN measured_at;
