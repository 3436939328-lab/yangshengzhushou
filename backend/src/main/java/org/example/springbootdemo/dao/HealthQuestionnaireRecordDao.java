package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.HealthQuestionnaireRecord;

import java.util.List;

@Mapper
public interface HealthQuestionnaireRecordDao {

    int insertSelective(HealthQuestionnaireRecord record);

    List<HealthQuestionnaireRecord> selectByUserId(@Param("userId") Long userId);
}
