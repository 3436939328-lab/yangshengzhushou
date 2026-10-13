package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.DoctorProfile;
import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.bean.User;
import org.example.springbootdemo.dao.DoctorProfileDao;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class DoctorProfileService {

    private final DoctorProfileDao doctorProfileDao;
    private final UserService userService;

    public DoctorProfileService(DoctorProfileDao doctorProfileDao, UserService userService) {
        this.doctorProfileDao = doctorProfileDao;
        this.userService = userService;
    }

    public DoctorProfile getDoctorProfileByUserId(Long userId) {
        DoctorProfile profile = doctorProfileDao.selectByUserId(userId);
        if (profile != null) {
            return profile;
        }

        User user = userService.getUserById(userId);
        if (user == null || user.getId() == null || !isDoctorUser(user.getId())) {
            return null;
        }
        return buildRegisteredDoctorFallbackProfile(user);
    }

    public List<DoctorProfile> listDoctorProfiles() {
        Map<Long, DoctorProfile> savedProfilesByUserId = new HashMap<>();
        for (DoctorProfile profile : doctorProfileDao.selectList()) {
            if (profile.getUserId() != null) {
                savedProfilesByUserId.put(profile.getUserId(), profile);
            }
        }

        List<DoctorProfile> result = new ArrayList<>();
        for (User user : userService.listUsers()) {
            if (user.getId() == null || !isDoctorUser(user.getId())) {
                continue;
            }
            DoctorProfile profile = savedProfilesByUserId.get(user.getId());
            result.add(profile != null ? profile : buildRegisteredDoctorFallbackProfile(user));
        }
        return result;
    }

    public int saveDoctorProfile(DoctorProfile doctorProfile) {
        DoctorProfile existing = doctorProfileDao.selectByUserId(doctorProfile.getUserId());
        if (existing == null) {
            if (doctorProfile.getCreateTime() == null) {
                doctorProfile.setCreateTime(new Date());
            }
            return doctorProfileDao.insertSelective(doctorProfile);
        }

        doctorProfile.setId(existing.getId());
        return doctorProfileDao.updateByPrimaryKeySelective(doctorProfile);
    }

    private boolean isDoctorUser(Long userId) {
        for (Role role : userService.getRolesByUserId(userId)) {
            String roleCode = role.getRoleCode();
            if ("DOCTOR".equals(roleCode) || "ADVISER".equals(roleCode)) {
                return true;
            }
        }
        return false;
    }

    private DoctorProfile buildRegisteredDoctorFallbackProfile(User user) {
        DoctorProfile profile = new DoctorProfile();
        profile.setUserId(user.getId());
        profile.setDoctorName(displayDoctorName(user));
        profile.setTitle("医生");
        profile.setSpecialty("资料待完善");
        profile.setIntroduction("医生已注册，资料待完善。");
        return profile;
    }

    private String displayDoctorName(User user) {
        if (!isBlank(user.getRealName())) {
            return user.getRealName();
        }
        if (!isBlank(user.getUsername())) {
            return user.getUsername();
        }
        if (!isBlank(user.getPhone())) {
            return user.getPhone();
        }
        return "医生";
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
