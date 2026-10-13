package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.TongueImageRecord;

import java.util.List;

@Mapper
public interface TongueImageRecordDao {

    int insertSelective(TongueImageRecord record);

    TongueImageRecord selectByPrimaryKey(@Param("id") Long id);

    List<TongueImageRecord> selectByUserId(@Param("userId") Long userId);

    List<TongueImageRecord> selectByUserIdWithLimit(@Param("userId") Long userId, @Param("limit") int limit);

    int updateByPrimaryKeySelective(TongueImageRecord record);

    int logicalDeleteByPrimaryKey(@Param("id") Long id);
}
