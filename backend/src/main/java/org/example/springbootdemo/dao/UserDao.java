package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.User;

import java.util.List;

@Mapper
public interface UserDao {
    int deleteByPrimaryKey(@Param("id") Long id);

    int insert(User record);

    int insertSelective(User record);

    User selectByPrimaryKey(@Param("id") Long id);

    User selectByUsername(@Param("username") String username);

    User selectByPhone(@Param("phone") String phone);

    List<User> selectList();

    int updateByPrimaryKeySelective(User record);

    int updateByPrimaryKey(User record);
}
