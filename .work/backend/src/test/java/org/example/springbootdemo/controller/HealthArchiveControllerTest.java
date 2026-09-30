package org.example.springbootdemo.controller;

import org.example.springbootdemo.bean.HealthArchive;
import org.example.springbootdemo.service.HealthArchiveService;
import org.example.springbootdemo.support.AuthenticatedWebMvcTest;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(HealthArchiveController.class)
class HealthArchiveControllerTest extends AuthenticatedWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private HealthArchiveService healthArchiveService;

    @Test
    void getHealthArchiveByIdReturnsArchive() throws Exception {
        HealthArchive archive = new HealthArchive();
        archive.setId(1L);
        archive.setUserId(1L);
        archive.setHeight(new BigDecimal("175.00"));
        archive.setWeight(new BigDecimal("68.50"));
        archive.setConstitutionType("平和质");

        Mockito.when(healthArchiveService.getHealthArchiveById(1L)).thenReturn(archive);

        mockMvc.perform(authGet("/health-archive").param("id", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("query success"))
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.userId").value(1))
                .andExpect(jsonPath("$.data.constitutionType").value("平和质"));
    }

    @Test
    void listHealthArchivesReturnsArchives() throws Exception {
        HealthArchive archive = new HealthArchive();
        archive.setId(2L);
        archive.setUserId(3L);
        archive.setHeight(new BigDecimal("165.00"));
        archive.setWeight(new BigDecimal("56.00"));
        archive.setHealthGoal("增强免疫力");
        archive.setConstitutionType("气虚质");

        Mockito.when(healthArchiveService.listHealthArchives()).thenReturn(List.of(archive));

        mockMvc.perform(authGet("/api/health-archive/list"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("query success"))
                .andExpect(jsonPath("$.data[0].id").value(2))
                .andExpect(jsonPath("$.data[0].userId").value(3))
                .andExpect(jsonPath("$.data[0].healthGoal").value("增强免疫力"))
                .andExpect(jsonPath("$.data[0].constitutionType").value("气虚质"));
    }
    @Test
    void listHealthArchivesRejectsNonAdminUser() throws Exception {
        Mockito.when(permissionService.isAdmin(any())).thenReturn(false);

        mockMvc.perform(authGet("/api/health-archive/list"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }
    @Test
    void getHealthArchiveByUserIdReturnsOwnArchive() throws Exception {
        HealthArchive archive = new HealthArchive();
        archive.setId(3L);
        archive.setUserId(9L);
        archive.setHeight(new BigDecimal("170.00"));
        archive.setWeight(new BigDecimal("60.00"));

        Mockito.when(healthArchiveService.getHealthArchiveByUserId(9L)).thenReturn(archive);

        mockMvc.perform(authGet("/api/health-archive").param("userId", "9"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("query success"))
                .andExpect(jsonPath("$.data.id").value(3))
                .andExpect(jsonPath("$.data.userId").value(9));
    }

    @Test
    void getHealthArchiveByUserIdRejectsOtherUser() throws Exception {
        Mockito.when(permissionService.canAccessUser(any(), org.mockito.ArgumentMatchers.eq(99L))).thenReturn(false);

        mockMvc.perform(authGet("/api/health-archive").param("userId", "99"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("forbidden"));
    }

    @Test
    void upsertCurrentHealthArchiveUsesCurrentTokenUserId() throws Exception {
        Mockito.when(tokenStore.getUserId("test-token")).thenReturn(7L);
        HealthArchive saved = new HealthArchive();
        saved.setId(11L);
        saved.setUserId(7L);
        saved.setConstitutionType("Qi deficiency");
        Mockito.when(healthArchiveService.upsertHealthArchiveForUser(any(HealthArchive.class), org.mockito.ArgumentMatchers.eq(7L))).thenReturn(saved);

        mockMvc.perform(authPut("/api/health-archive/current")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"userId":99,"constitutionType":"Qi deficiency","healthGoal":"Better sleep"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("health archive saved"))
                .andExpect(jsonPath("$.data.id").value(11))
                .andExpect(jsonPath("$.data.userId").value(7));

        ArgumentCaptor<HealthArchive> captor = ArgumentCaptor.forClass(HealthArchive.class);
        verify(healthArchiveService).upsertHealthArchiveForUser(captor.capture(), org.mockito.ArgumentMatchers.eq(7L));
        org.junit.jupiter.api.Assertions.assertEquals(7L, captor.getValue().getUserId());
        org.junit.jupiter.api.Assertions.assertEquals("Qi deficiency", captor.getValue().getConstitutionType());
    }

    @Test
    void getCurrentHealthArchiveUsesCurrentTokenUserId() throws Exception {
        Mockito.when(tokenStore.getUserId("test-token")).thenReturn(7L);
        HealthArchive archive = new HealthArchive();
        archive.setId(12L);
        archive.setUserId(7L);
        archive.setConstitutionType("Qi deficiency");
        archive.setHealthGoal("Better sleep");
        Mockito.when(healthArchiveService.getHealthArchiveByUserId(7L)).thenReturn(archive);

        mockMvc.perform(authGet("/api/health-archive/current"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("query success"))
                .andExpect(jsonPath("$.data.id").value(12))
                .andExpect(jsonPath("$.data.userId").value(7))
                .andExpect(jsonPath("$.data.constitutionType").value("Qi deficiency"))
                .andExpect(jsonPath("$.data.healthGoal").value("Better sleep"));
    }
}
