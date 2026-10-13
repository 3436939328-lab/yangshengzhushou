package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.ConsultationMessage;

import java.util.List;

@Mapper
public interface ConsultationMessageDao {

    int deleteByPrimaryKey(Long id);

    int insert(ConsultationMessage record);

    int insertSelective(ConsultationMessage record);

    ConsultationMessage selectByPrimaryKey(@Param("id") Long id);

    List<ConsultationMessage> selectByConsultationId(@Param("consultationId") Long consultationId);

    int updateByPrimaryKeySelective(ConsultationMessage record);

    int updateByPrimaryKey(ConsultationMessage record);
}
