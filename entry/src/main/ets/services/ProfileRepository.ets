import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { http } from '@kit.NetworkKit';
import {
  HealthIndicatorEntry,
  HealthProfile,
  QuestionnaireAnswer,
  QuestionnaireRecord,
  ReminderPreference,
  TongueObservationNote
} from '../model/ProfileModels';
import { ConstitutionResult } from '../model/WellnessModels';
import { buildApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';

const PROFILE_KEY: string = 'health_profile';

export interface ProfileStorageAdapter {
  read(key: string): Promise<string>;
  write(key: string, value: string): Promise<void>;
}

export interface BackendHealthArchivePayload {
  constitutionType: string;
  healthGoal: string;
  medicalHistory: string;
  allergyHistory: string;
}

export interface BackendHealthDetailBundle {
  questionnaireRecords: QuestionnaireRecord[];
  healthIndicators: HealthIndicatorEntry[];
  tongueNotes: TongueObservationNote[];
}

interface BackendHealthArchiveData {
  constitutionType?: string;
  healthGoal?: string;
  medicalHistory?: string;
  allergyHistory?: string;
}

interface BackendHealthArchiveResponse {
  success?: boolean;
  message?: string;
  data?: BackendHealthArchiveData | null;
}

interface BackendQuestionnaireRecordData {
  id?: number;
  constitutionType?: string;
  totalScore?: number;
  suggestion?: string;
  answersJson?: string;
  createTime?: string;
}

interface BackendHealthIndicatorRecordData {
  id?: number;
  name?: string;
  value?: string;
  unit?: string;
  recordedAt?: string;
}

interface BackendTongueObservationRecordData {
  id?: number;
  color?: string;
  coating?: string;
  dryness?: string;
  note?: string;
  recordedAt?: string;
}

interface BackendHealthDetailData {
  questionnaireRecords?: BackendQuestionnaireRecordData[];
  healthIndicators?: BackendHealthIndicatorRecordData[];
  tongueNotes?: BackendTongueObservationRecordData[];
}

interface BackendHealthDetailResponse {
  success?: boolean;
  message?: string;
  data?: BackendHealthDetailData | null;
}

interface BackendQuestionnaireRecordResponse {
  success?: boolean;
  message?: string;
  data?: BackendQuestionnaireRecordData | null;
}

interface BackendHealthIndicatorRecordResponse {
  success?: boolean;
  message?: string;
  data?: BackendHealthIndicatorRecordData | null;
}

interface BackendTongueObservationRecordResponse {
  success?: boolean;
  message?: string;
  data?: BackendTongueObservationRecordData | null;
}

interface BackendMutationResponse {
  success?: boolean;
  message?: string;
}

interface BackendQuestionnaireCreatePayload {
  constitutionType: string;
  totalScore: number;
  suggestion: string;
  answersJson: string;
}

interface BackendHealthIndicatorCreatePayload {
  name: string;
  value: string;
  unit: string;
  recordedAt: string;
}

interface BackendTongueObservationCreatePayload {
  color: string;
  coating: string;
  dryness: string;
  note: string;
  recordedAt: string;
}

export interface ProfileBackendAdapter {
  loadCurrentHealthArchive(): Promise<BackendHealthArchivePayload | null>;
  loadCurrentHealthDetails(): Promise<BackendHealthDetailBundle | null>;
  syncCurrentHealthArchive(profile: HealthProfile): Promise<void>;
  createQuestionnaireRecord(record: QuestionnaireRecord): Promise<QuestionnaireRecord | null>;
  createHealthIndicator(entry: HealthIndicatorEntry): Promise<HealthIndicatorEntry | null>;
  createTongueNote(note: TongueObservationNote): Promise<TongueObservationNote | null>;
  deleteHealthIndicator(entry: HealthIndicatorEntry): Promise<void>;
  deleteTongueNote(note: TongueObservationNote): Promise<void>;
}

function defaultConstitution(): ConstitutionResult {
  return {
    name: '平和质',
    score: 0,
    suggestion: '保持规律作息，饮食有节，继续维持稳定状态。'
  };
}

function cloneProfile(profile: HealthProfile): HealthProfile {
  return {
    id: profile.id,
    displayName: profile.displayName,
    constitution: profile.constitution,
    questionnaireRecords: profile.questionnaireRecords,
    healthIndicators: profile.healthIndicators,
    tongueNotes: profile.tongueNotes,
    reminderPreferences: profile.reminderPreferences,
    updatedAt: profile.updatedAt
  };
}

export function createDefaultHealthProfile(updatedAt: string = new Date().toISOString()): HealthProfile {
  return {
    id: 'local-profile',
    displayName: '本地用户',
    constitution: defaultConstitution(),
    questionnaireRecords: [],
    healthIndicators: [],
    tongueNotes: [],
    reminderPreferences: [
      { title: '饮水提醒', time: '10:00', enabled: true },
      { title: '久坐拉伸', time: '15:30', enabled: true },
      { title: '睡前泡脚', time: '21:40', enabled: false }
    ],
    updatedAt
  };
}

export function serializeHealthProfile(profile: HealthProfile): string {
  return JSON.stringify(profile);
}

function isValidProfile(value: HealthProfile): boolean {
  return value.id.length > 0 && value.constitution.name.length > 0 && value.updatedAt.length > 0;
}

export function deserializeHealthProfile(value: string): HealthProfile {
  try {
    const parsed = JSON.parse(value) as HealthProfile;
    if (isValidProfile(parsed)) {
      return parsed;
    }
  } catch (err) {
    return createDefaultHealthProfile();
  }
  return createDefaultHealthProfile();
}

export function buildBackendHealthArchivePayload(profile: HealthProfile): BackendHealthArchivePayload {
  const latestIndicators = profile.healthIndicators.slice(0, 5).map((entry: HealthIndicatorEntry) => {
    return `${entry.name}:${entry.value}${entry.unit}`;
  }).join('；');
  const latestTongue = profile.tongueNotes.length > 0
    ? `${profile.tongueNotes[0].color}/${profile.tongueNotes[0].coating}/${profile.tongueNotes[0].dryness}`
    : '暂无舌象记录';
  const healthGoal = profile.questionnaireRecords.length > 0 ? profile.questionnaireRecords[0].suggestion : profile.constitution.suggestion;
  const payload: BackendHealthArchivePayload = {
    constitutionType: profile.constitution.name,
    healthGoal,
    medicalHistory: latestIndicators.length > 0 ? latestIndicators : '暂无健康指标记录',
    allergyHistory: latestTongue
  };
  return payload;
}

function normalizeArchiveText(value: string | undefined, fallback: string): string {
  if (value && value.trim().length > 0) {
    return value;
  }
  return fallback;
}

function normalizeBackendId(value: number | undefined): string | undefined {
  if (typeof value === 'number') {
    return `${value}`;
  }
  return undefined;
}

function buildQuestionnaireAnswerJson(record: QuestionnaireRecord): string {
  return JSON.stringify(record.answers);
}

function buildQuestionnaireAnswersFromJson(value: string | undefined): QuestionnaireAnswer[] {
  if (!value || value.trim().length === 0) {
    return [];
  }
  try {
    return JSON.parse(value) as QuestionnaireAnswer[];
  } catch (err) {
    return [];
  }
}

function buildQuestionnaireFromBackendRecord(data: BackendQuestionnaireRecordData): QuestionnaireRecord {
  const totalScore = typeof data.totalScore === 'number' ? data.totalScore : 0;
  const constitutionName = normalizeArchiveText(data.constitutionType, '平和质');
  const suggestion = normalizeArchiveText(data.suggestion, '');
  const constitution: ConstitutionResult = {
    name: constitutionName,
    score: totalScore,
    suggestion
  };
  const record: QuestionnaireRecord = {
    id: normalizeBackendId(data.id),
    submittedAt: normalizeArchiveText(data.createTime, new Date().toISOString()),
    answers: buildQuestionnaireAnswersFromJson(data.answersJson),
    totalScore,
    constitution,
    suggestion
  };
  return record;
}

function buildHealthIndicatorFromBackendRecord(data: BackendHealthIndicatorRecordData): HealthIndicatorEntry {
  const entry: HealthIndicatorEntry = {
    id: normalizeBackendId(data.id),
    name: normalizeArchiveText(data.name, ''),
    value: normalizeArchiveText(data.value, ''),
    unit: normalizeArchiveText(data.unit, ''),
    recordedAt: normalizeArchiveText(data.recordedAt, new Date().toISOString())
  };
  return entry;
}

function buildTongueNoteFromBackendRecord(data: BackendTongueObservationRecordData): TongueObservationNote {
  const note: TongueObservationNote = {
    id: normalizeBackendId(data.id),
    color: normalizeArchiveText(data.color, ''),
    coating: normalizeArchiveText(data.coating, ''),
    dryness: normalizeArchiveText(data.dryness, ''),
    note: normalizeArchiveText(data.note, ''),
    recordedAt: normalizeArchiveText(data.recordedAt, new Date().toISOString())
  };
  return note;
}

export function buildBackendHealthDetailsFromResponse(payload: string): BackendHealthDetailBundle | null {
  const response = JSON.parse(payload) as BackendHealthDetailResponse;
  if (response.success !== true || !response.data) {
    return null;
  }
  const data = response.data;
  const questionnaireRecords: QuestionnaireRecord[] = [];
  const healthIndicators: HealthIndicatorEntry[] = [];
  const tongueNotes: TongueObservationNote[] = [];
  const backendQuestionnaires = data.questionnaireRecords ? data.questionnaireRecords : [];
  for (let index = 0; index < backendQuestionnaires.length; index++) {
    questionnaireRecords.push(buildQuestionnaireFromBackendRecord(backendQuestionnaires[index]));
  }
  const backendIndicators = data.healthIndicators ? data.healthIndicators : [];
  for (let index = 0; index < backendIndicators.length; index++) {
    healthIndicators.push(buildHealthIndicatorFromBackendRecord(backendIndicators[index]));
  }
  const backendTongueNotes = data.tongueNotes ? data.tongueNotes : [];
  for (let index = 0; index < backendTongueNotes.length; index++) {
    tongueNotes.push(buildTongueNoteFromBackendRecord(backendTongueNotes[index]));
  }
  const details: BackendHealthDetailBundle = {
    questionnaireRecords,
    healthIndicators,
    tongueNotes
  };
  return details;
}

export function buildHealthProfileFromBackendDetails(
  details: BackendHealthDetailBundle,
  fallback: HealthProfile,
  updatedAt: string = new Date().toISOString()
): HealthProfile {
  const profile = cloneProfile(fallback);
  profile.questionnaireRecords = details.questionnaireRecords;
  profile.healthIndicators = details.healthIndicators;
  profile.tongueNotes = details.tongueNotes;
  if (details.questionnaireRecords.length > 0) {
    profile.constitution = details.questionnaireRecords[0].constitution;
  }
  profile.updatedAt = updatedAt;
  return profile;
}

export function buildBackendHealthArchivePayloadFromResponse(payload: string): BackendHealthArchivePayload | null {
  const response = JSON.parse(payload) as BackendHealthArchiveResponse;
  if (response.success !== true || !response.data) {
    return null;
  }
  const data = response.data;
  const archive: BackendHealthArchivePayload = {
    constitutionType: normalizeArchiveText(data.constitutionType, ''),
    healthGoal: normalizeArchiveText(data.healthGoal, ''),
    medicalHistory: normalizeArchiveText(data.medicalHistory, ''),
    allergyHistory: normalizeArchiveText(data.allergyHistory, '')
  };
  return archive;
}

export function buildHealthProfileFromBackendArchive(
  archive: BackendHealthArchivePayload,
  fallback: HealthProfile,
  updatedAt: string = new Date().toISOString()
): HealthProfile {
  const constitution: ConstitutionResult = {
    name: normalizeArchiveText(archive.constitutionType, fallback.constitution.name),
    score: fallback.constitution.score,
    suggestion: normalizeArchiveText(archive.healthGoal, fallback.constitution.suggestion)
  };
  const profile = cloneProfile(fallback);
  profile.constitution = constitution;
  profile.updatedAt = updatedAt;
  return profile;
}

export class HttpProfileBackendAdapter implements ProfileBackendAdapter {
  private ensureSuccess(payload: string, fallbackMessage: string): void {
    const response = JSON.parse(payload) as BackendMutationResponse;
    if (response.success === false) {
      throw new Error(response.message ? response.message : fallbackMessage);
    }
  }

  loadCurrentHealthArchive(): Promise<BackendHealthArchivePayload | null> {
    const config = getApiConfig();
    const request = http.createHttp();
    return request.request(buildApiUrl(config.healthArchiveCurrentPath), {
      method: http.RequestMethod.GET,
      header: buildAuthorizedJsonHeaders(),
      connectTimeout: config.timeoutMs,
      readTimeout: config.timeoutMs
    }).then((response: http.HttpResponse) => {
      request.destroy();
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return null;
      }
      return buildBackendHealthArchivePayloadFromResponse(`${response.result}`);
    }).catch((error: Error) => {
      request.destroy();
      return Promise.reject(error);
    });
  }

  loadCurrentHealthDetails(): Promise<BackendHealthDetailBundle | null> {
    const config = getApiConfig();
    const request = http.createHttp();
    return request.request(buildApiUrl(config.healthDetailCurrentPath), {
      method: http.RequestMethod.GET,
      header: buildAuthorizedJsonHeaders(),
      connectTimeout: config.timeoutMs,
      readTimeout: config.timeoutMs
    }).then((response: http.HttpResponse) => {
      request.destroy();
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return null;
      }
      return buildBackendHealthDetailsFromResponse(`${response.result}`);
    }).catch((error: Error) => {
      request.destroy();
      return Promise.reject(error);
    });
  }

  syncCurrentHealthArchive(profile: HealthProfile): Promise<void> {
    const config = getApiConfig();
    const request = http.createHttp();
    return request.request(buildApiUrl(config.healthArchiveCurrentPath), {
      method: http.RequestMethod.PUT,
      header: buildAuthorizedJsonHeaders(),
      extraData: JSON.stringify(buildBackendHealthArchivePayload(profile)),
      connectTimeout: config.timeoutMs,
      readTimeout: config.timeoutMs
    }).then((response: http.HttpResponse) => {
      request.destroy();
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
      }
      const payload = JSON.parse(`${response.result}`) as BackendHealthArchiveResponse;
      if (payload.success === false) {
        return Promise.reject(new Error(payload.message ? payload.message : 'health archive sync failed'));
      }
      return Promise.resolve();
    }).catch((error: Error) => {
      request.destroy();
      return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
    });
  }

  createQuestionnaireRecord(record: QuestionnaireRecord): Promise<QuestionnaireRecord | null> {
    const config = getApiConfig();
    const request = http.createHttp();
    const payload: BackendQuestionnaireCreatePayload = {
      constitutionType: record.constitution.name,
      totalScore: record.totalScore,
      suggestion: record.suggestion,
      answersJson: buildQuestionnaireAnswerJson(record)
    };
    return request.request(buildApiUrl(config.healthDetailQuestionnairePath), {
      method: http.RequestMethod.POST,
      header: buildAuthorizedJsonHeaders(),
      extraData: JSON.stringify(payload),
      connectTimeout: config.timeoutMs,
      readTimeout: config.timeoutMs
    }).then((response: http.HttpResponse) => {
      request.destroy();
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
      }
      const body = `${response.result}`;
      const backendResponse = JSON.parse(body) as BackendQuestionnaireRecordResponse;
      if (backendResponse.success === false) {
        return Promise.reject(new Error(backendResponse.message ? backendResponse.message : 'questionnaire sync failed'));
      }
      if (!backendResponse.data) {
        return null;
      }
      return buildQuestionnaireFromBackendRecord(backendResponse.data);
    }).catch((error: Error) => {
      request.destroy();
      return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
    });
  }

  createHealthIndicator(entry: HealthIndicatorEntry): Promise<HealthIndicatorEntry | null> {
    const config = getApiConfig();
    const request = http.createHttp();
    const payload: BackendHealthIndicatorCreatePayload = {
      name: entry.name,
      value: entry.value,
      unit: entry.unit,
      recordedAt: entry.recordedAt
    };
    return request.request(buildApiUrl(config.healthDetailIndicatorPath), {
      method: http.RequestMethod.POST,
      header: buildAuthorizedJsonHeaders(),
      extraData: JSON.stringify(payload),
      connectTimeout: config.timeoutMs,
      readTimeout: config.timeoutMs
    }).then((response: http.HttpResponse) => {
      request.destroy();
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
      }
      const backendResponse = JSON.parse(`${response.result}`) as BackendHealthIndicatorRecordResponse;
      if (backendResponse.success === false) {
        return Promise.reject(new Error(backendResponse.message ? backendResponse.message : 'health indicator sync failed'));
      }
      if (!backendResponse.data) {
        return null;
      }
      return buildHealthIndicatorFromBackendRecord(backendResponse.data);
    }).catch((error: Error) => {
      request.destroy();
      return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
    });
  }

  createTongueNote(note: TongueObservationNote): Promise<TongueObservationNote | null> {
    const config = getApiConfig();
    const request = http.createHttp();
    const payload: BackendTongueObservationCreatePayload = {
      color: note.color,
      coating: note.coating,
      dryness: note.dryness,
      note: note.note,
      recordedAt: note.recordedAt
    };
    return request.request(buildApiUrl(config.healthDetailTonguePath), {
      method: http.RequestMethod.POST,
      header: buildAuthorizedJsonHeaders(),
      extraData: JSON.stringify(payload),
      connectTimeout: config.timeoutMs,
      readTimeout: config.timeoutMs
    }).then((response: http.HttpResponse) => {
      request.destroy();
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
      }
      const backendResponse = JSON.parse(`${response.result}`) as BackendTongueObservationRecordResponse;
      if (backendResponse.success === false) {
        return Promise.reject(new Error(backendResponse.message ? backendResponse.message : 'tongue note sync failed'));
      }
      if (!backendResponse.data) {
        return null;
      }
      return buildTongueNoteFromBackendRecord(backendResponse.data);
    }).catch((error: Error) => {
      request.destroy();
      return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
    });
  }

  deleteHealthIndicator(entry: HealthIndicatorEntry): Promise<void> {
    if (!entry.id) {
      return Promise.resolve();
    }
    const config = getApiConfig();
    const request = http.createHttp();
    return request.request(buildApiUrl(`${config.healthDetailIndicatorPath}?id=${entry.id}`), {
      method: http.RequestMethod.DELETE,
      header: buildAuthorizedJsonHeaders(),
      connectTimeout: config.timeoutMs,
      readTimeout: config.timeoutMs
    }).then((response: http.HttpResponse) => {
      request.destroy();
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
      }
      this.ensureSuccess(`${response.result}`, 'health indicator delete failed');
      return Promise.resolve();
    }).catch((error: Error) => {
      request.destroy();
      return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
    });
  }

  deleteTongueNote(note: TongueObservationNote): Promise<void> {
    if (!note.id) {
      return Promise.resolve();
    }
    const config = getApiConfig();
    const request = http.createHttp();
    return request.request(buildApiUrl(`${config.healthDetailTonguePath}?id=${note.id}`), {
      method: http.RequestMethod.DELETE,
      header: buildAuthorizedJsonHeaders(),
      connectTimeout: config.timeoutMs,
      readTimeout: config.timeoutMs
    }).then((response: http.HttpResponse) => {
      request.destroy();
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
      }
      this.ensureSuccess(`${response.result}`, 'tongue note delete failed');
      return Promise.resolve();
    }).catch((error: Error) => {
      request.destroy();
      return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
    });
  }
}

export class NoopProfileBackendAdapter implements ProfileBackendAdapter {
  async loadCurrentHealthArchive(): Promise<BackendHealthArchivePayload | null> {
    return null;
  }

  async loadCurrentHealthDetails(): Promise<BackendHealthDetailBundle | null> {
    return null;
  }

  async syncCurrentHealthArchive(profile: HealthProfile): Promise<void> {
    return;
  }

  async createQuestionnaireRecord(record: QuestionnaireRecord): Promise<QuestionnaireRecord | null> {
    return record;
  }

  async createHealthIndicator(entry: HealthIndicatorEntry): Promise<HealthIndicatorEntry | null> {
    return entry;
  }

  async createTongueNote(note: TongueObservationNote): Promise<TongueObservationNote | null> {
    return note;
  }

  async deleteHealthIndicator(entry: HealthIndicatorEntry): Promise<void> {
    return;
  }

  async deleteTongueNote(note: TongueObservationNote): Promise<void> {
    return;
  }
}

export class MemoryProfileStorageAdapter implements ProfileStorageAdapter {
  private values: Map<string, string> = new Map<string, string>();

  async read(key: string): Promise<string> {
    return this.values.get(key) || '';
  }

  async write(key: string, value: string): Promise<void> {
    this.values.set(key, value);
  }
}

export class PreferencesProfileStorageAdapter implements ProfileStorageAdapter {
  private context: common.UIAbilityContext;
  private storeName: string;

  constructor(context: common.UIAbilityContext, storeName: string = 'wellness_profile') {
    this.context = context;
    this.storeName = storeName;
  }

  async read(key: string): Promise<string> {
    try {
      const store = await preferences.getPreferences(this.context, { name: this.storeName });
      const value = store.getSync(key, '');
      return typeof value === 'string' ? value : '';
    } catch (error) {
      return '';
    }
  }

  async write(key: string, value: string): Promise<void> {
    try {
      const store = await preferences.getPreferences(this.context, { name: this.storeName });
      store.putSync(key, value);
      await store.flush();
    } catch (error) {
    }
  }
}

export function buildScopedProfileStoreName(scope: string): string {
  const trimmedScope = scope.trim();
  if (trimmedScope.length === 0) {
    return 'wellness_profile';
  }
  return `wellness_profile_${trimmedScope}`;
}

export class HealthProfileRepository {
  private storage: ProfileStorageAdapter;
  private backend: ProfileBackendAdapter;

  constructor(storage: ProfileStorageAdapter, backend: ProfileBackendAdapter = new NoopProfileBackendAdapter()) {
    this.storage = storage;
    this.backend = backend;
  }

  async loadProfile(): Promise<HealthProfile> {
    const stored = await this.storage.read(PROFILE_KEY);
    const localProfile = stored.length === 0 ? createDefaultHealthProfile() : deserializeHealthProfile(stored);
    try {
      const backendArchive = await this.backend.loadCurrentHealthArchive();
      let mergedProfile = localProfile;
      if (backendArchive !== null) {
        mergedProfile = buildHealthProfileFromBackendArchive(backendArchive, localProfile);
      }
      const backendDetails = await this.backend.loadCurrentHealthDetails();
      if (backendDetails !== null) {
        mergedProfile = buildHealthProfileFromBackendDetails(backendDetails, mergedProfile);
      }
      if (backendArchive !== null || backendDetails !== null) {
        await this.storage.write(PROFILE_KEY, serializeHealthProfile(mergedProfile));
      }
      return mergedProfile;
    } catch (err) {
      return localProfile;
    }
  }

  async loadLocalProfile(): Promise<HealthProfile> {
    const stored = await this.storage.read(PROFILE_KEY);
    if (stored.length === 0) {
      return createDefaultHealthProfile();
    }
    return deserializeHealthProfile(stored);
  }

  async saveProfile(profile: HealthProfile): Promise<HealthProfile> {
    const nextProfile = cloneProfile(profile);
    nextProfile.updatedAt = new Date().toISOString();
    await this.storage.write(PROFILE_KEY, serializeHealthProfile(nextProfile));
    try {
      await this.backend.syncCurrentHealthArchive(nextProfile);
    } catch (error) {
      return nextProfile;
    }
    return nextProfile;
  }

  async saveQuestionnaireRecord(record: QuestionnaireRecord): Promise<HealthProfile> {
    const profile = await this.loadProfile();
    let backendRecord: QuestionnaireRecord | null = null;
    try {
      backendRecord = await this.backend.createQuestionnaireRecord(record);
    } catch (error) {
      backendRecord = null;
    }
    const savedRecord = backendRecord === null ? record : backendRecord;
    const nextProfile = cloneProfile(profile);
    nextProfile.constitution = savedRecord.constitution;
    nextProfile.questionnaireRecords = [savedRecord].concat(profile.questionnaireRecords);
    nextProfile.updatedAt = savedRecord.submittedAt;
    await this.storage.write(PROFILE_KEY, serializeHealthProfile(nextProfile));
    try {
      await this.backend.syncCurrentHealthArchive(nextProfile);
    } catch (error) {
      return nextProfile;
    }
    return nextProfile;
  }

  async saveTongueNote(note: TongueObservationNote): Promise<HealthProfile> {
    const profile = await this.loadProfile();
    let backendNote: TongueObservationNote | null = null;
    try {
      backendNote = await this.backend.createTongueNote(note);
    } catch (error) {
      backendNote = null;
    }
    const savedNote = backendNote === null ? note : backendNote;
    const nextProfile = cloneProfile(profile);
    nextProfile.tongueNotes = [savedNote].concat(profile.tongueNotes);
    return this.saveProfile(nextProfile);
  }

  async saveHealthIndicator(entry: HealthIndicatorEntry): Promise<HealthProfile> {
    const profile = await this.loadProfile();
    let backendEntry: HealthIndicatorEntry | null = null;
    try {
      backendEntry = await this.backend.createHealthIndicator(entry);
    } catch (error) {
      backendEntry = null;
    }
    const savedEntry = backendEntry === null ? entry : backendEntry;
    const nextProfile = cloneProfile(profile);
    nextProfile.healthIndicators = [savedEntry].concat(profile.healthIndicators);
    return this.saveProfile(nextProfile);
  }

  async deleteHealthIndicator(recordedAt: string): Promise<HealthProfile> {
    const profile = await this.loadProfile();
    const matchedEntries = profile.healthIndicators.filter((entry: HealthIndicatorEntry) => {
      return entry.recordedAt === recordedAt;
    });
    if (matchedEntries.length > 0) {
      try {
        await this.backend.deleteHealthIndicator(matchedEntries[0]);
      } catch (error) {
      }
    }
    const nextProfile = cloneProfile(profile);
    nextProfile.healthIndicators = profile.healthIndicators.filter((entry: HealthIndicatorEntry) => {
      return entry.recordedAt !== recordedAt;
    });
    return this.saveProfile(nextProfile);
  }

  async deleteTongueNote(recordedAt: string): Promise<HealthProfile> {
    const profile = await this.loadProfile();
    const matchedNotes = profile.tongueNotes.filter((note: TongueObservationNote) => {
      return note.recordedAt === recordedAt;
    });
    if (matchedNotes.length > 0) {
      try {
        await this.backend.deleteTongueNote(matchedNotes[0]);
      } catch (error) {
      }
    }
    const nextProfile = cloneProfile(profile);
    nextProfile.tongueNotes = profile.tongueNotes.filter((note: TongueObservationNote) => {
      return note.recordedAt !== recordedAt;
    });
    return this.saveProfile(nextProfile);
  }

  async updateReminderPreferences(reminderPreferences: ReminderPreference[]): Promise<HealthProfile> {
    const profile = await this.loadProfile();
    const nextProfile = cloneProfile(profile);
    nextProfile.reminderPreferences = reminderPreferences;
    return this.saveProfile(nextProfile);
  }
}

export function createPreferencesHealthProfileRepository(
  context: common.UIAbilityContext,
  profileScope: string = ''
): HealthProfileRepository {
  return new HealthProfileRepository(
    new PreferencesProfileStorageAdapter(context, buildScopedProfileStoreName(profileScope)),
    new HttpProfileBackendAdapter()
  );
}
