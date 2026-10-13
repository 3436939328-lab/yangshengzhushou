package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.ComplaintDecision;

import java.util.List;

@Mapper
public interface ComplaintDecisionDao {
    int insertSelective(ComplaintDecision record);
    List<ComplaintDecision> selectByEventId(@Param("eventId") Long eventId);
    ComplaintDecision selectByPrimaryKey(@Param("id") Long id);
}
