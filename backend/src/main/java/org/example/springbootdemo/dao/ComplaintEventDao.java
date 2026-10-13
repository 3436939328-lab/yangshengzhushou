package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.ComplaintEvent;

@Mapper
public interface ComplaintEventDao {
    int insertSelective(ComplaintEvent record);
    ComplaintEvent selectByPrimaryKey(@Param("id") Long id);
    ComplaintEvent selectByConsultationIdAndDoctor(@Param("consultationId") Long consultationId, @Param("doctorId") Long doctorId);
    int updateEffectiveDecision(ComplaintEvent record);
}
