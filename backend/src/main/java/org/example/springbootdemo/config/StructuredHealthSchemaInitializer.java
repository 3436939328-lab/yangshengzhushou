package org.example.springbootdemo.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * 结构化健康指标数据表初始化
 */
@Component
public class StructuredHealthSchemaInitializer implements CommandLineRunner {

    private static final String COLUMN_QUERY = """
            select column_name
            from information_schema.columns
            where table_schema = ?
              and table_name = ?
            """;

    private final JdbcTemplate jdbcTemplate;

    public StructuredHealthSchemaInitializer(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) {
        // 结构化健康测量表
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS structured_health_measurement (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  user_id BIGINT NOT NULL,
                  metric_code VARCHAR(30) NOT NULL COMMENT '指标编码',
                  measured_at VARCHAR(40) NULL COMMENT '测量时间ISO字符串',
                  timezone VARCHAR(30) NULL DEFAULT 'Asia/Shanghai' COMMENT '时区',
                  source VARCHAR(20) NULL DEFAULT 'MANUAL' COMMENT '来源:MANUAL/DEVICE/WEARABLE',
                  source_name VARCHAR(100) NULL COMMENT '来源名称',
                  provider_record_id VARCHAR(100) NULL COMMENT '来源设备记录ID',
                  version INT NULL DEFAULT 1 COMMENT '数据版本',
                  quality_status VARCHAR(20) NULL COMMENT '数据质量状态',
                  assessment VARCHAR(20) NULL COMMENT '评估状态:IN_RANGE/ATTENTION/URGENT/UNKNOWN',
                  assessment_reason VARCHAR(500) NULL COMMENT '评估原因',
                  note VARCHAR(500) NULL COMMENT '备注',
                  type_specific_json VARCHAR(2000) NULL COMMENT '类型专属字段JSON',
                  sync_status VARCHAR(20) NULL DEFAULT 'synced' COMMENT '同步状态',
                  is_deleted BIT NOT NULL DEFAULT 0 COMMENT '逻辑删除',
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  INDEX idx_structured_health_user (user_id),
                  INDEX idx_structured_health_user_metric (user_id, metric_code),
                  INDEX idx_structured_health_measured_at (measured_at),
                  CONSTRAINT fk_structured_health_user FOREIGN KEY (user_id) REFERENCES sys_user(id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='结构化健康测量记录'
                """);

        // 舌象照片表
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS tongue_image_record (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  user_id BIGINT NOT NULL,
                  image_asset_id VARCHAR(100) NULL COMMENT '图片资源ID',
                  image_url VARCHAR(500) NULL COMMENT '图片访问URL(短期)',
                  thumbnail_url VARCHAR(500) NULL COMMENT '缩略图URL',
                  captured_at VARCHAR(40) NULL COMMENT '拍摄时间',
                  uploaded_at VARCHAR(40) NULL COMMENT '上传时间',
                  source VARCHAR(20) NULL DEFAULT 'CAMERA' COMMENT '来源:CAMERA/ALBUM',
                  quality_status VARCHAR(20) NULL DEFAULT 'PENDING' COMMENT '质量状态:PENDING/ANALYZABLE/NEED_RETAKE',
                  quality_note VARCHAR(500) NULL COMMENT '质量备注',
                  analysis_status VARCHAR(20) NULL DEFAULT 'PENDING_UPLOAD' COMMENT '分析状态',
                  analysis_id VARCHAR(100) NULL COMMENT '分析任务ID',
                  analysis_result_json VARCHAR(2000) NULL COMMENT '分析结果JSON',
                  model_version VARCHAR(50) NULL COMMENT '模型版本',
                  note VARCHAR(500) NULL COMMENT '用户备注',
                  is_deleted BIT NOT NULL DEFAULT 0 COMMENT '逻辑删除',
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  INDEX idx_tongue_image_user (user_id),
                  INDEX idx_tongue_image_analysis (analysis_status),
                  CONSTRAINT fk_tongue_image_user FOREIGN KEY (user_id) REFERENCES sys_user(id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='舌象照片记录'
                """);

        // 亲人关系表
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS family_relation (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  inviter_id BIGINT NOT NULL COMMENT '邀请人ID',
                  invitee_id BIGINT NULL COMMENT '被邀请人ID(注册后填充)',
                  invitee_phone VARCHAR(20) NOT NULL COMMENT '被邀请人手机号',
                  relation_type VARCHAR(20) NOT NULL COMMENT '关系类型',
                  relation_label VARCHAR(50) NULL COMMENT '关系称呼',
                  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT '状态:PENDING/ACTIVE/REJECTED/EXPIRED/REMOVED',
                  expires_at VARCHAR(40) NULL COMMENT '过期时间',
                  inviter_granted_categories VARCHAR(500) NULL COMMENT '邀请人授权的类别JSON',
                  invitee_granted_categories VARCHAR(500) NULL COMMENT '被邀请人授权的类别JSON',
                  history_window_days INT NULL DEFAULT 7 COMMENT '历史数据可见天数',
                  display_name_inviter VARCHAR(50) NULL COMMENT '邀请人显示的称呼',
                  display_name_invitee VARCHAR(50) NULL COMMENT '被邀请人显示的称呼',
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  INDEX idx_family_relation_inviter (inviter_id),
                  INDEX idx_family_relation_invitee (invitee_id),
                  INDEX idx_family_relation_phone (invitee_phone),
                  INDEX idx_family_relation_status (status)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='亲人关系'
                """);

        // 问诊评价表
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS consultation_rating (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  consultation_id BIGINT NOT NULL COMMENT '问诊ID',
                  user_id BIGINT NOT NULL COMMENT '评价人ID',
                  rating INT NOT NULL COMMENT '评分1-5',
                  content VARCHAR(1000) NULL COMMENT '评价内容',
                  tags VARCHAR(500) NULL COMMENT '标签JSON',
                  is_visible BIT NOT NULL DEFAULT 1 COMMENT '是否可见',
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_consultation_rating (consultation_id),
                  INDEX idx_consultation_rating_user (user_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='问诊评价'
                """);

        // 异常提醒表
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS abnormal_alert (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  user_id BIGINT NOT NULL COMMENT '用户ID',
                  metric_code VARCHAR(30) NOT NULL COMMENT '指标编码',
                  state VARCHAR(20) NOT NULL COMMENT '状态:ATTENTION/URGENT',
                  value_text VARCHAR(100) NULL COMMENT '数值文本',
                  measured_at VARCHAR(40) NULL COMMENT '测量时间',
                  reason VARCHAR(500) NULL COMMENT '原因',
                  suggestion VARCHAR(500) NULL COMMENT '建议',
                  is_read BIT NOT NULL DEFAULT 0 COMMENT '是否已读',
                  related_measurement_id BIGINT NULL COMMENT '关联的测量记录ID',
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_abnormal_alert_user (user_id),
                  INDEX idx_abnormal_alert_read (user_id, is_read)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='异常提醒'
                """);

        // 建议生成任务表
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS suggestion_generation_task (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  user_id BIGINT NOT NULL COMMENT '用户ID',
                  task_date VARCHAR(20) NOT NULL COMMENT '建议日期',
                  trigger_type VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED' COMMENT '触发类型',
                  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT '状态',
                  progress INT NULL DEFAULT 0 COMMENT '进度0-100',
                  plan_version VARCHAR(50) NULL COMMENT '生成的建议版本',
                  error_message VARCHAR(500) NULL COMMENT '错误信息',
                  retry_count INT NULL DEFAULT 0 COMMENT '重试次数',
                  max_retries INT NULL DEFAULT 3 COMMENT '最大重试次数',
                  started_at VARCHAR(40) NULL COMMENT '开始时间',
                  completed_at VARCHAR(40) NULL COMMENT '完成时间',
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  INDEX idx_suggestion_task_user (user_id),
                  INDEX idx_suggestion_task_date (user_id, task_date),
                  INDEX idx_suggestion_task_status (status)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='建议生成任务'
                """);

        // sys_user 表补充字段（昵称、用户编号）
        String schemaName = jdbcTemplate.queryForObject("select database()", String.class);
        if (schemaName != null && !schemaName.isBlank()) {
            addUserColumnIfMissing(schemaName, "nickname",
                    "ALTER TABLE sys_user ADD COLUMN nickname VARCHAR(50) NULL COMMENT '昵称' AFTER real_name");
            addUserColumnIfMissing(schemaName, "user_no",
                    "ALTER TABLE sys_user ADD COLUMN user_no VARCHAR(30) NULL COMMENT '用户编号' AFTER id");
            addUserColumnIfMissing(schemaName, "avatar_asset_id",
                    "ALTER TABLE sys_user ADD COLUMN avatar_asset_id VARCHAR(100) NULL COMMENT '头像资源ID' AFTER avatar");
        }
    }

    private void addUserColumnIfMissing(String schemaName, String columnName, String sql) {
        Set<String> columns = new HashSet<>(
                jdbcTemplate.queryForList(COLUMN_QUERY, String.class, schemaName, "sys_user"));
        if (!columns.contains(columnName)) {
            try {
                jdbcTemplate.execute(sql);
            } catch (Exception ignored) {
            }
        }
    }
}
