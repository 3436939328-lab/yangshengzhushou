package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.TongueObservationRecord;
import org.example.springbootdemo.dao.TongueObservationRecordDao;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class TongueObservationRecordService {

    private final TongueObservationRecordDao tongueObservationRecordDao;

    public TongueObservationRecordService(TongueObservationRecordDao tongueObservationRecordDao) {
        this.tongueObservationRecordDao = tongueObservationRecordDao;
    }

    public List<TongueObservationRecord> listByUserId(Long userId) {
        return tongueObservationRecordDao.selectByUserId(userId);
    }

    public int addRecord(TongueObservationRecord record) {
        if (record.getCreateTime() == null) {
            record.setCreateTime(new Date());
        }
        return tongueObservationRecordDao.insertSelective(record);
    }
}
