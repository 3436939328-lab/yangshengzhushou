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

class HealthDetailSchemaInitializerTest {

    @Test
    void runAddsMissingHealthDetailColumnsForExistingTables() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        HealthDetailSchemaInitializer initializer = new HealthDetailSchemaInitializer(jdbcTemplate);

        when(jdbcTemplate.queryForObject("select database()", String.class)).thenReturn("yangsheng_db");
        when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq("yangsheng_db"), eq("health_questionnaire_record")))
                .thenReturn(List.of("id", "user_id"));
        when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq("yangsheng_db"), eq("health_indicator_record")))
                .thenReturn(List.of("id", "user_id", "indicator_type", "indicator_name", "indicator_value", "measured_at"));
        when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq("yangsheng_db"), eq("tongue_observation_record")))
                .thenReturn(List.of("id", "user_id"));

        initializer.run();

        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record ADD COLUMN name"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record ADD COLUMN value"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record ADD COLUMN unit"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record ADD COLUMN recorded_at"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record MODIFY COLUMN recorded_at"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record MODIFY COLUMN indicator_type"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record MODIFY COLUMN indicator_name"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record MODIFY COLUMN indicator_value"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record MODIFY COLUMN measured_at"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE tongue_observation_record ADD COLUMN color"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE tongue_observation_record MODIFY COLUMN recorded_at"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_questionnaire_record ADD COLUMN constitution_type"));
    }

    @Test
    void runSkipsAlterWhenHealthDetailColumnsAlreadyExist() {
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        HealthDetailSchemaInitializer initializer = new HealthDetailSchemaInitializer(jdbcTemplate);

        when(jdbcTemplate.queryForObject("select database()", String.class)).thenReturn("yangsheng_db");
        when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq("yangsheng_db"), eq("health_questionnaire_record")))
                .thenReturn(List.of("id", "user_id", "constitution_type", "total_score", "suggestion", "answers_json", "create_time"));
        when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq("yangsheng_db"), eq("health_indicator_record")))
                .thenReturn(List.of("id", "user_id", "indicator_type", "indicator_name", "indicator_value", "measured_at", "name", "value", "unit", "recorded_at", "create_time"));
        when(jdbcTemplate.queryForList(anyString(), eq(String.class), eq("yangsheng_db"), eq("tongue_observation_record")))
                .thenReturn(List.of("id", "user_id", "color", "coating", "dryness", "note", "recorded_at", "create_time"));

        initializer.run();

        verify(jdbcTemplate, never()).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record ADD COLUMN name"));
        verify(jdbcTemplate, never()).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE tongue_observation_record ADD COLUMN color"));
        verify(jdbcTemplate, never()).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_questionnaire_record ADD COLUMN constitution_type"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record MODIFY COLUMN recorded_at"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record MODIFY COLUMN indicator_type"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record MODIFY COLUMN indicator_name"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record MODIFY COLUMN indicator_value"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE health_indicator_record MODIFY COLUMN measured_at"));
        verify(jdbcTemplate).execute(org.mockito.ArgumentMatchers.startsWith("ALTER TABLE tongue_observation_record MODIFY COLUMN recorded_at"));
    }
}
