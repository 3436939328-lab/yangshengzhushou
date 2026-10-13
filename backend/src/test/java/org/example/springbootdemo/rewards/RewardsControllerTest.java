package org.example.springbootdemo.rewards;

import org.example.springbootdemo.support.AuthenticatedWebMvcTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import java.util.List;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(RewardsController.class)
class RewardsControllerTest extends AuthenticatedWebMvcTest {
    @Autowired MockMvc mvc;
    @MockBean RewardsService service;

    @Test void memberCannotCreateCatalogItems() throws Exception {
        when(permissionService.currentUserId(any())).thenReturn(2L);
        when(permissionService.isAdmin(any())).thenReturn(false);
        mvc.perform(authPost("/api/rewards/admin/products").contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"Cup\",\"points\":5,\"stock\":1,\"active\":true}"))
                .andExpect(status().isForbidden());
        verifyNoInteractions(service);
    }

    @Test void memberCannotFulfillOrders() throws Exception {
        when(permissionService.currentUserId(any())).thenReturn(2L);
        when(permissionService.isAdmin(any())).thenReturn(false);
        mvc.perform(authPost("/api/rewards/admin/orders/order-1/fulfill").contentType(MediaType.APPLICATION_JSON)
                .content("{\"carrier\":\"Carrier\",\"trackingNumber\":\"123\"}"))
                .andExpect(status().isForbidden());
        verifyNoInteractions(service);
    }

    @Test void ordersAlwaysUseAuthenticatedOwner() throws Exception {
        when(permissionService.currentUserId(any())).thenReturn(2L);
        when(service.orders(2L)).thenReturn(List.of());
        mvc.perform(authGet("/api/rewards/orders?userId=99"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data").isEmpty());
        verify(service).orders(2L);
    }
}
