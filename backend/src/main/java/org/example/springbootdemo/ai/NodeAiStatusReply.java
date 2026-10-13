package org.example.springbootdemo.ai;

public record NodeAiStatusReply(
        boolean nodeAvailable,
        String mode,
        String nodeStatus,
        String nodeBaseUrl,
        String message
) {
}
