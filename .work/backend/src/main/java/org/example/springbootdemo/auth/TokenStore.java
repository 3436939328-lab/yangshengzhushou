package org.example.springbootdemo.auth;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.Base64;

@Component
public class TokenStore {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final String TOKEN_SEPARATOR = ".";

    private final String tokenSecret;
    private final long ttlSeconds;

    public TokenStore(
            @Value("${app.auth.token-secret:${AUTH_TOKEN_SECRET:dev-change-me-token-secret}}") String tokenSecret,
            @Value("${app.auth.token-ttl-seconds:${AUTH_TOKEN_TTL_SECONDS:604800}}") long ttlSeconds
    ) {
        this.tokenSecret = tokenSecret;
        this.ttlSeconds = ttlSeconds;
    }

    public String createToken(Long userId) {
        if (userId == null) {
            throw new IllegalArgumentException("userId is required");
        }
        long expiresAt = Instant.now().getEpochSecond() + ttlSeconds;
        String payload = userId + ":" + expiresAt;
        return base64Url(payload) + TOKEN_SEPARATOR + signature(payload);
    }

    public boolean isValid(String token) {
        TokenPayload payload = parse(token);
        return payload != null && payload.expiresAt() >= Instant.now().getEpochSecond();
    }

    public Long getUserId(String token) {
        TokenPayload payload = parse(token);
        if (payload == null || payload.expiresAt() < Instant.now().getEpochSecond()) {
            return null;
        }
        return payload.userId();
    }

    private TokenPayload parse(String token) {
        if (token == null || token.trim().isEmpty()) {
            return null;
        }
        String[] parts = token.split("\\.", -1);
        if (parts.length != 2 || parts[0].isEmpty() || parts[1].isEmpty()) {
            return null;
        }
        try {
            String payload = new String(Base64.getUrlDecoder().decode(parts[0]), StandardCharsets.UTF_8);
            String expectedSignature = signature(payload);
            if (!MessageDigest.isEqual(expectedSignature.getBytes(StandardCharsets.UTF_8), parts[1].getBytes(StandardCharsets.UTF_8))) {
                return null;
            }
            String[] payloadParts = payload.split(":", -1);
            if (payloadParts.length != 2) {
                return null;
            }
            return new TokenPayload(Long.parseLong(payloadParts[0]), Long.parseLong(payloadParts[1]));
        } catch (RuntimeException exception) {
            return null;
        }
    }

    private String signature(String payload) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(tokenSecret.getBytes(StandardCharsets.UTF_8), HMAC_ALGORITHM));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception exception) {
            throw new IllegalStateException("token signing failed", exception);
        }
    }

    private String base64Url(String value) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(value.getBytes(StandardCharsets.UTF_8));
    }

    private record TokenPayload(Long userId, long expiresAt) {}
}
