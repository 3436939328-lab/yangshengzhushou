package org.example.springbootdemo.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.example.springbootdemo.bean.HealthCardSummary;
import org.example.springbootdemo.bean.StructuredHealthMeasurement;
import org.example.springbootdemo.dao.StructuredHealthMeasurementDao;
import org.springframework.stereotype.Service;

import java.text.SimpleDateFormat;
import java.util.*;

/**
 * 健康卡服务
 * 负责健康指标评估、健康卡摘要构建
 */
@Service
public class HealthCardService {

    private final StructuredHealthMeasurementDao measurementDao;
    private final ObjectMapper objectMapper = new ObjectMapper();

    // 指标编码常量
    public static final String METRIC_BLOOD_PRESSURE = "BLOOD_PRESSURE";
    public static final String METRIC_BLOOD_SUGAR = "BLOOD_SUGAR";
    public static final String METRIC_HEART_RATE = "HEART_RATE";
    public static final String METRIC_BLOOD_OXYGEN = "BLOOD_OXYGEN";
    public static final String METRIC_TEMPERATURE = "TEMPERATURE";
    public static final String METRIC_BODY = "BODY";
    public static final String METRIC_STEPS = "STEPS";
    public static final String METRIC_EXERCISE = "EXERCISE";
    public static final String METRIC_WATER = "WATER";
    public static final String METRIC_SLEEP = "SLEEP";

    // 评估状态
    public static final String STATE_IN_RANGE = "IN_RANGE";
    public static final String STATE_ATTENTION = "ATTENTION";
    public static final String STATE_URGENT = "URGENT";
    public static final String STATE_UNKNOWN = "UNKNOWN";

    public HealthCardService(StructuredHealthMeasurementDao measurementDao) {
        this.measurementDao = measurementDao;
    }

    /**
     * 构建指定用户的健康卡摘要
     */
    public HealthCardSummary buildHealthCard(Long userId, String subjectName) {
        HealthCardSummary card = new HealthCardSummary();
        card.setSubjectId(String.valueOf(userId));
        card.setSubjectName(subjectName);
        card.setGeneratedAt(new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss").format(new Date()));
        card.setAttentionCount(0);
        card.setUrgentCount(0);
        card.setMissingCategories(new ArrayList<>());

        // 获取各指标最新记录
        StructuredHealthMeasurement bp = measurementDao.selectLatestByUserIdAndMetric(userId, METRIC_BLOOD_PRESSURE);
        StructuredHealthMeasurement bs = measurementDao.selectLatestByUserIdAndMetric(userId, METRIC_BLOOD_SUGAR);
        StructuredHealthMeasurement hr = measurementDao.selectLatestByUserIdAndMetric(userId, METRIC_HEART_RATE);
        StructuredHealthMeasurement bo = measurementDao.selectLatestByUserIdAndMetric(userId, METRIC_BLOOD_OXYGEN);
        StructuredHealthMeasurement temp = measurementDao.selectLatestByUserIdAndMetric(userId, METRIC_TEMPERATURE);
        StructuredHealthMeasurement body = measurementDao.selectLatestByUserIdAndMetric(userId, METRIC_BODY);
        StructuredHealthMeasurement sleep = measurementDao.selectLatestByUserIdAndMetric(userId, METRIC_SLEEP);
        StructuredHealthMeasurement steps = measurementDao.selectLatestByUserIdAndMetric(userId, METRIC_STEPS);

        // 血压
        if (bp != null) {
            HealthCardSummary.MetricSummary summary = assessBloodPressure(bp);
            card.setBloodPressure(summary);
            if (STATE_ATTENTION.equals(summary.getState())) card.setAttentionCount(card.getAttentionCount() + 1);
            if (STATE_URGENT.equals(summary.getState())) card.setUrgentCount(card.getUrgentCount() + 1);
        } else {
            card.getMissingCategories().add(METRIC_BLOOD_PRESSURE);
        }

        // 血糖
        if (bs != null) {
            HealthCardSummary.MetricSummary summary = assessBloodSugar(bs);
            card.setBloodSugar(summary);
            if (STATE_ATTENTION.equals(summary.getState())) card.setAttentionCount(card.getAttentionCount() + 1);
            if (STATE_URGENT.equals(summary.getState())) card.setUrgentCount(card.getUrgentCount() + 1);
        } else {
            card.getMissingCategories().add(METRIC_BLOOD_SUGAR);
        }

        // 心率
        if (hr != null) {
            HealthCardSummary.MetricSummary summary = assessHeartRate(hr);
            card.setHeartRate(summary);
            if (STATE_ATTENTION.equals(summary.getState())) card.setAttentionCount(card.getAttentionCount() + 1);
            if (STATE_URGENT.equals(summary.getState())) card.setUrgentCount(card.getUrgentCount() + 1);
        } else {
            card.getMissingCategories().add(METRIC_HEART_RATE);
        }

        // 血氧
        if (bo != null) {
            HealthCardSummary.MetricSummary summary = assessBloodOxygen(bo);
            card.setBloodOxygen(summary);
            if (STATE_ATTENTION.equals(summary.getState())) card.setAttentionCount(card.getAttentionCount() + 1);
            if (STATE_URGENT.equals(summary.getState())) card.setUrgentCount(card.getUrgentCount() + 1);
        } else {
            card.getMissingCategories().add(METRIC_BLOOD_OXYGEN);
        }

        // 体温
        if (temp != null) {
            HealthCardSummary.MetricSummary summary = assessTemperature(temp);
            card.setTemperature(summary);
            if (STATE_ATTENTION.equals(summary.getState())) card.setAttentionCount(card.getAttentionCount() + 1);
            if (STATE_URGENT.equals(summary.getState())) card.setUrgentCount(card.getUrgentCount() + 1);
        } else {
            card.getMissingCategories().add(METRIC_TEMPERATURE);
        }

        // 体格
        if (body != null) {
            HealthCardSummary.BodySummary summary = assessBody(body);
            card.setBody(summary);
            if (STATE_ATTENTION.equals(summary.getState())) card.setAttentionCount(card.getAttentionCount() + 1);
            if (STATE_URGENT.equals(summary.getState())) card.setUrgentCount(card.getUrgentCount() + 1);
        }

        // 睡眠
        if (sleep != null) {
            HealthCardSummary.SleepSummary summary = assessSleep(sleep);
            card.setSleep(summary);
            if (STATE_ATTENTION.equals(summary.getState())) card.setAttentionCount(card.getAttentionCount() + 1);
            if (STATE_URGENT.equals(summary.getState())) card.setUrgentCount(card.getUrgentCount() + 1);
        } else {
            card.getMissingCategories().add(METRIC_SLEEP);
        }

        // 步数
        if (steps != null) {
            HealthCardSummary.StepsSummary summary = new HealthCardSummary.StepsSummary();
            JsonNode json = parseJson(steps.getTypeSpecificJson());
            if (json != null && json.has("steps")) {
                summary.setSteps(json.get("steps").asInt());
            }
            summary.setMeasuredAt(steps.getMeasuredAt());
            summary.setSource(steps.getSourceName() != null ? steps.getSourceName() : "手动记录");
            card.setSteps(summary);
        }

        return card;
    }

    // ==================== 各指标评估方法 ====================

    private HealthCardSummary.MetricSummary assessBloodPressure(StructuredHealthMeasurement m) {
        HealthCardSummary.MetricSummary summary = new HealthCardSummary.MetricSummary();
        summary.setMeasuredAt(m.getMeasuredAt());

        JsonNode json = parseJson(m.getTypeSpecificJson());
        double systolic = 0, diastolic = 0;
        if (json != null) {
            systolic = json.has("systolic") ? json.get("systolic").asDouble() : 0;
            diastolic = json.has("diastolic") ? json.get("diastolic").asDouble() : 0;
        }
        summary.setValueText(String.format("%.0f/%.0f mmHg", systolic, diastolic));

        // 收缩压评估
        String sysState = assessRange(systolic, 90, 140, 80, 160);
        // 舒张压评估
        String diaState = assessRange(diastolic, 60, 90, 50, 100);
        // 取更严重的
        String state = getWorseState(sysState, diaState);
        summary.setState(state);
        summary.setStateText(stateText(state));
        return summary;
    }

    private HealthCardSummary.MetricSummary assessBloodSugar(StructuredHealthMeasurement m) {
        HealthCardSummary.MetricSummary summary = new HealthCardSummary.MetricSummary();
        summary.setMeasuredAt(m.getMeasuredAt());

        JsonNode json = parseJson(m.getTypeSpecificJson());
        double value = 0;
        String sugarType = "FASTING";
        if (json != null) {
            value = json.has("value") ? json.get("value").asDouble() : 0;
            sugarType = json.has("sugarType") ? json.get("sugarType").asText() : "FASTING";
        }

        String typeText = switch (sugarType) {
            case "FASTING" -> "空腹";
            case "POST_MEAL_2H" -> "餐后2小时";
            case "RANDOM" -> "随机";
            default -> sugarType;
        };
        summary.setValueText(String.format("%.1f mmol/L · %s", value, typeText));

        String state;
        if ("FASTING".equals(sugarType)) {
            state = assessRange(value, 3.9, 6.1, 3.0, 7.0);
        } else if ("POST_MEAL_2H".equals(sugarType)) {
            state = assessRange(value, 3.9, 7.8, 3.0, 11.1);
        } else {
            state = assessRange(value, 3.9, 11.1, 3.0, 13.9);
        }
        summary.setState(state);
        summary.setStateText(stateText(state));
        return summary;
    }

    private HealthCardSummary.MetricSummary assessHeartRate(StructuredHealthMeasurement m) {
        HealthCardSummary.MetricSummary summary = new HealthCardSummary.MetricSummary();
        summary.setMeasuredAt(m.getMeasuredAt());

        JsonNode json = parseJson(m.getTypeSpecificJson());
        double value = 0;
        String context = "RESTING";
        if (json != null) {
            value = json.has("value") ? json.get("value").asDouble() : 0;
            context = json.has("context") ? json.get("context").asText() : "RESTING";
        }
        summary.setValueText(String.format("%.0f 次/分", value));

        String state;
        if ("RESTING".equals(context)) {
            state = assessRange(value, 60, 100, 50, 120);
        } else {
            state = assessRange(value, 50, 120, 40, 150);
        }
        summary.setState(state);
        summary.setStateText(stateText(state));
        return summary;
    }

    private HealthCardSummary.MetricSummary assessBloodOxygen(StructuredHealthMeasurement m) {
        HealthCardSummary.MetricSummary summary = new HealthCardSummary.MetricSummary();
        summary.setMeasuredAt(m.getMeasuredAt());

        JsonNode json = parseJson(m.getTypeSpecificJson());
        double value = json != null && json.has("value") ? json.get("value").asDouble() : 0;
        summary.setValueText(String.format("%.0f%%", value));

        // 血氧：≥95正常，90-94关注，<90紧急
        String state;
        if (value >= 95) state = STATE_IN_RANGE;
        else if (value >= 90) state = STATE_ATTENTION;
        else state = STATE_URGENT;

        summary.setState(state);
        summary.setStateText(stateText(state));
        return summary;
    }

    private HealthCardSummary.MetricSummary assessTemperature(StructuredHealthMeasurement m) {
        HealthCardSummary.MetricSummary summary = new HealthCardSummary.MetricSummary();
        summary.setMeasuredAt(m.getMeasuredAt());

        JsonNode json = parseJson(m.getTypeSpecificJson());
        double value = 0;
        String site = "AXILLARY";
        if (json != null) {
            value = json.has("value") ? json.get("value").asDouble() : 0;
            site = json.has("site") ? json.get("site").asText() : "AXILLARY";
        }
        summary.setValueText(String.format("%.1f℃", value));

        String state;
        if ("ORAL".equals(site)) {
            state = assessRange(value, 36.3, 37.2, 35.8, 38.5);
        } else {
            // 腋下默认
            state = assessRange(value, 36.0, 37.3, 35.5, 38.5);
        }
        summary.setState(state);
        summary.setStateText(stateText(state));
        return summary;
    }

    private HealthCardSummary.BodySummary assessBody(StructuredHealthMeasurement m) {
        HealthCardSummary.BodySummary summary = new HealthCardSummary.BodySummary();
        summary.setMeasuredAt(m.getMeasuredAt());

        JsonNode json = parseJson(m.getTypeSpecificJson());
        Double height = null, weight = null, bmi = null;
        if (json != null) {
            if (json.has("heightCm") && !json.get("heightCm").isNull()) height = json.get("heightCm").asDouble();
            if (json.has("weightKg") && !json.get("weightKg").isNull()) weight = json.get("weightKg").asDouble();
            if (json.has("bmi") && !json.get("bmi").isNull()) bmi = json.get("bmi").asDouble();
        }

        summary.setHeightCm(height);
        summary.setWeightKg(weight);

        // 自动计算BMI
        if (bmi == null && height != null && weight != null && height > 0) {
            bmi = weight / ((height / 100) * (height / 100));
        }
        summary.setBmi(bmi);

        StringBuilder valueText = new StringBuilder();
        if (weight != null) valueText.append(String.format("%.1fkg", weight));
        if (bmi != null) valueText.append(String.format(" · BMI %.1f", bmi));
        summary.setValueText(valueText.length() > 0 ? valueText.toString() : "--");

        // BMI 评估（中国标准）
        String state = STATE_UNKNOWN;
        if (bmi != null) {
            if (bmi < 16.0 || bmi >= 28.0) state = STATE_URGENT;
            else if (bmi < 18.5 || bmi >= 24.0) state = STATE_ATTENTION;
            else state = STATE_IN_RANGE;
        }
        summary.setState(state);
        summary.setStateText(stateText(state));
        return summary;
    }

    private HealthCardSummary.SleepSummary assessSleep(StructuredHealthMeasurement m) {
        HealthCardSummary.SleepSummary summary = new HealthCardSummary.SleepSummary();
        summary.setMeasuredAt(m.getMeasuredAt());

        JsonNode json = parseJson(m.getTypeSpecificJson());
        int totalMinutes = 0;
        String sleepType = "MAIN";
        if (json != null) {
            totalMinutes = json.has("totalSleepMinutes") ? json.get("totalSleepMinutes").asInt() : 0;
            sleepType = json.has("sleepType") ? json.get("sleepType").asText() : "MAIN";
            if (json.has("lightMinutes")) summary.setLightMinutes(json.get("lightMinutes").asInt());
            if (json.has("deepMinutes")) summary.setDeepMinutes(json.get("deepMinutes").asInt());
            if (json.has("remMinutes")) summary.setRemMinutes(json.get("remMinutes").asInt());
        }

        summary.setTotalMinutes(totalMinutes);
        summary.setTotalText(formatSleepDuration(totalMinutes));
        summary.setSleepType(sleepType);
        summary.setSource(m.getSourceName() != null ? m.getSourceName() : "手动记录");
        summary.setValueText(formatSleepDuration(totalMinutes));

        // 睡眠时长评估（成人7-9小时）
        String state;
        if (sleepType.equals("MAIN")) {
            state = assessRange(totalMinutes, 420, 540, 300, 600);
        } else {
            state = STATE_UNKNOWN; // 小睡不评估
        }
        summary.setState(state);
        summary.setStateText(stateText(state));
        return summary;
    }

    // ==================== 工具方法 ====================

    /**
     * 范围评估：正常值在 attentionMin~attentionMax 之间
     */
    private String assessRange(double value, double attentionMin, double attentionMax,
                               double urgentMin, double urgentMax) {
        if (value < urgentMin || value > urgentMax) return STATE_URGENT;
        if (value < attentionMin || value > attentionMax) return STATE_ATTENTION;
        return STATE_IN_RANGE;
    }

    private String getWorseState(String state1, String state2) {
        Map<String, Integer> order = new HashMap<>();
        order.put(STATE_IN_RANGE, 0);
        order.put(STATE_UNKNOWN, 1);
        order.put(STATE_ATTENTION, 2);
        order.put(STATE_URGENT, 3);

        int o1 = order.getOrDefault(state1, 0);
        int o2 = order.getOrDefault(state2, 0);
        return o1 >= o2 ? state1 : state2;
    }

    private String stateText(String state) {
        return switch (state) {
            case STATE_IN_RANGE -> "正常";
            case STATE_ATTENTION -> "需要关注";
            case STATE_URGENT -> "需及时处理";
            default -> "未知";
        };
    }

    private String formatSleepDuration(int minutes) {
        int hours = minutes / 60;
        int mins = minutes % 60;
        if (mins == 0) return hours + "小时";
        return hours + "小时" + mins + "分";
    }

    private JsonNode parseJson(String json) {
        if (json == null || json.isBlank()) return null;
        try {
            return objectMapper.readTree(json);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * 保存测量记录并自动评估
     */
    public StructuredHealthMeasurement addMeasurement(StructuredHealthMeasurement record) {
        // 自动评估
        autoAssess(record);
        if (record.getVersion() == null) record.setVersion(1);
        if (record.getSource() == null) record.setSource("MANUAL");
        if (record.getIsDeleted() == null) record.setIsDeleted(false);
        if (record.getSyncStatus() == null) record.setSyncStatus("synced");
        if (record.getCreateTime() == null) record.setCreateTime(new Date());

        measurementDao.insertSelective(record);
        return record;
    }

    /**
     * 自动评估测量记录
     */
    public void autoAssess(StructuredHealthMeasurement record) {
        if (record == null || record.getMetricCode() == null) return;

        String state = STATE_UNKNOWN;
        String reason = "暂无参考范围";

        switch (record.getMetricCode()) {
            case METRIC_BLOOD_PRESSURE -> {
                JsonNode json = parseJson(record.getTypeSpecificJson());
                if (json != null && json.has("systolic") && json.has("diastolic")) {
                    double sys = json.get("systolic").asDouble();
                    double dia = json.get("diastolic").asDouble();
                    String sysState = assessRange(sys, 90, 140, 80, 160);
                    String diaState = assessRange(dia, 60, 90, 50, 100);
                    state = getWorseState(sysState, diaState);
                    reason = String.format("收缩压 %.0f mmHg，舒张压 %.0f mmHg（参考：90-140/60-90）", sys, dia);
                }
            }
            case METRIC_BLOOD_SUGAR -> {
                JsonNode json = parseJson(record.getTypeSpecificJson());
                if (json != null && json.has("value")) {
                    double val = json.get("value").asDouble();
                    String type = json.has("sugarType") ? json.get("sugarType").asText() : "FASTING";
                    if ("FASTING".equals(type)) {
                        state = assessRange(val, 3.9, 6.1, 3.0, 7.0);
                        reason = String.format("空腹血糖 %.1f mmol/L（参考：3.9-6.1）", val);
                    } else if ("POST_MEAL_2H".equals(type)) {
                        state = assessRange(val, 3.9, 7.8, 3.0, 11.1);
                        reason = String.format("餐后2小时血糖 %.1f mmol/L（参考：3.9-7.8）", val);
                    }
                }
            }
            case METRIC_HEART_RATE -> {
                JsonNode json = parseJson(record.getTypeSpecificJson());
                if (json != null && json.has("value")) {
                    double val = json.get("value").asDouble();
                    state = assessRange(val, 60, 100, 50, 120);
                    reason = String.format("心率 %.0f 次/分（参考：60-100）", val);
                }
            }
            case METRIC_BLOOD_OXYGEN -> {
                JsonNode json = parseJson(record.getTypeSpecificJson());
                if (json != null && json.has("value")) {
                    double val = json.get("value").asDouble();
                    if (val >= 95) state = STATE_IN_RANGE;
                    else if (val >= 90) state = STATE_ATTENTION;
                    else state = STATE_URGENT;
                    reason = String.format("血氧 %.0f%%（参考：≥95%%）", val);
                }
            }
            case METRIC_TEMPERATURE -> {
                JsonNode json = parseJson(record.getTypeSpecificJson());
                if (json != null && json.has("value")) {
                    double val = json.get("value").asDouble();
                    state = assessRange(val, 36.0, 37.3, 35.5, 38.5);
                    reason = String.format("体温 %.1f℃（参考：36.0-37.3）", val);
                }
            }
            case METRIC_BODY -> {
                JsonNode json = parseJson(record.getTypeSpecificJson());
                if (json != null) {
                    Double bmi = null;
                    if (json.has("bmi") && !json.get("bmi").isNull()) {
                        bmi = json.get("bmi").asDouble();
                    } else if (json.has("heightCm") && json.has("weightKg")) {
                        double h = json.get("heightCm").asDouble() / 100;
                        double w = json.get("weightKg").asDouble();
                        if (h > 0) bmi = w / (h * h);
                    }
                    if (bmi != null) {
                        if (bmi < 16.0 || bmi >= 28.0) state = STATE_URGENT;
                        else if (bmi < 18.5 || bmi >= 24.0) state = STATE_ATTENTION;
                        else state = STATE_IN_RANGE;
                        reason = String.format("BMI %.1f（参考：18.5-24.0）", bmi);
                    }
                }
            }
            case METRIC_SLEEP -> {
                JsonNode json = parseJson(record.getTypeSpecificJson());
                if (json != null && json.has("totalSleepMinutes")) {
                    int mins = json.get("totalSleepMinutes").asInt();
                    state = assessRange(mins, 420, 540, 300, 600);
                    reason = String.format("睡眠 %d分钟（参考：420-540分钟）", mins);
                }
            }
            default -> {
                state = STATE_UNKNOWN;
                reason = "该指标暂无参考范围";
            }
        }

        record.setAssessment(state);
        record.setAssessmentReason(reason);
    }
}
