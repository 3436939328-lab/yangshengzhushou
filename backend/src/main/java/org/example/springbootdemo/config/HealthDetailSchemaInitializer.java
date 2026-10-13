package org.example.springbootdemo.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Component
public class HealthDetailSchemaInitializer implements CommandLineRunner {

    private static final String COLUMN_QUERY = """
            select column_name
            from information_schema.columns
            where table_schema = ?
              and table_name = ?
            """;

    private final JdbcTemplate jdbcTemplate;

    public HealthDetailSchemaInitializer(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS health_questionnaire_record (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  user_id BIGINT NOT NULL,
                  constitution_type VARCHAR(50) NOT NULL,
                  total_score INT NULL,
                  suggestion VARCHAR(1000) NULL,
                  answers_json VARCHAR(4000) NULL,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_health_questionnaire_user (user_id),
                  CONSTRAINT fk_health_questionnaire_user FOREIGN KEY (user_id) REFERENCES sys_user(id)
                )
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS health_indicator_record (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  user_id BIGINT NOT NULL,
                  name VARCHAR(50) NOT NULL,
                  value VARCHAR(50) NOT NULL,
                  unit VARCHAR(30) NULL,
                  recorded_at VARCHAR(40) NULL,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_health_indicator_user (user_id),
                  CONSTRAINT fk_health_indicator_user FOREIGN KEY (user_id) REFERENCES sys_user(id)
                )
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS tongue_observation_record (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  user_id BIGINT NOT NULL,
                  color VARCHAR(50) NOT NULL,
                  coating VARCHAR(50) NOT NULL,
                  dryness VARCHAR(50) NOT NULL,
                  note VARCHAR(1000) NULL,
                  recorded_at VARCHAR(40) NULL,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_tongue_observation_user (user_id),
                  CONSTRAINT fk_tongue_observation_user FOREIGN KEY (user_id) REFERENCES sys_user(id)
                )
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS tongue_image (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  user_id BIGINT NOT NULL,
                  asset_id VARCHAR(100) NULL,
                  image_url VARCHAR(500) NULL,
                  thumbnail_url VARCHAR(500) NULL,
                  source VARCHAR(20) NULL COMMENT 'CAMERA/ALBUM',
                  quality_status VARCHAR(20) NULL DEFAULT 'PENDING' COMMENT 'PENDING/ANALYZABLE/NEED_RETAKE',
                  quality_note VARCHAR(500) NULL,
                  analysis_status VARCHAR(30) NULL DEFAULT 'PENDING_UPLOAD' COMMENT 'PENDING_UPLOAD/UPLOADING/QUEUED/ANALYZING/SUCCESS/FAILED/CANCELLED',
                  analysis_id VARCHAR(100) NULL,
                  model_version VARCHAR(50) NULL,
                  tongue_color VARCHAR(100) NULL,
                  tongue_coating VARCHAR(100) NULL,
                  tongue_dryness VARCHAR(100) NULL,
                  tongue_shape VARCHAR(100) NULL,
                  coating_thickness VARCHAR(100) NULL,
                  coating_color VARCHAR(100) NULL,
                  constitution_suggestion VARCHAR(500) NULL,
                  health_advice VARCHAR(1000) NULL,
                  warning_signs VARCHAR(500) NULL,
                  analysis_note VARCHAR(2000) NULL,
                  captured_at VARCHAR(40) NULL,
                  uploaded_at VARCHAR(40) NULL,
                  analyzed_at VARCHAR(40) NULL,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  is_deleted TINYINT NOT NULL DEFAULT 0,
                  INDEX idx_tongue_image_user (user_id),
                  INDEX idx_tongue_image_status (analysis_status),
                  CONSTRAINT fk_tongue_img_user FOREIGN KEY (user_id) REFERENCES sys_user(id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
                """);

        String schemaName = jdbcTemplate.queryForObject("select database()", String.class);
        if (schemaName == null || schemaName.isBlank()) {
            return;
        }

        addMissingColumns("health_questionnaire_record", buildQuestionnaireColumnStatements(), schemaName);
        addMissingColumns("health_indicator_record", buildIndicatorColumnStatements(), schemaName);
        addMissingColumns("tongue_observation_record", buildTongueColumnStatements(), schemaName);
        jdbcTemplate.execute("ALTER TABLE health_indicator_record MODIFY COLUMN recorded_at VARCHAR(40) NULL");
        jdbcTemplate.execute("ALTER TABLE tongue_observation_record MODIFY COLUMN recorded_at VARCHAR(40) NULL");
    }

    private void addMissingColumns(String tableName, List<ColumnStatement> statements, String schemaName) {
        Set<String> columns = new HashSet<>(jdbcTemplate.queryForList(COLUMN_QUERY, String.class, schemaName, tableName));
        for (ColumnStatement statement : statements) {
            if (!columns.contains(statement.columnName())) {
                jdbcTemplate.execute(statement.sql());
            }
        }
        if ("health_indicator_record".equals(tableName) && columns.contains("indicator_type")) {
            jdbcTemplate.execute("ALTER TABLE health_indicator_record MODIFY COLUMN indicator_type VARCHAR(50) NULL");
        }
        if ("health_indicator_record".equals(tableName) && columns.contains("indicator_name")) {
            jdbcTemplate.execute("ALTER TABLE health_indicator_record MODIFY COLUMN indicator_name VARCHAR(50) NULL");
        }
        if ("health_indicator_record".equals(tableName) && columns.contains("indicator_value")) {
            jdbcTemplate.execute("ALTER TABLE health_indicator_record MODIFY COLUMN indicator_value VARCHAR(50) NULL");
        }
        if ("health_indicator_record".equals(tableName) && columns.contains("measured_at")) {
            jdbcTemplate.execute("ALTER TABLE health_indicator_record MODIFY COLUMN measured_at VARCHAR(40) NULL");
        }
    }

    private List<ColumnStatement> buildQuestionnaireColumnStatements() {
        return List.of(
                new ColumnStatement("constitution_type", "ALTER TABLE health_questionnaire_record ADD COLUMN constitution_type VARCHAR(50) NULL AFTER user_id"),
                new ColumnStatement("total_score", "ALTER TABLE health_questionnaire_record ADD COLUMN total_score INT NULL AFTER constitution_type"),
                new ColumnStatement("suggestion", "ALTER TABLE health_questionnaire_record ADD COLUMN suggestion VARCHAR(1000) NULL AFTER total_score"),
                new ColumnStatement("answers_json", "ALTER TABLE health_questionnaire_record ADD COLUMN answers_json VARCHAR(4000) NULL AFTER suggestion"),
                new ColumnStatement("create_time", "ALTER TABLE health_questionnaire_record ADD COLUMN create_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP AFTER answers_json")
        );
    }

    private List<ColumnStatement> buildIndicatorColumnStatements() {
        return List.of(
                new ColumnStatement("name", "ALTER TABLE health_indicator_record ADD COLUMN name VARCHAR(50) NULL AFTER user_id"),
                new ColumnStatement("value", "ALTER TABLE health_indicator_record ADD COLUMN value VARCHAR(50) NULL AFTER name"),
                new ColumnStatement("unit", "ALTER TABLE health_indicator_record ADD COLUMN unit VARCHAR(30) NULL AFTER value"),
                new ColumnStatement("recorded_at", "ALTER TABLE health_indicator_record ADD COLUMN recorded_at VARCHAR(40) NULL AFTER unit"),
                new ColumnStatement("create_time", "ALTER TABLE health_indicator_record ADD COLUMN create_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP AFTER recorded_at")
        );
    }

    private List<ColumnStatement> buildTongueColumnStatements() {
        return List.of(
                new ColumnStatement("color", "ALTER TABLE tongue_observation_record ADD COLUMN color VARCHAR(50) NULL AFTER user_id"),
                new ColumnStatement("coating", "ALTER TABLE tongue_observation_record ADD COLUMN coating VARCHAR(50) NULL AFTER color"),
                new ColumnStatement("dryness", "ALTER TABLE tongue_observation_record ADD COLUMN dryness VARCHAR(50) NULL AFTER coating"),
                new ColumnStatement("note", "ALTER TABLE tongue_observation_record ADD COLUMN note VARCHAR(1000) NULL AFTER dryness"),
                new ColumnStatement("recorded_at", "ALTER TABLE tongue_observation_record ADD COLUMN recorded_at VARCHAR(40) NULL AFTER note"),
                new ColumnStatement("create_time", "ALTER TABLE tongue_observation_record ADD COLUMN create_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP AFTER recorded_at")
        );
    }

    private record ColumnStatement(String columnName, String sql) {
    }
}
