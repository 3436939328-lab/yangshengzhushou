package org.example.springbootdemo.config;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DoctorProfileSchemaInitializerTest {

    @Test
    void runAddsMissingDoctorProfileColumns() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        DoctorProfileSchemaInitializer initializer = new DoctorProfileSchemaInitializer(jdbcTemplate);

        when(jdbcTemplate.queryForObject("select database()", String.class)).thenReturn("yangsheng_db");
        when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq("yangsheng_db")))
                .thenReturn(List.of("id", "user_id"));

        initializer.run();

        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.contains("CREATE TABLE IF NOT EXISTS doctor_profile"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE doctor_profile ADD COLUMN doctor_name"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE doctor_profile ADD COLUMN title"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE doctor_profile ADD COLUMN specialty"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE doctor_profile ADD COLUMN introduction"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE doctor_profile ADD COLUMN create_time"));
    }

    @Test
    void runSkipsAlterWhenColumnsAlreadyExist() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        DoctorProfileSchemaInitializer initializer = new DoctorProfileSchemaInitializer(jdbcTemplate);

        when(jdbcTemplate.queryForObject("select database()", String.class)).thenReturn("yangsheng_db");
        when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq("yangsheng_db")))
                .thenReturn(List.of("id", "user_id", "doctor_name", "title", "specialty", "introduction", "create_time"));

        initializer.run();

        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.contains("CREATE TABLE IF NOT EXISTS doctor_profile"));
        verify(jdbcTemplate, never()).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE doctor_profile ADD COLUMN doctor_name"));
        verify(jdbcTemplate, never()).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE doctor_profile ADD COLUMN title"));
        verify(jdbcTemplate, never()).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE doctor_profile ADD COLUMN specialty"));
        verify(jdbcTemplate, never()).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE doctor_profile ADD COLUMN introduction"));
        verify(jdbcTemplate, never()).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE doctor_profile ADD COLUMN create_time"));
    }
}
