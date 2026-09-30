package org.example.springbootdemo.weather;

public record WeatherReply(
        String city,
        String condition,
        String temperature,
        String humidity,
        String advice,
        String riskLevel,
        String sourceLabel,
        boolean isFallback
) {
    public static WeatherReply fallback(Double latitude, Double longitude) {
        String city = WeatherCities.inferCity(latitude, longitude);
        return new WeatherReply(
                city,
                "天气未获取",
                "--℃",
                "--",
                "暂未获取实时天气，本次建议不使用实时温湿度。",
                "天气待更新",
                "天气服务未连接",
                true
        );
    }
}
