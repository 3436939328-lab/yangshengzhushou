package org.example.springbootdemo.controller;

import org.example.springbootdemo.bean.TongueObservationRecord;
import org.example.springbootdemo.service.TongueObservationRecordService;
import org.example.springbootdemo.support.AuthenticatedWebMvcTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(TongueObservationRecordController.class)
class TongueObservationRecordControllerTest extends AuthenticatedWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private TongueObservationRecordService tongueObservationRecordService;

    @Test
    void currentUserTongueRecordsOnlyReturnCurrentUsersRecords() throws Exception {
        TongueObservationRecord record = new TongueObservationRecord();
        record.setId(7L);
        record.setUserId(3L);
        record.setColor("淡红");
        record.setCoating("薄白");
        record.setDryness("润");

        when(permissionService.currentUserId(org.mockito.ArgumentMatchers.any())).thenReturn(3L);
        when(tongueObservationRecordService.listByUserId(3L)).thenReturn(List.of(record));

        mockMvc.perform(authGet("/api/tongue-observation/current"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].id").value(7))
                .andExpect(jsonPath("$.data[0].userId").value(3))
                .andExpect(jsonPath("$.data[0].color").value("淡红"));
    }
}
