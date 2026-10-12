package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.ai.tongue.TongueAnalysisResult;
import org.example.springbootdemo.ai.tongue.TongueAnalysisService;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.bean.TongueImage;
import org.example.springbootdemo.service.TongueImageService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.*;

/**
 * 舌象分析控制器
 * 提供舌象图片上传、AI分析、结果查询等接口
 */
@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
@RequestMapping("/api/tongue-image")
public class TongueImageController {

    @Value("${app.assets.upload-dir:./uploads/assets}")
    private String uploadDir;

    private final TongueImageService tongueImageService;
    private final TongueAnalysisService tongueAnalysisService;
    private final PermissionService permissionService;

    public TongueImageController(TongueImageService tongueImageService,
                                  TongueAnalysisService tongueAnalysisService,
                                  PermissionService permissionService) {
        this.tongueImageService = tongueImageService;
        this.tongueAnalysisService = tongueAnalysisService;
        this.permissionService = permissionService;
    }

    /**
     * 获取当前用户的舌象图片列表
     */
    @GetMapping("/list")
    public ResponseEntity<Map<String, Object>> listMyImages(HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return forbidden();
        }
        List<TongueImage> images = tongueImageService.listByUserId(userId);
        return ResponseEntity.ok(response(true, "success", images));
    }

    /**
     * 获取单张舌象图片详情
     */
    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getImageDetail(@PathVariable Long id, HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return forbidden();
        }
        TongueImage image = tongueImageService.getById(id);
        if (image == null || !image.getUserId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response(false, "not found"));
        }
        return ResponseEntity.ok(response(true, "success", image));
    }

    /**
     * 上传舌象图片并进行AI分析
     * @param file 图片文件
     * @param source 来源：CAMERA / ALBUM
     */
    @PostMapping("/upload-and-analyze")
    public ResponseEntity<Map<String, Object>> uploadAndAnalyze(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "source", defaultValue = "CAMERA") String source,
            HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return forbidden();
        }
        if (file == null || file.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(response(false, "file is required"));
        }

        String originalFilename = file.getOriginalFilename();
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf('.')).toLowerCase();
        }
        if (!isAllowedImageExtension(extension)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(response(false, "only jpg/jpeg/png/webp images are allowed"));
        }

        try {
            // 1. 保存图片文件
            String assetId = UUID.randomUUID().toString().replace("-", "") + extension;
            Path targetPath = Paths.get(uploadDir, assetId);
            Files.createDirectories(targetPath.getParent());
            Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);

            // 构建访问URL
            String baseUrl = getBaseUrl(request);
            String imageUrl = baseUrl + "/assets/" + assetId;

            // 2. 创建记录
            TongueImage record = new TongueImage();
            record.setUserId(userId);
            record.setAssetId(assetId);
            record.setImageUrl(imageUrl);
            record.setSource(source);
            record.setQualityStatus("ANALYZABLE");
            record.setAnalysisStatus("ANALYZING");
            record.setCapturedAt(nowTimestamp());
            record.setUploadedAt(nowTimestamp());
            tongueImageService.addRecord(record);

            // 3. 读取图片为Base64，调用AI分析
            String imageType = extensionToMimeType(extension);
            String base64Image = Base64.getEncoder().encodeToString(file.getBytes());

            TongueAnalysisResult analysisResult = tongueAnalysisService.analyze(base64Image, imageType);

            // 4. 更新分析结果
            if (analysisResult.isSuccess()) {
                record.setAnalysisStatus("SUCCESS");
                record.setTongueColor(analysisResult.getTongueColor());
                record.setTongueCoating(analysisResult.getTongueCoating());
                record.setTongueDryness(analysisResult.getTongueDryness());
                record.setTongueShape(analysisResult.getTongueShape());
                record.setCoatingThickness(analysisResult.getCoatingThickness());
                record.setCoatingColor(analysisResult.getCoatingColor());
                record.setConstitutionSuggestion(analysisResult.getConstitutionSuggestion());
                record.setHealthAdvice(analysisResult.getHealthAdvice());
                record.setWarningSigns(analysisResult.getWarningSigns());
                record.setAnalysisNote(analysisResult.getAnalysisNote());
                record.setModelVersion(analysisResult.getModelVersion());
                record.setAnalyzedAt(nowTimestamp());
            } else {
                record.setAnalysisStatus("FAILED");
                record.setAnalysisNote("分析失败: " + analysisResult.getErrorMessage());
            }
            tongueImageService.updateRecord(record);

            return ResponseEntity.ok(response(true, "analysis completed", record));

        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(response(false, "upload failed: " + e.getMessage()));
        }
    }

    /**
     * 对已上传的图片重新进行AI分析
     */
    @PostMapping("/{id}/reanalyze")
    public ResponseEntity<Map<String, Object>> reanalyze(@PathVariable Long id, HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return forbidden();
        }
        TongueImage image = tongueImageService.getById(id);
        if (image == null || !image.getUserId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response(false, "not found"));
        }

        try {
            // 读取本地图片文件
            Path imagePath = Paths.get(uploadDir, image.getAssetId());
            if (!Files.exists(imagePath)) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(response(false, "image file not found"));
            }

            byte[] imageBytes = Files.readAllBytes(imagePath);
            String imageType = filenameToMimeType(image.getAssetId());
            String base64Image = Base64.getEncoder().encodeToString(imageBytes);

            // 更新状态为分析中
            image.setAnalysisStatus("ANALYZING");
            tongueImageService.updateRecord(image);

            // 调用AI分析
            TongueAnalysisResult analysisResult = tongueAnalysisService.analyze(base64Image, imageType);

            // 更新结果
            if (analysisResult.isSuccess()) {
                image.setAnalysisStatus("SUCCESS");
                image.setTongueColor(analysisResult.getTongueColor());
                image.setTongueCoating(analysisResult.getTongueCoating());
                image.setTongueDryness(analysisResult.getTongueDryness());
                image.setTongueShape(analysisResult.getTongueShape());
                image.setCoatingThickness(analysisResult.getCoatingThickness());
                image.setCoatingColor(analysisResult.getCoatingColor());
                image.setConstitutionSuggestion(analysisResult.getConstitutionSuggestion());
                image.setHealthAdvice(analysisResult.getHealthAdvice());
                image.setWarningSigns(analysisResult.getWarningSigns());
                image.setAnalysisNote(analysisResult.getAnalysisNote());
                image.setModelVersion(analysisResult.getModelVersion());
                image.setAnalyzedAt(nowTimestamp());
            } else {
                image.setAnalysisStatus("FAILED");
                image.setAnalysisNote("分析失败: " + analysisResult.getErrorMessage());
            }
            tongueImageService.updateRecord(image);

            return ResponseEntity.ok(response(true, "reanalysis completed", image));

        } catch (IOException e) {
            image.setAnalysisStatus("FAILED");
            image.setAnalysisNote("分析失败: " + e.getMessage());
            tongueImageService.updateRecord(image);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(response(false, "analysis failed: " + e.getMessage()));
        }
    }

    /**
     * 通过Base64方式上传舌象图片并进行AI分析
     */
    @PostMapping("/analyze-base64")
    public ResponseEntity<Map<String, Object>> analyzeByBase64(
            @RequestBody Map<String, Object> body,
            HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return forbidden();
        }

        String base64Data = text(body.get("base64Data"));
        String filename = text(body.get("filename"));
        String contentType = text(body.get("contentType"));
        String source = text(body.get("source"));
        if (source.isEmpty()) source = "CAMERA";

        if (base64Data.isEmpty()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(response(false, "base64Data is required"));
        }

        // 解析扩展名
        String extension = "";
        if (filename.length() > 0 && filename.contains(".")) {
            extension = filename.substring(filename.lastIndexOf('.')).toLowerCase();
        }
        if (extension.length() == 0 && contentType.length() > 0) {
            if (contentType.contains("png")) extension = ".png";
            else if (contentType.contains("webp")) extension = ".webp";
            else if (contentType.contains("bmp")) extension = ".bmp";
            else extension = ".jpg";
        }
        if (extension.length() == 0) {
            extension = ".jpg";
        }
        if (!isAllowedImageExtension(extension)) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(response(false, "only jpg/jpeg/png/webp images are allowed"));
        }

        try {
            // 解码Base64
            byte[] imageBytes = Base64.getDecoder().decode(base64Data);

            // 保存文件
            String assetId = UUID.randomUUID().toString().replace("-", "") + extension;
            Path targetPath = Paths.get(uploadDir, assetId);
            Files.createDirectories(targetPath.getParent());
            Files.write(targetPath, imageBytes);

            String baseUrl = getBaseUrl(request);
            String imageUrl = baseUrl + "/assets/" + assetId;

            // 创建记录
            TongueImage record = new TongueImage();
            record.setUserId(userId);
            record.setAssetId(assetId);
            record.setImageUrl(imageUrl);
            record.setSource(source.toUpperCase());
            record.setQualityStatus("ANALYZABLE");
            record.setAnalysisStatus("ANALYZING");
            record.setCapturedAt(nowTimestamp());
            record.setUploadedAt(nowTimestamp());
            tongueImageService.addRecord(record);

            // 调用AI分析
            String imageType = extensionToMimeType(extension);
            TongueAnalysisResult analysisResult = tongueAnalysisService.analyze(base64Data, imageType);

            // 更新结果
            if (analysisResult.isSuccess()) {
                record.setAnalysisStatus("SUCCESS");
                record.setTongueColor(analysisResult.getTongueColor());
                record.setTongueCoating(analysisResult.getTongueCoating());
                record.setTongueDryness(analysisResult.getTongueDryness());
                record.setTongueShape(analysisResult.getTongueShape());
                record.setCoatingThickness(analysisResult.getCoatingThickness());
                record.setCoatingColor(analysisResult.getCoatingColor());
                record.setConstitutionSuggestion(analysisResult.getConstitutionSuggestion());
                record.setHealthAdvice(analysisResult.getHealthAdvice());
                record.setWarningSigns(analysisResult.getWarningSigns());
                record.setAnalysisNote(analysisResult.getAnalysisNote());
                record.setModelVersion(analysisResult.getModelVersion());
                record.setAnalyzedAt(nowTimestamp());
            } else {
                record.setAnalysisStatus("FAILED");
                record.setAnalysisNote("分析失败: " + analysisResult.getErrorMessage());
            }
            tongueImageService.updateRecord(record);

            return ResponseEntity.ok(response(true, "analysis completed", record));

        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(response(false, "invalid base64 data: " + e.getMessage()));
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(response(false, "analysis failed: " + e.getMessage()));
        }
    }

    /**
     * 删除舌象图片
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, Object>> deleteImage(@PathVariable Long id, HttpServletRequest request) {
        Long userId = permissionService.currentUserId(request);
        if (userId == null) {
            return forbidden();
        }
        boolean deleted = tongueImageService.deleteRecord(id, userId);
        return ResponseEntity.ok(response(deleted, deleted ? "deleted" : "delete failed"));
    }

    // ==================== 辅助方法 ====================

    private boolean isAllowedImageExtension(String ext) {
        return ".jpg".equals(ext) || ".jpeg".equals(ext) || ".png".equals(ext) || ".webp".equals(ext);
    }

    private String extensionToMimeType(String ext) {
        switch (ext) {
            case ".png": return "image/png";
            case ".gif": return "image/gif";
            case ".webp": return "image/webp";
            case ".bmp": return "image/bmp";
            default: return "image/jpeg";
        }
    }

    private String filenameToMimeType(String filename) {
        if (filename == null) return "image/jpeg";
        String lower = filename.toLowerCase();
        if (lower.endsWith(".png")) return "image/png";
        if (lower.endsWith(".gif")) return "image/gif";
        if (lower.endsWith(".webp")) return "image/webp";
        return "image/jpeg";
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

    private String nowTimestamp() {
        return new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
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

    private ResponseEntity<Map<String, Object>> forbidden() {
        return ResponseEntity.status(403).body(response(false, "forbidden"));
    }
}
