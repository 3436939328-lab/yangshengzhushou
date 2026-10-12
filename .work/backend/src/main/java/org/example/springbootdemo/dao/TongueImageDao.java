package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.TongueImage;

import java.util.List;

@Mapper
public interface TongueImageDao {

    int insertSelective(TongueImage record);

    TongueImage selectByPrimaryKey(@Param("id") Long id);

    List<TongueImage> selectByUserId(@Param("userId") Long userId);

    int updateByPrimaryKeySelective(TongueImage record);

    int markDeleted(@Param("id") Long id);
}
