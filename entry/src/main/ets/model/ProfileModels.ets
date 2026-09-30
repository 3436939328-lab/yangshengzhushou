import { ConstitutionResult } from './WellnessModels';

// ==================== 问卷相关 ====================

export interface QuestionnaireOption {
  label: string;
  score: number;
}

export interface QuestionnaireQuestion {
  id: string;
  group: string;
  title: string;
  options: QuestionnaireOption[];
}

export interface QuestionnaireAnswer {
  questionId: string;
  score: number;
  label: string;
}

export interface QuestionnaireRecord {
  id?: string;
  submittedAt: string;
  answers: QuestionnaireAnswer[];
  totalScore: number;
  constitution: ConstitutionResult;
  suggestion: string;
}

// ==================== 健康指标类型枚举 ====================

/**
 * 健康指标类型编码
 */
export enum MetricCode {
  BLOOD_PRESSURE = 'BLOOD_PRESSURE',
  BLOOD_SUGAR = 'BLOOD_SUGAR',
  HEART_RATE = 'HEART_RATE',
  BLOOD_OXYGEN = 'BLOOD_OXYGEN',
  TEMPERATURE = 'TEMPERATURE',
  BODY = 'BODY',
  STEPS = 'STEPS',
  EXERCISE = 'EXERCISE',
  WATER = 'WATER',
  SLEEP = 'SLEEP'
}

/**
 * 血糖类型
 */
export enum BloodSugarType {
  FASTING = 'FASTING',           // 空腹
  POST_MEAL_2H = 'POST_MEAL_2H', // 餐后两小时
  RANDOM = 'RANDOM'              // 随机
}

/**
 * 心率情境
 */
export enum HeartRateContext {
  RESTING = 'RESTING',     // 静息
  AFTER_EXERCISE = 'AFTER_EXERCISE', // 运动后
  UNKNOWN = 'UNKNOWN'      // 未知
}

/**
 * 体温测量部位
 */
export enum TemperatureSite {
  ORAL = 'ORAL',       // 口腔
  AXILLARY = 'AXILLARY', // 腋下
  EAR = 'EAR',         // 耳温
  FOREHEAD = 'FOREHEAD', // 额温
  RECTAL = 'RECTAL'    // 直肠
}

/**
 * 血压测量体位
 */
export enum BloodPressurePosition {
  SITTING = 'SITTING',   // 坐位
  STANDING = 'STANDING', // 立位
  LYING = 'LYING'        // 卧位
}

/**
 * 血压测量手臂
 */
export enum BloodPressureArm {
  LEFT = 'LEFT',     // 左臂
  RIGHT = 'RIGHT'    // 右臂
}

/**
 * 睡眠类型
 */
export enum SleepType {
  MAIN = 'MAIN',     // 夜间主睡眠
  NAP = 'NAP'        // 小睡
}

/**
 * 睡眠阶段代码
 */
export enum SleepStageCode {
  AWAKE = 'AWAKE',   // 清醒
  LIGHT = 'LIGHT',   // 浅睡
  DEEP = 'DEEP',     // 深睡
  REM = 'REM',       // 快速眼动
  UNKNOWN = 'UNKNOWN' // 未分类
}

/**
 * 数据来源
 */
export enum DataSource {
  MANUAL = 'MANUAL',           // 手工录入
  DEVICE = 'DEVICE',           // 设备同步
  WEARABLE = 'WEARABLE'        // 可穿戴设备
}

/**
 * 异常状态
 */
export enum AssessmentState {
  IN_RANGE = 'IN_RANGE',       // 范围内
  ATTENTION = 'ATTENTION',     // 需要关注
  URGENT = 'URGENT',           // 需及时处理
  UNKNOWN = 'UNKNOWN'          // 无法判定
}

/**
 * 睡眠主观感受
 */
export enum SleepSubjectiveFeeling {
  GOOD = 'GOOD',       // 精神良好
  FAIR = 'FAIR',       // 一般
  TIRED = 'TIRED'      // 困倦
}

// ==================== 结构化健康指标记录 ====================

/**
 * 基础测量记录（所有指标的公共字段）
 */
export interface BaseMeasurement {
  id?: string;
  ownerId?: string;
  metricCode: MetricCode;
  measuredAt: string;     // ISO 时间戳
  timezone?: string;      // 时区，如 Asia/Shanghai
  source: DataSource;
  sourceName?: string;    // 来源名称，如设备名
  providerRecordId?: string; // 来源设备记录ID
  version?: number;
  qualityStatus?: string; // 数据质量状态
  note?: string;          // 备注
  createdAt?: string;
  updatedAt?: string;
  syncStatus?: 'pending' | 'synced' | 'failed'; // 同步状态
  assessment?: AssessmentState; // 评估状态
  assessmentReason?: string;   // 评估原因
}

/**
 * 血压记录
 */
export interface BloodPressureMeasurement extends BaseMeasurement {
  metricCode: MetricCode.BLOOD_PRESSURE;
  systolic: number;         // 收缩压（高压）mmHg
  diastolic: number;        // 舒张压（低压）mmHg
  pulse?: number;           // 脉搏 次/分
  position?: BloodPressurePosition; // 体位
  arm?: BloodPressureArm;   // 左右臂
}

/**
 * 血糖记录
 */
export interface BloodSugarMeasurement extends BaseMeasurement {
  metricCode: MetricCode.BLOOD_SUGAR;
  value: number;            // 血糖值 mmol/L
  sugarType: BloodSugarType; // 血糖类型
  measureMethod?: string;   // 测量方式
}

/**
 * 心率记录
 */
export interface HeartRateMeasurement extends BaseMeasurement {
  metricCode: MetricCode.HEART_RATE;
  value: number;            // 心率值 次/分
  context: HeartRateContext; // 测量情境
}

/**
 * 血氧记录
 */
export interface BloodOxygenMeasurement extends BaseMeasurement {
  metricCode: MetricCode.BLOOD_OXYGEN;
  value: number;            // 血氧饱和度 %
}

/**
 * 体温记录
 */
export interface TemperatureMeasurement extends BaseMeasurement {
  metricCode: MetricCode.TEMPERATURE;
  value: number;            // 温度 ℃
  site: TemperatureSite;    // 测量部位
}

/**
 * 体格记录（身高、体重、BMI）
 */
export interface BodyMeasurement extends BaseMeasurement {
  metricCode: MetricCode.BODY;
  heightCm?: number;        // 身高 cm
  weightKg?: number;        // 体重 kg
  waistCm?: number;         // 腰围 cm
  bmi?: number;             // BMI（自动计算）
}

/**
 * 步数记录
 */
export interface StepsMeasurement extends BaseMeasurement {
  metricCode: MetricCode.STEPS;
  steps: number;            // 步数
}

/**
 * 运动记录
 */
export interface ExerciseMeasurement extends BaseMeasurement {
  metricCode: MetricCode.EXERCISE;
  durationMinutes: number;  // 运动时长 分钟
  exerciseType?: string;    // 运动类型
  calories?: number;        // 消耗卡路里
}

/**
 * 饮水记录
 */
export interface WaterMeasurement extends BaseMeasurement {
  metricCode: MetricCode.WATER;
  amountMl: number;         // 饮水量 mL
}

/**
 * 睡眠阶段
 */
export interface SleepStageEntry {
  startAt: string;          // 阶段开始时间
  endAt: string;            // 阶段结束时间
  stageCode: SleepStageCode; // 阶段代码
  source?: string;          // 数据来源
}

/**
 * 睡眠记录
 */
export interface SleepMeasurement extends BaseMeasurement {
  metricCode: MetricCode.SLEEP;
  sleepStartAt: string;     // 入睡时间
  sleepEndAt: string;       // 醒来时间
  bedAt?: string;           // 上床时间（可选）
  outOfBedAt?: string;      // 离床时间（可选）
  totalSleepMinutes: number; // 总睡眠时长（分钟）
  lightMinutes?: number;    // 浅睡分钟数
  deepMinutes?: number;     // 深睡分钟数
  remMinutes?: number;      // REM 分钟数
  awakeMinutes?: number;    // 清醒分钟数
  awakenings?: number;      // 觉醒次数
  unknownMinutes?: number;  // 未分类阶段分钟数
  stages?: SleepStageEntry[]; // 睡眠阶段时间线（可选）
  sleepType: SleepType;     // 主睡眠/小睡
  subjectiveFeeling?: SleepSubjectiveFeeling; // 主观感受
  feelingNote?: string;     // 主观感受备注
}

/**
 * 统一的测量记录类型
 */
export type HealthMeasurement =
  | BloodPressureMeasurement
  | BloodSugarMeasurement
  | HeartRateMeasurement
  | BloodOxygenMeasurement
  | TemperatureMeasurement
  | BodyMeasurement
  | StepsMeasurement
  | ExerciseMeasurement
  | WaterMeasurement
  | SleepMeasurement;

// ==================== 舌象相关 ====================

/**
 * 舌象照片质量状态
 */
export enum TongueImageQualityStatus {
  PENDING = 'PENDING',           // 待检查
  ANALYZABLE = 'ANALYZABLE',     // 可分析
  NEED_RETAKE = 'NEED_RETAKE'    // 需要重拍
}

/**
 * 舌象分析状态
 */
export enum TongueAnalysisStatus {
  PENDING_UPLOAD = 'PENDING_UPLOAD',   // 待上传
  UPLOADING = 'UPLOADING',             // 上传中
  QUEUED = 'QUEUED',                   // 排队中
  ANALYZING = 'ANALYZING',             // 分析中
  SUCCESS = 'SUCCESS',                 // 成功
  FAILED = 'FAILED',                   // 失败
  CANCELLED = 'CANCELLED'              // 已取消
}

/**
 * 舌象照片记录
 */
export interface TongueImageRecord {
  id: string;
  ownerId?: string;
  imageUrl?: string;           // 图片访问URL（短期）
  thumbnailUrl?: string;       // 缩略图URL
  imageAssetId?: string;       // 图片资源ID（私有存储）
  capturedAt: string;          // 拍摄时间
  uploadedAt?: string;         // 上传时间
  source: 'CAMERA' | 'ALBUM';  // 来源：相机/相册
  qualityStatus: TongueImageQualityStatus; // 质量状态
  qualityNote?: string;        // 质量备注
  analysisStatus: TongueAnalysisStatus; // 分析状态
  analysisId?: string;         // 分析任务ID
  analysisResult?: TongueObservationNote; // 分析结果
  modelVersion?: string;       // 模型版本
  note?: string;               // 用户备注
  isDeleted?: boolean;         // 是否已删除
}

/**
 * 舌象观察记录（保留旧接口兼容）
 */
export interface TongueObservationNote {
  id?: string;
  color: string;               // 舌色
  coating: string;             // 舌苔
  dryness: string;             // 干湿
  note: string;                // 备注
  recordedAt: string;          // 记录时间
  imageId?: string;            // 关联的照片ID
  source?: 'MANUAL' | 'AI';    // 来源：手动/AI
}

// ==================== 提醒相关 ====================

export interface ReminderPreference {
  id?: string;
  title: string;
  time: string;
  enabled: boolean;
  category?: string;            // 提醒分类
  daysOfWeek?: number[];        // 重复的星期
  reminderId?: string;          // 系统提醒ID
}

// ==================== 健康档案扩展 ====================

/**
 * 用户个人资料
 */
export interface UserProfile {
  userId: string;
  nickname?: string;            // 昵称
  avatarAssetId?: string;       // 头像资源ID
  avatarUrl?: string;           // 头像URL（短期访问）
  userNo?: string;              // 用户编号
  birthday?: string;            // 出生日期
  gender?: 'MALE' | 'FEMALE' | 'OTHER' | 'UNKNOWN'; // 性别
  realName?: string;            // 真实姓名
  phone?: string;               // 手机号（脱敏）
}

/**
 * 参考范围规则
 */
export interface ReferenceRule {
  id: string;
  metricCode: MetricCode;
  unit: string;
  context?: string;             // 测量情境
  minValue?: number;            // 最小值
  maxValue?: number;            // 最大值
  attentionMin?: number;        // 关注下限
  attentionMax?: number;        // 关注上限
  urgentMin?: number;           // 紧急下限
  urgentMax?: number;           // 紧急上限
  applicableGroup?: string;     // 适用人群
  sourceName?: string;          // 来源名称
  version: string;              // 版本
  effectiveDate?: string;       // 生效日期
}

/**
 * 健康卡摘要（本人/亲人/问诊快照通用）
 */
export interface BloodPressureSummary {
  systolic: number;
  diastolic: number;
  pulse?: number;
  measuredAt: string;
  state: AssessmentState;
  stateText: string;
}

export interface BloodSugarSummary {
  value: number;
  unit: string;
  type: BloodSugarType;
  typeText: string;
  measuredAt: string;
  state: AssessmentState;
  stateText: string;
}

export interface HeartRateSummary {
  value: number;
  unit: string;
  context: HeartRateContext;
  measuredAt: string;
  state: AssessmentState;
  stateText: string;
}

export interface BloodOxygenSummary {
  value: number;
  unit: string;
  measuredAt: string;
  state: AssessmentState;
  stateText: string;
}

export interface TemperatureSummary {
  value: number;
  unit: string;
  site: TemperatureSite;
  measuredAt: string;
  state: AssessmentState;
  stateText: string;
}

export interface BodySummary {
  heightCm?: number;
  weightKg?: number;
  bmi?: number;
  measuredAt: string;
  state: AssessmentState;
  stateText: string;
}

export interface SleepSummary {
  totalMinutes: number;
  totalText: string;
  sleepType: SleepType;
  measuredAt: string;
  source: string;
  state: AssessmentState;
  stateText: string;
  lightMinutes?: number;
  deepMinutes?: number;
  remMinutes?: number;
}

export interface StepsSummary {
  steps: number;
  measuredAt: string;
  source: string;
}

export interface HealthCardSummary {
  subjectId: string;            // 数据所属人ID
  subjectName: string;          // 所属人名称
  generatedAt: string;          // 生成时间
  dataVersion?: string;         // 数据版本
  attentionCount: number;       // 需要关注的项数
  urgentCount: number;          // 紧急项数
  missingCategories: string[];  // 缺失的类别
  olderItemsNote?: string;      // 较旧项说明

  // 各类别最新记录摘要
  bloodPressure?: BloodPressureSummary;
  bloodSugar?: BloodSugarSummary;
  heartRate?: HeartRateSummary;
  bloodOxygen?: BloodOxygenSummary;
  temperature?: TemperatureSummary;
  body?: BodySummary;
  sleep?: SleepSummary;
  steps?: StepsSummary;
}

// ==================== 旧接口兼容 ====================

/**
 * 旧版简单健康指标条目（保留向后兼容）
 */
export interface HealthIndicatorEntry {
  id?: string;
  name: string;
  value: string;
  unit: string;
  recordedAt: string;
}

/**
 * 健康档案（保留原有结构，扩展新字段）
 */
export interface HealthProfile {
  id: string;
  displayName: string;
  constitution: ConstitutionResult;
  questionnaireRecords: QuestionnaireRecord[];
  healthIndicators: HealthIndicatorEntry[];  // 旧格式，保留兼容
  tongueNotes: TongueObservationNote[];
  reminderPreferences: ReminderPreference[];
  updatedAt: string;

  // 新增：结构化测量记录
  measurements?: HealthMeasurement[];
  // 新增：舌象照片记录
  tongueImages?: TongueImageRecord[];
  // 新增：用户个人资料
  userProfile?: UserProfile;
  // 新增：健康卡摘要缓存
  healthCard?: HealthCardSummary;
}
