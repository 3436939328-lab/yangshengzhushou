package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.TongueImage;
import org.example.springbootdemo.dao.TongueImageDao;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class TongueImageService {

    private final TongueImageDao tongueImageDao;

    public TongueImageService(TongueImageDao tongueImageDao) {
        this.tongueImageDao = tongueImageDao;
    }

    public List<TongueImage> listByUserId(Long userId) {
        return tongueImageDao.selectByUserId(userId);
    }

    public TongueImage getById(Long id) {
        return tongueImageDao.selectByPrimaryKey(id);
    }

    public int addRecord(TongueImage record) {
        if (record.getCreateTime() == null) {
            record.setCreateTime(new Date());
        }
        if (record.getIsDeleted() == null) {
            record.setIsDeleted(0);
        }
        return tongueImageDao.insertSelective(record);
    }

    public int updateRecord(TongueImage record) {
        return tongueImageDao.updateByPrimaryKeySelective(record);
    }

    public boolean deleteRecord(Long id, Long userId) {
        TongueImage record = tongueImageDao.selectByPrimaryKey(id);
        if (record == null || !record.getUserId().equals(userId)) {
            return false;
        }
        return tongueImageDao.markDeleted(id) > 0;
    }
}
