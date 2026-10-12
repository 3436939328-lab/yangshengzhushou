package org.example.springbootdemo.config;

import org.example.springbootdemo.auth.AuthInterceptor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Value("${app.assets.upload-dir:./uploads/assets}")
    private String uploadDir;

    private final AuthInterceptor authInterceptor;

    public WebMvcConfig(AuthInterceptor authInterceptor) {
        this.authInterceptor = authInterceptor;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(authInterceptor)
                .addPathPatterns("/api/**", "/user/**", "/role/**", "/user-role/**",
                        "/health-archive/**", "/health-question/**", "/doctor-profile/**",
                        "/consultation/**", "/consultation-message/**",
                        "/api/doctor-registration/**", "/api/doctor/**", "/api/admin/**")
                .excludePathPatterns("/api/auth/**", "/api/weather/**", "/health", "/api/health");
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 公开访问上传的图片资源，无需登录
        String absolutePath = "file:" + uploadDir.replace("\\", "/");
        if (!absolutePath.endsWith("/")) {
            absolutePath = absolutePath + "/";
        }
        registry.addResourceHandler("/assets/**")
                .addResourceLocations(absolutePath);
    }
}
