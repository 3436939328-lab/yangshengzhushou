package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.IdempotentRequest;
import org.example.springbootdemo.dao.IdempotentRequestDao;
import org.springframework.stereotype.Service;

import java.util.Date;

/**
 * 幂等键校验：相同 (actor, action, key) 返回同一 result_ref；
 * 相同 key 不同 request_hash 抛 IllegalStateException(409)
 */
@Service
public class IdempotencyService {

    private final IdempotentRequestDao idempotentRequestDao;

    public IdempotencyService(IdempotentRequestDao idempotentRequestDao) {
        this.idempotentRequestDao = idempotentRequestDao;
    }

    /**
     * 返回 result_ref：null 表示首次请求需执行；非 null 表示已有结果可直接返回；
     * 抛 IllegalStateException 表示 key 相同但请求体不同(409)
     */
    public String checkOrRecord(Long actorId, String action, String key, String requestHash) {
        IdempotentRequest existing = idempotentRequestDao.selectByActorActionKey(actorId, action, key);
        if (existing != null) {
            if (requestHash != null && existing.getRequestHash() != null
                    && !requestHash.equals(existing.getRequestHash())) {
                throw new IllegalStateException("idempotency key conflict: same key different body");
            }
            return existing.getResultRef();
        }
        IdempotentRequest record = new IdempotentRequest();
        record.setActorId(actorId);
        record.setAction(action);
        record.setKey(key);
        record.setRequestHash(requestHash);
        record.setStatus(IdempotentRequest.STATUS_PENDING);
        Date now = new Date();
        Date expires = new Date(now.getTime() + 24L * 60 * 60 * 1000);
        record.setExpiresAt(expires);
        record.setCreatedAt(now);
        idempotentRequestDao.insertIfAbsent(record);
        return null;
    }

    public void recordResult(Long actorId, String action, String key, String resultRef) {
        IdempotentRequest existing = idempotentRequestDao.selectByActorActionKey(actorId, action, key);
        if (existing != null) {
            idempotentRequestDao.updateResult(existing.getId(), resultRef, IdempotentRequest.STATUS_DONE);
        }
    }
}
