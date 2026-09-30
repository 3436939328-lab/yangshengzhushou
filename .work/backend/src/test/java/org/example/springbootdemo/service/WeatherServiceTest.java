package org.example.springbootdemo.service;

import org.example.springbootdemo.weather.ProviderWeather;
import org.example.springbootdemo.weather.WeatherProviderClient;
import org.example.springbootdemo.weather.WeatherReply;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class WeatherServiceTest {

    @Test
    void currentUsesDeviceGeocodedCityAndActualCoordinateWeather() {
        WeatherProviderClient providerClient = (latitude, longitude) -> Optional.of(
                new ProviderWeather(26.4, 61, 0)
        );
        WeatherService service = new WeatherService(providerClient);

        WeatherReply result = service.current(36.6512, 117.1201, "济南市");

        assertEquals("济南市", result.city());
        assertEquals("\u6674", result.condition());
        assertEquals("26\u2103", result.temperature());
        assertEquals("61%", result.humidity());
        assertEquals("Open-Meteo", result.sourceLabel());
        assertFalse(result.isFallback());
    }

    @Test
    void currentReturnsFallbackWhenCoordinatesAreMissing() {
        WeatherProviderClient providerClient = (latitude, longitude) -> Optional.empty();
        WeatherService service = new WeatherService(providerClient);

        WeatherReply result = service.current(null, null);

        assertEquals("定位未获取", result.city());
        assertEquals("天气未获取", result.condition());
        assertEquals("--℃", result.temperature());
        assertEquals("天气服务未连接", result.sourceLabel());
        assertTrue(result.isFallback());
    }

    @Test
    void currentReturnsFallbackWhenProviderFails() {
        WeatherProviderClient providerClient = (latitude, longitude) -> {
            throw new IllegalStateException("provider down");
        };
        WeatherService service = new WeatherService(providerClient);

        WeatherReply result = service.current(31.2304, 121.4737, "上海市");

        assertEquals("上海市", result.city());
        assertEquals("--", result.humidity());
        assertEquals("天气服务未连接", result.sourceLabel());
        assertTrue(result.isFallback());
    }
}
