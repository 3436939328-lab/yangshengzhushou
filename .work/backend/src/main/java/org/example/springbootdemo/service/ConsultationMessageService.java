package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.ConsultationMessage;
import org.example.springbootdemo.dao.ConsultationMessageDao;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class ConsultationMessageService {

    private final ConsultationMessageDao consultationMessageDao;

    public ConsultationMessageService(ConsultationMessageDao consultationMessageDao) {
        this.consultationMessageDao = consultationMessageDao;
    }

    public List<ConsultationMessage> listMessagesByConsultationId(Long consultationId) {
        return consultationMessageDao.selectByConsultationId(consultationId);
    }

    public int addConsultationMessage(ConsultationMessage consultationMessage) {
        if (consultationMessage.getCreateTime() == null) {
            consultationMessage.setCreateTime(new Date());
        }
        return consultationMessageDao.insertSelective(consultationMessage);
    }
}
