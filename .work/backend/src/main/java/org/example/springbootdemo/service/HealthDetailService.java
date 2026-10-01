package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.HealthDetailBundle;
import org.example.springbootdemo.bean.HealthIndicatorRecord;
import org.example.springbootdemo.bean.HealthQuestionnaireRecord;
import org.example.springbootdemo.bean.TongueObservationRecord;
import org.example.springbootdemo.dao.HealthIndicatorRecordDao;
import org.example.springbootdemo.dao.HealthQuestionnaireRecordDao;
import org.example.springbootdemo.dao.TongueObservationRecordDao;
import org.springframework.stereotype.Service;

import java.util.Date;

@Service
public class HealthDetailService {

    private final HealthQuestionnaireRecordDao questionnaireRecordDao;
    private final HealthIndicatorRecordDao indicatorRecordDao;
    private final TongueObservationRecordDao tongueObservationRecordDao;

    public HealthDetailService(
            HealthQuestionnaireRecordDao questionnaireRecordDao,
            HealthIndicatorRecordDao indicatorRecordDao,
            TongueObservationRecordDao tongueObservationRecordDao) {
        this.questionnaireRecordDao = questionnaireRecordDao;
        this.indicatorRecordDao = indicatorRecordDao;
        this.tongueObservationRecordDao = tongueObservationRecordDao;
    }

    public HealthDetailBundle getDetailsByUserId(Long userId) {
        return new HealthDetailBundle(
                questionnaireRecordDao.selectByUserId(userId),
                indicatorRecordDao.selectByUserId(userId),
                tongueObservationRecordDao.selectByUserId(userId)
        );
    }

    public java.util.List<HealthIndicatorRecord> getIndicatorRecordsByUserId(Long userId) {
        return indicatorRecordDao.selectByUserId(userId);
    }

    public HealthQuestionnaireRecord addQuestionnaireRecord(HealthQuestionnaireRecord record) {
        if (record.getCreateTime() == null) {
            record.setCreateTime(new Date());
        }
        questionnaireRecordDao.insertSelective(record);
        return record;
    }

    public HealthIndicatorRecord addHealthIndicator(HealthIndicatorRecord record) {
        if (record.getCreateTime() == null) {
            record.setCreateTime(new Date());
        }
        indicatorRecordDao.insertSelective(record);
        return record;
    }

    public TongueObservationRecord addTongueObservation(TongueObservationRecord record) {
        if (record.getCreateTime() == null) {
            record.setCreateTime(new Date());
        }
        tongueObservationRecordDao.insertSelective(record);
        return record;
    }

    public HealthIndicatorRecord getHealthIndicatorById(Long id) {
        return indicatorRecordDao.selectByPrimaryKey(id);
    }

    public TongueObservationRecord getTongueObservationById(Long id) {
        return tongueObservationRecordDao.selectByPrimaryKey(id);
    }

    public int deleteHealthIndicator(Long id) {
        return indicatorRecordDao.deleteByPrimaryKey(id);
    }

    public int deleteTongueObservation(Long id) {
        return tongueObservationRecordDao.deleteByPrimaryKey(id);
    }
}
