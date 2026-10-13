package org.example.springbootdemo.config;

import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;

class ProductionLoggingConfigTest {

    @Test
    void productionProfileDefinesRollingAppAndErrorLogs() throws Exception {
        ClassPathResource prodConfig = new ClassPathResource("application-prod.yml");
        ClassPathResource logbackConfig = new ClassPathResource("logback-spring.xml");

        assertThat(prodConfig.exists()).isTrue();
        assertThat(logbackConfig.exists()).isTrue();

        String prodYaml = prodConfig.getContentAsString(StandardCharsets.UTF_8);
        String logbackXml = logbackConfig.getContentAsString(StandardCharsets.UTF_8);

        assertThat(prodYaml).contains("root: info");
        assertThat(prodYaml).contains("org.example.springbootdemo: info");
        assertThat(prodYaml).contains("org.springframework: warn");

        assertThat(logbackXml).contains("springProfile name=\"prod\"");
        assertThat(logbackXml).contains("ruange-app.log");
        assertThat(logbackXml).contains("ruange-error.log");
        assertThat(logbackXml).contains("ThresholdFilter");
        assertThat(logbackXml).contains("<level>ERROR</level>");
        assertThat(logbackXml).contains("<maxHistory>30</maxHistory>");
    }
}
