package org.example.springbootdemo.weather;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Locale;
import java.util.Optional;

@Component
public class OpenMeteoWeatherProviderClient implements WeatherProviderClient {

    private final WeatherProperties properties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient = HttpClient.newHttpClient();

    public OpenMeteoWeatherProviderClient(WeatherProperties properties, ObjectMapper objectMapper) {
        this.properties = properties;
        this.objectMapper = objectMapper;
    }

    @Override
    public Optional<ProviderWeather> fetch(Double latitude, Double longitude) {
        if (latitude == null || longitude == null) {
            return Optional.empty();
        }
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(buildUrl(latitude, longitude)))
                    .timeout(Duration.ofMillis(properties.getTimeoutMs()))
                    .GET()
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                return Optional.empty();
            }
            JsonNode current = objectMapper.readTree(response.body()).path("current");
            if (current.isMissingNode()) {
                return Optional.empty();
            }
            double temperature = current.path("temperature_2m").asDouble(Double.NaN);
            int humidity = current.path("relative_humidity_2m").asInt(-1);
            int weatherCode = current.path("weather_code").asInt(-1);
            if (Double.isNaN(temperature) || humidity < 0 || weatherCode < 0) {
                return Optional.empty();
            }
            return Optional.of(new ProviderWeather(temperature, humidity, weatherCode));
        } catch (Exception exception) {
            return Optional.empty();
        }
    }

    private String buildUrl(double latitude, double longitude) {
        String current = URLEncoder.encode("temperature_2m,relative_humidity_2m,weather_code", StandardCharsets.UTF_8);
        return String.format(
                Locale.US,
                "%s?latitude=%.6f&longitude=%.6f&current=%s&timezone=auto",
                properties.getBaseUrl(),
                latitude,
                longitude,
                current
        );
    }
}
