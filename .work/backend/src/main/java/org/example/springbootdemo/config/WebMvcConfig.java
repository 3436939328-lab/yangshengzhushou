package org.example.springbootdemo.config;

import org.example.springbootdemo.auth.AuthInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    private final AuthInterceptor authInterceptor;

    public WebMvcConfig(AuthInterceptor authInterceptor) {
        this.authInterceptor = authInterceptor;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(authInterceptor)
                .addPathPatterns("/api/**", "/user/**", "/role/**", "/user-role/**",
                        "/health-archive/**", "/health-question/**", "/doctor-profile/**",
                        "/consultation/**", "/consultation-message/**")
                .excludePathPatterns("/api/auth/**", "/api/weather/**", "/health", "/api/health");
    }
}
