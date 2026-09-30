package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.HealthQuestion;

import java.util.List;

@Mapper
public interface HealthQuestionDao {

    int deleteByPrimaryKey(Long id);

    int insert(HealthQuestion record);

    int insertSelective(HealthQuestion record);

    HealthQuestion selectByPrimaryKey(@Param("id") Long id);

    List<HealthQuestion> selectList();

    List<HealthQuestion> selectListByUserId(@Param("userId") Long userId);

    int updateByPrimaryKeySelective(HealthQuestion record);

    int updateByPrimaryKey(HealthQuestion record);
}
