package org.example.springbootdemo.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * 投诉与申诉闭环模块建表
 * 11 张表：6 核心 + 5 支撑(审计/权限/通知/幂等)
 */
@Component
public class ComplaintSchemaInitializer implements CommandLineRunner {

    private final JdbcTemplate jdbcTemplate;

    public ComplaintSchemaInitializer(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) {
        exec("""
                CREATE TABLE IF NOT EXISTS complaint_event (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  doctor_id BIGINT NOT NULL,
                  consultation_id BIGINT NULL,
                  category VARCHAR(40) NOT NULL,
                  effective_decision VARCHAR(20) NULL,
                  decision_at TIMESTAMP NULL,
                  policy_version INT NOT NULL DEFAULT 1,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  KEY idx_complaint_event_doctor (doctor_id, decision_at),
                  KEY idx_complaint_event_consultation (consultation_id)
                )
                """);
        exec("""
                CREATE TABLE IF NOT EXISTS complaint (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  event_id BIGINT NOT NULL,
                  reporter_id BIGINT NOT NULL,
                  description VARCHAR(2000) NOT NULL,
                  status VARCHAR(20) NOT NULL DEFAULT 'SUBMITTED',
                  assignee_id BIGINT NULL,
                  merged_into_id BIGINT NULL,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  updated_at TIMESTAMP NULL,
                  version INT NOT NULL DEFAULT 1,
                  KEY idx_complaint_status (status, created_at),
                  KEY idx_complaint_event (event_id),
                  KEY idx_complaint_reporter (reporter_id)
                )
                """);
        exec("""
                CREATE TABLE IF NOT EXISTS complaint_evidence (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  complaint_id BIGINT NOT NULL,
                  uploader_id BIGINT NOT NULL,
                  storage_bucket VARCHAR(100) NULL,
                  object_key VARCHAR(255) NULL,
                  format VARCHAR(20) NULL,
                  size BIGINT NULL,
                  summary VARCHAR(500) NULL,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  KEY idx_complaint_evidence_complaint (complaint_id)
                )
                """);
        exec("""
                CREATE TABLE IF NOT EXISTS complaint_decision (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  event_id BIGINT NOT NULL,
                  reviewer_id BIGINT NOT NULL,
                  result VARCHAR(20) NOT NULL,
                  severity VARCHAR(20) NULL,
                  reason VARCHAR(1000) NULL,
                  evidence_snapshot TEXT NULL,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  KEY idx_complaint_decision_event (event_id)
                )
                """);
        exec("""
                CREATE TABLE IF NOT EXISTS doctor_sanction (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  event_id BIGINT NOT NULL,
                  decision_id BIGINT NULL,
                  doctor_id BIGINT NOT NULL,
                  type VARCHAR(30) NOT NULL,
                  scope VARCHAR(30) NOT NULL,
                  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
                  starts_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  ends_at TIMESTAMP NULL,
                  issuer_id BIGINT NOT NULL,
                  approver_id BIGINT NULL,
                  reason VARCHAR(1000) NULL,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  KEY idx_doctor_sanction_doctor (doctor_id, status, ends_at),
                  KEY idx_doctor_sanction_event (event_id)
                )
                """);
        exec("""
                CREATE TABLE IF NOT EXISTS complaint_appeal (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  decision_id BIGINT NOT NULL,
                  doctor_id BIGINT NOT NULL,
                  status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
                  reason VARCHAR(1000) NULL,
                  reviewer_id BIGINT NULL,
                  result_reason VARCHAR(1000) NULL,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  reviewed_at TIMESTAMP NULL,
                  version INT NOT NULL DEFAULT 1,
                  KEY idx_complaint_appeal_status (status, created_at),
                  KEY idx_complaint_appeal_decision (decision_id)
                )
                """);
        exec("""
                CREATE TABLE IF NOT EXISTS admin_audit_log (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  actor_id BIGINT NOT NULL,
                  action VARCHAR(60) NOT NULL,
                  target_type VARCHAR(30) NOT NULL,
                  target_id BIGINT NULL,
                  summary VARCHAR(500) NULL,
                  reason VARCHAR(500) NULL,
                  result VARCHAR(20) NULL,
                  request_id VARCHAR(64) NULL,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  KEY idx_audit_target (target_type, target_id, created_at),
                  KEY idx_audit_actor (actor_id, created_at)
                )
                """);
        exec("""
                CREATE TABLE IF NOT EXISTS admin_permission (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  admin_user_id BIGINT NOT NULL,
                  permission_code VARCHAR(60) NOT NULL,
                  granted_by BIGINT NULL,
                  granted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_admin_permission (admin_user_id, permission_code)
                )
                """);
        exec("""
                CREATE TABLE IF NOT EXISTS notification_outbox (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  event_key VARCHAR(64) NOT NULL,
                  recipient_id BIGINT NOT NULL,
                  type VARCHAR(30) NOT NULL,
                  title VARCHAR(100) NULL,
                  body VARCHAR(500) NULL,
                  status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
                  retry_count INT NOT NULL DEFAULT 0,
                  next_retry_at TIMESTAMP NULL,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_outbox_event (event_key, recipient_id)
                )
                """);
        exec("""
                CREATE TABLE IF NOT EXISTS inbox_notification (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  recipient_id BIGINT NOT NULL,
                  event_key VARCHAR(64) NOT NULL,
                  title VARCHAR(100) NULL,
                  body VARCHAR(500) NULL,
                  read_at TIMESTAMP NULL,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  KEY idx_inbox_recipient (recipient_id, created_at)
                )
                """);
        exec("""
                CREATE TABLE IF NOT EXISTS idempotent_request (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  actor_id BIGINT NOT NULL,
                  action VARCHAR(40) NOT NULL,
                  key VARCHAR(64) NOT NULL,
                  request_hash VARCHAR(64) NULL,
                  result_ref VARCHAR(100) NULL,
                  status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
                  expires_at TIMESTAMP NULL,
                  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_idempotent (actor_id, action, key)
                )
                """);
    }

    private void exec(String sql) {
        try {
            jdbcTemplate.execute(sql);
        } catch (Exception ignored) {
            // 表已存在或列已存在时忽略
        }
    }
}
