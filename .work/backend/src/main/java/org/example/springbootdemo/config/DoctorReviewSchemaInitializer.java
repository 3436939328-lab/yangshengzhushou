package org.example.springbootdemo.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * 医生资质审核记录表初始化
 * 一个医生可有多条记录形成历史，按 version 倒序排列
 */
@Component
public class DoctorReviewSchemaInitializer implements CommandLineRunner {

    private static final String CREATE_TABLE_SQL = """
            CREATE TABLE IF NOT EXISTS doctor_review (
              id BIGINT PRIMARY KEY AUTO_INCREMENT,
              doctor_user_id BIGINT NOT NULL,
              reviewer_id BIGINT NULL,
              status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
              reason VARCHAR(1000) NULL,
              version INT NOT NULL DEFAULT 1,
              created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
              submitted_at TIMESTAMP NULL,
              reviewed_at TIMESTAMP NULL,
              KEY idx_doctor_review_doctor (doctor_user_id),
              KEY idx_doctor_review_status (status, created_at),
              CONSTRAINT fk_doctor_review_user FOREIGN KEY (doctor_user_id) REFERENCES sys_user(id)
            )
            """;

    private final JdbcTemplate jdbcTemplate;

    public DoctorReviewSchemaInitializer(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) {
        jdbcTemplate.execute(CREATE_TABLE_SQL);

        String schemaName = jdbcTemplate.queryForObject("select database()", String.class);
        if (schemaName == null || schemaName.isBlank()) {
            return;
        }

        Set<String> columns = new HashSet<>(jdbcTemplate.queryForList(
                """
                        select column_name
                        from information_schema.columns
                        where table_schema = ?
                          and table_name = 'doctor_review'
                        """,
                String.class,
                schemaName
        ));

        for (String statement : buildMissingColumnStatements(columns)) {
            jdbcTemplate.execute(statement);
        }
    }

    List<String> buildMissingColumnStatements(Set<String> columns) {
        List<String> statements = new java.util.ArrayList<>();
        if (!columns.contains("reviewer_id")) {
            statements.add("ALTER TABLE doctor_review ADD COLUMN reviewer_id BIGINT NULL AFTER doctor_user_id");
        }
        if (!columns.contains("reason")) {
            statements.add("ALTER TABLE doctor_review ADD COLUMN reason VARCHAR(1000) NULL AFTER status");
        }
        if (!columns.contains("version")) {
            statements.add("ALTER TABLE doctor_review ADD COLUMN version INT NOT NULL DEFAULT 1 AFTER reason");
        }
        if (!columns.contains("submitted_at")) {
            statements.add("ALTER TABLE doctor_review ADD COLUMN submitted_at TIMESTAMP NULL AFTER created_at");
        }
        if (!columns.contains("reviewed_at")) {
            statements.add("ALTER TABLE doctor_review ADD COLUMN reviewed_at TIMESTAMP NULL AFTER submitted_at");
        }
        return statements;
    }
}
