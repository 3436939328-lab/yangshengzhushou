package org.example.springbootdemo.weather;

public record ProviderWeather(
        double temperatureCelsius,
        int relativeHumidity,
        int weatherCode
) {}
