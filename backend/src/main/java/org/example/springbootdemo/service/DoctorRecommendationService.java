package org.example.springbootdemo.service;

import org.example.springbootdemo.ai.AssistantChatRequest;
import org.example.springbootdemo.bean.DoctorProfile;
import org.example.springbootdemo.bean.HealthDetailBundle;
import org.example.springbootdemo.bean.HealthIndicatorRecord;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class DoctorRecommendationService {

    private final HealthArchiveService healthArchiveService;
    private final HealthDetailService healthDetailService;
    private final DoctorProfileService doctorProfileService;
    private final AssistantChatService assistantChatService;

    public DoctorRecommendationService(
            HealthArchiveService healthArchiveService,
            HealthDetailService healthDetailService,
            DoctorProfileService doctorProfileService,
            AssistantChatService assistantChatService) {
        this.healthArchiveService = healthArchiveService;
        this.healthDetailService = healthDetailService;
        this.doctorProfileService = doctorProfileService;
        this.assistantChatService = assistantChatService;
    }

    public Map<String, Object> recommendDoctor(Long userId) {
        // 1. 获取用户健康数据（每个调用都用 try-catch 包裹，失败时静默忽略）
        Object healthArchive = null;
        try {
            healthArchive = healthArchiveService.getHealthArchiveByUserId(userId);
        } catch (Exception e) {
            // 静默忽略
        }

        Map<String, Object> latestReadings = null;
        try {
            latestReadings = getLatestReadings(userId);
        } catch (Exception e) {
            // 静默忽略
        }

        // 2. 获取所有已审核通过的医生列表
        List<DoctorProfile> approvedDoctors = getApprovedDoctors();
        if (approvedDoctors == null || approvedDoctors.isEmpty()) {
            return null;
        }

        // 3. 尝试 AI 推荐
        Map<String, Object> aiResult = null;
        try {
            if (assistantChatService != null) {
                aiResult = callAiRecommendation(userId, healthArchive, latestReadings, approvedDoctors);
            }
        } catch (Exception e) {
            // AI 调用失败，回退到规则匹配
        }

        if (aiResult != null && aiResult.get("doctorId") != null) {
            return aiResult;
        }

        // 4. 规则匹配回退逻辑
        return ruleBasedRecommendation(healthArchive, latestReadings, approvedDoctors);
    }

    /**
     * 获取最新健康指标，转换为 Map 形式
     */
    private Map<String, Object> getLatestReadings(Long userId) {
        Map<String, Object> readings = new HashMap<>();
        try {
            List<HealthIndicatorRecord> records = healthDetailService.getIndicatorRecordsByUserId(userId);
            if (records != null) {
                for (HealthIndicatorRecord record : records) {
                    if (record.getName() != null && record.getValue() != null) {
                        readings.put(record.getName(), record.getValue() + (record.getUnit() != null ? record.getUnit() : ""));
                    }
                }
            }
            // 也尝试获取完整健康数据
            HealthDetailBundle bundle = healthDetailService.getDetailsByUserId(userId);
            if (bundle != null && bundle.getHealthIndicators() != null) {
                for (HealthIndicatorRecord record : bundle.getHealthIndicators()) {
                    if (record.getName() != null && record.getValue() != null) {
                        readings.putIfAbsent(record.getName(),
                                record.getValue() + (record.getUnit() != null ? record.getUnit() : ""));
                    }
                }
            }
        } catch (Exception e) {
            // 忽略
        }
        return readings;
    }

    /**
     * 获取所有已审核通过的医生列表
     */
    private List<DoctorProfile> getApprovedDoctors() {
        List<DoctorProfile> allDoctors;
        try {
            allDoctors = doctorProfileService.listDoctorProfiles();
        } catch (Exception e) {
            return Collections.emptyList();
        }

        if (allDoctors == null || allDoctors.isEmpty()) {
            return Collections.emptyList();
        }

        List<DoctorProfile> approved = new ArrayList<>();
        for (DoctorProfile doctor : allDoctors) {
            if ("APPROVED".equals(doctor.getVerificationStatus())) {
                approved.add(doctor);
            }
        }
        return approved;
    }

    /**
     * 调用 AI 进行医生推荐
     */
    private Map<String, Object> callAiRecommendation(Long userId, Object healthArchive,
                                                      Map<String, Object> latestReadings,
                                                      List<DoctorProfile> doctors) {
        // 构建用户健康数据摘要
        StringBuilder userHealthSummary = new StringBuilder();
        userHealthSummary.append("用户ID: ").append(userId).append("\n");

        if (healthArchive != null) {
            userHealthSummary.append("健康档案: ").append(healthArchive.toString()).append("\n");
        }

        if (latestReadings != null && !latestReadings.isEmpty()) {
            userHealthSummary.append("最新健康指标: ").append(latestReadings.toString()).append("\n");
        }

        // 构建医生列表
        StringBuilder doctorListInfo = new StringBuilder();
        for (DoctorProfile doctor : doctors) {
            doctorListInfo.append("医生ID: ").append(doctor.getId())
                    .append(", 姓名: ").append(doctor.getDoctorName())
                    .append(", 科室: ").append(doctor.getDepartment() != null ? doctor.getDepartment() : doctor.getSpecialty())
                    .append(", 职称: ").append(doctor.getTitle())
                    .append(", 简介: ").append(doctor.getIntroduction())
                    .append("\n");
        }

        // 构建 prompt
        String prompt = "你是一个智能医疗推荐助手。请根据以下用户健康数据，从医生列表中为用户推荐最合适的医生。\n\n"
                + "【用户健康数据】\n" + userHealthSummary.toString() + "\n"
                + "【医生列表】\n" + doctorListInfo.toString() + "\n"
                + "请严格按照以下JSON格式返回结果（不要包含其他文字）：\n"
                + "{\"doctorId\": 推荐的医生ID数字, \"reason\": \"推荐理由说明\", \"department\": \"推荐科室\"}";

        // 调用 AI
        String aiResponse;
        try {
            AssistantChatRequest request = new AssistantChatRequest(prompt, null, null, null);
            var reply = assistantChatService.chat(request, java.util.List.of());
            aiResponse = reply != null ? reply.reply() : null;
        } catch (Exception e) {
            throw new RuntimeException("AI 调用失败", e);
        }

        if (aiResponse == null || aiResponse.isBlank()) {
            return null;
        }

        // 解析 AI 返回的 JSON
        return parseAiResponse(aiResponse, doctors);
    }

    /**
     * 解析 AI 返回的 JSON 响应
     */
    private Map<String, Object> parseAiResponse(String aiResponse, List<DoctorProfile> doctors) {
        try {
            aiResponse = aiResponse.trim();
            // 去除可能的 markdown 代码块标记
            if (aiResponse.startsWith("```")) {
                aiResponse = aiResponse.replaceAll("```json\\s*", "").replaceAll("```\\s*$", "");
                aiResponse = aiResponse.replaceAll("```\\s*", "");
            }

            // 提取 doctorId
            Long doctorId = extractLongValue(aiResponse, "doctorId");
            String reason = extractStringValue(aiResponse, "reason");
            String department = extractStringValue(aiResponse, "department");

            if (doctorId != null) {
                // 验证医生 ID 是否存在于列表中
                boolean found = false;
                for (DoctorProfile doctor : doctors) {
                    if (doctorId.equals(doctor.getId())) {
                        found = true;
                        if (department == null || department.isBlank()) {
                            department = doctor.getDepartment() != null ? doctor.getDepartment() : doctor.getSpecialty();
                        }
                        break;
                    }
                }
                if (!found) {
                    return null;
                }

                Map<String, Object> result = new HashMap<>();
                result.put("doctorId", doctorId);
                result.put("reason", reason != null ? reason : "AI 智能推荐");
                result.put("department", department != null ? department : "");
                result.put("source", "ai");
                return result;
            }
        } catch (Exception e) {
            // 解析失败，返回 null 触发回退
        }
        return null;
    }

    /**
     * 从 JSON 字符串中提取 Long 类型值
     */
    private Long extractLongValue(String json, String key) {
        String pattern = "\"" + key + "\"\\s*:\\s*(\\d+)";
        java.util.regex.Pattern p = java.util.regex.Pattern.compile(pattern);
        java.util.regex.Matcher m = p.matcher(json);
        if (m.find()) {
            try {
                return Long.parseLong(m.group(1));
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }

    /**
     * 从 JSON 字符串中提取 String 类型值
     */
    private String extractStringValue(String json, String key) {
        String pattern = "\"" + key + "\"\\s*:\\s*\"([^\"]*)\"";
        java.util.regex.Pattern p = java.util.regex.Pattern.compile(pattern);
        java.util.regex.Matcher m = p.matcher(json);
        if (m.find()) {
            return m.group(1);
        }
        return null;
    }

    /**
     * 基于规则的医生推荐（回退逻辑）
     */
    private Map<String, Object> ruleBasedRecommendation(Object healthArchive,
                                                         Map<String, Object> latestReadings,
                                                         List<DoctorProfile> doctors) {
        String matchedDepartment = null;
        String reason = null;

        // 检查血压异常 → 优先推荐心血管内科医生
        if (hasBloodPressureAbnormality(latestReadings)) {
            matchedDepartment = findMatchingDepartment(doctors, "心血管内科", "心内科", "心血管");
            if (matchedDepartment != null) {
                reason = "根据您的血压异常情况，为您推荐心血管内科医生";
            }
        }

        // 检查血糖异常 → 优先推荐内分泌科医生
        if (matchedDepartment == null && hasBloodSugarAbnormality(latestReadings)) {
            matchedDepartment = findMatchingDepartment(doctors, "内分泌科", "内分泌");
            if (matchedDepartment != null) {
                reason = "根据您的血糖异常情况，为您推荐内分泌科医生";
            }
        }

        // 检查睡眠问题 → 优先推荐神经内科医生
        if (matchedDepartment == null && hasSleepProblem(healthArchive, latestReadings)) {
            matchedDepartment = findMatchingDepartment(doctors, "神经内科", "神经科", "神经内科");
            if (matchedDepartment != null) {
                reason = "根据您的睡眠问题，为您推荐神经内科医生";
            }
        }

        // 体质偏颇（如气虚、阳虚等）→ 优先推荐中医科医生
        if (matchedDepartment == null && hasConstitutionImbalance(healthArchive)) {
            matchedDepartment = findMatchingDepartment(doctors, "中医科", "中医", "中西医结合");
            if (matchedDepartment != null) {
                reason = "根据您的体质偏颇情况，为您推荐中医科医生";
            }
        }

        // 查找匹配科室的第一个医生
        if (matchedDepartment != null) {
            for (DoctorProfile doctor : doctors) {
                String dept = doctor.getDepartment() != null ? doctor.getDepartment() : doctor.getSpecialty();
                if (dept != null && dept.contains(matchedDepartment)) {
                    Map<String, Object> result = new HashMap<>();
                    result.put("doctorId", doctor.getId());
                    result.put("reason", reason);
                    result.put("department", dept);
                    result.put("source", "rule");
                    return result;
                }
            }
        }

        // 如果没有匹配科室，返回第一个医生
        if (!doctors.isEmpty()) {
            DoctorProfile firstDoctor = doctors.get(0);
            String dept = firstDoctor.getDepartment() != null ? firstDoctor.getDepartment() : firstDoctor.getSpecialty();
            Map<String, Object> result = new HashMap<>();
            result.put("doctorId", firstDoctor.getId());
            result.put("reason", "为您推荐首位接诊医生");
            result.put("department", dept != null ? dept : "");
            result.put("source", "rule");
            return result;
        }

        return null;
    }

    /**
     * 检查是否有血压异常
     */
    private boolean hasBloodPressureAbnormality(Map<String, Object> latestReadings) {
        if (latestReadings == null || latestReadings.isEmpty()) {
            return false;
        }
        try {
            Object systolic = getValueFromMap(latestReadings, "收缩压", "systolic", "systolicPressure", "highPressure", "高压");
            Object diastolic = getValueFromMap(latestReadings, "舒张压", "diastolic", "diastolicPressure", "lowPressure", "低压");
            Object bloodPressure = getValueFromMap(latestReadings, "血压", "bloodPressure");

            if (bloodPressure != null) {
                String bpStr = String.valueOf(bloodPressure);
                if (bpStr.contains("/")) {
                    String[] parts = bpStr.split("/");
                    if (parts.length == 2) {
                        try {
                            double sys = Double.parseDouble(parts[0].trim());
                            double dia = Double.parseDouble(parts[1].trim());
                            return sys >= 140 || dia >= 90 || sys < 90 || dia < 60;
                        } catch (NumberFormatException e) {
                            // 继续检查其他方式
                        }
                    }
                }
            }

            if (systolic != null) {
                double sys = parseDoubleValue(systolic);
                if (sys >= 140 || sys < 90) {
                    return true;
                }
            }

            if (diastolic != null) {
                double dia = parseDoubleValue(diastolic);
                if (dia >= 90 || dia < 60) {
                    return true;
                }
            }
        } catch (Exception e) {
            // 解析失败，返回 false
        }
        return false;
    }

    /**
     * 检查是否有血糖异常
     */
    private boolean hasBloodSugarAbnormality(Map<String, Object> latestReadings) {
        if (latestReadings == null || latestReadings.isEmpty()) {
            return false;
        }
        try {
            Object bloodSugar = getValueFromMap(latestReadings, "血糖", "bloodSugar", "glucose", "空腹血糖");
            if (bloodSugar != null) {
                double sugar = parseDoubleValue(bloodSugar);
                // 空腹血糖正常范围 3.9-6.1 mmol/L
                return sugar >= 7.0 || sugar < 3.9;
            }
        } catch (Exception e) {
            // 解析失败，返回 false
        }
        return false;
    }

    /**
     * 检查是否有睡眠问题
     */
    private boolean hasSleepProblem(Object healthArchive, Map<String, Object> latestReadings) {
        // 检查健康指标中的睡眠相关数据
        if (latestReadings != null && !latestReadings.isEmpty()) {
            Object sleepQuality = getValueFromMap(latestReadings, "睡眠质量", "sleepQuality", "sleep", "睡眠");
            if (sleepQuality != null) {
                String sleepStr = String.valueOf(sleepQuality).toLowerCase();
                if (sleepStr.contains("差") || sleepStr.contains("不好") || sleepStr.contains("失眠")
                        || sleepStr.contains("poor") || sleepStr.contains("bad") || sleepStr.contains("insomnia")) {
                    return true;
                }
            }
            Object sleepDuration = getValueFromMap(latestReadings, "睡眠时长", "sleepDuration", "睡眠时间");
            if (sleepDuration != null) {
                double hours = parseDoubleValue(sleepDuration);
                if (hours > 0 && (hours < 5 || hours > 10)) {
                    return true;
                }
            }
        }

        // 检查健康档案中的病史
        if (healthArchive != null) {
            String archiveStr = healthArchive.toString();
            if (archiveStr.contains("失眠") || archiveStr.contains("睡眠障碍") || archiveStr.contains("睡眠不好")) {
                return true;
            }
        }

        return false;
    }

    /**
     * 检查是否有体质偏颇
     */
    private boolean hasConstitutionImbalance(Object healthArchive) {
        // 常见的偏颇体质类型
        String[] imbalanceTypes = {"气虚", "阳虚", "阴虚", "痰湿", "湿热", "血瘀", "气郁", "特禀"};

        // 检查健康档案中的体质类型
        if (healthArchive != null) {
            String archiveStr = healthArchive.toString();
            for (String type : imbalanceTypes) {
                if (archiveStr.contains(type + "质")) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * 从医生列表中查找匹配的科室
     */
    private String findMatchingDepartment(List<DoctorProfile> doctors, String... keywords) {
        for (DoctorProfile doctor : doctors) {
            String dept = doctor.getDepartment() != null ? doctor.getDepartment() : doctor.getSpecialty();
            if (dept != null) {
                for (String keyword : keywords) {
                    if (dept.contains(keyword)) {
                        return keyword;
                    }
                }
            }
        }
        return null;
    }

    /**
     * 从 Map 中根据多个可能的 key 获取值
     */
    private Object getValueFromMap(Map<String, Object> map, String... keys) {
        if (map == null || keys == null) {
            return null;
        }
        for (String key : keys) {
            if (map.containsKey(key)) {
                return map.get(key);
            }
            // 不区分大小写的查找
            for (Map.Entry<String, Object> entry : map.entrySet()) {
                if (entry.getKey().equalsIgnoreCase(key)) {
                    return entry.getValue();
                }
            }
        }
        return null;
    }

    /**
     * 将对象解析为 double 值
     */
    private double parseDoubleValue(Object value) {
        if (value == null) {
            return 0;
        }
        if (value instanceof Number) {
            return ((Number) value).doubleValue();
        }
        try {
            // 尝试去除单位后解析
            String str = String.valueOf(value).trim();
            // 移除非数字字符（保留小数点和负号）
            str = str.replaceAll("[^0-9.\\-]", "");
            return Double.parseDouble(str);
        } catch (NumberFormatException e) {
            return 0;
        }
    }
}
