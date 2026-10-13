-- Base tables for yangsheng_db
-- Creates sys_user, sys_role, sys_user_role before other SQL scripts

CREATE TABLE IF NOT EXISTS sys_user (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  username VARCHAR(50) NOT NULL,
  password VARCHAR(200) NOT NULL,
  real_name VARCHAR(50) NULL,
  phone VARCHAR(20) NULL,
  email VARCHAR(100) NULL,
  birthday VARCHAR(20) NULL,
  avatar LONGTEXT NULL,
  gender VARCHAR(10) NULL,
  age INT NULL,
  status TINYINT NOT NULL DEFAULT 1,
  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_sys_user_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='system users';

CREATE TABLE IF NOT EXISTS sys_role (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  role_name VARCHAR(50) NOT NULL,
  role_code VARCHAR(50) NOT NULL,
  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_sys_role_code (role_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='system roles';

CREATE TABLE IF NOT EXISTS sys_user_role (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  role_id BIGINT NOT NULL,
  UNIQUE KEY uk_sys_user_role (user_id, role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='user-role mapping';

INSERT INTO sys_role (role_name, role_code) VALUES ('管理员', 'ADMIN');
INSERT INTO sys_role (role_name, role_code) VALUES ('医生', 'DOCTOR');
INSERT INTO sys_role (role_name, role_code) VALUES ('普通用户', 'USER');
