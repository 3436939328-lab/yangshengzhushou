package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.HealthArchive;

import java.util.List;

@Mapper
public interface HealthArchiveDao {

    int deleteByPrimaryKey(@Param("id") Long id);

    int insert(HealthArchive record);

    int insertSelective(HealthArchive record);

    HealthArchive selectByPrimaryKey(@Param("id") Long id);

    HealthArchive selectByUserId(@Param("userId") Long userId);

    List<HealthArchive> selectList();

    int updateByPrimaryKeySelective(HealthArchive record);

    int updateByPrimaryKey(HealthArchive record);
}
