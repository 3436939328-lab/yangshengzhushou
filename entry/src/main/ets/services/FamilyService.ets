import { http } from '@kit.NetworkKit';
import { buildApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';
import {
  AssessmentState,
  BloodPressureSummary,
  BloodSugarSummary,
  BodySummary,
  BloodSugarType,
  HeartRateContext,
  HeartRateSummary,
  HealthCardSummary,
  SleepSummary,
  SleepType
} from '../model/ProfileModels';

interface FamilyIndicatorPayload {
  name?: string;
  value?: string;
  unit?: string;
  recordedAt?: string;
}

interface FamilyArchivePayload {
  height?: number;
  weight?: number;
  constitutionType?: string;
  allergyHistory?: string;
  medicalHistory?: string;
  healthGoal?: string;
}

interface AssessmentResult {
  state: AssessmentState;
  stateText: string;
}

interface BloodPressureParts {
  systolic: number;
  diastolic: number;
}

interface FamilyHealthSummaryPayload {
  userId?: number;
  realName?: string;
  phone?: string;
  gender?: string;
  age?: number;
  avatar?: string;
  healthArchive?: FamilyArchivePayload;
  indicators?: FamilyIndicatorPayload[];
}

interface ApiResponsePayload {
  success?: boolean;
  message?: string;
  data?: FamilyHealthSummaryPayload;
}

export interface FamilyMemberInfo {
  userId: string;
  realName: string;
  phone: string;
  gender: string;
  age: number;
  avatar: string;
  healthCard: HealthCardSummary | null;
}

function parseResponse(payload: string): ApiResponsePayload {
  return JSON.parse(payload) as ApiResponsePayload;
}

function requestJson(url: string, method: http.RequestMethod, body?: Object): Promise<string> {
  const config = getApiConfig();
  const request = http.createHttp();
  return request.request(url, {
    method,
    header: buildAuthorizedJsonHeaders(),
    extraData: body ? JSON.stringify(body) : undefined,
    connectTimeout: config.timeoutMs,
    readTimeout: config.timeoutMs
  }).then((response: http.HttpResponse) => {
    request.destroy();
    if (response.responseCode < 200 || response.responseCode >= 300) {
      return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
    }
    return `${response.result}`;
  }).catch((error: Error) => {
    request.destroy();
    return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
  });
}

function findIndicator(indicators: FamilyIndicatorPayload[], ...names: string[]): FamilyIndicatorPayload | null {
  for (const name of names) {
    for (const item of indicators) {
      if (item.name && item.name.indexOf(name) >= 0) {
        return item;
      }
    }
  }
  return null;
}

function parseNumber(value: string | undefined): number {
  if (!value) return 0;
  const cleaned = value.replace(/[^0-9.]/g, '');
  const num = parseFloat(cleaned);
  return isNaN(num) ? 0 : num;
}

function parseBloodPressure(value: string | undefined): BloodPressureParts {
  if (!value) return { systolic: 0, diastolic: 0 } as BloodPressureParts;
  const parts = value.split('/');
  if (parts.length >= 2) {
    return { systolic: parseNumber(parts[0]), diastolic: parseNumber(parts[1]) } as BloodPressureParts;
  }
  return { systolic: parseNumber(value), diastolic: 0 } as BloodPressureParts;
}

function assessBloodPressure(systolic: number, diastolic: number): AssessmentResult {
  if (systolic === 0 && diastolic === 0) return { state: AssessmentState.UNKNOWN, stateText: '未记录' } as AssessmentResult;
  if (systolic >= 180 || diastolic >= 110) return { state: AssessmentState.URGENT, stateText: '三级高血压' } as AssessmentResult;
  if (systolic >= 160 || diastolic >= 100) return { state: AssessmentState.URGENT, stateText: '二级高血压' } as AssessmentResult;
  if (systolic >= 140 || diastolic >= 90) return { state: AssessmentState.ATTENTION, stateText: '偏高' } as AssessmentResult;
  if (systolic < 90 || diastolic < 60) return { state: AssessmentState.ATTENTION, stateText: '偏低' } as AssessmentResult;
  return { state: AssessmentState.IN_RANGE, stateText: '正常' } as AssessmentResult;
}

function assessBloodSugar(value: number): AssessmentResult {
  if (value === 0) return { state: AssessmentState.UNKNOWN, stateText: '未记录' } as AssessmentResult;
  if (value >= 11.1) return { state: AssessmentState.URGENT, stateText: '糖尿病范围' } as AssessmentResult;
  if (value >= 7.0) return { state: AssessmentState.ATTENTION, stateText: '偏高' } as AssessmentResult;
  if (value < 3.9) return { state: AssessmentState.ATTENTION, stateText: '偏低' } as AssessmentResult;
  return { state: AssessmentState.IN_RANGE, stateText: '正常' } as AssessmentResult;
}

function assessHeartRate(value: number): AssessmentResult {
  if (value === 0) return { state: AssessmentState.UNKNOWN, stateText: '未记录' } as AssessmentResult;
  if (value > 120 || value < 50) return { state: AssessmentState.URGENT, stateText: '异常' } as AssessmentResult;
  if (value > 100) return { state: AssessmentState.ATTENTION, stateText: '偏快' } as AssessmentResult;
  if (value < 60) return { state: AssessmentState.ATTENTION, stateText: '偏慢' } as AssessmentResult;
  return { state: AssessmentState.IN_RANGE, stateText: '正常' } as AssessmentResult;
}

function assessBmi(bmi: number): AssessmentResult {
  if (bmi === 0) return { state: AssessmentState.UNKNOWN, stateText: '未记录' } as AssessmentResult;
  if (bmi >= 28) return { state: AssessmentState.ATTENTION, stateText: '肥胖' } as AssessmentResult;
  if (bmi >= 24) return { state: AssessmentState.ATTENTION, stateText: '超重' } as AssessmentResult;
  if (bmi < 18.5) return { state: AssessmentState.ATTENTION, stateText: '偏瘦' } as AssessmentResult;
  return { state: AssessmentState.IN_RANGE, stateText: '正常' } as AssessmentResult;
}

export function fetchFamilyHealthSummary(phone: string): Promise<FamilyMemberInfo> {
  const url = buildApiUrl(`/api/family/health-summary?phone=${encodeURIComponent(phone)}`);
  return requestJson(url, http.RequestMethod.GET).then((payload: string) => {
    const response = parseResponse(payload);
    if (response.success !== true || !response.data) {
      throw new Error(response.message ? response.message : 'family health summary failed');
    }
    const data = response.data;
    const indicators = data.indicators ? data.indicators : [];

    const attentionItems: string[] = [];
    let attentionCount = 0;

    let bloodPressure: BloodPressureSummary | undefined;
    const bpRecord = findIndicator(indicators, '血压', 'blood_pressure', 'bloodPressure');
    if (bpRecord && bpRecord.value) {
      const bpParts = parseBloodPressure(bpRecord.value);
      const bpAssessment = assessBloodPressure(bpParts.systolic, bpParts.diastolic);
      if (bpAssessment.state !== AssessmentState.IN_RANGE && bpAssessment.state !== AssessmentState.UNKNOWN) {
        attentionCount++;
        attentionItems.push('血压');
      }
      bloodPressure = {
        systolic: bpParts.systolic,
        diastolic: bpParts.diastolic,
        measuredAt: bpRecord.recordedAt ? bpRecord.recordedAt : '',
        state: bpAssessment.state,
        stateText: bpAssessment.stateText
      };
    }

    let bloodSugar: BloodSugarSummary | undefined;
    const bsRecord = findIndicator(indicators, '血糖', 'blood_sugar', 'bloodSugar');
    if (bsRecord && bsRecord.value) {
      const value = parseNumber(bsRecord.value);
      const bsAssessment = assessBloodSugar(value);
      if (bsAssessment.state !== AssessmentState.IN_RANGE && bsAssessment.state !== AssessmentState.UNKNOWN) {
        attentionCount++;
        attentionItems.push('血糖');
      }
      bloodSugar = {
        value: value,
        unit: bsRecord.unit ? bsRecord.unit : 'mmol/L',
        type: BloodSugarType.FASTING,
        typeText: '空腹',
        measuredAt: bsRecord.recordedAt ? bsRecord.recordedAt : '',
        state: bsAssessment.state,
        stateText: bsAssessment.stateText
      };
    }

    let heartRate: HeartRateSummary | undefined;
    const hrRecord = findIndicator(indicators, '心率', 'heart_rate', 'heartRate');
    if (hrRecord && hrRecord.value) {
      const value = parseNumber(hrRecord.value);
      const hrAssessment = assessHeartRate(value);
      if (hrAssessment.state !== AssessmentState.IN_RANGE && hrAssessment.state !== AssessmentState.UNKNOWN) {
        attentionCount++;
        attentionItems.push('心率');
      }
      heartRate = {
        value: value,
        unit: hrRecord.unit ? hrRecord.unit : '次/分',
        context: HeartRateContext.RESTING,
        measuredAt: hrRecord.recordedAt ? hrRecord.recordedAt : '',
        state: hrAssessment.state,
        stateText: hrAssessment.stateText
      };
    }

    let body: BodySummary | undefined;
    const archive = data.healthArchive;
    const weightRecord = findIndicator(indicators, '体重', 'weight', 'body');
    const heightVal = archive && archive.height ? parseNumber(`${archive.height}`) : 0;
    const weightVal = weightRecord && weightRecord.value ? parseNumber(weightRecord.value) : (archive && archive.weight ? parseNumber(`${archive.weight}`) : 0);
    if (weightVal > 0 || heightVal > 0) {
      const bmi = heightVal > 0 ? Math.round((weightVal / (heightVal * heightVal / 10000)) * 10) / 10 : 0;
      const bodyAssessment = assessBmi(bmi);
      if (bodyAssessment.state !== AssessmentState.IN_RANGE && bodyAssessment.state !== AssessmentState.UNKNOWN) {
        attentionCount++;
        attentionItems.push('体重');
      }
      body = {
        heightCm: heightVal > 0 ? heightVal : undefined,
        weightKg: weightVal > 0 ? weightVal : undefined,
        bmi: bmi > 0 ? bmi : undefined,
        measuredAt: weightRecord && weightRecord.recordedAt ? weightRecord.recordedAt : '',
        state: bodyAssessment.state,
        stateText: bodyAssessment.stateText
      };
    }

    let sleep: SleepSummary | undefined;
    const sleepRecord = findIndicator(indicators, '睡眠', 'sleep');
    if (sleepRecord && sleepRecord.value) {
      const totalMinutes = parseNumber(sleepRecord.value);
      const sleepAssessment: AssessmentResult = totalMinutes >= 420
        ? { state: AssessmentState.IN_RANGE, stateText: '正常' } as AssessmentResult
        : { state: AssessmentState.ATTENTION, stateText: '不足' } as AssessmentResult;
      if (sleepAssessment.state !== AssessmentState.IN_RANGE) {
        attentionCount++;
        attentionItems.push('睡眠');
      }
      const hours = Math.floor(totalMinutes / 60);
      const minutes = totalMinutes % 60;
      sleep = {
        totalMinutes: totalMinutes,
        totalText: `${hours}小时${minutes > 0 ? minutes + '分钟' : ''}`,
        sleepType: SleepType.MAIN,
        measuredAt: sleepRecord.recordedAt ? sleepRecord.recordedAt : '',
        source: 'FAIR',
        state: sleepAssessment.state,
        stateText: sleepAssessment.stateText
      };
    }

    const healthCard: HealthCardSummary = {
      subjectId: data.userId ? `${data.userId}` : '',
      subjectName: data.realName ? data.realName : '',
      generatedAt: new Date().toISOString(),
      attentionCount,
      urgentCount: 0,
      missingCategories: [],
      bloodPressure,
      bloodSugar,
      heartRate,
      body,
      sleep
    };

    return {
      userId: data.userId ? `${data.userId}` : '',
      realName: data.realName ? data.realName : '',
      phone: data.phone ? data.phone : '',
      gender: data.gender ? data.gender : '',
      age: data.age ? data.age : 0,
      avatar: data.avatar ? data.avatar : '',
      healthCard
    } as FamilyMemberInfo;
  });
}
