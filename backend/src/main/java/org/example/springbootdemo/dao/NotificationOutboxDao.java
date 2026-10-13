package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.NotificationOutbox;

import java.util.List;

@Mapper
public interface NotificationOutboxDao {
    int insertSelective(NotificationOutbox record);
    List<NotificationOutbox> selectPendingForRetry(@Param("limit") int limit);
    int updateStatus(@Param("id") Long id, @Param("status") String status, @Param("retryCount") Integer retryCount, @Param("nextRetryAt") java.util.Date nextRetryAt);
}
