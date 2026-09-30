import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { generateContextualHealthAnswer, generateHealthAnswer } from '../main/ets/services/AIService';
import { geoLocationManager } from '@kit.LocationKit';
import {
  buildAiApiUrl,
  buildApiUrl,
  buildAuthApiUrl,
  buildSuggestionApiUrl,
  getApiConfig,
  normalizeApiBaseUrl,
  setRuntimeAiBaseUrl,
  setRuntimeBaseUrl
} from '../main/ets/services/ApiConfig';
import {
  buildAssistantReplyFromBackendPayload,
  buildAssistantRequestPayload,
  buildBackendHistory,
  requestAssistantReply
} from '../main/ets/services/AssistantReplyService';
import {
  AuthSessionRepository,
  buildAuthorizedJsonHeaders,
  buildAuthFailureText,
  buildAuthRequestPayload,
  buildAuthSessionFromBackendPayload,
  buildAuthSessionFromCurrentUserPayload,
  buildPasswordResetIdentifyPayload,
  buildPasswordResetRequestPayload,
  buildPasswordResetTargetFromBackendPayload,
  buildSmsCodeRequestPayload,
  buildSmsCodeResultFromBackendPayload,
  MemoryAuthStorageAdapter,
  setRuntimeAuthToken
} from '../main/ets/services/AuthService';
import {
  getRoleTabs,
  normalizeRoleCode,
  resolveAuthorizedTabIndex,
  resolvePrimaryRole
} from '../main/ets/services/RoleExperienceService';
import { buildBackendStatusFromHealthPayload, getBackendStatus } from '../main/ets/services/BackendStatusService';
import {
  buildAdminAssistantLogGroups,
  buildAdminAssistantLogsFromPayload
} from '../main/ets/services/AdminAssistantLogService';
import { buildNodeAiStatusFromPayload } from '../main/ets/services/NodeAiStatusService';
import { buildAdminUsersFromPayload, buildCreateAdminUserPayload } from '../main/ets/services/AdminPeopleService';
import { buildAdminRolesFromPayload, buildAdminUserRolesFromPayload } from '../main/ets/services/AdminRoleService';
import { buildAdminOverviewMetrics } from '../main/ets/services/AdminOverviewMetricsService';
import { buildFilteredAdminUsers } from '../main/ets/services/AdminPeopleFilterService';
import {
  buildAdminAssistantLogMetrics,
  buildAdminConsultationMetrics
} from '../main/ets/services/AdminTabMetricsService';
import {
  buildConsultationSaveErrorMessage,
  buildConsultationSaveFailureText,
  buildConsultationMessagesFromPayload,
  buildConsultationThreadsFromPayload,
  buildDoctorOptionsFromPayload,
  buildDoctorPendingNoticeTitle,
  countOngoingConsultations
} from '../main/ets/services/ConsultationService';
import {
  buildDoctorProfileFromPayload,
  buildDoctorProfileIdentityText,
  buildDoctorProfileSaveErrorMessage,
  buildDoctorProfileSaveFailureText,
  buildDoctorProfileValidationText
} from '../main/ets/services/DoctorProfileService';
import {
  ChatHistoryRepository,
  MemoryChatHistoryStorageAdapter,
  buildScopedChatHistoryStoreName,
  deserializeChatHistory,
  serializeChatHistory,
  trimChatHistory
} from '../main/ets/services/ChatHistoryRepository';
import { countPendingDeviceSyncs, getDeviceSyncSummary, getDeviceStatuses } from '../main/ets/services/DeviceService';
import { getEmptyStateInfo } from '../main/ets/services/EmptyStateService';
import {
  buildArchiveSummariesFromProfile,
  buildHealthArchiveSummary
} from '../main/ets/services/HealthDataService';
import { searchAcupoints, searchFoodContraindications, searchHerbalRecipes } from '../main/ets/services/KnowledgeService';
import { formatReminderSummary } from '../main/ets/services/NotificationService';
import { generatePersonalPlan } from '../main/ets/services/PersonalPlanService';
import {
  buildPrivacyStatusItemsFromPermissionStates,
  getPrivacyStatusItems,
  getPrivacySummary
} from '../main/ets/services/PrivacyService';
import {
  MemoryPermissionStatusStorageAdapter,
  PermissionStatusRepository
} from '../main/ets/services/PermissionStatusRepository';
import { buildSaveFailureText, buildSaveSuccessText } from '../main/ets/services/SaveFeedbackService';
import {
  buildHttpFailureText,
  normalizeNetworkErrorMessage
} from '../main/ets/services/RequestErrorService';
import {
  clearSessionInvalidationHandler,
  setSessionInvalidationHandler
} from '../main/ets/services/SessionInvalidationService';
import { generateLocalMonthlyReport, generateMonthlyReport, interpretMedicalIndicators } from '../main/ets/services/ReportService';
import { getProfileActions, getQuickActions } from '../main/ets/services/WellnessContentService';
import {
  buildCurrentLocationRequest,
  buildLocatedWeatherUrl,
  buildWeatherBackendUnavailableFallback,
  buildWeatherCoordinateUnavailableFallback,
  buildWeatherFromBackendPayload,
  buildWeatherLocationUnavailableFallback,
  buildWeatherLocationPermissionDeniedFallback,
  buildWeatherLocationSwitchOffFallback,
  getCurrentWeatherWellness
} from '../main/ets/services/WeatherService';
import {
  buildSuggestionRequestPayload,
  buildSuggestionResultFromBackendPayload
} from '../main/ets/services/SuggestionService';
import {
  buildQuestionnaireRecord,
  getConstitutionQuestions,
  scoreConstitutionAnswers
} from '../main/ets/services/QuestionnaireService';
import {
  createDefaultHealthProfile,
  BackendHealthArchivePayload,
  BackendHealthDetailBundle,
  buildBackendHealthArchivePayload,
  buildScopedProfileStoreName,
  buildHealthProfileFromBackendDetails,
  deserializeHealthProfile,
  HealthProfileRepository,
  MemoryProfileStorageAdapter,
  ProfileBackendAdapter,
  serializeHealthProfile
} from '../main/ets/services/ProfileRepository';
import {
  HealthIndicatorEntry,
  HealthProfile,
  QuestionnaireRecord,
  TongueObservationNote
} from '../main/ets/model/ProfileModels';
import { calculateConstitution } from '../main/ets/utils/ConstitutionUtil';
import { recommendByProfile } from '../main/ets/utils/RecommendationUtil';
import { summarizeHealthRisk } from '../main/ets/utils/HealthRiskUtil';
import { getCurrentSolarTerm } from '../main/ets/utils/SolarTermUtil';
import { ChatMessage, WeatherWellness } from '../main/ets/model/WellnessModels';
import {
  appendLocalAssistantReply,
  appendAssistantReplyResult,
  appendUserQuestion,
  buildAssistantSourceText,
  buildDisplayMetrics,
  buildLocalHealthRisk,
  buildLocalMedicalReport,
  buildLocalPersonalPlan,
  buildRecentIndicatorRecords,
  buildRecentTongueRecords,
  canSendAssistantQuestion,
  countEnabledReminderPreferences,
  createProfileSummary,
  inferHomeGoal,
  inferSleepHours,
  toggleReminderPreference
} from '../main/ets/viewmodel/ProfileViewModel';

class FakeProfileBackendAdapter implements ProfileBackendAdapter {
  currentArchive: BackendHealthArchivePayload | null = null;
  currentDetails: BackendHealthDetailBundle | null = null;
  failLoad: boolean = false;
  failSync: boolean = false;
  syncedPayloads: BackendHealthArchivePayload[] = [];
  savedIndicators: string[] = [];
  savedTongueNotes: string[] = [];
  savedQuestionnaires: string[] = [];
  deletedIndicators: string[] = [];
  deletedTongueNotes: string[] = [];

  async loadCurrentHealthArchive(): Promise<BackendHealthArchivePayload | null> {
    if (this.failLoad) {
      throw new Error('backend unavailable');
    }
    return this.currentArchive;
  }

  async loadCurrentHealthDetails(): Promise<BackendHealthDetailBundle | null> {
    if (this.failLoad) {
      throw new Error('backend unavailable');
    }
    return this.currentDetails;
  }

  async syncCurrentHealthArchive(profile: HealthProfile): Promise<void> {
    if (this.failSync) {
      throw new Error('backend sync failed');
    }
    this.syncedPayloads.push(buildBackendHealthArchivePayload(profile));
  }

  async createQuestionnaireRecord(record: QuestionnaireRecord): Promise<QuestionnaireRecord | null> {
    if (this.failSync) {
      throw new Error('backend sync failed');
    }
    this.savedQuestionnaires.push(record.submittedAt);
    record.id = '101';
    return record;
  }

  async createHealthIndicator(entry: HealthIndicatorEntry): Promise<HealthIndicatorEntry | null> {
    if (this.failSync) {
      throw new Error('backend sync failed');
    }
    this.savedIndicators.push(entry.recordedAt);
    entry.id = '201';
    return entry;
  }

  async createTongueNote(note: TongueObservationNote): Promise<TongueObservationNote | null> {
    if (this.failSync) {
      throw new Error('backend sync failed');
    }
    this.savedTongueNotes.push(note.recordedAt);
    note.id = '301';
    return note;
  }

  async deleteHealthIndicator(entry: HealthIndicatorEntry): Promise<void> {
    if (entry.id) {
      this.deletedIndicators.push(entry.id);
    }
  }

  async deleteTongueNote(note: TongueObservationNote): Promise<void> {
    if (note.id) {
      this.deletedTongueNotes.push(note.id);
    }
  }
}

export default function localUnitTest() {
  describe('localUnitTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    });
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    });
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    });
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    });
    it('assertContain', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let a = 'abc';
      let b = 'b';
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(a).assertContain(b);
      expect(a).assertEqual(a);
    });

    it('calculates dominant constitution from questionnaire answers', 0, () => {
      const result = calculateConstitution([2, 3, 3, 2, 1]);

      expect(result.name).assertEqual('气虚质');
      expect(result.score).assertEqual(11);
      expect(result.suggestion).assertContain('温和运动');
    });

    it('provides compact constitution questionnaire questions', 0, () => {
      const questions = getConstitutionQuestions();

      expect(questions.length).assertEqual(6);
      expect(questions[0].title).assertContain('精神');
      expect(questions[0].options.length).assertEqual(4);
    });

    it('scores questionnaire answers into qi deficiency result', 0, () => {
      const result = scoreConstitutionAnswers([
        { questionId: 'energy', score: 3, label: '经常' },
        { questionId: 'breath', score: 3, label: '经常' },
        { questionId: 'sweat', score: 2, label: '有时' },
        { questionId: 'appetite', score: 2, label: '有时' },
        { questionId: 'sleep', score: 1, label: '偶尔' },
        { questionId: 'cold', score: 0, label: '很少' }
      ]);

      expect(result.name).assertEqual('气虚质');
      expect(result.score).assertEqual(11);
      expect(result.suggestion).assertContain('温和运动');
    });

    it('builds questionnaire record with submitted result', 0, () => {
      const record = buildQuestionnaireRecord([
        { questionId: 'energy', score: 0, label: '很少' },
        { questionId: 'breath', score: 0, label: '很少' },
        { questionId: 'sweat', score: 0, label: '很少' },
        { questionId: 'appetite', score: 0, label: '很少' },
        { questionId: 'sleep', score: 0, label: '很少' },
        { questionId: 'cold', score: 0, label: '很少' }
      ], '2026-06-23T10:30:00.000Z');

      expect(record.submittedAt).assertEqual('2026-06-23T10:30:00.000Z');
      expect(record.constitution.name).assertEqual('平和质');
      expect(record.answers.length).assertEqual(6);
    });

    it('provides local default weather through weather service', 0, () => {
      const weather = getCurrentWeatherWellness();

      expect(weather.city).assertEqual('杭州');
      expect(weather.sourceLabel).assertEqual('本地默认');
      expect(weather.advice).assertContain('湿度');
    });

    it('builds located weather from backend payload with fallback flag', 0, () => {
      const weather = buildWeatherFromBackendPayload('{"city":"上海","condition":"多云","temperature":"22℃","humidity":"56%","advice":"湿度适中","riskLevel":"天气平稳","sourceLabel":"Open-Meteo","isFallback":false}');
      const fallback = buildWeatherFromBackendPayload('{"city":"上海","sourceLabel":"后端兜底","isFallback":true}');

      expect(weather.city).assertEqual('上海');
      expect(weather.sourceLabel).assertEqual('Open-Meteo');
      expect(weather.isFallback).assertFalse();
      expect(fallback.city).assertEqual('上海');
      expect(fallback.isFallback).assertTrue();
    });

    it('builds weather url with current coordinates for spring boot', 0, () => {
      const url: string = buildLocatedWeatherUrl('http://172.20.10.10:8181', '/api/weather/current', 31.2304, 121.4737);

      expect(url).assertEqual('http://172.20.10.10:8181/api/weather/current?latitude=31.2304&longitude=121.4737');
    });

    it('builds first-fix current location request for real device weather', 0, () => {
      const request: geoLocationManager.CurrentLocationRequest = buildCurrentLocationRequest();

      expect(request.priority).assertEqual(geoLocationManager.LocationRequestPriority.FIRST_FIX);
      expect(request.scenario).assertEqual(geoLocationManager.LocationRequestScenario.DAILY_LIFE_SERVICE);
    });

    it('uses explicit fallback weather when location or backend is unavailable', 0, () => {
      const locationFallback: WeatherWellness = buildWeatherLocationUnavailableFallback();
      const backendFallback: WeatherWellness = buildWeatherBackendUnavailableFallback();

      expect(locationFallback.city).assertEqual('定位未获取');
      expect(locationFallback.sourceLabel).assertEqual('定位未获取');
      expect(locationFallback.advice).assertContain('定位权限');
      expect(backendFallback.sourceLabel).assertEqual('Spring Boot天气未连接');
      expect(backendFallback.advice).assertContain('Spring Boot');
    });

    it('builds separate weather fallbacks for location failure reasons', 0, () => {
      const permissionFallback: WeatherWellness = buildWeatherLocationPermissionDeniedFallback();
      const switchFallback: WeatherWellness = buildWeatherLocationSwitchOffFallback();
      const coordinateFallback: WeatherWellness = buildWeatherCoordinateUnavailableFallback();

      expect(permissionFallback.riskLevel).assertEqual('定位权限待开启');
      expect(permissionFallback.advice).assertContain('APP定位权限');
      expect(switchFallback.riskLevel).assertEqual('系统定位待开启');
      expect(switchFallback.advice).assertContain('系统定位服务');
      expect(coordinateFallback.riskLevel).assertEqual('定位信号待获取');
      expect(coordinateFallback.advice).assertContain('稍后刷新');
    });

    it('creates default local health profile', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');

      expect(profile.id).assertEqual('local-profile');
      expect(profile.constitution.name).assertEqual('平和质');
      expect(profile.questionnaireRecords.length).assertEqual(0);
    });

    it('builds backend health archive payload from local profile', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.constitution.name = '气虚质';
      profile.healthIndicators = [
        { name: '血压', value: '128/82', unit: 'mmHg', recordedAt: '2026-06-23T11:05:00.000Z' }
      ];
      profile.tongueNotes = [{
        color: '淡红',
        coating: '薄白',
        dryness: '适中',
        note: '晨起观察。',
        recordedAt: '2026-06-23T08:00:00.000Z'
      }];

      const payload = buildBackendHealthArchivePayload(profile);

      expect(payload.constitutionType).assertEqual('气虚质');
      expect(payload.medicalHistory).assertContain('血压');
      expect(payload.allergyHistory).assertContain('淡红');
    });

    it('serializes and deserializes health profile', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const serialized = serializeHealthProfile(profile);
      const restored = deserializeHealthProfile(serialized);

      expect(restored.updatedAt).assertEqual('2026-06-23T10:30:00.000Z');
      expect(restored.constitution.name).assertEqual('平和质');
    });

    it('falls back to default profile for malformed stored content', 0, () => {
      const restored = deserializeHealthProfile('{bad json');

      expect(restored.id).assertEqual('local-profile');
      expect(restored.constitution.name).assertEqual('平和质');
    });

    it('loads current health archive from backend and caches merged profile', 0, async () => {
      const storage = new MemoryProfileStorageAdapter();
      const localProfile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      localProfile.constitution.name = '平和质';
      await storage.write('health_profile', serializeHealthProfile(localProfile));
      const backend = new FakeProfileBackendAdapter();
      const archive: BackendHealthArchivePayload = {
        constitutionType: '气虚质',
        healthGoal: '改善睡眠',
        medicalHistory: '血压:128/82mmHg',
        allergyHistory: '淡红/薄白/适中'
      };
      backend.currentArchive = archive;
      const repository = new HealthProfileRepository(storage, backend);

      const profile = await repository.loadProfile();
      const cached = deserializeHealthProfile(await storage.read('health_profile'));

      expect(profile.constitution.name).assertEqual('气虚质');
      expect(profile.constitution.suggestion).assertEqual('改善睡眠');
      expect(cached.constitution.name).assertEqual('气虚质');
    });

    it('merges current health detail records from backend', 0, async () => {
      const localProfile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const detailQuestionnaire: QuestionnaireRecord = {
        id: '101',
        submittedAt: '2026-06-24T10:00:00.000Z',
        answers: [],
        totalScore: 9,
        constitution: {
          name: '阳虚质',
          score: 9,
          suggestion: '注意温养'
        },
        suggestion: '注意温养'
      };
      const detailIndicator: HealthIndicatorEntry = {
        id: '201',
        name: '睡眠',
        value: '7',
        unit: '小时',
        recordedAt: '2026-06-24T08:00:00.000Z'
      };
      const detailTongueNote: TongueObservationNote = {
        id: '301',
        color: '淡红',
        coating: '薄白',
        dryness: '适中',
        note: '状态平稳',
        recordedAt: '2026-06-24T07:30:00.000Z'
      };
      const details: BackendHealthDetailBundle = {
        questionnaireRecords: [detailQuestionnaire],
        healthIndicators: [detailIndicator],
        tongueNotes: [detailTongueNote]
      };

      const profile = buildHealthProfileFromBackendDetails(details, localProfile);

      expect(profile.questionnaireRecords[0].id).assertEqual('101');
      expect(profile.healthIndicators[0].name).assertEqual('睡眠');
      expect(profile.tongueNotes[0].id).assertEqual('301');
      expect(profile.constitution.name).assertEqual('阳虚质');
    });

    it('keeps local health profile when backend archive load fails', 0, async () => {
      const storage = new MemoryProfileStorageAdapter();
      const localProfile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      localProfile.constitution.name = '气虚质';
      await storage.write('health_profile', serializeHealthProfile(localProfile));
      const backend = new FakeProfileBackendAdapter();
      backend.failLoad = true;
      const repository = new HealthProfileRepository(storage, backend);

      const profile = await repository.loadProfile();

      expect(profile.constitution.name).assertEqual('气虚质');
      expect(profile.updatedAt).assertEqual('2026-06-23T10:30:00.000Z');
    });

    it('saves questionnaire record into local profile repository', 0, async () => {
      const storage = new MemoryProfileStorageAdapter();
      const repository = new HealthProfileRepository(storage);
      const record = buildQuestionnaireRecord([
        { questionId: 'energy', score: 3, label: '经常' },
        { questionId: 'breath', score: 3, label: '经常' },
        { questionId: 'sweat', score: 2, label: '有时' },
        { questionId: 'appetite', score: 2, label: '有时' },
        { questionId: 'sleep', score: 1, label: '偶尔' },
        { questionId: 'cold', score: 0, label: '很少' }
      ], '2026-06-23T10:30:00.000Z');

      const profile = await repository.saveQuestionnaireRecord(record);

      expect(profile.questionnaireRecords.length).assertEqual(1);
      expect(profile.constitution.name).assertEqual('气虚质');
    });

    it('saves questionnaire detail record through backend when connected', 0, async () => {
      const storage = new MemoryProfileStorageAdapter();
      const backend = new FakeProfileBackendAdapter();
      const repository = new HealthProfileRepository(storage, backend);
      const record = buildQuestionnaireRecord([
        { questionId: 'energy', score: 3, label: '经常' },
        { questionId: 'breath', score: 3, label: '经常' },
        { questionId: 'sweat', score: 2, label: '有时' },
        { questionId: 'appetite', score: 2, label: '有时' },
        { questionId: 'sleep', score: 1, label: '偶尔' },
        { questionId: 'cold', score: 0, label: '很少' }
      ], '2026-06-23T10:30:00.000Z');

      const profile = await repository.saveQuestionnaireRecord(record);

      expect(backend.savedQuestionnaires.length).assertEqual(1);
      expect(profile.questionnaireRecords[0].id).assertEqual('101');
    });

    it('saves tongue observation note into local profile repository', 0, async () => {
      const storage = new MemoryProfileStorageAdapter();
      const repository = new HealthProfileRepository(storage);

      const profile = await repository.saveTongueNote({
        color: '淡红',
        coating: '薄白',
        dryness: '适中',
        note: '晨起观察，精神尚可。',
        recordedAt: '2026-06-23T11:00:00.000Z'
      });

      expect(profile.tongueNotes.length).assertEqual(1);
      expect(profile.tongueNotes[0].color).assertEqual('淡红');
    });

    it('saves health indicator into local profile repository', 0, async () => {
      const storage = new MemoryProfileStorageAdapter();
      const repository = new HealthProfileRepository(storage);

      const profile = await repository.saveHealthIndicator({
        name: '血压',
        value: '128/82',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      });

      expect(profile.healthIndicators.length).assertEqual(1);
      expect(profile.healthIndicators[0].name).assertEqual('血压');
    });

    it('saves health indicator detail through backend when connected', 0, async () => {
      const storage = new MemoryProfileStorageAdapter();
      const backend = new FakeProfileBackendAdapter();
      const repository = new HealthProfileRepository(storage, backend);

      const profile = await repository.saveHealthIndicator({
        name: '血压',
        value: '128/82',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      });

      expect(backend.savedIndicators.length).assertEqual(1);
      expect(profile.healthIndicators[0].id).assertEqual('201');
    });

    it('keeps health indicator locally when backend sync fails', 0, async () => {
      const storage = new MemoryProfileStorageAdapter();
      const backend = new FakeProfileBackendAdapter();
      backend.failSync = true;
      const repository = new HealthProfileRepository(storage, backend);

      const profile = await repository.saveHealthIndicator({
        name: '血压',
        value: '128/82',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      });
      const cached = deserializeHealthProfile(await storage.read('health_profile'));

      expect(profile.healthIndicators.length).assertEqual(1);
      expect(profile.healthIndicators[0].name).assertEqual('血压');
      expect(cached.healthIndicators.length).assertEqual(1);
    });

    it('deletes health indicator from local profile repository', 0, async () => {
      const storage = new MemoryProfileStorageAdapter();
      const repository = new HealthProfileRepository(storage);
      await repository.saveHealthIndicator({
        name: '血压',
        value: '128/82',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      });
      await repository.saveHealthIndicator({
        name: '睡眠',
        value: '6.8',
        unit: '小时',
        recordedAt: '2026-06-22T22:00:00.000Z'
      });

      const profile = await repository.deleteHealthIndicator('2026-06-23T11:05:00.000Z');

      expect(profile.healthIndicators.length).assertEqual(1);
      expect(profile.healthIndicators[0].recordedAt).assertEqual('2026-06-22T22:00:00.000Z');
    });

    it('deletes backend health indicator when local record has backend id', 0, async () => {
      const storage = new MemoryProfileStorageAdapter();
      const backend = new FakeProfileBackendAdapter();
      const repository = new HealthProfileRepository(storage, backend);
      await repository.saveHealthIndicator({
        id: '201',
        name: '血压',
        value: '128/82',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      });

      await repository.deleteHealthIndicator('2026-06-23T11:05:00.000Z');

      expect(backend.deletedIndicators[0]).assertEqual('201');
    });

    it('deletes tongue note from local profile repository', 0, async () => {
      const storage = new MemoryProfileStorageAdapter();
      const repository = new HealthProfileRepository(storage);
      await repository.saveTongueNote({
        color: '淡红',
        coating: '薄白',
        dryness: '适中',
        note: '晨起观察',
        recordedAt: '2026-06-23T08:00:00.000Z'
      });
      await repository.saveTongueNote({
        color: '偏红',
        coating: '少苔',
        dryness: '偏干',
        note: '午后观察',
        recordedAt: '2026-06-23T12:00:00.000Z'
      });

      const profile = await repository.deleteTongueNote('2026-06-23T08:00:00.000Z');

      expect(profile.tongueNotes.length).assertEqual(1);
      expect(profile.tongueNotes[0].recordedAt).assertEqual('2026-06-23T12:00:00.000Z');
    });

    it('creates profile summary from local health profile', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const summary = createProfileSummary(profile);

      expect(summary.constitutionName).assertEqual('平和质');
      expect(summary.recordCount).assertEqual(0);
      expect(summary.completenessText).assertContain('1/4');
    });

    it('formats recent indicator records with limit', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [
        { name: '血压', value: '128/82', unit: 'mmHg', recordedAt: '2026-06-23T11:05:00.000Z' },
        { name: '睡眠', value: '6.8', unit: '小时', recordedAt: '2026-06-22T22:00:00.000Z' }
      ];

      const records = buildRecentIndicatorRecords(profile, 1);

      expect(records.length).assertEqual(1);
      expect(records[0].title).assertEqual('血压');
      expect(records[0].detail).assertEqual('128/82 mmHg');
      expect(records[0].tag).assertEqual('指标');
    });

    it('formats recent tongue records with note text', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.tongueNotes = [{
        color: '淡红',
        coating: '薄白',
        dryness: '适中',
        note: '晨起观察。',
        recordedAt: '2026-06-23T08:00:00.000Z'
      }];

      const records = buildRecentTongueRecords(profile, 3);

      expect(records.length).assertEqual(1);
      expect(records[0].title).assertEqual('舌象观察');
      expect(records[0].detail).assertContain('淡红');
      expect(records[0].detail).assertContain('晨起观察。');
      expect(records[0].tag).assertEqual('舌象');
    });

    it('returns no recent records for non-positive limit', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [{
        name: '血压',
        value: '128/82',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      }];

      const records = buildRecentIndicatorRecords(profile, 0);

      expect(records.length).assertEqual(0);
    });

    it('counts enabled local reminder preferences', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');

      expect(countEnabledReminderPreferences(profile)).assertEqual(2);
    });

    it('toggles local reminder preference off', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const preferences = toggleReminderPreference(profile.reminderPreferences, '饮水提醒', false);

      expect(preferences[0].enabled).assertFalse();
    });

    it('leaves reminders unchanged for unknown title', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const preferences = toggleReminderPreference(profile.reminderPreferences, '不存在的提醒', false);

      expect(preferences[0].enabled).assertTrue();
      expect(preferences.length).assertEqual(3);
    });

    it('uses local health indicators before mock metrics', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [{
        name: '血压',
        value: '128/82',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      }];

      const metrics = buildDisplayMetrics(profile, []);

      expect(metrics.length).assertEqual(1);
      expect(metrics[0].value).assertEqual('128/82');
    });

    it('returns empty display metrics when local indicators are empty', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const metrics = buildDisplayMetrics(profile, [
        { name: '睡眠', value: '7.1', unit: '小时', status: '可改善', trend: [35, 48] }
      ]);

      expect(metrics.length).assertEqual(0);
    });

    it('builds local home plan from default profile', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const plan = buildLocalPersonalPlan(profile);

      expect(inferHomeGoal(profile)).assertEqual('节气养护');
      expect(plan.exercise.reason).assertContain('平和质');
    });

    it('infers glucose goal for local home plan', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [{
        name: '空腹血糖',
        value: '7.2',
        unit: 'mmol/L',
        recordedAt: '2026-06-23T11:05:00.000Z'
      }];

      const plan = buildLocalPersonalPlan(profile);

      expect(inferHomeGoal(profile)).assertEqual('控糖');
      expect(plan.diet.title).assertEqual('控糖健脾餐');
    });

    it('uses local sleep value for home plan', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [{
        name: '睡眠',
        value: '6.4',
        unit: '小时',
        recordedAt: '2026-06-23T11:05:00.000Z'
      }];

      const plan = buildLocalPersonalPlan(profile);

      expect(inferSleepHours(profile)).assertEqual(6.4);
      expect(plan.sleep.title).assertEqual('睡眠修复计划');
    });

    it('adds hydration hint for dry tongue home plan', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.tongueNotes = [{
        color: '淡红',
        coating: '薄白',
        dryness: '偏干',
        note: '晨起观察。',
        recordedAt: '2026-06-23T08:00:00.000Z'
      }];

      const plan = buildLocalPersonalPlan(profile);

      expect(plan.diet.detail).assertContain('温水');
    });

    it('builds local health risk from saved blood pressure', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [{
        name: '血压',
        value: '146/94',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      }];

      const risk = buildLocalHealthRisk(profile);

      expect(risk.level).assertEqual('需关注');
      expect(risk.message).assertContain('血压');
    });

    it('builds local medical report from saved indicators', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [{
        name: '血压',
        value: '146/94',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      }];
      const fallback = interpretMedicalIndicators(118, 76, 5.4, 7.2);

      const report = buildLocalMedicalReport(profile, fallback);

      expect(report.abnormalItems.length).assertEqual(2);
      expect(report.abnormalItems[0].name).assertEqual('收缩压');
    });

    it('keeps fallback medical report when local indicators are empty', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const fallback = interpretMedicalIndicators(146, 94, 5.6, 6.5);

      const report = buildLocalMedicalReport(profile, fallback);

      expect(report.summary).assertEqual(fallback.summary);
    });

    it('returns summer solstice wellness guidance for June 21', 0, () => {
      const result = getCurrentSolarTerm(new Date('2026-06-21T08:00:00'));

      expect(result.name).assertEqual('夏至');
      expect(result.focus).assertContain('养心');
      expect(result.foods.length > 0).assertTrue();
    });

    it('recommends herbal and acupoint plan by profile', 0, () => {
      const result = recommendByProfile('气虚质', '困倦');

      expect(result.recipe.name).assertEqual('黄芪山药粥');
      expect(result.acupoint.name).assertEqual('足三里');
      expect(result.warning).assertContain('不替代诊疗');
    });

    it('summarizes elevated blood pressure risk', 0, () => {
      const result = summarizeHealthRisk(146, 94, 5.6, 6.5);

      expect(result.level).assertEqual('需关注');
      expect(result.message).assertContain('血压');
      expect(result.actions.length > 0).assertTrue();
    });

    it('generates safe local answer with medical disclaimer', 0, () => {
      const result = generateHealthAnswer('最近困倦', '气虚质');

      expect(result).assertContain('气虚质');
      expect(result).assertContain('不能替代医生诊断');
    });

    it('generates contextual answer with constitution from local profile', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const result = generateContextualHealthAnswer('最近有点困', profile);

      expect(result).assertContain('平和质');
      expect(result).assertContain('不能替代医生诊断');
    });

    it('includes latest tongue note in contextual answer', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.tongueNotes = [{
        color: '淡红',
        coating: '薄白',
        dryness: '适中',
        note: '晨起观察，精神尚可。',
        recordedAt: '2026-06-23T11:00:00.000Z'
      }];

      const result = generateContextualHealthAnswer('今天怎么调理', profile);

      expect(result).assertContain('淡红');
      expect(result).assertContain('薄白');
    });

    it('includes latest health indicator in contextual answer', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [{
        name: '血压',
        value: '128/82',
        unit: 'mmHg',
        recordedAt: '2026-06-23T11:05:00.000Z'
      }];

      const result = generateContextualHealthAnswer('', profile);

      expect(result).assertContain('日常调理');
      expect(result).assertContain('血压 128/82mmHg');
    });

    it('returns assistant reply through replaceable reply service', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const result = requestAssistantReply('最近有点困', profile);

      expect(result.source).assertEqual('本地规则');
      expect(result.targetUrl).assertEqual('http://172.20.10.10:8181/api/ai/chat');
      expect(result.healthUrl).assertEqual('http://172.20.10.10:8181/api/health');
      expect(result.content).assertContain('最近有点困');
      expect(result.content).assertContain('不能替代医生诊断');
    });

    it('builds assistant reply from structured backend payload', 0, () => {
      const result = buildAssistantReplyFromBackendPayload('{"reply":"后端回复内容","source":"后端模拟","riskLevel":"normal","suggestions":["规律作息","清淡饮食"],"disclaimer":"不能替代医生诊断"}');

      expect(result.source).assertEqual('后端模拟');
      expect(result.content).assertEqual('后端回复内容');
      expect(result.riskLevel).assertEqual('normal');
      expect(result.suggestions.length).assertEqual(2);
      expect(result.disclaimer).assertContain('不能替代医生诊断');
      expect(result.targetUrl).assertEqual('http://172.20.10.10:8181/api/ai/chat');
    });

    it('builds auth request payload with trimmed phone', 0, () => {
      const payload = buildAuthRequestPayload(' 13800138000 ', 'abc12345');

      expect(payload.phone).assertEqual('13800138000');
      expect(payload.password).assertEqual('abc12345');
    });

    it('builds register auth payload with selected role', 0, () => {
      const userPayload = buildAuthRequestPayload(' 13800138000 ', 'abc12345', 'USER');
      const doctorPayload = buildAuthRequestPayload('13800138001', 'abc12345', 'DOCTOR');
      const defaultPayload = buildAuthRequestPayload('13800138002', 'abc12345', '');
      const codePayload = buildAuthRequestPayload('13800138003', 'abc12345', 'USER', ' 246810 ');

      expect(userPayload.roleCode).assertEqual('USER');
      expect(doctorPayload.roleCode).assertEqual('DOCTOR');
      expect(defaultPayload.roleCode).assertEqual('USER');
      expect(codePayload.code).assertEqual('246810');
    });

    it('builds sms auth and password reset payloads', 0, () => {
      const smsPayload = buildSmsCodeRequestPayload(' 13800138000 ', 'login');
      const identifyPayload = buildPasswordResetIdentifyPayload(' doctorLi ');
      const resetPayload = buildPasswordResetRequestPayload(' 13800138000 ', ' 975310 ', 'newpass123');

      expect(smsPayload.phone).assertEqual('13800138000');
      expect(smsPayload.purpose).assertEqual('LOGIN');
      expect(identifyPayload.account).assertEqual('doctorLi');
      expect(resetPayload.phone).assertEqual('13800138000');
      expect(resetPayload.code).assertEqual('975310');
      expect(resetPayload.newPassword).assertEqual('newpass123');
    });

    it('parses sms code and password reset account responses', 0, () => {
      const codeResult = buildSmsCodeResultFromBackendPayload('{"success":true,"message":"verification code sent","data":{"devCode":"135790"}}');
      const resetTarget = buildPasswordResetTargetFromBackendPayload('{"success":true,"message":"account verified","data":{"phone":"139****9010","rawPhone":"13900139010"}}');

      expect(codeResult.devCode).assertEqual('135790');
      expect(codeResult.message).assertEqual('verification code sent');
      expect(resetTarget.maskedPhone).assertEqual('139****9010');
      expect(resetTarget.phone).assertEqual('13900139010');
    });

    it('maps backend auth failure messages to user friendly text', 0, () => {
      expect(buildAuthFailureText(false, 'phone or password error')).assertContain('手机号或密码错误');
      expect(buildAuthFailureText(false, 'user disabled')).assertContain('禁用');
      expect(buildAuthFailureText(true, 'phone already exists')).assertContain('已注册');
      expect(buildAuthFailureText(false, 'verification code error')).assertContain('验证码');
      expect(buildAuthFailureText(false, 'phone not found')).assertContain('手机号不存在');
    });

    it('builds auth session from backend payload', 0, () => {
      const session = buildAuthSessionFromBackendPayload('{"token":"token-value","user":{"id":"user-1","phone":"13800138000","createdAt":"2026-06-24T00:00:00.000Z"}}');

      expect(session.token).assertEqual('token-value');
      expect(session.user.id).assertEqual('user-1');
      expect(session.user.phone).assertEqual('13800138000');
    });

    it('builds auth session from spring boot backend payload', 0, () => {
      const session = buildAuthSessionFromBackendPayload('{"success":true,"message":"login success","data":{"token":"spring-token","user":{"id":1,"username":"13800138000","phone":"13800138000","realName":"张三","createTime":"2026-06-24T00:00:00.000Z","roles":["USER"]}}}');

      expect(session.token).assertEqual('spring-token');
      expect(session.user.id).assertEqual('1');
      expect(session.user.phone).assertEqual('13800138000');
      expect(session.user.createdAt).assertEqual('2026-06-24T00:00:00.000Z');
      expect(session.user.roles[0]).assertEqual('USER');
      expect(session.user.primaryRole).assertEqual('USER');
    });

    it('maps adviser backend role to doctor app role', 0, () => {
      const session = buildAuthSessionFromBackendPayload('{"success":true,"message":"login success","data":{"token":"doctor-token","user":{"id":2,"phone":"13800138001","createTime":"2026-06-24T00:00:00.000Z","roles":["ADVISER"]}}}');

      expect(session.user.roles[0]).assertEqual('DOCTOR');
      expect(session.user.primaryRole).assertEqual('DOCTOR');
      expect(normalizeRoleCode('ADVISER')).assertEqual('DOCTOR');
      expect(resolvePrimaryRole(['USER', 'ADVISER'])).assertEqual('DOCTOR');
    });

    it('builds current auth session from spring boot me payload', 0, () => {
      const session = buildAuthSessionFromCurrentUserPayload('stored-token', '{"success":true,"message":"session valid","data":{"user":{"id":2,"phone":"13800138001","createTime":"2026-06-24T00:00:00.000Z","roles":["ADVISER"]}}}');

      expect(session.token).assertEqual('stored-token');
      expect(session.user.id).assertEqual('2');
      expect(session.user.roles[0]).assertEqual('DOCTOR');
      expect(session.user.primaryRole).assertEqual('DOCTOR');
    });

    it('builds different app tabs for three roles', 0, () => {
      const userTabs = getRoleTabs('USER');
      const doctorTabs = getRoleTabs('DOCTOR');
      const adminTabs = getRoleTabs('ADMIN');

      expect(userTabs[2].key).assertEqual('consultation');
      expect(doctorTabs[0].key).assertEqual('doctorWorkbench');
      expect(adminTabs[1].key).assertEqual('adminPeople');
      expect(adminTabs[2].key).assertEqual('adminAssistantLogs');
    });

    it('falls back to role home tab when current tab is outside role scope', 0, () => {
      expect(resolveAuthorizedTabIndex('USER', 'adminPeople')).assertEqual(0);
      expect(resolveAuthorizedTabIndex('DOCTOR', 'consultation')).assertEqual(0);
      expect(resolveAuthorizedTabIndex('ADMIN', 'doctorWorkbench')).assertEqual(0);
      expect(resolveAuthorizedTabIndex('ADMIN', 'adminAssistantLogs')).assertEqual(2);
      expect(resolveAuthorizedTabIndex('ADVISER', 'doctorConsultation')).assertEqual(1);
    });

    it('builds doctor options from spring boot payload', 0, () => {
      const doctors = buildDoctorOptionsFromPayload('{"success":true,"data":[{"id":1,"userId":2,"doctorName":"李医生","title":"主治医师","specialty":"睡眠调理","introduction":"擅长睡眠管理"}]}');

      expect(doctors.length).assertEqual(1);
      expect(doctors[0].userId).assertEqual('2');
      expect(doctors[0].name).assertEqual('李医生');
      expect(doctors[0].specialty).assertEqual('睡眠调理');
    });

    it('builds consultation threads and messages from spring boot payload', 0, () => {
      const threads = buildConsultationThreadsFromPayload('{"success":true,"data":[{"id":7,"userId":3,"doctorId":2,"symptom":"睡眠差","description":"持续一周","status":0}]}');
      const messages = buildConsultationMessagesFromPayload('{"success":true,"data":[{"id":9,"consultationId":7,"senderId":3,"senderRole":"USER","content":"医生您好"}]}');

      expect(threads[0].id).assertEqual('7');
      expect(threads[0].statusText).assertEqual('进行中');
      expect(messages[0].senderRole).assertEqual('USER');
      expect(messages[0].content).assertEqual('医生您好');
    });

    it('counts ongoing consultations for doctor reminder', 0, () => {
      const threads = buildConsultationThreadsFromPayload('{"success":true,"data":[{"id":7,"userId":3,"doctorId":2,"symptom":"睡眠差","description":"持续一周","status":0},{"id":8,"userId":4,"doctorId":2,"symptom":"乏力","description":"三天","status":1},{"id":9,"userId":5,"doctorId":2,"symptom":"头晕","description":"一天","status":0}]}');

      expect(countOngoingConsultations(threads)).assertEqual(2);
      expect(buildDoctorPendingNoticeTitle(threads)).assertContain('2 条待回复');
      expect(buildDoctorPendingNoticeTitle([])).assertContain('暂无');
    });

    it('builds consultation summary metrics from loaded rows', 0, () => {
      const threads = buildConsultationThreadsFromPayload('{"success":true,"data":[{"id":7,"userId":3,"doctorId":2,"symptom":"睡眠差","description":"持续一周","status":0},{"id":8,"userId":4,"doctorId":2,"symptom":"乏力","description":"三天","status":1},{"id":9,"userId":5,"doctorId":2,"symptom":"头晕","description":"一天","status":0}]}');

      const metrics = buildAdminConsultationMetrics(threads);

      expect(metrics.totalConsultations).assertEqual(3);
      expect(metrics.ongoingConsultations).assertEqual(2);
      expect(metrics.repliedConsultations).assertEqual(1);
    });

    it('normalizes consultation status values from spring boot payload', 0, () => {
      const threads = buildConsultationThreadsFromPayload('{"success":true,"data":[{"id":7,"userId":3,"doctorId":2,"symptom":"睡眠差","description":"持续一周","status":48},{"id":8,"userId":4,"doctorId":2,"symptom":"乏力","description":"三天","status":49}]}');

      expect(threads[0].statusCode).assertEqual(0);
      expect(threads[0].statusText).assertEqual('进行中');
      expect(threads[1].statusCode).assertEqual(1);
      expect(threads[1].statusText).assertEqual('已回复');
    });

    it('extracts consultation save failure message', 0, () => {
      expect(buildConsultationSaveErrorMessage('{"success":true,"message":"consultation created"}')).assertEqual('');
      expect(buildConsultationSaveErrorMessage('{"success":false,"message":"doctorId is required"}')).assertEqual('doctorId is required');
      expect(buildConsultationSaveErrorMessage('{"success":false,"message":"forbidden"}')).assertEqual('forbidden');
    });

    it('maps consultation save failures to clear text', 0, () => {
      expect(buildConsultationSaveFailureText('doctorId is required')).assertContain('选择医生');
      expect(buildConsultationSaveFailureText('content is required')).assertContain('消息内容');
      expect(buildConsultationSaveFailureText('forbidden')).assertContain('无权');
      expect(buildConsultationSaveFailureText('')).assertContain('操作失败');
    });

    it('builds admin user rows from spring boot payload', 0, () => {
      const rows = buildAdminUsersFromPayload('{"success":true,"data":[{"id":1,"username":"admin","realName":"管理员","phone":"13800138000","status":1}]}');

      expect(rows.length).assertEqual(1);
      expect(rows[0].id).assertEqual('1');
      expect(rows[0].realName).assertEqual('管理员');
      expect(rows[0].statusText).assertEqual('正常');
    });

    it('builds admin create user payload with password and role', 0, () => {
      const payload = buildCreateAdminUserPayload(' doctor01 ', ' 李医生 ', ' 13800138001 ', ' abc12345 ', ' doctor ');

      expect(payload.username).assertEqual('doctor01');
      expect(payload.realName).assertEqual('李医生');
      expect(payload.phone).assertEqual('13800138001');
      expect(payload.password).assertEqual('abc12345');
      expect(payload.roleCode).assertEqual('DOCTOR');
      expect(payload.status).assertEqual(1);
    });

    it('rejects failed admin user payload instead of treating it as empty', 0, () => {
      let rejected = false;

      try {
        buildAdminUsersFromPayload('{"success":false,"message":"forbidden"}');
      } catch (error) {
        rejected = true;
      }

      expect(rejected).assertTrue();
    });

    it('builds admin assistant logs from spring boot health-question payload', 0, () => {
      const logs = buildAdminAssistantLogsFromPayload('{"success":true,"data":[{"id":11,"userId":3,"question":"最近睡眠不好怎么办","answer":"建议保持规律作息","status":1,"createTime":"2026-06-25 08:30:00"}]}');

      expect(logs.length).assertEqual(1);
      expect(logs[0].id).assertEqual('11');
      expect(logs[0].userId).assertEqual('3');
      expect(logs[0].question).assertEqual('最近睡眠不好怎么办');
      expect(logs[0].answer).assertEqual('建议保持规律作息');
      expect(logs[0].statusText).assertEqual('已回答');
    });

    it('groups admin assistant logs by user for overview rows', 0, () => {
      const logs = buildAdminAssistantLogsFromPayload('{"success":true,"data":[{"id":11,"userId":3,"question":"睡不好","answer":"规律作息","status":1,"createTime":"2026-06-25 08:30:00"},{"id":12,"userId":3,"question":"胃口差","answer":"","status":0,"createTime":"2026-06-25 09:00:00"},{"id":13,"userId":4,"question":"头晕","answer":"及时就医","status":1,"createTime":"2026-06-25 09:30:00"}]}');
      const groups = buildAdminAssistantLogGroups(logs);

      expect(groups.length).assertEqual(2);
      expect(groups[0].userId).assertEqual('3');
      expect(groups[0].totalCount).assertEqual(2);
      expect(groups[0].answeredCount).assertEqual(1);
      expect(groups[0].latestQuestion).assertEqual('胃口差');
      expect(groups[1].userId).assertEqual('4');
    });

    it('keeps newest admin assistant question as group latest when backend returns id desc', 0, () => {
      const logs = buildAdminAssistantLogsFromPayload('{"success":true,"data":[{"id":12,"userId":3,"question":"最新问题","answer":"","status":0,"createTime":"2026-06-25 09:00:00"},{"id":11,"userId":3,"question":"旧问题","answer":"规律作息","status":1,"createTime":"2026-06-25 08:30:00"}]}');

      const groups = buildAdminAssistantLogGroups(logs);

      expect(groups.length).assertEqual(1);
      expect(groups[0].latestQuestion).assertEqual('最新问题');
      expect(groups[0].latestTime).assertEqual('2026-06-25 09:00:00');
    });

    it('builds assistant log summary metrics from loaded rows', 0, () => {
      const logs = buildAdminAssistantLogsFromPayload('{"success":true,"data":[{"id":11,"userId":3,"question":"睡不好","answer":"规律作息","status":1,"createTime":"2026-06-25 08:30:00"},{"id":12,"userId":3,"question":"胃口差","answer":"","status":0,"createTime":"2026-06-25 09:00:00"},{"id":13,"userId":4,"question":"头晕","answer":"及时就医","status":1,"createTime":"2026-06-25 09:30:00"}]}');
      const groups = buildAdminAssistantLogGroups(logs);

      const metrics = buildAdminAssistantLogMetrics(logs, groups);

      expect(metrics.totalLogs).assertEqual(3);
      expect(metrics.userCount).assertEqual(2);
      expect(metrics.answeredLogs).assertEqual(2);
    });

    it('builds per-user profile storage names', 0, () => {
      expect(buildScopedProfileStoreName('')).assertEqual('wellness_profile');
      expect(buildScopedProfileStoreName('20')).assertEqual('wellness_profile_20');
      expect(buildScopedProfileStoreName(' user-3 ')).assertEqual('wellness_profile_user-3');
    });

    it('builds per-user assistant chat storage names', 0, () => {
      expect(buildScopedChatHistoryStoreName('')).assertEqual('wellness_chat_history');
      expect(buildScopedChatHistoryStoreName('20')).assertEqual('wellness_chat_history_20');
      expect(buildScopedChatHistoryStoreName(' user-3 ')).assertEqual('wellness_chat_history_user-3');
    });

    it('builds online node ai status from spring boot payload', 0, () => {
      const status = buildNodeAiStatusFromPayload('{"nodeAvailable":true,"mode":"node-ai","nodeStatus":"ok","nodeBaseUrl":"http://127.0.0.1:8787","message":"Node AI engine is available."}');

      expect(status.available).assertTrue();
      expect(status.badgeText).assertEqual('Node AI 在线');
      expect(status.statusText).assertEqual('AI 引擎：Node LangGraph');
      expect(status.detail).assertContain('http://127.0.0.1:8787');
    });

    it('builds fallback node ai status from spring boot payload', 0, () => {
      const status = buildNodeAiStatusFromPayload('{"nodeAvailable":false,"mode":"springboot-fallback","nodeStatus":"unavailable","nodeBaseUrl":"http://127.0.0.1:8787","message":"Node AI engine is unavailable. Spring Boot fallback is active."}');

      expect(status.available).assertFalse();
      expect(status.badgeText).assertEqual('兜底中');
      expect(status.statusText).assertEqual('AI 引擎：Spring Boot 兜底');
      expect(status.detail).assertContain('Node AI 未在线');
    });

    it('builds doctor profile from spring boot payload', 0, () => {
      const profile = buildDoctorProfileFromPayload('{"success":true,"data":{"id":5,"userId":2,"doctorName":"李医生","title":"主治医师","specialty":"睡眠调理","introduction":"擅长慢病养生管理"}}', '2');

      expect(profile.id).assertEqual('5');
      expect(profile.userId).assertEqual('2');
      expect(profile.doctorName).assertEqual('李医生');
      expect(profile.title).assertEqual('主治医师');
      expect(profile.specialty).assertEqual('睡眠调理');
      expect(profile.introduction).assertContain('慢病');
    });

    it('validates doctor profile before saving', 0, () => {
      expect(buildDoctorProfileValidationText({
        id: '',
        userId: '2',
        doctorName: '',
        title: '主治医师',
        specialty: '睡眠调理',
        introduction: ''
      })).assertContain('医生姓名');
      expect(buildDoctorProfileValidationText({
        id: '',
        userId: '2',
        doctorName: '李医生',
        title: '主治医师',
        specialty: '',
        introduction: ''
      })).assertContain('擅长方向');
      expect(buildDoctorProfileValidationText({
        id: '',
        userId: '2',
        doctorName: '李医生',
        title: '主治医师',
        specialty: '睡眠调理',
        introduction: ''
      })).assertEqual('');
    });

    it('validates doctor profile login identity before saving', 0, () => {
      expect(buildDoctorProfileIdentityText('')).assertContain('重新登录');
      expect(buildDoctorProfileIdentityText('  ')).assertContain('重新登录');
      expect(buildDoctorProfileIdentityText('abc')).assertContain('重新登录');
      expect(buildDoctorProfileIdentityText('2')).assertEqual('');
    });

    it('maps doctor profile save failures to clear text', 0, () => {
      expect(buildDoctorProfileSaveFailureText('{"success":false,"message":"specialty is required"}')).assertContain('擅长方向');
      expect(buildDoctorProfileSaveFailureText('{"success":false,"message":"forbidden"}')).assertContain('医生账号');
      expect(buildDoctorProfileSaveFailureText('当前账号没有权限执行该操作。')).assertContain('医生账号');
      expect(buildDoctorProfileSaveFailureText('')).assertContain('保存失败');
    });

    it('extracts backend doctor profile save failure message', 0, () => {
      expect(buildDoctorProfileSaveErrorMessage('{"success":true,"message":"doctor profile saved"}')).assertEqual('');
      expect(buildDoctorProfileSaveErrorMessage('{"success":false,"message":"forbidden"}')).assertEqual('forbidden');
      expect(buildDoctorProfileSaveErrorMessage('{"success":false,"message":"specialty is required"}')).assertEqual('specialty is required');
    });

    it('builds admin roles and user-role bindings from spring boot payload', 0, () => {
      const roles = buildAdminRolesFromPayload('{"success":true,"data":[{"id":1,"roleName":"管理员","roleCode":"ADMIN"},{"id":2,"roleName":"医生","roleCode":"ADVISER"}]}');
      const userRoles = buildAdminUserRolesFromPayload('{"success":true,"data":[{"id":9,"userId":3,"roleId":2}]}');

      expect(roles.length).assertEqual(2);
      expect(roles[1].roleCode).assertEqual('ADVISER');
      expect(roles[1].normalizedRoleCode).assertEqual('DOCTOR');
      expect(userRoles.length).assertEqual(1);
      expect(userRoles[0].userId).assertEqual('3');
      expect(userRoles[0].roleId).assertEqual('2');
    });

    it('builds admin overview metrics from loaded backend rows', 0, () => {
      const users = buildAdminUsersFromPayload('{"success":true,"data":[{"id":1,"username":"admin","realName":"管理员","phone":"13800000001","status":1},{"id":2,"username":"doctor","realName":"医生","phone":"13800000002","status":1},{"id":3,"username":"adviser","realName":"顾问","phone":"13800000003","status":1},{"id":4,"username":"user","realName":"用户","phone":"13800000004","status":1}]}');
      const roles = buildAdminRolesFromPayload('{"success":true,"data":[{"id":10,"roleName":"管理员","roleCode":"ADMIN"},{"id":11,"roleName":"医生","roleCode":"DOCTOR"},{"id":12,"roleName":"养生顾问","roleCode":"ADVISER"}]}');
      const userRoles = buildAdminUserRolesFromPayload('{"success":true,"data":[{"id":101,"userId":1,"roleId":10},{"id":102,"userId":2,"roleId":11},{"id":103,"userId":3,"roleId":12}]}');
      const logs = buildAdminAssistantLogsFromPayload('{"success":true,"data":[{"id":201,"userId":4,"question":"睡眠不好","answer":"规律作息","status":1},{"id":202,"userId":4,"question":"怎么吃","answer":"","status":0}]}');
      const consultations = buildConsultationThreadsFromPayload('{"success":true,"data":[{"id":301,"userId":4,"doctorId":2,"symptom":"头疼","description":"持续一天","status":0}]}');

      const metrics = buildAdminOverviewMetrics(users, roles, userRoles, logs, consultations);

      expect(metrics.totalUsers).assertEqual(4);
      expect(metrics.normalUsers).assertEqual(1);
      expect(metrics.adminUsers).assertEqual(1);
      expect(metrics.doctorUsers).assertEqual(2);
      expect(metrics.roleBindings).assertEqual(3);
      expect(metrics.assistantLogCount).assertEqual(2);
      expect(metrics.consultationCount).assertEqual(1);
    });

    it('filters admin people by selected role', 0, () => {
      const users = buildAdminUsersFromPayload('{"success":true,"data":[{"id":1,"username":"admin","realName":"管理员","phone":"13800000001","status":1},{"id":2,"username":"doctor","realName":"医生","phone":"13800000002","status":1},{"id":3,"username":"adviser","realName":"顾问","phone":"13800000003","status":1},{"id":4,"username":"user","realName":"用户","phone":"13800000004","status":1}]}');
      const roles = buildAdminRolesFromPayload('{"success":true,"data":[{"id":10,"roleName":"管理员","roleCode":"ADMIN"},{"id":11,"roleName":"医生","roleCode":"DOCTOR"},{"id":12,"roleName":"养生顾问","roleCode":"ADVISER"}]}');
      const userRoles = buildAdminUserRolesFromPayload('{"success":true,"data":[{"id":101,"userId":1,"roleId":10},{"id":102,"userId":2,"roleId":11},{"id":103,"userId":3,"roleId":12}]}');

      expect(buildFilteredAdminUsers(users, roles, userRoles, 'ALL').length).assertEqual(4);
      expect(buildFilteredAdminUsers(users, roles, userRoles, 'USER')[0].id).assertEqual('4');
      expect(buildFilteredAdminUsers(users, roles, userRoles, 'ADMIN')[0].id).assertEqual('1');
      const doctors = buildFilteredAdminUsers(users, roles, userRoles, 'DOCTOR');
      expect(doctors.length).assertEqual(2);
      expect(doctors[0].id).assertEqual('2');
      expect(doctors[1].id).assertEqual('3');
    });

    it('rejects failed admin role payload instead of treating it as empty', 0, () => {
      let rejected = false;

      try {
        buildAdminRolesFromPayload('{"success":false,"message":"forbidden"}');
      } catch (error) {
        rejected = true;
      }

      expect(rejected).assertTrue();
    });

    it('adds bearer token to json headers', 0, () => {
      setRuntimeAuthToken('token-123');

      const headers = buildAuthorizedJsonHeaders();

      expect(headers['Content-Type']).assertEqual('application/json');
      expect(headers['Authorization']).assertEqual('Bearer token-123');
      setRuntimeAuthToken('');
    });

    it('saves and clears auth session repository', 0, async () => {
      const repository = new AuthSessionRepository(new MemoryAuthStorageAdapter());

      await repository.saveSession({
        token: 'token-value',
        user: {
          id: 'user-1',
          phone: '13800138000',
          createdAt: '2026-06-24T00:00:00.000Z',
          roles: ['USER'],
          primaryRole: 'USER'
        }
      });
      const loaded = await repository.loadSession();
      await repository.clearSession();
      const cleared = await repository.loadSession();

      expect(loaded === null ? '' : loaded.user.phone).assertEqual('13800138000');
      expect(cleared === null).assertTrue();
    });

    it('builds weather-aware suggestion request payload', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const weather = getCurrentWeatherWellness();
      const payload = buildSuggestionRequestPayload('home', weather, profile);

      expect(payload.scenario).assertEqual('home');
      expect(payload.weather.temperature).assertEqual('27℃');
      expect(payload.profile.constitution.name).assertEqual('平和质');
      expect(payload.location.city).assertEqual(weather.city);
      expect(payload.location.address).assertEqual(weather.city);
    });

    it('builds suggestion result from backend payload', 0, () => {
      const result = buildSuggestionResultFromBackendPayload('{"source":"规则兜底","riskLevel":"normal","summary":"湿度偏高","suggestions":["室内通风"],"plans":[{"timeOfDay":"morning","title":"清淡饮食","action":"少油腻","reason":"湿度偏高"}],"disclaimer":"不能替代医生诊断"}');

      expect(result.source).assertEqual('规则兜底');
      expect(result.summary).assertContain('湿度');
      expect(result.suggestions[0]).assertEqual('室内通风');
      expect(result.plans[0].title).assertEqual('清淡饮食');
    });

    it('includes weather in assistant request payload', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const weather = getCurrentWeatherWellness();
      const payload = buildAssistantRequestPayload('今天怎么吃', profile, [], weather);

      expect(payload).assertContain('"weather"');
      expect(payload).assertContain('"humidity":"68%"');
      expect(payload).assertContain('"temperature":"27℃"');
    });

    it('builds limited backend chat history', 0, () => {
      const history = buildBackendHistory([
        { role: 'user', content: '1' },
        { role: 'assistant', content: '2' },
        { role: 'user', content: '3' },
        { role: 'assistant', content: '4' },
        { role: 'user', content: '5' },
        { role: 'assistant', content: '6' },
        { role: 'user', content: '7' }
      ]);

      expect(history.length).assertEqual(6);
      expect(history[0].content).assertEqual('2');
      expect(history[5].content).assertEqual('7');
    });

    it('serializes and trims assistant chat history', 0, () => {
      const messages: ChatMessage[] = [];
      for (let index = 0; index < 32; index++) {
        messages.push({ role: 'user', content: `${index}` });
      }

      const trimmed = trimChatHistory(messages);
      const restored = deserializeChatHistory(serializeChatHistory(messages));

      expect(trimmed.length).assertEqual(30);
      expect(trimmed[0].content).assertEqual('2');
      expect(restored.length).assertEqual(30);
      expect(restored[29].content).assertEqual('31');
    });

    it('saves and loads assistant chat history repository', 0, async () => {
      const repository = new ChatHistoryRepository(new MemoryChatHistoryStorageAdapter());

      await repository.saveMessages([{ role: 'user', content: '睡眠不好' }]);
      const messages = await repository.loadMessages();

      expect(messages.length).assertEqual(1);
      expect(messages[0].content).assertEqual('睡眠不好');
    });

    it('clears assistant chat history repository', 0, async () => {
      const repository = new ChatHistoryRepository(new MemoryChatHistoryStorageAdapter());

      await repository.saveMessages([{ role: 'user', content: '睡眠不好' }]);
      const cleared = await repository.clearMessages();
      const loaded = await repository.loadMessages();

      expect(cleared.length > 0).assertTrue();
      expect(loaded[0].role).assertEqual('assistant');
    });

    it('provides backend api configuration skeleton', 0, () => {
      setRuntimeBaseUrl('http://172.20.10.10:8181');
      const config = getApiConfig();

      expect(config.baseUrl).assertEqual('http://172.20.10.10:8181');
      expect(config.authBaseUrl).assertEqual('http://172.20.10.10:8181');
      expect(config.aiBaseUrl).assertEqual('http://172.20.10.10:8181');
      expect(config.suggestionsBaseUrl).assertEqual('http://172.20.10.10:8181');
      expect(config.aiChatPath).assertEqual('/api/ai/chat');
      expect(config.aiStatusPath).assertEqual('/api/ai/status');
      expect(config.authMePath).assertEqual('/api/auth/me');
      expect(config.authSmsCodePath).assertEqual('/api/auth/sms-code');
      expect(config.authSmsLoginPath).assertEqual('/api/auth/sms-login');
      expect(config.authPasswordResetIdentifyPath).assertEqual('/api/auth/password-reset/identify');
      expect(config.authPasswordResetPath).assertEqual('/api/auth/password-reset');
      expect(config.suggestionsPath).assertEqual('/api/ai/suggestions');
      expect(config.weatherPath).assertEqual('/api/weather/current');
      expect(config.healthArchiveCurrentPath).assertEqual('/api/health-archive/current');
      expect(config.healthPath).assertEqual('/api/health');
      expect(config.timeoutMs).assertEqual(6000);
      expect(buildApiUrl(config.weatherPath)).assertEqual('http://172.20.10.10:8181/api/weather/current');
      expect(buildApiUrl(config.healthArchiveCurrentPath)).assertEqual('http://172.20.10.10:8181/api/health-archive/current');
      expect(buildAiApiUrl(config.aiChatPath)).assertEqual('http://172.20.10.10:8181/api/ai/chat');
      expect(buildAiApiUrl(config.aiStatusPath)).assertEqual('http://172.20.10.10:8181/api/ai/status');
      expect(buildSuggestionApiUrl(config.suggestionsPath)).assertEqual('http://172.20.10.10:8181/api/ai/suggestions');
      expect(buildAuthApiUrl(config.authLoginPath)).assertEqual('http://172.20.10.10:8181/api/auth/login');
      expect(buildAuthApiUrl(config.authSmsCodePath)).assertEqual('http://172.20.10.10:8181/api/auth/sms-code');
      expect(buildAuthApiUrl(config.authPasswordResetPath)).assertEqual('http://172.20.10.10:8181/api/auth/password-reset');
      expect(buildAuthApiUrl(config.authMePath)).assertEqual('http://172.20.10.10:8181/api/auth/me');
      expect(buildAiApiUrl(config.healthPath)).assertEqual('http://172.20.10.10:8181/api/health');
    });

    it('switches auth endpoints when runtime backend base url changes', 0, () => {
      setRuntimeBaseUrl('http://192.168.1.8:8181');

      expect(getApiConfig().authBaseUrl).assertEqual('http://192.168.1.8:8181');
      expect(buildAuthApiUrl(getApiConfig().authLoginPath)).assertEqual('http://192.168.1.8:8181/api/auth/login');

      setRuntimeBaseUrl('http://172.20.10.10:8181');
    });

    it('normalizes runtime backend urls before saving', 0, () => {
      expect(normalizeApiBaseUrl('  http://192.168.1.8:8181/  ')).assertEqual('http://192.168.1.8:8181');
      expect(normalizeApiBaseUrl('https://api.example.com/v1//')).assertEqual('https://api.example.com/v1');
      expect(normalizeApiBaseUrl('ftp://192.168.1.8:8181')).assertEqual('');
      expect(normalizeApiBaseUrl('   ')).assertEqual('');

      setRuntimeBaseUrl('http://192.168.1.8:8181/');
      setRuntimeAiBaseUrl('https://api.example.com/v1//');

      expect(getApiConfig().baseUrl).assertEqual('http://192.168.1.8:8181');
      expect(getApiConfig().aiBaseUrl).assertEqual('https://api.example.com/v1');

      setRuntimeBaseUrl('ftp://bad-host');
      setRuntimeAiBaseUrl('');

      expect(getApiConfig().baseUrl).assertEqual('http://192.168.1.8:8181');
      expect(getApiConfig().aiBaseUrl).assertEqual('https://api.example.com/v1');

      setRuntimeBaseUrl('http://172.20.10.10:8181');
      setRuntimeAiBaseUrl('http://172.20.10.10:8181');
    });

    it('provides backend status skeleton before network integration', 0, () => {
      const status = getBackendStatus();

      expect(status.available).assertFalse();
      expect(status.mode).assertEqual('本地兜底');
      expect(status.healthUrl).assertEqual('http://172.20.10.10:8181/api/health');
    });

    it('builds available backend status from health payload', 0, () => {
      const status = buildBackendStatusFromHealthPayload('{"status":"ok","service":"yangshengzhushou_db"}');

      expect(status.available).assertTrue();
      expect(status.mode).assertEqual('后端可用');
      expect(status.healthUrl).assertEqual('http://172.20.10.10:8181/api/health');
    });

    it('appends user question and local assistant reply', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const result = appendLocalAssistantReply([], ' 最近有点困 ', profile);

      expect(result.length).assertEqual(2);
      expect(result[0].role).assertEqual('user');
      expect(result[0].content).assertEqual('最近有点困');
      expect(result[1].role).assertEqual('assistant');
      expect(result[1].content).assertContain('最近有点困');
    });

    it('keeps assistant messages unchanged for empty question', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const result = appendLocalAssistantReply([{ role: 'assistant', content: '你好' }], '   ', profile);

      expect(result.length).assertEqual(1);
      expect(result[0].content).assertEqual('你好');
    });

    it('appends user question and assistant reply separately', 0, () => {
      const userMessages = appendUserQuestion([], ' 后端问题 ');
      const result = appendAssistantReplyResult(userMessages, {
        content: '后端回答',
        source: '后端模拟',
        riskLevel: 'normal',
        suggestions: ['规律作息'],
        plan: [],
        disclaimer: '不能替代医生诊断',
        targetUrl: 'http://172.20.10.10:8181/api/ai/chat',
        healthUrl: 'http://172.20.10.10:8181/api/health'
      });

      expect(result.length).assertEqual(2);
      expect(result[0].content).assertEqual('后端问题');
      expect(result[1].content).assertEqual('后端回答');
      expect(result[1].source).assertEqual('后端模拟');
      expect(result[1].suggestions ? result[1].suggestions.length : 0).assertEqual(1);
      expect(result[1].riskLevel).assertEqual('normal');
    });

    it('keeps urgent risk level on assistant message', 0, () => {
      const result = appendAssistantReplyResult([], {
        content: '请及时就医',
        source: '后端模拟',
        riskLevel: 'urgent',
        suggestions: ['及时就医'],
        plan: [],
        disclaimer: '不能替代医生诊断',
        targetUrl: 'http://172.20.10.10:8181/api/ai/chat',
        healthUrl: 'http://172.20.10.10:8181/api/health'
      });

      expect(result.length).assertEqual(1);
      expect(result[0].riskLevel).assertEqual('urgent');
      expect(result[0].suggestions ? result[0].suggestions[0] : '').assertEqual('及时就医');
    });

    it('builds assistant source text from latest reply source', 0, () => {
      expect(buildAssistantSourceText('DeepSeek', '后端可用')).assertEqual('当前回复来源：DeepSeek · 后端可用');
      expect(buildAssistantSourceText('', '本地兜底')).assertEqual('当前回复来源：本地规则 · 本地兜底');
    });

    it('checks whether assistant question can be sent', 0, () => {
      expect(canSendAssistantQuestion('', false)).assertFalse();
      expect(canSendAssistantQuestion('   ', false)).assertFalse();
      expect(canSendAssistantQuestion('睡眠不好', true)).assertFalse();
      expect(canSendAssistantQuestion('睡眠不好', false)).assertTrue();
    });

    it('builds health archive summary from metric count', 0, () => {
      const result = buildHealthArchiveSummary(4, '气虚质');

      expect(result).assertContain('4项指标');
      expect(result).assertContain('气虚质');
    });

    it('builds profile archive summaries from saved records', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.constitution.name = '气虚质';
      profile.questionnaireRecords = [{
        submittedAt: '2026-06-23T10:00:00.000Z',
        answers: [],
        totalScore: 11,
        constitution: {
          name: '气虚质',
          score: 11,
          suggestion: '温和运动'
        },
        suggestion: '温和运动'
      }];
      profile.healthIndicators = [
        { name: '血压', value: '128/82', unit: 'mmHg', recordedAt: '2026-06-24T08:00:00.000Z' },
        { name: '睡眠', value: '7', unit: '小时', recordedAt: '2026-06-24T22:00:00.000Z' }
      ];
      profile.tongueNotes = [{
        color: '淡红',
        coating: '薄白',
        dryness: '适中',
        note: '状态平稳',
        recordedAt: '2026-06-24T07:30:00.000Z'
      }];

      const summaries = buildArchiveSummariesFromProfile(profile);

      expect(summaries.length).assertEqual(3);
      expect(summaries[0].value).assertEqual('气虚质');
      expect(summaries[1].value).assertEqual('2条');
      expect(summaries[2].value).assertEqual('2天');
      expect(summaries[1].description).assertContain('舌象1条');
    });

    it('formats device sync summary', 0, () => {
      const result = getDeviceSyncSummary(0, 0);

      expect(result).assertEqual('设备同步暂未接入');
    });

    it('keeps default device sync list empty before integration', 0, () => {
      const devices = getDeviceStatuses();

      expect(devices.length).assertEqual(0);
      expect(countPendingDeviceSyncs(devices)).assertEqual(0);
    });

    it('formats reminder summary', 0, () => {
      const result = formatReminderSummary(2, 3);

      expect(result).assertEqual('已开启2/3个提醒');
    });

    it('returns recent records empty state copy', 0, () => {
      const info = getEmptyStateInfo('records');

      expect(info.title).assertEqual('暂无本地记录');
      expect(info.detail).assertContain('保存舌象或健康指标');
    });

    it('returns generic empty state for unknown key', 0, () => {
      const info = getEmptyStateInfo('unknown');

      expect(info.title).assertEqual('暂无可显示内容');
      expect(info.detail).assertContain('继续使用');
    });

    it('returns profile load fallback copy', 0, () => {
      const info = getEmptyStateInfo('profileLoad');

      expect(info.title).assertEqual('本地档案暂不可用');
      expect(info.detail).assertContain('默认档案');
    });

    it('builds local save success feedback text', 0, () => {
      expect(buildSaveSuccessText('tongueNote')).assertEqual('舌象记录已保存');
      expect(buildSaveSuccessText('healthIndicator')).assertEqual('健康指标已保存');
      expect(buildSaveSuccessText('questionnaire')).assertEqual('问卷结果已保存');
      expect(buildSaveSuccessText('reminder')).assertEqual('提醒设置已保存');
    });

    it('builds local save failure feedback text', 0, () => {
      expect(buildSaveFailureText('tongueNote')).assertContain('舌象记录');
      expect(buildSaveFailureText('healthIndicator')).assertContain('健康指标');
      expect(buildSaveFailureText('questionnaire')).assertContain('问卷结果');
      expect(buildSaveFailureText('reminder')).assertContain('提醒设置');
    });

    it('normalizes backend http and network failures for app feedback', 0, () => {
      expect(buildHttpFailureText(401, '{"success":false,"message":"token expired"}')).assertContain('重新登录');
      expect(buildHttpFailureText(403, '{"success":false,"message":"forbidden"}')).assertContain('没有权限');
      expect(buildHttpFailureText(500, '{"success":false,"message":"database error"}')).assertContain('后端服务异常');
      expect(buildHttpFailureText(400, '{"success":false,"message":"phone already exists"}')).assertEqual('phone already exists');
      expect(normalizeNetworkErrorMessage('connect ECONNREFUSED 172.20.10.10:8181')).assertContain('无法连接后端');
      expect(normalizeNetworkErrorMessage('request timeout')).assertContain('响应超时');
    });

    it('notifies app shell when backend returns unauthorized', 0, () => {
      let notice = '';
      clearSessionInvalidationHandler();
      setSessionInvalidationHandler((message: string) => {
        notice = message;
      });

      buildHttpFailureText(401, '{"success":false,"message":"token expired"}');

      expect(notice).assertContain('重新登录');
      clearSessionInvalidationHandler();
    });

    it('does not invalidate session for forbidden backend response', 0, () => {
      let notice = '';
      clearSessionInvalidationHandler();
      setSessionInvalidationHandler((message: string) => {
        notice = message;
      });

      buildHttpFailureText(403, '{"success":false,"message":"forbidden"}');

      expect(notice).assertEqual('');
      clearSessionInvalidationHandler();
    });

    it('lists local device storage in privacy status', 0, () => {
      const items = getPrivacyStatusItems();

      expect(items.length).assertEqual(7);
      expect(items[0].title).assertEqual('数据位置');
      expect(items[0].detail).assertContain('本机');
    });

    it('builds privacy status from permission states', 0, () => {
      const items = buildPrivacyStatusItemsFromPermissionStates({
        location: 'granted',
        camera: 'notGranted',
        notification: 'notConfigured',
        bluetooth: 'notUsed'
      });

      expect(items.length).assertEqual(7);
      expect(items[2].title).assertEqual('定位权限');
      expect(items[2].status).assertEqual('已授权');
      expect(items[3].title).assertEqual('相机权限');
      expect(items[3].status).assertEqual('未授权');
      expect(items[4].title).assertEqual('通知权限');
      expect(items[4].status).assertEqual('未配置');
      expect(items[5].title).assertEqual('设备连接权限');
      expect(items[5].status).assertEqual('当前未使用');
    });

    it('defaults stored location permission to not granted', 0, async () => {
      const repository = new PermissionStatusRepository(new MemoryPermissionStatusStorageAdapter());

      const state = await repository.loadLocationPermissionState();

      expect(state).assertEqual('notGranted');
    });

    it('persists granted location permission state', 0, async () => {
      const repository = new PermissionStatusRepository(new MemoryPermissionStatusStorageAdapter());

      await repository.saveLocationPermissionState('granted');
      const state = await repository.loadLocationPermissionState();

      expect(state).assertEqual('granted');
    });

    it('shows cloud sync disabled in privacy status', 0, () => {
      const items = getPrivacyStatusItems();

      expect(items[1].title).assertEqual('云同步');
      expect(items[1].status).assertEqual('未开启');
      expect(items[2].title).assertEqual('定位权限');
      expect(items[2].status).assertEqual('未授权');
    });

    it('summarizes local privacy boundary', 0, () => {
      const summary = getPrivacySummary();

      expect(summary).assertContain('本地');
      expect(summary).assertContain('未开启云同步');
    });

    it('keeps tongue quick action as local text record', 0, () => {
      const result = getQuickActions();

      expect(result[1].title).assertEqual('舌象记录');
      expect(result[1].description).assertEqual('记录舌象文字特征');
    });

    it('marks profile actions with truthful availability status', 0, () => {
      const result = getProfileActions();

      expect(result.length).assertEqual(4);
      expect(result[0].status).assertEqual('本页可用');
      expect(result[1].status).assertEqual('暂未接入');
      expect(result[1].description).assertContain('手动记录');
    });

    it('searches herbal recipes by constitution', 0, () => {
      const result = searchHerbalRecipes('气虚质');

      expect(result.length > 0).assertTrue();
      expect(result[0].name).assertEqual('黄芪山药粥');
    });

    it('searches food contraindications by keyword', 0, () => {
      const result = searchFoodContraindications('孕期');

      expect(result.length > 0).assertTrue();
      expect(result[0].warning).assertContain('谨慎');
    });

    it('searches acupoints by symptom', 0, () => {
      const result = searchAcupoints('失眠');

      expect(result.length > 0).assertTrue();
      expect(result[0].name).assertEqual('神门');
    });

    it('generates personalized diet exercise and sleep plan', 0, () => {
      const result = generatePersonalPlan('气虚质', '控糖', 6.5);

      expect(result.diet.title).assertEqual('控糖健脾餐');
      expect(result.exercise.detail).assertContain('八段锦');
      expect(result.sleep.detail).assertContain('固定入睡时间');
    });

    it('interprets medical indicators and flags abnormal blood pressure', 0, () => {
      const result = interpretMedicalIndicators(146, 94, 5.6, 7.2);

      expect(result.abnormalItems.length).assertEqual(2);
      expect(result.abnormalItems[0].name).assertEqual('收缩压');
      expect(result.summary).assertContain('2项异常');
    });

    it('generates monthly report summary', 0, () => {
      const result = generateMonthlyReport(18, 3, '气虚质');

      expect(result.title).assertEqual('月度养生报告');
      expect(result.summary).assertContain('18天');
      expect(result.suggestion).assertContain('气虚质');
    });

    it('generates empty local monthly report from saved profile', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      const result = generateLocalMonthlyReport(profile);

      expect(result.title).assertEqual('本地月度养生报告');
      expect(result.summary).assertContain('本月暂无本地记录');
      expect(result.suggestion).assertContain('完成体质问卷');
    });

    it('generates local monthly report from profile records', 0, () => {
      const profile = createDefaultHealthProfile('2026-06-23T10:30:00.000Z');
      profile.healthIndicators = [
        { name: '血压', value: '146/94', unit: 'mmHg', recordedAt: '2026-06-20T08:00:00.000Z' },
        { name: '空腹血糖', value: '7.2', unit: 'mmol/L', recordedAt: '2026-06-20T09:00:00.000Z' },
        { name: '睡眠', value: '6.5', unit: '小时', recordedAt: '2026-06-21T08:00:00.000Z' }
      ];
      profile.tongueNotes = [{
        color: '淡红',
        coating: '厚黄',
        dryness: '偏干',
        note: '晨起观察。',
        recordedAt: '2026-06-22T08:00:00.000Z'
      }];

      const result = generateLocalMonthlyReport(profile);

      expect(result.summary).assertContain('3天');
      expect(result.summary).assertContain('4类需要关注');
      expect(result.suggestion).assertContain('平和质');
    });
  });
}
