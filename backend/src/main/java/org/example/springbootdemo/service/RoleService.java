package org.example.springbootdemo.service;

import org.example.springbootdemo.bean.Role;
import org.example.springbootdemo.dao.RoleDao;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class RoleService {

    private final RoleDao roleDao;
    private final JdbcTemplate jdbcTemplate;

    public RoleService(RoleDao roleDao, JdbcTemplate jdbcTemplate) {
        this.roleDao = roleDao;
        this.jdbcTemplate = jdbcTemplate;
    }

    public Role getRoleById(Long id) {
        return roleDao.selectByPrimaryKey(id);
    }

    public List<Role> listRoles() {
        return roleDao.selectList();
    }

    public int addRole(Role role) {
        return roleDao.insertSelective(role);
    }

    public int updateRole(Role role) {
        return roleDao.updateByPrimaryKeySelective(role);
    }

    @Transactional
    public int deleteRole(Long id) {
        if (id == null) {
            return 0;
        }
        jdbcTemplate.update("delete from sys_user_role where role_id = ?", id);
        return roleDao.deleteByPrimaryKey(id);
    }
}
