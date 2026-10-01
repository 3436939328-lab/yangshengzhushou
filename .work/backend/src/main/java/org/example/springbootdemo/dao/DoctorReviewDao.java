package org.example.springbootdemo.dao;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.example.springbootdemo.bean.DoctorReview;

import java.util.List;

@Mapper
public interface DoctorReviewDao {

    int insertSelective(DoctorReview record);

    int updateStatus(DoctorReview record);

    DoctorReview selectByPrimaryKey(@Param("id") Long id);

    /** 按版本倒序取该医生全部审核记录 */
    List<DoctorReview> selectByDoctorUserIdOrderByVersionDesc(@Param("doctorUserId") Long doctorUserId);

    /** 取该医生最新一条审核记录 */
    DoctorReview selectLatestByDoctorUserId(@Param("doctorUserId") Long doctorUserId);

    /** 管理员审核队列：按状态筛选，分页倒序 */
    List<DoctorReview> selectListForAdmin(@Param("status") String status, @Param("offset") int offset, @Param("size") int size);

    /** 队列总数 */
    long countListForAdmin(@Param("status") String status);

    /** 管理员取最近 PENDING/NEED_INFO 记录用于决策 */
    DoctorReview selectPendingByDoctorUserId(@Param("doctorUserId") Long doctorUserId);
}
