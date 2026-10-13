package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/assets")
public class AssetController {

    @Value("${app.assets.upload-dir:./uploads/assets}")
    private String uploadDir;

    private final PermissionService permissionService;

    public AssetController(PermissionService permissionService) {
        this.permissionService = permissionService;
    }

    @PostMapping("/upload")
    public ResponseEntity<Map<String, Object>> upload(@RequestParam("file") MultipartFile file,
                                                       HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response(false, "unauthorized"));
        }
        if (file == null || file.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response(false, "file is required"));
        }
        String originalFilename = file.getOriginalFilename();
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf('.')).toLowerCase();
        }
        if (!isAllowedImageExtension(extension)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(response(false, "only jpg/jpeg/png/gif/webp images are allowed"));
        }
        try {
            File dir = new File(uploadDir);
            if (!dir.exists()) {
                dir.mkdirs();
            }
            String newFilename = UUID.randomUUID().toString().replace("-", "") + extension;
            Path targetPath = Paths.get(uploadDir, newFilename);
            Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);

            // 构建可访问的 URL
            String baseUrl = getBaseUrl(request);
            String imageUrl = baseUrl + "/assets/" + newFilename;

            Map<String, Object> data = new HashMap<>();
            data.put("assetId", newFilename);
            data.put("imageUrl", imageUrl);
            data.put("filename", originalFilename);
            data.put("size", file.getSize());
            return ok(response(true, "upload success", data));
        } catch (IOException ex) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(response(false, "upload failed: " + ex.getMessage()));
        }
    }

    @PostMapping("/upload-base64")
    public ResponseEntity<Map<String, Object>> uploadBase64(@RequestBody Map<String, Object> body,
                                                            HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response(false, "unauthorized"));
        }
        String filename = text(body.get("filename"));
        String contentType = text(body.get("contentType"));
        String base64Data = text(body.get("base64Data"));
        if (base64Data.length() == 0) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response(false, "base64Data is required"));
        }
        String extension = "";
        if (filename.length() > 0 && filename.contains(".")) {
            extension = filename.substring(filename.lastIndexOf('.')).toLowerCase();
        }
        if (extension.length() == 0 && contentType.length() > 0) {
            if (contentType.contains("png")) extension = ".png";
            else if (contentType.contains("gif")) extension = ".gif";
            else if (contentType.contains("webp")) extension = ".webp";
            else if (contentType.contains("bmp")) extension = ".bmp";
            else if (contentType.contains("jpeg") || contentType.contains("jpg")) extension = ".jpg";
        }
        if (!isAllowedImageExtension(extension)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(response(false, "only jpg/jpeg/png/gif/webp images are allowed"));
        }
        try {
            byte[] imageBytes = Base64.getDecoder().decode(base64Data);
            File dir = new File(uploadDir);
            if (!dir.exists()) {
                dir.mkdirs();
            }
            String newFilename = UUID.randomUUID().toString().replace("-", "") + extension;
            Path targetPath = Paths.get(uploadDir, newFilename);
            Files.write(targetPath, imageBytes);

            String baseUrl = getBaseUrl(request);
            String imageUrl = baseUrl + "/assets/" + newFilename;

            Map<String, Object> data = new HashMap<>();
            data.put("assetId", newFilename);
            data.put("imageUrl", imageUrl);
            data.put("filename", filename.length() > 0 ? filename : newFilename);
            data.put("size", imageBytes.length);
            return ok(response(true, "upload success", data));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(response(false, "invalid base64 data: " + ex.getMessage()));
        } catch (IOException ex) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(response(false, "upload failed: " + ex.getMessage()));
        }
    }

    private boolean isAllowedImageExtension(String ext) {
        return ".jpg".equals(ext) || ".jpeg".equals(ext) || ".png".equals(ext)
                || ".gif".equals(ext) || ".webp".equals(ext) || ".bmp".equals(ext);
    }

    private String getBaseUrl(HttpServletRequest request) {
        String scheme = request.getScheme();
        String serverName = request.getServerName();
        int serverPort = request.getServerPort();
        String contextPath = request.getContextPath();
        StringBuilder url = new StringBuilder();
        url.append(scheme).append("://").append(serverName);
        if ((scheme.equals("http") && serverPort != 80)
                || (scheme.equals("https") && serverPort != 443)) {
            url.append(":").append(serverPort);
        }
        url.append(contextPath);
        return url.toString();
    }

    private Map<String, Object> response(boolean success, String message) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", success);
        response.put("message", message);
        return response;
    }

    private Map<String, Object> response(boolean success, String message, Object data) {
        Map<String, Object> response = response(success, message);
        response.put("data", data);
        return response;
    }

    private ResponseEntity<Map<String, Object>> ok(Map<String, Object> body) {
        return ResponseEntity.ok(body);
    }

    private String text(Object value) {
        return value != null ? String.valueOf(value) : "";
    }
}
