package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.DoctorProfile;
import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.bean.User;
import org.example.springbootdemo.dao.DoctorProfileDao;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class DoctorProfileServiceTest {

    @Test
    void getDoctorProfileByUserIdReturnsFallbackForRegisteredDoctorWithoutProfile() {
        DoctorProfileDao doctorProfileDao = mock(DoctorProfileDao.class);
        UserService userService = mock(UserService.class);
        DoctorProfileService service = new DoctorProfileService(doctorProfileDao, userService);

        User adviser = user(2L, "13800000002", "养生顾问");
        when(doctorProfileDao.selectByUserId(2L)).thenReturn(null);
        when(userService.getUserById(2L)).thenReturn(adviser);
        when(userService.getRolesByUserId(2L)).thenReturn(List.of(role("ADVISER")));

        DoctorProfile profile = service.getDoctorProfileByUserId(2L);

        assertEquals(2L, profile.getUserId());
        assertEquals("养生顾问", profile.getDoctorName());
        assertEquals("资料待完善", profile.getSpecialty());
    }

    @Test
    void listDoctorProfilesIncludesRegisteredDoctorsWithoutProfile() {
        DoctorProfileDao doctorProfileDao = mock(DoctorProfileDao.class);
        UserService userService = mock(UserService.class);
        DoctorProfileService service = new DoctorProfileService(doctorProfileDao, userService);

        User adviser = user(2L, "13800000002", "养生顾问");
        User normalUser = user(3L, "13800000003", "普通用户");
        when(userService.listUsers()).thenReturn(List.of(adviser, normalUser));
        when(userService.getRolesByUserId(2L)).thenReturn(List.of(role("ADVISER")));
        when(userService.getRolesByUserId(3L)).thenReturn(List.of(role("USER")));
        when(doctorProfileDao.selectList()).thenReturn(List.of());

        List<DoctorProfile> profiles = service.listDoctorProfiles();

        assertEquals(1, profiles.size());
        assertEquals(2L, profiles.get(0).getUserId());
        assertEquals("养生顾问", profiles.get(0).getDoctorName());
        assertEquals("资料待完善", profiles.get(0).getSpecialty());
    }

    @Test
    void listDoctorProfilesPrefersSavedProfileForRegisteredDoctor() {
        DoctorProfileDao doctorProfileDao = mock(DoctorProfileDao.class);
        UserService userService = mock(UserService.class);
        DoctorProfileService service = new DoctorProfileService(doctorProfileDao, userService);

        User adviser = user(2L, "13800000002", "养生顾问");
        DoctorProfile savedProfile = new DoctorProfile();
        savedProfile.setId(9L);
        savedProfile.setUserId(2L);
        savedProfile.setDoctorName("李医生");
        savedProfile.setSpecialty("睡眠调理");
        when(userService.listUsers()).thenReturn(List.of(adviser));
        when(userService.getRolesByUserId(2L)).thenReturn(List.of(role("ADVISER")));
        when(doctorProfileDao.selectList()).thenReturn(List.of(savedProfile));

        List<DoctorProfile> profiles = service.listDoctorProfiles();

        assertEquals(1, profiles.size());
        assertEquals(9L, profiles.get(0).getId());
        assertEquals("李医生", profiles.get(0).getDoctorName());
        assertEquals("睡眠调理", profiles.get(0).getSpecialty());
    }

    private User user(Long id, String phone, String realName) {
        User user = new User();
        user.setId(id);
        user.setPhone(phone);
        user.setRealName(realName);
        return user;
    }

    private Role role(String roleCode) {
        Role role = new Role();
        role.setRoleCode(roleCode);
        return role;
    }
}
