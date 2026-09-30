package org.example.springbootdemo.config;

import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.bean.User;
import org.example.springbootdemo.dao.RoleDao;
import org.example.springbootdemo.dao.UserDao;
import org.example.springbootdemo.service.UserService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.Date;

@Component
public class DataInitializer implements CommandLineRunner {

    private final UserDao userDao;
    private final RoleDao roleDao;
    private final UserService userService;

    public DataInitializer(UserDao userDao, RoleDao roleDao, UserService userService) {
        this.userDao = userDao;
        this.roleDao = roleDao;
        this.userService = userService;
    }

    @Override
    public void run(String... args) {
        ensureRole("ADMIN", "管理员");
        ensureRole("ADVISER", "养生顾问");
        ensureRole("USER", "普通用户");

        ensureUser("13800000001", "admin", "系统管理员", "ADMIN");
        ensureUser("13800000002", "adviser", "养生顾问", "ADVISER");
        ensureUser("13800000003", "visitor", "体验用户", "USER");
    }

    private void ensureRole(String roleCode, String roleName) {
        if (roleDao.selectByCode(roleCode) != null) {
            return;
        }
        Role role = new Role();
        role.setRoleCode(roleCode);
        role.setRoleName(roleName);
        role.setCreateTime(new Date());
        roleDao.insertSelective(role);
    }

    private void ensureUser(String phone, String username, String realName, String roleCode) {
        User user = userDao.selectByPhone(phone);
        if (user == null) {
            user = userDao.selectByUsername(username);
        }
        if (user == null) {
            user = new User();
            user.setCreateTime(new Date());
            user.setId(null);
        }

        user.setPhone(phone);
        user.setUsername(username);
        user.setPassword("123456");
        user.setRealName(realName);
        user.setGender("男");
        user.setAge(28);
        user.setStatus((byte) 1);

        if (user.getCreateTime() == null) {
            user.setCreateTime(new Date());
        }

        if (user.getId() == null) {
            userDao.insertSelective(user);
        } else {
            userDao.updateByPrimaryKeySelective(user);
        }
        if (user.getId() != null) {
            userService.ensureUserRole(user.getId(), roleCode);
        }
    }
}
