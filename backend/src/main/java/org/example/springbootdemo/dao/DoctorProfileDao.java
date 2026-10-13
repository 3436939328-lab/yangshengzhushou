package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.DoctorProfile;

import java.util.List;

@Mapper
public interface DoctorProfileDao {

    int deleteByPrimaryKey(Long id);

    int insert(DoctorProfile record);

    int insertSelective(DoctorProfile record);

    DoctorProfile selectByPrimaryKey(@Param("id") Long id);

    DoctorProfile selectByUserId(@Param("userId") Long userId);

    List<DoctorProfile> selectList();

    int updateByPrimaryKeySelective(DoctorProfile record);

    int updateByPrimaryKey(DoctorProfile record);
}
