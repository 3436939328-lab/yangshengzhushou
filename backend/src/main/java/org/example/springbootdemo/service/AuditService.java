package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.AdminAuditLog;
import org.example.springbootdemo.dao.AdminAuditLogDao;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class AuditService {

    private final AdminAuditLogDao adminAuditLogDao;

    public AuditService(AdminAuditLogDao adminAuditLogDao) {
        this.adminAuditLogDao = adminAuditLogDao;
    }

    public void appendAudit(Long actorId, String action, String targetType, Long targetId, String summary, String reason, String result, String requestId) {
        AdminAuditLog log = new AdminAuditLog();
        log.setActorId(actorId);
        log.setAction(action);
        log.setTargetType(targetType);
        log.setTargetId(targetId);
        log.setSummary(summary);
        log.setReason(reason);
        log.setResult(result);
        log.setRequestId(requestId);
        log.setCreatedAt(new Date());
        adminAuditLogDao.insertSelective(log);
    }

    public Map<String, Object> listAudit(String targetType, Long actorId, int page, int size) {
        if (page < 1) page = 1;
        if (size < 1 || size > 100) size = 20;
        long total = adminAuditLogDao.countListByFilter(targetType, actorId);
        List<AdminAuditLog> items = adminAuditLogDao.selectListByFilter(targetType, actorId, (page - 1) * size, size);
        Map<String, Object> data = new HashMap<>();
        data.put("items", items);
        data.put("page", page);
        data.put("pageSize", size);
        data.put("total", total);
        return data;
    }
}
