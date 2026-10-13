package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.InboxNotification;

import java.util.List;

@Mapper
public interface InboxNotificationDao {
    int insertSelective(InboxNotification record);
    List<InboxNotification> selectByRecipientId(@Param("recipientId") Long recipientId);
    int updateReadAt(@Param("id") Long id, @Param("readAt") java.util.Date readAt);
}
