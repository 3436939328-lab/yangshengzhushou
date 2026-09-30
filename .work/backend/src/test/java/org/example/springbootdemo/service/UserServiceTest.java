package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.bean.User;
import org.example.springbootdemo.bean.UserRole;
import org.example.springbootdemo.dao.RoleDao;
import org.example.springbootdemo.dao.UserDao;
import org.example.springbootdemo.dao.UserRoleDao;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class UserServiceTest {

    @Test
    void getRolesByUserIdReturnsRolesFromRoleDao() {
        UserDao userDao = mock(UserDao.class);
        RoleDao roleDao = mock(RoleDao.class);
        UserRoleDao userRoleDao = mock(UserRoleDao.class);
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        UserService userService = new UserService(userDao, roleDao, userRoleDao, jdbcTemplate);

        Role admin = new Role();
        admin.setId(1L);
        admin.setRoleName("管理员");
        admin.setRoleCode("ADMIN");
        when(roleDao.selectRolesByUserId(10L)).thenReturn(List.of(admin));

        List<Role> roles = userService.getRolesByUserId(10L);

        assertEquals(1, roles.size());
        assertEquals("ADMIN", roles.get(0).getRoleCode());
    }

    @Test
    void registerUserBindsRequestedIdentityRole() {
        UserDao userDao = mock(UserDao.class);
        RoleDao roleDao = mock(RoleDao.class);
        UserRoleDao userRoleDao = mock(UserRoleDao.class);
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        UserService userService = new UserService(userDao, roleDao, userRoleDao, jdbcTemplate);

        Role adviser = new Role();
        adviser.setId(2L);
        adviser.setRoleCode("ADVISER");
        when(roleDao.selectByCode("ADVISER")).thenReturn(adviser);
        when(userRoleDao.selectList()).thenReturn(new ArrayList<>());
        doAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId(20L);
            return 1;
        }).when(userDao).insertSelective(any(User.class));

        User user = new User();
        user.setPhone("13800138088");
        user.setPassword("123456");
        user.setRoleCode("ADVISER");

        userService.registerUser(user, "123456");

        verify(userRoleDao).insertSelective(any(UserRole.class));
        assertEquals(20L, user.getId());
        assertEquals("13800138088", user.getUsername());
    }

    @Test
    void addUserPreparesLoginFieldsAndBindsRequestedRole() {
        UserDao userDao = mock(UserDao.class);
        RoleDao roleDao = mock(RoleDao.class);
        UserRoleDao userRoleDao = mock(UserRoleDao.class);
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        UserService userService = new UserService(userDao, roleDao, userRoleDao, jdbcTemplate);

        Role doctor = new Role();
        doctor.setId(3L);
        doctor.setRoleCode("DOCTOR");
        when(roleDao.selectByCode("DOCTOR")).thenReturn(doctor);
        when(userRoleDao.selectList()).thenReturn(new ArrayList<>());
        doAnswer(invocation -> {
            User insertedUser = invocation.getArgument(0);
            insertedUser.setId(30L);
            return 1;
        }).when(userDao).insertSelective(any(User.class));

        User user = new User();
        user.setUsername("doctor001");
        user.setPassword("abc12345");
        user.setPhone("13800138030");
        user.setRoleCode("DOCTOR");

        int inserted = userService.addUser(user);

        assertEquals(1, inserted);
        assertEquals(30L, user.getId());
        assertEquals((byte) 1, user.getStatus());
        assertNotNull(user.getCreateTime());
        assertNotEquals("abc12345", user.getPassword());
        assertTrue(userService.matchesPassword("abc12345", user.getPassword()));
        verify(userRoleDao).insertSelective(any(UserRole.class));
    }

    @Test
    void deleteRoleAssignmentsBeforeRoleCanBeDeleted() {
        UserDao userDao = mock(UserDao.class);
        RoleDao roleDao = mock(RoleDao.class);
        UserRoleDao userRoleDao = mock(UserRoleDao.class);
        JdbcTemplate jdbcTemplate = mock(JdbcTemplate.class);
        RoleService roleService = new RoleService(roleDao, jdbcTemplate);

        when(roleDao.deleteByPrimaryKey(3L)).thenReturn(1);

        int deleted = roleService.deleteRole(3L);

        assertEquals(1, deleted);
        verify(jdbcTemplate).update("delete from sys_user_role where role_id = ?", 3L);
        verify(roleDao).deleteByPrimaryKey(3L);
    }
}
