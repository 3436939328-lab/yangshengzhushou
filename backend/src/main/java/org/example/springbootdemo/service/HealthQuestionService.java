package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.HealthQuestion;
import org.example.springbootdemo.dao.HealthQuestionDao;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class HealthQuestionService {

    private final HealthQuestionDao healthQuestionDao;

    public HealthQuestionService(HealthQuestionDao healthQuestionDao) {
        this.healthQuestionDao = healthQuestionDao;
    }

    public List<HealthQuestion> listHealthQuestions() {
        return healthQuestionDao.selectList();
    }

    public List<HealthQuestion> listHealthQuestions(Long userId) {
        if (userId == null) {
            return listHealthQuestions();
        }
        return healthQuestionDao.selectListByUserId(userId);
    }

    public int addHealthQuestion(HealthQuestion healthQuestion) {
        if (healthQuestion.getStatus() == null) {
            healthQuestion.setStatus((byte) 0);
        }
        if (healthQuestion.getCreateTime() == null) {
            healthQuestion.setCreateTime(new Date());
        }
        return healthQuestionDao.insertSelective(healthQuestion);
    }

    public int answerHealthQuestion(HealthQuestion healthQuestion) {
        healthQuestion.setStatus((byte) 1);
        return healthQuestionDao.updateByPrimaryKeySelective(healthQuestion);
    }
}
