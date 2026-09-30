package org.example.springbootdemo.auth;

import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class VerificationCodeService {

    private static final int CODE_BOUND = 1_000_000;
    private static final long CODE_TTL_MINUTES = 5;

    private final SecureRandom secureRandom = new SecureRandom();
    private final Map<String, VerificationCode> codes = new ConcurrentHashMap<>();
    private final Clock clock;

    public VerificationCodeService() {
        this(Clock.systemUTC());
    }

    VerificationCodeService(Clock clock) {
        this.clock = clock;
    }

    public String generate(String purpose, String phone) {
        String code = String.format("%06d", secureRandom.nextInt(CODE_BOUND));
        codes.put(key(purpose, phone), new VerificationCode(code, Instant.now(clock).plus(CODE_TTL_MINUTES, ChronoUnit.MINUTES)));
        return code;
    }

    public boolean verify(String purpose, String phone, String code) {
        VerificationCode stored = codes.get(key(purpose, phone));
        return stored != null
                && !stored.expiresAt().isBefore(Instant.now(clock))
                && stored.code().equals(code);
    }

    public boolean consume(String purpose, String phone, String code) {
        String key = key(purpose, phone);
        if (!verify(purpose, phone, code)) {
            return false;
        }
        codes.remove(key);
        return true;
    }

    private String key(String purpose, String phone) {
        return normalize(purpose) + ":" + normalize(phone);
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toUpperCase();
    }

    private record VerificationCode(String code, Instant expiresAt) {}
}
