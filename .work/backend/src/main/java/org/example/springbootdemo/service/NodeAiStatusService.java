package org.example.springbootdemo.service;

import org.example.springbootdemo.ai.NodeAiStatusReply;
import org.example.springbootdemo.ai.NodeAssistantOrchestrationClient;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class NodeAiStatusService {

    private final NodeAssistantOrchestrationClient nodeClient;

    public NodeAiStatusService(NodeAssistantOrchestrationClient nodeClient) {
        this.nodeClient = nodeClient;
    }

    public NodeAiStatusReply status() {
        try {
            Map<String, Object> health = nodeClient.health();
            return new NodeAiStatusReply(
                    true,
                    "node-ai",
                    readStatus(health),
                    nodeClient.getBaseUrl(),
                    "Node AI engine is available."
            );
        } catch (RuntimeException exception) {
            return new NodeAiStatusReply(
                    false,
                    "springboot-fallback",
                    "unavailable",
                    nodeClient.getBaseUrl(),
                    "Node AI engine is unavailable. Spring Boot fallback is active."
            );
        }
    }

    private String readStatus(Map<String, Object> health) {
        if (health == null || health.get("status") == null) {
            return "unknown";
        }
        String status = String.valueOf(health.get("status")).trim();
        return status.isEmpty() ? "unknown" : status;
    }
}
