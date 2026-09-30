package org.example.springbootdemo.config;

import org.junit.jupiter.api.Test;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.AnnotationUtils;
import org.springframework.core.annotation.Order;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class UserProfileSchemaInitializerTest {

    @Test
    void runAddsMissingUserProfileColumns() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        UserProfileSchemaInitializer initializer = new UserProfileSchemaInitializer(jdbcTemplate);

        when(jdbcTemplate.queryForObject("select database()", String.class)).thenReturn("yangsheng_db");
        when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq("yangsheng_db")))
                .thenReturn(List.of("id", "username", "password", "real_name", "phone"));

        initializer.run();

        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE sys_user ADD COLUMN email"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE sys_user ADD COLUMN birthday"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE sys_user ADD COLUMN avatar"));
    }

    @Test
    void runSkipsAlterWhenUserProfileColumnsAlreadyExist() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        UserProfileSchemaInitializer initializer = new UserProfileSchemaInitializer(jdbcTemplate);

        when(jdbcTemplate.queryForObject("select database()", String.class)).thenReturn("yangsheng_db");
        when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq("yangsheng_db")))
                .thenReturn(List.of("id", "username", "password", "real_name", "phone", "email", "birthday", "avatar"));

        initializer.run();

        verify(jdbcTemplate, never()).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE sys_user ADD COLUMN email"));
        verify(jdbcTemplate, never()).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE sys_user ADD COLUMN birthday"));
        verify(jdbcTemplate, never()).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE sys_user ADD COLUMN avatar"));
    }

    @Test
    void initializerRunsBeforeDataInitializerQueriesUsers() {
        Order order = AnnotationUtils.findAnnotation(UserProfileSchemaInitializer.class, Order.class);

        assertNotNull(order);
        assertEquals(Ordered.HIGHEST_PRECEDENCE, order.value());
    }
}
