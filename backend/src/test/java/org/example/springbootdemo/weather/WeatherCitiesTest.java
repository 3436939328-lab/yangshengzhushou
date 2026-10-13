package org.example.springbootdemo.weather;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class WeatherCitiesTest {

    @Test
    void doesNotGuessAdministrativeCityFromNearestOfSevenCenters() {
        assertThat(WeatherCities.inferCity(36.6512, 117.1201)).isEqualTo("位置已获取");
        assertThat(WeatherCities.inferCity(null, null)).isEqualTo("定位未获取");
    }
}
