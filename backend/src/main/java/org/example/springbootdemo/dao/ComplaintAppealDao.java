package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.ComplaintAppeal;

import java.util.List;

@Mapper
public interface ComplaintAppealDao {
    int insertSelective(ComplaintAppeal record);
    int updateStatus(ComplaintAppeal record);
    ComplaintAppeal selectByPrimaryKey(@Param("id") Long id);
    List<ComplaintAppeal> selectListForAdmin(@Param("status") String status, @Param("offset") int offset, @Param("size") int size);
    long countListForAdmin(@Param("status") String status);
    List<ComplaintAppeal> selectByDecisionId(@Param("decisionId") Long decisionId);
}
