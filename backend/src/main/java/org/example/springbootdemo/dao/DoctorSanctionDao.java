package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.DoctorSanction;

import java.util.List;

@Mapper
public interface DoctorSanctionDao {
    int insertSelective(DoctorSanction record);
    int updateStatus(DoctorSanction record);
    DoctorSanction selectByPrimaryKey(@Param("id") Long id);
    List<DoctorSanction> selectByEventId(@Param("eventId") Long eventId);
    /** 查医生当前有效且未过期的处罚(用于业务拦截) */
    List<DoctorSanction> selectActiveByDoctor(@Param("doctorId") Long doctorId, @Param("now") java.util.Date now);

    /** 管理员查看医生全部处罚记录(含已过期/已撤销) */
    List<DoctorSanction> selectAllByDoctor(@Param("doctorId") Long doctorId);
}
