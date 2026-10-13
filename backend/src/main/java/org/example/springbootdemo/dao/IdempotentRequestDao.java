package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.IdempotentRequest;

@Mapper
public interface IdempotentRequestDao {
    /** INSERT IGNORE 依赖 unique(actor_id, action, key) 防并发 */
    int insertIfAbsent(IdempotentRequest record);
    IdempotentRequest selectByActorActionKey(@Param("actorId") Long actorId, @Param("action") String action, @Param("key") String key);
    int updateResult(@Param("id") Long id, @Param("resultRef") String resultRef, @Param("status") String status);
}
