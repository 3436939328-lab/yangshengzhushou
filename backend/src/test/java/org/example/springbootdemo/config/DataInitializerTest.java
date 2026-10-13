package org.example.springbootdemo.config;

import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.bean.User;
import org.example.springbootdemo.dao.RoleDao;
import org.example.springbootdemo.dao.UserDao;
import org.example.springbootdemo.service.UserService;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class DataInitializerTest {

    @Test
    void runUpdatesSeededUserWhenUsernameAlreadyExists() {
        UserDao userDao = mock(UserDao.class);
        RoleDao roleDao = mock(RoleDao.class);
        UserService userService = mock(UserService.class);
        DataInitializer initializer = new DataInitializer(userDao, roleDao, userService);

        when(roleDao.selectByCode("ADMIN")).thenReturn(role(1L, "ADMIN"));
        when(roleDao.selectByCode("ADVISER")).thenReturn(role(2L, "ADVISER"));
        when(roleDao.selectByCode("USER")).thenReturn(role(3L, "USER"));

        when(userDao.selectByPhone("13800000001")).thenReturn(null);
        User existingAdmin = new User();
        existingAdmin.setId(99L);
        existingAdmin.setUsername("admin");
        existingAdmin.setPhone("19900000000");
        existingAdmin.setPassword("old-password");
        when(userDao.selectByUsername("admin")).thenReturn(existingAdmin);

        when(userDao.selectByPhone("13800000002")).thenReturn(null);
        when(userDao.selectByUsername("adviser")).thenReturn(null);
        when(userDao.selectByPhone("13800000003")).thenReturn(null);
        when(userDao.selectByUsername("visitor")).thenReturn(null);

        initializer.run();

        verify(userDao).updateByPrimaryKeySelective(any(User.class));
        verify(userService).ensureUserRole(99L, "ADMIN");
        assertEquals("admin", existingAdmin.getUsername());
    }

    private static Role role(Long id, String roleCode) {
        Role role = new Role();
        role.setId(id);
        role.setRoleCode(roleCode);
        return role;
    }
}
