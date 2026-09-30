package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.Consultation;
import org.example.springbootdemo.dao.ConsultationDao;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ConsultationServiceTest {

    @Test
    void addConsultationFillsRequiredTitleBeforeInsert() {
        ConsultationDao consultationDao = mock(ConsultationDao.class);
        ConsultationService consultationService = new ConsultationService(consultationDao);
        when(consultationDao.insertSelective(any(Consultation.class))).thenReturn(1);

        Consultation consultation = new Consultation();
        consultation.setUserId(3L);
        consultation.setDoctorId(2L);
        consultation.setSymptom("头疼");
        consultation.setDescription("最近有点头疼");

        consultationService.addConsultation(consultation);

        assertEquals("一对一问诊", consultation.getTitle());
        verify(consultationDao).insertSelective(consultation);
    }
}
