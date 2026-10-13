package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.Consultation;
import org.example.springbootdemo.dao.ConsultationDao;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class ConsultationService {

    private final ConsultationDao consultationDao;

    public ConsultationService(ConsultationDao consultationDao) {
        this.consultationDao = consultationDao;
    }

    public List<Consultation> listConsultations() {
        return consultationDao.selectList();
    }

    public Consultation getConsultationById(Long id) {
        return consultationDao.selectByPrimaryKey(id);
    }

    public List<Consultation> listConsultations(Long userId, Long doctorId) {
        if (userId == null && doctorId == null) {
            return listConsultations();
        }
        return consultationDao.selectListByFilter(userId, doctorId);
    }

    public int addConsultation(Consultation consultation) {
        if (consultation.getStatus() == null) {
            consultation.setStatus((byte) 0);
        }
        if (consultation.getCreateTime() == null) {
            consultation.setCreateTime(new Date());
        }
        if (consultation.getTitle() == null || consultation.getTitle().trim().isEmpty()) {
            consultation.setTitle("一对一问诊");
        }
        return consultationDao.insertSelective(consultation);
    }

    public int markConsultationReplied(Long id) {
        if (id == null) {
            return 0;
        }
        Consultation consultation = new Consultation();
        consultation.setId(id);
        consultation.setStatus((byte) 1);
        return consultationDao.updateByPrimaryKeySelective(consultation);
    }

    public int updateConsultationStatus(Long id, Byte status) {
        if (id == null || status == null) {
            return 0;
        }
        Consultation consultation = new Consultation();
        consultation.setId(id);
        consultation.setStatus(status);
        return consultationDao.updateByPrimaryKeySelective(consultation);
    }
}
