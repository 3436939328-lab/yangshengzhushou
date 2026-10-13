package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.InboxNotification;
import org.example.springbootdemo.bean.NotificationOutbox;
import org.example.springbootdemo.dao.InboxNotificationDao;
import org.example.springbootdemo.dao.NotificationOutboxDao;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);
    private static final int MAX_RETRY = 5;

    private final NotificationOutboxDao notificationOutboxDao;
    private final InboxNotificationDao inboxNotificationDao;

    public NotificationService(NotificationOutboxDao notificationOutboxDao, InboxNotificationDao inboxNotificationDao) {
        this.notificationOutboxDao = notificationOutboxDao;
        this.inboxNotificationDao = inboxNotificationDao;
    }

    /** 事务内写 outbox（与业务变更同事务提交） */
    @Transactional
    public void writeOutbox(String eventKey, Long recipientId, String type, String title, String body) {
        NotificationOutbox outbox = new NotificationOutbox();
        outbox.setEventKey(eventKey);
        outbox.setRecipientId(recipientId);
        outbox.setType(type);
        outbox.setTitle(title);
        outbox.setBody(body);
        outbox.setStatus(NotificationOutbox.STATUS_PENDING);
        outbox.setRetryCount(0);
        outbox.setCreatedAt(new Date());
        notificationOutboxDao.insertSelective(outbox);
    }

    /** 调度调用：拉 PENDING → 写 inbox → 标 DELIVERED；失败累计重试超限标 FAILED */
    @Transactional
    public void flushOutbox(int limit) {
        List<NotificationOutbox> pending = notificationOutboxDao.selectPendingForRetry(limit);
        for (NotificationOutbox ob : pending) {
            try {
                InboxNotification inbox = new InboxNotification();
                inbox.setRecipientId(ob.getRecipientId());
                inbox.setEventKey(ob.getEventKey());
                inbox.setTitle(ob.getTitle());
                inbox.setBody(ob.getBody());
                inbox.setCreatedAt(new Date());
                inboxNotificationDao.insertSelective(inbox);
                notificationOutboxDao.updateStatus(ob.getId(), NotificationOutbox.STATUS_DELIVERED, ob.getRetryCount(), null);
            } catch (Exception ex) {
                log.warn("deliver outbox {} failed: {}", ob.getId(), ex.getMessage());
                int retry = (ob.getRetryCount() == null ? 0 : ob.getRetryCount()) + 1;
                if (retry >= MAX_RETRY) {
                    notificationOutboxDao.updateStatus(ob.getId(), NotificationOutbox.STATUS_FAILED, retry, null);
                } else {
                    Date next = new Date(new Date().getTime() + 60L * 1000 * retry);
                    notificationOutboxDao.updateStatus(ob.getId(), NotificationOutbox.STATUS_PENDING, retry, next);
                }
            }
        }
    }

    public Map<String, Object> getInboxByRecipient(Long recipientId) {
        List<InboxNotification> items = inboxNotificationDao.selectByRecipientId(recipientId);
        Map<String, Object> data = new HashMap<>();
        data.put("items", items);
        return data;
    }

    @Transactional
    public boolean markRead(Long id) {
        return inboxNotificationDao.updateReadAt(id, new Date()) > 0;
    }
}
