package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.UserRole;
import org.example.springbootdemo.dao.UserRoleDao;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserRoleService {

    private final UserRoleDao userRoleDao;

    public UserRoleService(UserRoleDao userRoleDao) {
        this.userRoleDao = userRoleDao;
    }

    public UserRole getUserRoleById(Long id) {
        return userRoleDao.selectByPrimaryKey(id);
    }

    public List<UserRole> listUserRoles() {
        return userRoleDao.selectList();
    }

    public int addUserRole(UserRole userRole) {
        return userRoleDao.insertSelective(userRole);
    }

    public int updateUserRole(UserRole userRole) {
        return userRoleDao.updateByPrimaryKeySelective(userRole);
    }

    public int deleteUserRole(Long id) {
        return userRoleDao.deleteByPrimaryKey(id);
    }
}
