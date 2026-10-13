package org.example.springbootdemo.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.example.springbootdemo.auth.PermissionService;
import org.example.springbootdemo.service.AssistantSuggestionService;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;

import java.text.SimpleDateFormat;
import java.util.*;

/**
 * 建议生成任务控制器
 * 提供每日建议生成任务管理、任务状态查询、手动触发等接口
 */
@CrossOrigin(origins = {"http://localhost:5173", "http://127.0.0.1:5173"})
@RestController
public class SuggestionTaskController {

    private final JdbcTemplate jdbcTemplate;
    private final PermissionService permissionService;
    private final AssistantSuggestionService suggestionService;

    public SuggestionTaskController(JdbcTemplate jdbcTemplate,
                                    PermissionService permissionService,
                                    AssistantSuggestionService suggestionService) {
        this.jdbcTemplate = jdbcTemplate;
        this.permissionService = permissionService;
        this.suggestionService = suggestionService;
    }

    // ==================== 获取今日建议状态 ====================

    @GetMapping({"/suggestions/today/status", "/api/suggestions/today/status"})
    public ResponseEntity<Map<String, Object>> getTodaySuggestionStatus(HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) return forbidden();

        String today = new SimpleDateFormat("yyyy-MM-dd").format(new Date());

        // 查询今日最新任务
        Map<String, Object> latestTask = findLatestTask(currentUserId, today);

        Map<String, Object> result = new HashMap<>();
        result.put("date", today);
        result.put("hasSuggestion", latestTask != null && "SUCCESS".equals(latestTask.get("status")));
        result.put("latestTask", latestTask);

        return ResponseEntity.ok(response(true, "success", result));
    }

    // ==================== 触发生成 ====================

    @PostMapping({"/suggestions/generate", "/api/suggestions/generate"})
    public ResponseEntity<Map<String, Object>> generateSuggestion(
            @RequestBody(required = false) Map<String, String> body,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) return forbidden();

        String triggerType = body != null && body.get("triggerType") != null
                ? body.get("triggerType") : "MANUAL";
        String today = new SimpleDateFormat("yyyy-MM-dd").format(new Date());
        String now = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss").format(new Date());

        // 创建任务
        jdbcTemplate.update(
                "insert into suggestion_generation_task (user_id, task_date, trigger_type, status, " +
                        "progress, started_at, create_time) " +
                        "values (?, ?, ?, 'GENERATING', 10, ?, ?)",
                currentUserId, today, triggerType, now, now);

        Long taskId = jdbcTemplate.queryForObject("select last_insert_id()", Long.class);

        // 模拟异步生成（实际应调用AI服务）
        simulateGenerationAsync(taskId, currentUserId, today);

        Map<String, Object> result = new HashMap<>();
        result.put("taskId", taskId);
        result.put("status", "GENERATING");
        result.put("estimatedSeconds", 15);

        return ResponseEntity.ok(response(true, "生成任务已启动", result));
    }

    /**
     * 模拟建议生成（实际应通过AI服务异步处理）
     */
    private void simulateGenerationAsync(Long taskId, Long userId, String date) {
        new Thread(() -> {
            try {
                // 模拟生成过程
                for (int progress = 20; progress <= 100; progress += 20) {
                    Thread.sleep(800);
                    jdbcTemplate.update(
                            "update suggestion_generation_task set progress = ? where id = ?",
                            progress, taskId);
                }

                // 生成完成，标记成功
                String version = "v" + date.replace("-", "") + ".1";
                String completedAt = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss").format(new Date());
                jdbcTemplate.update(
                        "update suggestion_generation_task set status = 'SUCCESS', progress = 100, " +
                                "plan_version = ?, completed_at = ? where id = ?",
                        version, completedAt, taskId);

            } catch (Exception e) {
                jdbcTemplate.update(
                        "update suggestion_generation_task set status = 'FAILED', " +
                                "error_message = ? where id = ?",
                        e.getMessage(), taskId);
            }
        }).start();
    }

    // ==================== 查询任务状态 ====================

    @GetMapping({"/suggestions/tasks/{taskId}", "/api/suggestions/tasks/{taskId}"})
    public ResponseEntity<Map<String, Object>> getTaskStatus(
            @PathVariable Long taskId,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) return forbidden();

        Map<String, Object> task = findTaskById(taskId);
        if (task == null) {
            return ResponseEntity.ok(response(false, "任务不存在"));
        }

        // 验证任务所属
        Long taskUserId = (Long) task.get("userId");
        if (!currentUserId.equals(taskUserId) && !permissionService.isAdmin(request)) {
            return forbidden();
        }

        return ResponseEntity.ok(response(true, "success", task));
    }

    // ==================== 任务列表 ====================

    @GetMapping({"/suggestions/tasks", "/api/suggestions/tasks"})
    public ResponseEntity<Map<String, Object>> getTaskList(
            @RequestParam(defaultValue = "10") int limit,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) return forbidden();

        List<Map<String, Object>> tasks = jdbcTemplate.queryForList(
                "select id, user_id as userId, task_date as taskDate, trigger_type as triggerType, " +
                        "status, progress, plan_version as planVersion, error_message as errorMessage, " +
                        "retry_count as retryCount, started_at as startedAt, " +
                        "completed_at as completedAt, create_time as createTime " +
                        "from suggestion_generation_task where user_id = ? " +
                        "order by create_time desc limit ?",
                currentUserId, limit);

        return ResponseEntity.ok(response(true, "success", tasks));
    }

    // ==================== 重试任务 ====================

    @PostMapping({"/suggestions/tasks/{taskId}/retry", "/api/suggestions/tasks/{taskId}/retry"})
    public ResponseEntity<Map<String, Object>> retryTask(
            @PathVariable Long taskId,
            HttpServletRequest request) {
        Long currentUserId = permissionService.currentUserId(request);
        if (currentUserId == null) return forbidden();

        Map<String, Object> task = findTaskById(taskId);
        if (task == null) {
            return ResponseEntity.ok(response(false, "任务不存在"));
        }

        Long taskUserId = (Long) task.get("userId");
        if (!currentUserId.equals(taskUserId)) {
            return forbidden();
        }

        int retryCount = task.get("retryCount") != null ? (Integer) task.get("retryCount") : 0;
        int maxRetries = task.get("maxRetries") != null ? (Integer) task.get("maxRetries") : 3;
        if (retryCount >= maxRetries) {
            return ResponseEntity.ok(response(false, "已达最大重试次数"));
        }

        // 重置任务状态
        String now = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss").format(new Date());
        jdbcTemplate.update(
                "update suggestion_generation_task set status = 'PENDING', progress = 0, " +
                        "error_message = null, retry_count = retry_count + 1, " +
                        "started_at = ?, completed_at = null where id = ?",
                now, taskId);

        // 重新触发
        String taskDate = (String) task.get("taskDate");
        simulateGenerationAsync(taskId, currentUserId, taskDate);

        return ResponseEntity.ok(response(true, "重试已启动"));
    }

    // ==================== 辅助方法 ====================

    private Map<String, Object> findLatestTask(Long userId, String date) {
        try {
            return jdbcTemplate.queryForMap(
                    "select id, user_id as userId, task_date as taskDate, " +
                            "trigger_type as triggerType, status, progress, " +
                            "plan_version as planVersion, error_message as errorMessage, " +
                            "retry_count as retryCount, max_retries as maxRetries, " +
                            "started_at as startedAt, completed_at as completedAt, " +
                            "create_time as createTime " +
                            "from suggestion_generation_task where user_id = ? and task_date = ? " +
                            "order by create_time desc limit 1",
                    userId, date);
        } catch (Exception e) {
            return null;
        }
    }

    private Map<String, Object> findTaskById(Long taskId) {
        try {
            return jdbcTemplate.queryForMap(
                    "select id, user_id as userId, task_date as taskDate, " +
                            "trigger_type as triggerType, status, progress, " +
                            "plan_version as planVersion, error_message as errorMessage, " +
                            "retry_count as retryCount, max_retries as maxRetries, " +
                            "started_at as startedAt, completed_at as completedAt, " +
                            "create_time as createTime " +
                            "from suggestion_generation_task where id = ?",
                    taskId);
        } catch (Exception e) {
            return null;
        }
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
