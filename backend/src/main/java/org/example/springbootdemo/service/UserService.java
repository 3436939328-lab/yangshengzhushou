package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.bean.User;
import org.example.springbootdemo.bean.UserRole;
import org.example.springbootdemo.dao.RoleDao;
import org.example.springbootdemo.dao.UserDao;
import org.example.springbootdemo.dao.UserRoleDao;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;

@Service
public class UserService {

    private static final String DEFAULT_USER_ROLE_CODE = "USER";
    private static final String DEFAULT_ADMIN_CREATED_PASSWORD = "123456";

    private final UserDao userDao;
    private final RoleDao roleDao;
    private final UserRoleDao userRoleDao;
    private final JdbcTemplate jdbcTemplate;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public UserService(UserDao userDao, RoleDao roleDao, UserRoleDao userRoleDao, JdbcTemplate jdbcTemplate) {
        this.userDao = userDao;
        this.roleDao = roleDao;
        this.userRoleDao = userRoleDao;
        this.jdbcTemplate = jdbcTemplate;
    }

    public User getUserById(Long id) {
        return userDao.selectByPrimaryKey(id);
    }

    public User getUserByUsername(String username) {
        return userDao.selectByUsername(username);
    }

    public User getUserByPhone(String phone) {
        return userDao.selectByPhone(phone);
    }

    public List<User> listUsers() {
        return userDao.selectList();
    }

    public List<Role> getRolesByUserId(Long userId) {
        return roleDao.selectRolesByUserId(userId);
    }

    public User registerUser(User user, String rawPassword) {
        user.setUsername(user.getPhone());
        user.setPassword(passwordEncoder.encode(rawPassword));
        user.setStatus((byte) 1);
        user.setCreateTime(new Date());
        userDao.insertSelective(user);
        bindRequestedUserRole(user.getId(), user.getRoleCode());
        return user;
    }

    public boolean matchesPassword(String rawPassword, String encodedPassword) {
        if (rawPassword == null || encodedPassword == null) {
            return false;
        }
        if (isBCryptHash(encodedPassword)) {
            return passwordEncoder.matches(rawPassword, encodedPassword);
        }
        return rawPassword.equals(encodedPassword);
    }

    public void upgradePasswordIfNeeded(User user, String rawPassword) {
        if (user == null || user.getId() == null || rawPassword == null || isBCryptHash(user.getPassword())) {
            return;
        }
        User update = new User();
        update.setId(user.getId());
        update.setPassword(passwordEncoder.encode(rawPassword));
        userDao.updateByPrimaryKeySelective(update);
    }

    public int resetPassword(Long userId, String rawPassword) {
        if (userId == null || isBlank(rawPassword)) {
            return 0;
        }
        User update = new User();
        update.setId(userId);
        update.setPassword(passwordEncoder.encode(rawPassword));
        return userDao.updateByPrimaryKeySelective(update);
    }

    private boolean isBCryptHash(String password) {
        return password != null && (password.startsWith("$2a$") || password.startsWith("$2b$") || password.startsWith("$2y$"));
    }

    public int addUser(User user) {
        prepareAdminCreatedUser(user);
        int inserted = userDao.insertSelective(user);
        if (inserted > 0) {
            bindRequestedUserRole(user.getId(), user.getRoleCode());
        }
        return inserted;
    }

    public int updateUser(User user) {
        return userDao.updateByPrimaryKeySelective(user);
    }

    @Transactional
    public int deleteUser(Long id) {
        if (id == null) {
            return 0;
        }
        jdbcTemplate.update(
                "delete from consultation_message where consultation_id in " +
                        "(select id from (select id from consultation where user_id = ? or doctor_id = ?) as matched_consultations)",
                id, id
        );
        jdbcTemplate.update("delete from consultation_message where sender_id = ?", id);
        jdbcTemplate.update("delete from consultation where user_id = ? or doctor_id = ?", id, id);
        jdbcTemplate.update("delete from health_question where user_id = ?", id);
        jdbcTemplate.update("delete from doctor_profile where user_id = ?", id);
        jdbcTemplate.update("delete from health_indicator_record where user_id = ?", id);
        jdbcTemplate.update("delete from tongue_observation_record where user_id = ?", id);
        jdbcTemplate.update("delete from health_questionnaire_record where user_id = ?", id);
        jdbcTemplate.update("delete from health_archive where user_id = ?", id);
        jdbcTemplate.update("delete from sys_user_role where user_id = ?", id);
        return userDao.deleteByPrimaryKey(id);
    }

    public void ensureUserRole(Long userId, String roleCode) {
        if (userId == null || isBlank(roleCode)) {
            return;
        }
        Role role = roleDao.selectByCode(roleCode.trim().toUpperCase());
        if (role == null || role.getId() == null) {
            role = roleDao.selectByCode(DEFAULT_USER_ROLE_CODE);
        }
        if (role == null || role.getId() == null) {
            return;
        }
        Long roleId = role.getId();
        if (userRoleDao.selectList().stream().anyMatch(item ->
                userId.equals(item.getUserId()) && roleId.equals(item.getRoleId()))) {
            return;
        }
        UserRole userRole = new UserRole();
        userRole.setUserId(userId);
        userRole.setRoleId(roleId);
        userRoleDao.insertSelective(userRole);
    }

    private void bindRequestedUserRole(Long userId, String requestedRoleCode) {
        if (userId == null) {
            return;
        }
        String roleCode = isBlank(requestedRoleCode) ? DEFAULT_USER_ROLE_CODE : requestedRoleCode.trim().toUpperCase();
        ensureUserRole(userId, roleCode);
    }

    private void prepareAdminCreatedUser(User user) {
        if (user == null) {
            return;
        }
        if (isBlank(user.getUsername()) && !isBlank(user.getPhone())) {
            user.setUsername(user.getPhone());
        }
        String rawPassword = isBlank(user.getPassword()) ? DEFAULT_ADMIN_CREATED_PASSWORD : user.getPassword();
        if (!isBCryptHash(rawPassword)) {
            user.setPassword(passwordEncoder.encode(rawPassword));
        }
        if (user.getStatus() == null) {
            user.setStatus((byte) 1);
        }
        if (user.getCreateTime() == null) {
            user.setCreateTime(new Date());
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
