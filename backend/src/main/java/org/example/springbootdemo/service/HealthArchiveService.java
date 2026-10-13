package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.HealthArchive;
import org.example.springbootdemo.dao.HealthArchiveDao;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class HealthArchiveService {

    private final HealthArchiveDao healthArchiveDao;

    public HealthArchiveService(HealthArchiveDao healthArchiveDao) {
        this.healthArchiveDao = healthArchiveDao;
    }

    public HealthArchive getHealthArchiveById(Long id) {
        return healthArchiveDao.selectByPrimaryKey(id);
    }

    public HealthArchive getHealthArchiveByUserId(Long userId) {
        return healthArchiveDao.selectByUserId(userId);
    }

    public List<HealthArchive> listHealthArchives() {
        return healthArchiveDao.selectList();
    }

    public int addHealthArchive(HealthArchive healthArchive) {
        if (healthArchive.getCreateTime() == null) {
            healthArchive.setCreateTime(new Date());
        }
        return healthArchiveDao.insertSelective(healthArchive);
    }

    public int updateHealthArchive(HealthArchive healthArchive) {
        return healthArchiveDao.updateByPrimaryKeySelective(healthArchive);
    }

    public int deleteHealthArchive(Long id) {
        return healthArchiveDao.deleteByPrimaryKey(id);
    }

    public HealthArchive upsertHealthArchiveForUser(HealthArchive healthArchive, Long userId) {
        if (healthArchive == null || userId == null) {
            return null;
        }
        HealthArchive existing = getHealthArchiveByUserId(userId);
        healthArchive.setUserId(userId);
        if (existing == null || existing.getId() == null) {
            addHealthArchive(healthArchive);
            return healthArchive;
        }
        healthArchive.setId(existing.getId());
        updateHealthArchive(healthArchive);
        HealthArchive saved = getHealthArchiveById(existing.getId());
        return saved == null ? healthArchive : saved;
    }
}
