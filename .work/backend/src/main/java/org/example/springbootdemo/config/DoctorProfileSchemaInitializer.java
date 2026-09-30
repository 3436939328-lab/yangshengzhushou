package org.example.springbootdemo.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Component
public class DoctorProfileSchemaInitializer implements CommandLineRunner {

    private static final String CREATE_TABLE_SQL = """
            CREATE TABLE IF NOT EXISTS doctor_profile (
              id BIGINT PRIMARY KEY AUTO_INCREMENT,
              user_id BIGINT NOT NULL,
              doctor_name VARCHAR(50) NOT NULL,
              title VARCHAR(50) NULL,
              specialty VARCHAR(100) NULL,
              introduction VARCHAR(1000) NULL,
              create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
              UNIQUE KEY uk_doctor_profile_user (user_id),
              CONSTRAINT fk_doctor_profile_user FOREIGN KEY (user_id) REFERENCES sys_user(id)
            )
            """;

    private final JdbcTemplate jdbcTemplate;

    public DoctorProfileSchemaInitializer(JdbcTemplate jdbcTemplate) {
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
                          and table_name = 'doctor_profile'
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
        if (!columns.contains("doctor_name")) {
            statements.add("ALTER TABLE doctor_profile ADD COLUMN doctor_name VARCHAR(50) NULL AFTER user_id");
        }
        if (!columns.contains("title")) {
            statements.add("ALTER TABLE doctor_profile ADD COLUMN title VARCHAR(50) NULL AFTER doctor_name");
        }
        if (!columns.contains("specialty")) {
            statements.add("ALTER TABLE doctor_profile ADD COLUMN specialty VARCHAR(100) NULL AFTER title");
        }
        if (!columns.contains("introduction")) {
            statements.add("ALTER TABLE doctor_profile ADD COLUMN introduction VARCHAR(1000) NULL AFTER specialty");
        }
        if (!columns.contains("create_time")) {
            statements.add("ALTER TABLE doctor_profile ADD COLUMN create_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP AFTER introduction");
        }
        return statements;
    }
}
