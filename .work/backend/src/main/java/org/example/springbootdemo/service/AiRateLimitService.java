package org.example.springbootdemo.service;

import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.LocalDate;
import java.util.ArrayDeque;
import java.util.HashMap;
import java.util.Map;
import java.util.Queue;

@Service
public class AiRateLimitService {

    private static final int MAX_REQUESTS_PER_MINUTE = 5;
    private static final int MAX_REQUESTS_PER_DAY = 100;
    private static final long ONE_MINUTE_MILLIS = 60_000L;

    private final Clock clock;
    private final Map<String, Queue<Long>> minuteRequests = new HashMap<>();
    private final Map<String, DailyCounter> dailyRequests = new HashMap<>();

    public AiRateLimitService() {
        this(Clock.systemDefaultZone());
    }

    AiRateLimitService(Clock clock) {
        this.clock = clock;
    }

    public synchronized boolean tryAcquire(Long userId, String endpointKey) {
        String key = buildKey(userId, endpointKey);
        long now = clock.millis();
        if (!tryAcquireMinute(key, now)) {
            return false;
        }
        if (!tryAcquireDaily(key)) {
            Queue<Long> minuteQueue = minuteRequests.get(key);
            if (minuteQueue != null && !minuteQueue.isEmpty()) {
                minuteQueue.remove(now);
            }
            return false;
        }
        return true;
    }

    private boolean tryAcquireMinute(String key, long now) {
        Queue<Long> queue = minuteRequests.computeIfAbsent(key, ignored -> new ArrayDeque<>());
        while (!queue.isEmpty() && now - queue.peek() >= ONE_MINUTE_MILLIS) {
            queue.poll();
        }
        if (queue.size() >= MAX_REQUESTS_PER_MINUTE) {
            return false;
        }
        queue.add(now);
        return true;
    }

    private boolean tryAcquireDaily(String key) {
        LocalDate today = LocalDate.now(clock);
        DailyCounter counter = dailyRequests.get(key);
        if (counter == null || !counter.date.equals(today)) {
            counter = new DailyCounter(today, 0);
            dailyRequests.put(key, counter);
        }
        if (counter.count >= MAX_REQUESTS_PER_DAY) {
            return false;
        }
        counter.count++;
        return true;
    }

    private String buildKey(Long userId, String endpointKey) {
        String userKey = userId == null ? "anonymous" : String.valueOf(userId);
        return endpointKey + ":" + userKey;
    }

    private static class DailyCounter {
        private final LocalDate date;
        private int count;

        private DailyCounter(LocalDate date, int count) {
            this.date = date;
            this.count = count;
        }
    }
}