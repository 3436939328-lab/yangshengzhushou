package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.AdminPermission;

import java.util.List;

@Mapper
public interface AdminPermissionDao {
    int insertSelective(AdminPermission record);
    List<AdminPermission> selectByAdminUserId(@Param("adminUserId") Long adminUserId);
}
