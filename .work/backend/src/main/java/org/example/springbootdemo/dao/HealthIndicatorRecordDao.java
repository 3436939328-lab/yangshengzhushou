package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.HealthIndicatorRecord;

import java.util.List;

@Mapper
public interface HealthIndicatorRecordDao {

    int insertSelective(HealthIndicatorRecord record);

    HealthIndicatorRecord selectByPrimaryKey(@Param("id") Long id);

    List<HealthIndicatorRecord> selectByUserId(@Param("userId") Long userId);

    int deleteByPrimaryKey(@Param("id") Long id);
}
