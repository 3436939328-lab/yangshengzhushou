package org.example.springbootdemo.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class UserProfileSchemaInitializer implements CommandLineRunner {

    private static final String COLUMN_QUERY = """
            select column_name
            from information_schema.columns
            where table_schema = ?
              and table_name = 'sys_user'
            """;

    private final JdbcTemplate jdbcTemplate;

    public UserProfileSchemaInitializer(JdbcTemplate jdbcTemplate) {
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
                new ColumnStatement("email", "ALTER TABLE sys_user ADD COLUMN email VARCHAR(100) NULL AFTER phone"),
                new ColumnStatement("birthday", "ALTER TABLE sys_user ADD COLUMN birthday VARCHAR(20) NULL AFTER email"),
                new ColumnStatement("avatar", "ALTER TABLE sys_user ADD COLUMN avatar LONGTEXT NULL AFTER birthday")
        );
    }

    private record ColumnStatement(String columnName, String sql) {
    }
}
