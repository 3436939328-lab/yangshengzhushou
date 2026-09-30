package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.Role;

import java.util.List;

@Mapper
public interface RoleDao {
    int deleteByPrimaryKey(@Param("id") Long id);

    int insert(Role record);

    int insertSelective(Role record);

    Role selectByPrimaryKey(@Param("id") Long id);

    Role selectByCode(@Param("roleCode") String roleCode);

    List<Role> selectList();

    List<Role> selectRolesByUserId(@Param("userId") Long userId);

    int updateByPrimaryKeySelective(Role record);

    int updateByPrimaryKey(Role record);
}
