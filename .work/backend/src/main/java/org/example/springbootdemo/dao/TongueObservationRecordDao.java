package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.TongueObservationRecord;

import java.util.List;

@Mapper
public interface TongueObservationRecordDao {

    int insertSelective(TongueObservationRecord record);

    TongueObservationRecord selectByPrimaryKey(@Param("id") Long id);

    List<TongueObservationRecord> selectByUserId(@Param("userId") Long userId);

    int deleteByPrimaryKey(@Param("id") Long id);
}
