package org.example.springbootdemo.weather;

public final class WeatherCities {

    private WeatherCities() {}

    public static String inferCity(Double latitude, Double longitude) {
        return valid(latitude, longitude) ? "位置已获取" : "定位未获取";
    }

    public static boolean valid(Double latitude, Double longitude) {
        return latitude != null && longitude != null && Double.isFinite(latitude) && Double.isFinite(longitude)
                && latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
    }

}
