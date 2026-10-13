package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.AdminAuditLog;

import java.util.List;

@Mapper
public interface AdminAuditLogDao {
    int insertSelective(AdminAuditLog record);
    List<AdminAuditLog> selectListByFilter(@Param("targetType") String targetType, @Param("actorId") Long actorId, @Param("offset") int offset, @Param("size") int size);
    long countListByFilter(@Param("targetType") String targetType, @Param("actorId") Long actorId);
}
