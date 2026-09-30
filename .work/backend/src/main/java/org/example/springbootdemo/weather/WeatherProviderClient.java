package org.example.springbootdemo.weather;

import java.util.Optional;

public interface WeatherProviderClient {
    Optional<ProviderWeather> fetch(Double latitude, Double longitude);
}
