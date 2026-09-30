package org.example.springbootdemo.system;

import org.example.springbootdemo.auth.TokenStore;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.controller.UserController;
import org.example.springbootdemo.service.UserService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(UserController.class)
@Import({org.example.springbootdemo.config.WebMvcConfig.class, org.example.springbootdemo.auth.AuthInterceptor.class, TokenStore.class})
class AuthInterceptorTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private TokenStore tokenStore;

    @MockBean
    private UserService userService;

    @MockBean
    private PermissionService permissionService;

    @Test
    void authEndpointsDoNotRequireToken() throws Exception {
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void businessEndpointsRejectMissingToken() throws Exception {
        mockMvc.perform(get("/api/user/list"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void businessEndpointsAcceptRegisteredBearerToken() throws Exception {
        String token = tokenStore.createToken(1L);
        when(userService.listUsers()).thenReturn(java.util.List.of());
        when(permissionService.isAdmin(any())).thenReturn(true);

        mockMvc.perform(get("/api/user/list").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
    }
}
