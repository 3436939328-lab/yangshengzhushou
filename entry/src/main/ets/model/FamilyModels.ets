import { HealthCardSummary } from './ProfileModels';

/**
 * 亲人关系状态
 */
export enum FamilyRelationStatus {
  PENDING = 'PENDING',
  ACTIVE = 'ACTIVE',
  REJECTED = 'REJECTED',
  EXPIRED = 'EXPIRED',
  REMOVED = 'REMOVED'
}

/**
 * 亲人关系类型
 */
export enum FamilyRelationType {
  PARENT = 'PARENT',
  SPOUSE = 'SPOUSE',
  CHILD = 'CHILD',
  SIBLING = 'SIBLING',
  OTHER = 'OTHER'
}

/**
 * 共享类别
 */
export enum ShareCategory {
  BLOOD_PRESSURE = 'BLOOD_PRESSURE',
  BLOOD_SUGAR = 'BLOOD_SUGAR',
  HEART_RATE = 'HEART_RATE',
  BLOOD_OXYGEN = 'BLOOD_OXYGEN',
  TEMPERATURE = 'TEMPERATURE',
  BODY = 'BODY',
  SLEEP = 'SLEEP',
  EXERCISE = 'EXERCISE',
  WATER = 'WATER',
  TONGUE = 'TONGUE',
  AI_ANALYSIS = 'AI_ANALYSIS',
  ABNORMAL_NOTIFY = 'ABNORMAL_NOTIFY'
}

/**
 * 共享分组类型
 */
export type ShareGroup = 'vital' | 'lifestyle' | 'analysis' | 'notify';

/**
 * 共享类别配置项
 */
export interface ShareCategoryConfigItem {
  category: ShareCategory;
  label: string;
  description: string;
  icon: string;
  group: ShareGroup;
}

/**
 * 亲人血压信息
 */
export interface FamilyBloodPressureInfo {
  systolic: number;
  diastolic: number;
  measuredAt: string;
  status: string;
}

/**
 * 亲人血糖信息
 */
export interface FamilyBloodSugarInfo {
  value: number;
  unit: string;
  type: string;
  measuredAt: string;
  status: string;
}

/**
 * 亲人心率信息
 */
export interface FamilyHeartRateInfo {
  value: number;
  unit: string;
  measuredAt: string;
  status: string;
}

/**
 * 亲人睡眠信息
 */
export interface FamilySleepInfo {
  totalMinutes: number;
  measuredAt: string;
  source: string;
}

/**
 * 亲人体重信息
 */
export interface FamilyWeightInfo {
  value: number;
  bmi?: number;
  measuredAt: string;
}

/**
 * 亲人健康卡数据
 */
export interface FamilyMemberCard {
  id: string;
  relationId: string;
  displayName: string;
  relationType: FamilyRelationType;
  relationLabel: string;
  avatar?: string;
  lastUpdateTime: string;
  attentionCount: number;
  status: FamilyRelationStatus;
  grantedCategories: ShareCategory[];
  historyWindowDays: number;
  bloodPressure?: FamilyBloodPressureInfo;
  bloodSugar?: FamilyBloodSugarInfo;
  heartRate?: FamilyHeartRateInfo;
  sleep?: FamilySleepInfo;
  weight?: FamilyWeightInfo;
  healthCard?: HealthCardSummary | null;
}

/**
 * 亲人邀请
 */
export interface FamilyInvitation {
  id: string;
  inviterId: string;
  inviteePhone: string;
  relationType: FamilyRelationType;
  relationLabel: string;
  status: FamilyRelationStatus;
  expiresAt: string;
  createdAt: string;
}
