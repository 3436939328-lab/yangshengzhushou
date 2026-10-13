package org.example.springbootdemo.support;

import org.example.springbootdemo.auth.TokenStore;
import org.example.springbootdemo.auth.PermissionService;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.nullable;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;

public abstract class AuthenticatedWebMvcTest {

    private static final String TEST_TOKEN = "test-token";

    @MockBean
    protected TokenStore tokenStore;

    @MockBean
    protected PermissionService permissionService;

    @BeforeEach
    void allowTestToken() {
        when(tokenStore.isValid(TEST_TOKEN)).thenReturn(true);
        lenient().when(permissionService.isAdmin(any())).thenReturn(true);
        lenient().when(permissionService.canAccessUser(any(), nullable(Long.class))).thenReturn(true);
        lenient().when(permissionService.canManageDoctorProfile(any(), nullable(Long.class))).thenReturn(true);
        lenient().when(permissionService.canAnswerHealthQuestion(any())).thenReturn(true);
        lenient().when(permissionService.canListHealthQuestions(any(), nullable(Long.class))).thenReturn(true);
        lenient().when(permissionService.canAccessConsultationFilter(any(), nullable(Long.class), nullable(Long.class))).thenReturn(true);
        lenient().when(permissionService.canCreateConsultation(any(), nullable(Long.class))).thenReturn(true);
        lenient().when(permissionService.canAccessConsultation(any(), any())).thenReturn(true);
    }

    protected MockHttpServletRequestBuilder authGet(String urlTemplate, Object... uriVariables) {
        return get(urlTemplate, uriVariables).header("Authorization", "Bearer " + TEST_TOKEN);
    }

    protected MockHttpServletRequestBuilder authPost(String urlTemplate, Object... uriVariables) {
        return post(urlTemplate, uriVariables).header("Authorization", "Bearer " + TEST_TOKEN);
    }

    protected MockHttpServletRequestBuilder authPut(String urlTemplate, Object... uriVariables) {
        return put(urlTemplate, uriVariables).header("Authorization", "Bearer " + TEST_TOKEN);
    }
}
