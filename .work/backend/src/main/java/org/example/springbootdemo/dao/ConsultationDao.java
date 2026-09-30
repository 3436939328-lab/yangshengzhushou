package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.Consultation;

import java.util.List;

@Mapper
public interface ConsultationDao {

    int deleteByPrimaryKey(Long id);

    int insert(Consultation record);

    int insertSelective(Consultation record);

    Consultation selectByPrimaryKey(@Param("id") Long id);

    List<Consultation> selectList();

    List<Consultation> selectListByFilter(@Param("userId") Long userId, @Param("doctorId") Long doctorId);

    int updateByPrimaryKeySelective(Consultation record);

    int updateByPrimaryKey(Consultation record);
}
