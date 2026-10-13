package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.Complaint;

import java.util.List;

@Mapper
public interface ComplaintDao {
    int insertSelective(Complaint record);
    int updateStatus(Complaint record);
    Complaint selectByPrimaryKey(@Param("id") Long id);
    List<Complaint> selectByReporterId(@Param("reporterId") Long reporterId);
    List<Complaint> selectByEventId(@Param("eventId") Long eventId);
    List<Complaint> selectListForAdmin(@Param("status") String status, @Param("doctorId") Long doctorId, @Param("offset") int offset, @Param("size") int size);
    long countListForAdmin(@Param("status") String status, @Param("doctorId") Long doctorId);
    List<Complaint> selectByDoctorId(@Param("doctorId") Long doctorId);
}
