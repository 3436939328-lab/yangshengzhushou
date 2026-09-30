-- Yangsheng assistant extra business tables.
-- Run this script after the base tables such as sys_user have been created.

ALTER TABLE sys_user
  ADD COLUMN IF NOT EXISTS email VARCHAR(100) NULL AFTER phone;

ALTER TABLE sys_user
  ADD COLUMN IF NOT EXISTS birthday VARCHAR(20) NULL AFTER email;

ALTER TABLE sys_user
  ADD COLUMN IF NOT EXISTS avatar LONGTEXT NULL AFTER birthday;

CREATE TABLE IF NOT EXISTS health_question (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  question VARCHAR(500) NOT NULL,
  answer VARCHAR(1000) NULL,
  status TINYINT NOT NULL DEFAULT 0 COMMENT '0=pending, 1=answered',
  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_health_question_user
    FOREIGN KEY (user_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='health assistant questions';

CREATE TABLE IF NOT EXISTS doctor_profile (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  doctor_name VARCHAR(50) NOT NULL,
  title VARCHAR(50) NULL,
  specialty VARCHAR(100) NULL,
  introduction VARCHAR(1000) NULL,
  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_doctor_profile_user (user_id),
  CONSTRAINT fk_doctor_profile_user
    FOREIGN KEY (user_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='doctor profiles';

CREATE TABLE IF NOT EXISTS consultation (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  doctor_id BIGINT NOT NULL,
  title VARCHAR(100) NOT NULL DEFAULT '一对一问诊',
  symptom VARCHAR(200) NOT NULL,
  description VARCHAR(1000) NOT NULL,
  status TINYINT NOT NULL DEFAULT 0 COMMENT '0=open, 1=closed',
  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_consultation_user
    FOREIGN KEY (user_id) REFERENCES sys_user(id),
  CONSTRAINT fk_consultation_doctor
    FOREIGN KEY (doctor_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='consultations';

ALTER TABLE consultation
  ADD COLUMN IF NOT EXISTS title VARCHAR(100) NOT NULL DEFAULT '一对一问诊' AFTER doctor_id;

CREATE TABLE IF NOT EXISTS consultation_message (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  consultation_id BIGINT NOT NULL,
  sender_id BIGINT NOT NULL,
  sender_role VARCHAR(20) NOT NULL DEFAULT 'USER',
  content VARCHAR(1000) NOT NULL,
  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_consultation_message_consultation
    FOREIGN KEY (consultation_id) REFERENCES consultation(id),
  CONSTRAINT fk_consultation_message_sender
    FOREIGN KEY (sender_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='consultation messages';

ALTER TABLE consultation_message
  ADD COLUMN IF NOT EXISTS sender_role VARCHAR(20) NOT NULL DEFAULT 'USER' AFTER sender_id;
