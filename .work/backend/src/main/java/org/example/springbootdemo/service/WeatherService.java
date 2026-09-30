package org.example.springbootdemo.service;

import org.example.springbootdemo.weather.ProviderWeather;
import org.example.springbootdemo.weather.WeatherCities;
import org.example.springbootdemo.weather.WeatherProviderClient;
import org.example.springbootdemo.weather.WeatherReply;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class WeatherService {

    private final WeatherProviderClient providerClient;

    public WeatherService(WeatherProviderClient providerClient) {
        this.providerClient = providerClient;
    }

    public WeatherReply current(Double latitude, Double longitude) {
        return current(latitude, longitude, null);
    }

    public WeatherReply current(Double latitude, Double longitude, String locatedCity) {
        if (!WeatherCities.valid(latitude, longitude)) {
            return WeatherReply.fallback(latitude, longitude);
        }
        String city = locatedCity != null && !locatedCity.isBlank() && locatedCity.length() <= 100
                ? locatedCity.trim() : WeatherCities.inferCity(latitude, longitude);
        try {
            Optional<ProviderWeather> providerWeather = providerClient.fetch(latitude, longitude);
            if (providerWeather.isEmpty()) {
                return unavailable(latitude, longitude, city);
            }
            ProviderWeather weather = providerWeather.get();
            return new WeatherReply(
                    city,
                    conditionName(weather.weatherCode()),
                    Math.round(weather.temperatureCelsius()) + "\u2103",
                    weather.relativeHumidity() + "%",
                    adviceFor(weather.relativeHumidity(), weather.weatherCode()),
                    riskLevelFor(weather.relativeHumidity(), weather.weatherCode()),
                    "Open-Meteo",
                    false
            );
        } catch (RuntimeException exception) {
            return unavailable(latitude, longitude, city);
        }
    }

    private WeatherReply unavailable(Double latitude, Double longitude, String city) {
        WeatherReply fallback = WeatherReply.fallback(latitude, longitude);
        return new WeatherReply(city, fallback.condition(), fallback.temperature(), fallback.humidity(),
                fallback.advice(), fallback.riskLevel(), fallback.sourceLabel(), true);
    }

    private String conditionName(int weatherCode) {
        if (weatherCode == 0) {
            return "\u6674";
        }
        if (weatherCode <= 3) {
            return "\u591a\u4e91";
        }
        if (weatherCode >= 51 && weatherCode <= 67) {
            return "\u5c0f\u96e8";
        }
        if (weatherCode >= 80 && weatherCode <= 99) {
            return "\u96e8\u96ea";
        }
        return "\u5929\u6c14\u5e73\u7a33";
    }

    private String riskLevelFor(int humidity, int weatherCode) {
        if (humidity >= 75) {
            return "\u6e7f\u70ed\u63d0\u9192";
        }
        if (weatherCode >= 51) {
            return "\u964d\u96e8\u63d0\u9192";
        }
        return "\u5e73\u7a33\u5929\u6c14";
    }

    private String adviceFor(int humidity, int weatherCode) {
        if (humidity >= 75) {
            return "\u6e7f\u5ea6\u504f\u9ad8\uff0c\u4eca\u65e5\u5b9c\u6e05\u6de1\u996e\u98df\uff0c\u8fd0\u52a8\u540e\u53ca\u65f6\u66f4\u6362\u8863\u7269\u3002";
        }
        if (weatherCode >= 51) {
            return "\u4eca\u65e5\u6709\u964d\u96e8\u53ef\u80fd\uff0c\u51fa\u884c\u6ce8\u610f\u9632\u6ed1\uff0c\u5ba4\u5185\u53ef\u505a\u6e29\u548c\u62c9\u4f38\u3002";
        }
        return "\u4eca\u65e5\u5929\u6c14\u8f83\u5e73\u7a33\uff0c\u6ce8\u610f\u8865\u6c34\u5e76\u4fdd\u6301\u89c4\u5f8b\u4f5c\u606f\u3002";
    }
}
