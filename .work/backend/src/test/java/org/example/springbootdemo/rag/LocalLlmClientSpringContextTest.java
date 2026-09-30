package org.example.springbootdemo.rag;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;

import static org.assertj.core.api.Assertions.assertThat;

class LocalLlmClientSpringContextTest {

    private final ApplicationContextRunner contextRunner = new ApplicationContextRunner()
            .withBean(RagSuggestionProperties.class)
            .withBean(org.example.springbootdemo.ai.HealthQuestionAiClient.class, () -> org.mockito.Mockito.mock(org.example.springbootdemo.ai.HealthQuestionAiClient.class))
            .withBean(ObjectMapper.class)
            .withBean(org.example.springbootdemo.ai.AiProviderStatus.class)
            .withBean(LocalLlmClient.class);

    @Test
    void createsLocalLlmClientBeanWithConstructorInjection() {
        contextRunner.run(context -> assertThat(context).hasSingleBean(LocalLlmClient.class));
    }
}
