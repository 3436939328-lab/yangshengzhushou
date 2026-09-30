package org.example.springbootdemo.controller;

import org.example.springbootdemo.service.WeatherService;
import org.example.springbootdemo.support.AuthenticatedWebMvcTest;
import org.example.springbootdemo.weather.WeatherReply;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(WeatherController.class)
class WeatherControllerTest extends AuthenticatedWebMvcTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private WeatherService weatherService;

    @Test
    void currentWeatherReturnsAppCompatiblePayloadForCoordinatesWithoutToken() throws Exception {
        when(weatherService.current(31.2304, 121.4737, null)).thenReturn(
                new WeatherReply(
                        "\u4e0a\u6d77",
                        "\u6674",
                        "26\u2103",
                        "61%",
                        "\u4eca\u65e5\u5929\u6c14\u8f83\u5e73\u7a33\uff0c\u6ce8\u610f\u8865\u6c34\u5e76\u4fdd\u6301\u89c4\u5f8b\u4f5c\u606f\u3002",
                        "\u5e73\u7a33\u5929\u6c14",
                        "Open-Meteo",
                        false
                )
        );

        mockMvc.perform(get("/api/weather/current")
                .param("latitude", "31.2304")
                .param("longitude", "121.4737"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.city").value("\u4e0a\u6d77"))
                .andExpect(jsonPath("$.temperature").value("26\u2103"))
                .andExpect(jsonPath("$.humidity").value("61%"))
                .andExpect(jsonPath("$.sourceLabel").value("Open-Meteo"))
                .andExpect(jsonPath("$.isFallback").value(false));
    }

    @Test
    void currentWeatherReturnsFallbackPayloadWhenCoordinatesAreMissing() throws Exception {
        when(weatherService.current(null, null, null)).thenReturn(
                WeatherReply.fallback(null, null)
        );

        mockMvc.perform(get("/api/weather/current"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.city").value("定位未获取"))
                .andExpect(jsonPath("$.condition").value("天气未获取"))
                .andExpect(jsonPath("$.sourceLabel").value("天气服务未连接"))
                .andExpect(jsonPath("$.isFallback").value(true));
    }
}
