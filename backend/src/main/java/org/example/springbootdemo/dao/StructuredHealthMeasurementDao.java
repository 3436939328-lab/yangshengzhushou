package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.StructuredHealthMeasurement;

import java.util.List;

@Mapper
public interface StructuredHealthMeasurementDao {

    int insertSelective(StructuredHealthMeasurement record);

    StructuredHealthMeasurement selectByPrimaryKey(@Param("id") Long id);

    List<StructuredHealthMeasurement> selectByUserId(@Param("userId") Long userId);

    List<StructuredHealthMeasurement> selectByUserIdAndMetric(
            @Param("userId") Long userId,
            @Param("metricCode") String metricCode);

    List<StructuredHealthMeasurement> selectByUserIdWithLimit(
            @Param("userId") Long userId,
            @Param("metricCode") String metricCode,
            @Param("limit") int limit);

    StructuredHealthMeasurement selectLatestByUserIdAndMetric(
            @Param("userId") Long userId,
            @Param("metricCode") String metricCode);

    int updateByPrimaryKeySelective(StructuredHealthMeasurement record);

    int deleteByPrimaryKey(@Param("id") Long id);

    int logicalDeleteByPrimaryKey(@Param("id") Long id);
}
