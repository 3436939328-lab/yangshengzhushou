package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.ComplaintEvidence;

import java.util.List;

@Mapper
public interface ComplaintEvidenceDao {
    int insertSelective(ComplaintEvidence record);
    List<ComplaintEvidence> selectByComplaintId(@Param("complaintId") Long complaintId);
    ComplaintEvidence selectByPrimaryKey(@Param("id") Long id);
}
