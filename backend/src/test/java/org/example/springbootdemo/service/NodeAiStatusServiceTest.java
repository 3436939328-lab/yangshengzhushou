package org.example.springbootdemo.service;

import org.example.springbootdemo.ai.NodeAiStatusReply;
import org.example.springbootdemo.ai.NodeAssistantOrchestrationClient;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class NodeAiStatusServiceTest {

    @Test
    void statusReportsNodeAvailableWhenHealthEndpointResponds() {
        NodeAssistantOrchestrationClient nodeClient = mock(NodeAssistantOrchestrationClient.class);
        NodeAiStatusService service = new NodeAiStatusService(nodeClient);
        when(nodeClient.health()).thenReturn(Map.of("status", "ok", "service", "yangshengzhushou_db"));

        NodeAiStatusReply result = service.status();

        assertTrue(result.nodeAvailable());
        assertEquals("node-ai", result.mode());
        assertEquals("ok", result.nodeStatus());
        assertEquals("Node AI engine is available.", result.message());
        verify(nodeClient).health();
    }

    @Test
    void statusReportsFallbackModeWhenNodeHealthFails() {
        NodeAssistantOrchestrationClient nodeClient = mock(NodeAssistantOrchestrationClient.class);
        NodeAiStatusService service = new NodeAiStatusService(nodeClient);
        when(nodeClient.health()).thenThrow(new IllegalStateException("node down"));

        NodeAiStatusReply result = service.status();

        assertFalse(result.nodeAvailable());
        assertEquals("springboot-fallback", result.mode());
        assertEquals("unavailable", result.nodeStatus());
        assertEquals("Node AI engine is unavailable. Spring Boot fallback is active.", result.message());
        verify(nodeClient).health();
    }
}
