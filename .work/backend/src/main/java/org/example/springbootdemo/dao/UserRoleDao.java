package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.UserRole;

import java.util.List;

@Mapper
public interface UserRoleDao {
    int deleteByPrimaryKey(@Param("id") Long id);

    int insert(UserRole record);

    int insertSelective(UserRole record);

    UserRole selectByPrimaryKey(@Param("id") Long id);

    List<UserRole> selectList();

    int updateByPrimaryKeySelective(UserRole record);

    int updateByPrimaryKey(UserRole record);
}
