package org.example.springbootdemo.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * 为 consultation 表添加用户共享给医生的个人信息字段。
 * 启动时自动检测并补全缺失列，兼容已存在的数据库。
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class ConsultationSchemaInitializer implements CommandLineRunner {

    private static final String COLUMN_QUERY = """
            select column_name
            from information_schema.columns
            where table_schema = ?
              and table_name = 'consultation'
            """;

    private final JdbcTemplate jdbcTemplate;

    public ConsultationSchemaInitializer(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) {
        String schemaName = jdbcTemplate.queryForObject("select database()", String.class);
        if (schemaName == null || schemaName.isBlank()) {
            return;
        }

        Set<String> columns = new HashSet<>(jdbcTemplate.queryForList(COLUMN_QUERY, String.class, schemaName));
        for (ColumnStatement statement : buildColumnStatements()) {
            if (!columns.contains(statement.columnName())) {
                jdbcTemplate.execute(statement.sql());
            }
        }
    }

    private List<ColumnStatement> buildColumnStatements() {
        return List.of(
                new ColumnStatement("shared_name", "ALTER TABLE consultation ADD COLUMN shared_name VARCHAR(100) NULL AFTER create_time"),
                new ColumnStatement("shared_age", "ALTER TABLE consultation ADD COLUMN shared_age INT NULL AFTER shared_name"),
                new ColumnStatement("shared_gender", "ALTER TABLE consultation ADD COLUMN shared_gender VARCHAR(20) NULL AFTER shared_age"),
                new ColumnStatement("shared_phone", "ALTER TABLE consultation ADD COLUMN shared_phone VARCHAR(50) NULL AFTER shared_gender")
        );
    }

    private record ColumnStatement(String columnName, String sql) {
    }
}
