import { common } from '@kit.AbilityKit';
import { seasonBackground } from '../theme/SeasonBackground';
import { getCurrentSolarTerm } from '../utils/SolarTermUtil';
import { loadConnectionSettings } from '../services/ConnectionSettings';
import { QuickActionView } from '../components/QuickActionView';
import { cancelUserReminders } from '../services/NotificationService';
import { AdminAssistantLogsTab } from '../components/tabs/AdminAssistantLogsTab';
import { AdminConsultationsTab } from '../components/tabs/AdminConsultationsTab';
import { AdminOverviewTab } from '../components/tabs/AdminOverviewTab';
import { AdminPeopleTab } from '../components/tabs/AdminPeopleTab';
import { AppHeader } from '../components/AppHeader';
import { AuthView } from '../components/AuthView';
import { GuideView } from '../components/GuideView';
import { AssistantTab } from '../components/tabs/AssistantTab';
import { DataTab } from '../components/tabs/DataTab';
import { FamilyTab } from '../components/tabs/FamilyTab';
import { DoctorConsultationTab } from '../components/tabs/DoctorConsultationTab';
import { DoctorProfileTab } from '../components/tabs/DoctorProfileTab';
import { HomeTab } from '../components/tabs/HomeTab';
import { ProfileTab } from '../components/tabs/ProfileTab';
import { UserConsultationTab } from '../components/tabs/UserConsultationTab';
import { WellnessTabBar } from '../components/TabBar';
import { BRAND_GREEN, CARD_BG, MUTED_TEXT } from '../theme/WellnessTheme';
import { SolarTermInfo, SuggestionResult, WeatherWellness, WellnessPlan, WellnessPlanItem } from '../model/WellnessModels';
import {
  AuthSession,
  AuthSessionRepository,
  createPreferencesAuthSessionRepository,
  requestCurrentAuthSession,
  setRuntimeAuthToken
} from '../services/AuthService';
import { requestLocatedWeatherWellness } from '../services/WeatherService';
import { HealthProfile, MetricCode, HealthMeasurement } from '../model/ProfileModels';
import { StructuredHealthForm } from '../components/profile/StructuredHealthForm';
import { TongueImageView, TongueImageViewMode } from '../components/profile/TongueImageView';
import { TongueImageRecord } from '../model/ProfileModels';
import {
  HealthProfileRepository,
  createDefaultHealthProfile,
  createPreferencesHealthProfileRepository
} from '../services/ProfileRepository';
import { requestWeatherAwareSuggestions } from '../services/SuggestionService';
import {
  getRoleTabs,
  resolveAuthorizedTabIndex,
  resolvePrimaryRole,
  RoleTabItem
} from '../services/RoleExperienceService';
import {
  clearSessionInvalidationHandler,
  setSessionInvalidationHandler
} from '../services/SessionInvalidationService';
import { createWellnessDashboardData, WellnessDashboardData } from '../viewmodel/WellnessDashboardViewModel';

function mapPlanItemsToWellnessPlans(items: WellnessPlanItem[]): WellnessPlan[] {
  return items.map((item: WellnessPlanItem) => {
    const plan: WellnessPlan = {
      title: item.title,
      time: item.timeOfDay === 'morning' ? '07:30' : item.timeOfDay === 'afternoon' ? '13:00' : '22:00',
      detail: item.action,
      tag: item.timeOfDay === 'morning' ? '运动' : item.timeOfDay === 'afternoon' ? '食疗' : '作息'
    };
    return plan;
  });
}

@Entry
@Component
struct Index {
  @State isAuthChecked: boolean = false;
  @State authSession: AuthSession | null = null;
  @State hasEnteredApp: boolean = false;
  @State guideIndex: number = 0;
  @State currentTab: number = 0;
  @State questionnaireScore: number = 11;
  @State currentProfile: HealthProfile = createDefaultHealthProfile();
  @State currentWeather: WeatherWellness = createWellnessDashboardData().weather;
  @State weatherAwarePlans: WellnessPlan[] = [];
  @State homeSuggestion: SuggestionResult | null = null;
  @State homeSuggestionLoading: boolean = false;
  @State homeSuggestionError: string = '';
  @State weatherRefreshing: boolean = false;
  @State weatherRefreshStatus: string = '';
  @State dataSuggestionSummary: string = '';
  @State profileSuggestionSummary: string = '';
  @State authNotice: string = '';
  @State solarTerm: SolarTermInfo = getCurrentSolarTerm();
  @State seasonalImage: Resource = seasonBackground();
  @State shortcut: string = '';
  @State assistantDraft: string = '';
  @State pendingMetricCode: MetricCode = MetricCode.BLOOD_PRESSURE;
  @State showHealthForm: boolean = false;
  @State showTongueView: boolean = false;
  private calendarTimer: number = -1;

  private dashboard: WellnessDashboardData = createWellnessDashboardData();
  private authRepository?: AuthSessionRepository;
  private profileRepository?: HealthProfileRepository;

  aboutToAppear() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.authRepository = createPreferencesAuthSessionRepository(context);
    this.calendarTimer = setInterval(() => { this.refreshCalendar(); }, 30000);
    setSessionInvalidationHandler((message: string) => {
      this.handleSessionInvalidated(message);
    });
    loadConnectionSettings(context).catch(() => {}).then(() => this.authRepository!.loadSession()).then((session: AuthSession | null) => {
      if (session === null) {
        this.authSession = null;
        setRuntimeAuthToken('');
        this.currentTab = 0;
        this.isAuthChecked = true;
      } else {
        this.validateStoredSession(session);
      }
    }).catch(() => {
      this.authSession = null;
      setRuntimeAuthToken('');
      this.currentTab = 0;
      this.isAuthChecked = true;
    });
  }

  aboutToDisappear() {
    clearInterval(this.calendarTimer);
    clearSessionInvalidationHandler();
  }

  build() {
    Stack() {
      Image(this.seasonalImage)
        .width('100%').height('100%').objectFit(ImageFit.Cover)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM, SafeAreaEdge.START, SafeAreaEdge.END])
        .hitTestBehavior(HitTestMode.None)
    if (!this.isAuthChecked) {
      this.AuthCheckingView()
    } else if (this.authSession === null) {
      AuthView({
        initialNotice: this.authNotice,
        onAuthenticated: (session: AuthSession) => {
          this.saveAuthenticatedSession(session);
        }
      })
    } else if (!this.hasEnteredApp) {
      GuideView({
        guideIndex: $guideIndex,
        hasEnteredApp: $hasEnteredApp,
        guideSlides: this.dashboard.guideSlides
      })
    } else {
      this.MainView()
    }
    }.width('100%').height('100%')
  }

  onPageShow(): void {
    this.refreshCalendar();
  }

  private refreshCalendar(): void {
    this.solarTerm = getCurrentSolarTerm();
    this.seasonalImage = seasonBackground();
  }




  @Builder
  AuthCheckingView() {
    Column() {
      Text('养生助手')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textShadow({ radius: 4, color: '#99000000', offsetY: 1 })
      Text('正在检查登录状态...')
        .fontSize(14)
        .fontColor(Color.White)
        .textShadow({ radius: 4, color: '#99000000', offsetY: 1 })
        .margin({ top: 8 })
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
  }


  @Builder
  MainView() {
    Column() {
      AppHeader({ riskLevel: this.currentWeather.riskLevel })

      Scroll() {
        Column() {
          if (this.shortcut.length > 0 && this.currentTabKey() === 'home') {
            QuickActionView({ action: this.shortcut, userId: this.authUserId(),
              onBack: () => { this.shortcut = ''; },
              onProfileChanged: (profile: HealthProfile) => { this.handleProfileChanged(profile); }
            })
          } else if (this.currentTabKey() === 'home') {
            HomeTab({
              weather: this.currentWeather,
              solarTerm: this.solarTerm,
              plans: this.weatherAwarePlans,
              quickActions: this.dashboard.quickActions,
              suggestionSource: this.homeSuggestionSource(),
              suggestionSummary: this.homeSuggestionSummary(),
              suggestionItems: this.homeSuggestionItems(),
              suggestionRetrievalStatus: this.homeSuggestionRetrievalStatus(),
              suggestionLoading: this.homeSuggestionLoading,
              suggestionError: this.homeSuggestionError,
              weatherRefreshing: this.weatherRefreshing,
              weatherRefreshStatus: this.weatherRefreshStatus,
              onRefreshWeather: () => {
                this.refreshLocatedWeather();
              },
              onRefreshSuggestion: () => {
                this.refreshHomeSuggestion(this.currentWeather);
              },
              onQuickAction: (title: string) => {
                if (title === '体质问卷') {
                  this.shortcut = title;
                } else if (title === '舌象记录') {
                  this.currentTab = resolveAuthorizedTabIndex(this.primaryRole(), 'health');
                  this.showTongueView = true;
                } else {
                  this.assistantDraft = title === '食疗茶饮' ? '请结合我的体质和当前季节，给出适合我的食疗茶饮建议及注意事项。' : '请结合我的情况，介绍适合日常保健的穴位按揉方式和禁忌。';
                  this.currentTab = resolveAuthorizedTabIndex(this.primaryRole(), 'assistant');
                }
              },
              onWeatherSelected: (weather: WeatherWellness) => {
                this.currentWeather = weather;
                this.weatherRefreshStatus = '已选择手动位置';
              }
            })
          } else if (this.currentTabKey() === 'assistant') {
            AssistantTab({
              questionnaireScore: $questionnaireScore,
              weather: this.currentWeather,
              authUserId: this.authUserId(),
              profile: this.currentProfile,
              initialQuestion: this.assistantDraft,
              onDraftConsumed: () => { this.assistantDraft = ''; },
              onProfileChanged: (profile: HealthProfile) => {
                this.handleProfileChanged(profile);
              }
            })
          } else if (this.currentTabKey() === 'health') {
            if (this.showTongueView) {
              Column({ space: 14 }) {
                Row() {
                  Button('返回')
                    .fontColor(BRAND_GREEN)
                    .backgroundColor(Color.Transparent)
                    .onClick(() => { this.showTongueView = false; })
                }
                .width('100%')
                TongueImageView({
                  images: [] as TongueImageRecord[],
                  isLoading: false,
                  onBack: () => { this.showTongueView = false; },
                  onUploadImage: (uri: string, source: 'CAMERA' | 'ALBUM') => {
                    this.showTongueView = false;
                  }
                })
              }
              .width('100%')
            } else if (this.showHealthForm) {
              Column({ space: 14 }) {
                Row() {
                  Button('返回')
                    .fontColor(BRAND_GREEN)
                    .backgroundColor(Color.Transparent)
                    .onClick(() => { this.showHealthForm = false; })
                }
                .width('100%')
                StructuredHealthForm({
                  metricCode: this.pendingMetricCode,
                  isVisible: this.showHealthForm,
                  onClose: () => { this.showHealthForm = false; },
                  onSave: async (measurement: HealthMeasurement): Promise<boolean> => {
                    try {
                      const repository = createPreferencesHealthProfileRepository(this.getUIContext().getHostContext() as common.UIAbilityContext, this.authUserId());
                      const profile = await repository.loadProfile();
                      const nextProfile = profile;
                      if (!nextProfile.measurements) {
                        nextProfile.measurements = [];
                      }
                      nextProfile.measurements = [measurement].concat(nextProfile.measurements);
                      const saved = await repository.saveProfile(nextProfile);
                      this.currentProfile = saved;
                      this.showHealthForm = false;
                      return true;
                    } catch (error) {
                      return false;
                    }
                  }
                })
              }
              .width('100%')
            } else {
              DataTab({
                weather: this.currentWeather,
                weatherSuggestionSummary: this.dataSuggestionSummary,
                profile: this.currentProfile,
                metrics: this.dashboard.metrics,
                devices: this.dashboard.devices,
                authUserId: this.authUserId(),
                onAddRecord: (metricCode: MetricCode) => {
                  this.pendingMetricCode = metricCode;
                  this.showHealthForm = true;
                },
                onViewCategory: (category: string) => {
                  let code: MetricCode = MetricCode.BLOOD_PRESSURE;
                  switch (category) {
                    case 'bloodPressure': code = MetricCode.BLOOD_PRESSURE; break;
                    case 'bloodSugar': code = MetricCode.BLOOD_SUGAR; break;
                    case 'heartRate': code = MetricCode.HEART_RATE; break;
                    case 'bloodOxygen': code = MetricCode.BLOOD_OXYGEN; break;
                    case 'temperature': code = MetricCode.TEMPERATURE; break;
                    case 'body': code = MetricCode.BODY; break;
                    case 'steps': code = MetricCode.STEPS; break;
                    case 'exercise': code = MetricCode.EXERCISE; break;
                    case 'water': code = MetricCode.WATER; break;
                    default: code = MetricCode.BLOOD_PRESSURE; break;
                  }
                  this.pendingMetricCode = code;
                  this.showHealthForm = true;
                },
                onViewTongue: () => {
                  this.showTongueView = true;
                },
                onViewSleep: () => {
                  this.pendingMetricCode = MetricCode.SLEEP;
                  this.showHealthForm = true;
                }
              })
            }
          } else if (this.currentTabKey() === 'family') {
            FamilyTab({ userId: this.authUserId(), userPhone: this.authPhoneText() })
          } else if (this.currentTabKey() === 'profile') {
            ProfileTab({
              isAdmin: this.primaryRole() === 'ADMIN',
              weather: this.currentWeather,
              weatherSuggestionSummary: this.profileSuggestionSummary,
              questionnaireScore: this.questionnaireScore,
              metricCount: this.dashboard.metrics.length,
              archiveSummaries: this.dashboard.archiveSummaries,
              profileActions: this.dashboard.profileActions,
              profile: this.currentProfile,
              authPhone: this.authPhoneText(),
              authUserId: this.authUserId(),
              onProfileChanged: (profile: HealthProfile) => {
                this.handleProfileChanged(profile);
              },
              onLogout: () => {
                this.logout();
              },
              onNavigateFamily: () => {
                this.currentTab = resolveAuthorizedTabIndex(this.primaryRole(), 'family');
              }
            })
          } else if (this.currentTabKey() === 'consultation') {
            UserConsultationTab({
              userId: this.authUserId(),
              userName: this.currentProfile.displayName,
              userPhone: this.authPhoneText()
            })
          } else if (this.currentTabKey() === 'doctorWorkbench') {
            DoctorConsultationTab({ doctorId: this.authUserId(), title: '医生工作台' })
          } else if (this.currentTabKey() === 'doctorConsultation') {
            DoctorConsultationTab({ doctorId: this.authUserId(), title: '医生问诊' })
          } else if (this.currentTabKey() === 'doctorProfile') {
            DoctorProfileTab({ userId: this.authUserId() })
          } else if (this.currentTabKey() === 'adminOverview') {
            AdminOverviewTab()
          } else if (this.currentTabKey() === 'adminPeople') {
            AdminPeopleTab()
          } else if (this.currentTabKey() === 'adminAssistantLogs') {
            AdminAssistantLogsTab()
          } else if (this.currentTabKey() === 'adminConsultations') {
            AdminConsultationsTab()
          }
        }
        .padding({ left: 18, right: 18, bottom: 96 })
      }
      .layoutWeight(1)

      WellnessTabBar({ currentTab: $currentTab, tabTitles: this.currentTabTitles() })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
  }

  @Builder
  RolePlaceholderPage(title: string, subtitle: string, detail: string) {
    Column() {
      Text(title)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#17231D')
      Text(subtitle)
        .fontSize(14)
        .fontColor(MUTED_TEXT)
        .lineHeight(22)
        .margin({ top: 10 })
      Column() {
        Text(this.primaryRole())
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(BRAND_GREEN)
        Text(detail)
          .fontSize(15)
          .fontColor('#2F3B35')
          .lineHeight(24)
          .margin({ top: 10 })
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 18, bottom: 18 })
      .margin({ top: 18 })
      .backgroundColor(CARD_BG)
      .borderRadius(16)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  private saveAuthenticatedSession(session: AuthSession): void {
    this.authNotice = '';
    if (this.authRepository) {
      this.authRepository.saveSession(session).then((savedSession: AuthSession) => {
        this.applyAuthenticatedSession(savedSession, false);
        this.loadCurrentProfileAndRefreshWeather();
      }).catch(() => {
        this.applyAuthenticatedSession(session, false);
        this.loadCurrentProfileAndRefreshWeather();
      });
    } else {
      this.applyAuthenticatedSession(session, false);
      this.loadCurrentProfileAndRefreshWeather();
    }
  }

  private validateStoredSession(session: AuthSession): void {
    setRuntimeAuthToken(session.token);
    requestCurrentAuthSession(session).then((validatedSession: AuthSession) => {
      if (this.authRepository) {
        this.authRepository.saveSession(validatedSession).then((savedSession: AuthSession) => {
          this.applyAuthenticatedSession(savedSession, true);
          this.isAuthChecked = true;
          this.loadCurrentProfileAndRefreshWeather();
        }).catch(() => {
          this.applyAuthenticatedSession(validatedSession, true);
          this.isAuthChecked = true;
          this.loadCurrentProfileAndRefreshWeather();
        });
      } else {
        this.applyAuthenticatedSession(validatedSession, true);
        this.isAuthChecked = true;
        this.loadCurrentProfileAndRefreshWeather();
      }
    }).catch(() => {
      if (this.authRepository) {
        this.authRepository.clearSession().then(() => {
          this.authSession = null;
          setRuntimeAuthToken('');
          this.currentTab = 0;
          this.isAuthChecked = true;
        }).catch(() => {
          this.authSession = null;
          setRuntimeAuthToken('');
          this.currentTab = 0;
          this.isAuthChecked = true;
        });
      } else {
        this.authSession = null;
        setRuntimeAuthToken('');
        this.currentTab = 0;
        this.isAuthChecked = true;
      }
    });
  }

  private logout(): void {
    if (this.authRepository) {
      this.authRepository.clearSession().then(() => {
        this.resetAuthState();
      }).catch(() => {
        this.resetAuthState();
      });
    } else {
      this.resetAuthState();
    }
  }

  private handleSessionInvalidated(message: string): void {
    if (this.authRepository) {
      this.authRepository.clearSession().then(() => {
        this.resetAuthState(message);
      }).catch(() => {
        this.resetAuthState(message);
      });
    } else {
      this.resetAuthState(message);
    }
  }

  private resetAuthState(notice: string = ''): void {
    const departingUser = this.authUserId();
    if (departingUser.length > 0) {
      cancelUserReminders(this.getUIContext().getHostContext() as common.UIAbilityContext, departingUser)
        .catch(() => { this.authNotice = '已退出登录，但系统提醒取消失败，请检查通知设置。'; });
    }
    setRuntimeAuthToken('');
    this.authSession = null;
    this.hasEnteredApp = false;
    this.guideIndex = 0;
    this.currentTab = 0;
    this.authNotice = notice;
    this.currentProfile = createDefaultHealthProfile();
    this.weatherAwarePlans = [];
    this.homeSuggestion = null;
    this.dataSuggestionSummary = '';
    this.profileSuggestionSummary = '';
    this.shortcut = '';
    this.assistantDraft = '';
  }

  private applyAuthenticatedSession(session: AuthSession, keepGuideState: boolean): void {
    this.authSession = session;
    this.authNotice = '';
    setRuntimeAuthToken(session.token);
    if (!keepGuideState) {
      this.currentTab = 0;
      this.hasEnteredApp = false;
      this.guideIndex = 0;
    } else {
      this.currentTab = resolveAuthorizedTabIndex(this.primaryRole(), this.currentTabKey());
    }
  }

  private authPhoneText(): string {
    if (this.authSession !== null) {
      return this.authSession.user.phone;
    }
    return '';
  }

  private authUserId(): string {
    if (this.authSession !== null) {
      return this.authSession.user.id;
    }
    return '';
  }

  private primaryRole(): string {
    if (this.authSession === null) {
      return 'USER';
    }
    if (this.authSession.user.primaryRole && this.authSession.user.primaryRole.length > 0) {
      return this.authSession.user.primaryRole;
    }
    return resolvePrimaryRole(this.authSession.user.roles);
  }

  private currentRoleTabs(): RoleTabItem[] {
    return getRoleTabs(this.primaryRole());
  }

  private currentTabTitles(): string[] {
    return this.currentRoleTabs().map((tab: RoleTabItem) => tab.label);
  }

  private currentTabKey(): string {
    const tabs = this.currentRoleTabs();
    if (this.currentTab < 0 || this.currentTab >= tabs.length) {
      this.currentTab = 0;
      return tabs[0].key;
    }
    const tabKey = tabs[this.currentTab].key;
    const authorizedIndex = resolveAuthorizedTabIndex(this.primaryRole(), tabKey);
    if (authorizedIndex !== this.currentTab) {
      this.currentTab = authorizedIndex;
    }
    const finalKey = tabs[this.currentTab].key;
    if (finalKey !== 'health' && this.showHealthForm) {
      this.showHealthForm = false;
    }
    return finalKey;
  }



  private refreshLocatedWeather(): void {
    if (this.weatherRefreshing) {
      return;
    }
    this.weatherRefreshing = true;
    this.weatherRefreshStatus = '正在刷新天气，并重新生成大模型建议...';
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    requestLocatedWeatherWellness(context).then((weather: WeatherWellness) => {
      this.currentWeather = weather;
      this.weatherRefreshing = false;
      this.weatherRefreshStatus = this.buildWeatherRefreshStatus(weather);
      this.refreshWeatherAwareSuggestions(weather);
    }).catch(() => {
      const fallbackWeather = createWellnessDashboardData().weather;
      this.currentWeather = fallbackWeather;
      this.weatherRefreshing = false;
      this.weatherRefreshStatus = '天气刷新失败，已使用兜底天气并尝试重新生成建议。';
      this.refreshWeatherAwareSuggestions(fallbackWeather);
    });
  }

  private buildWeatherRefreshStatus(weather: WeatherWellness): string {
    const now = new Date();
    const minuteText = now.getMinutes() < 10 ? `0${now.getMinutes()}` : `${now.getMinutes()}`;
    const timeText = `${now.getHours()}:${minuteText}`;
    if (weather.isFallback === true) {
      return `已尝试刷新 ${timeText}，当前仍为兜底天气。`;
    }
    return `已刷新 ${timeText}，正在使用最新天气生成建议。`;
  }

  private loadCurrentProfileAndRefreshWeather(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.profileRepository = createPreferencesHealthProfileRepository(context, this.authUserId());
    this.profileRepository.loadProfile().then((profile: HealthProfile) => {
      this.currentProfile = profile;
      this.questionnaireScore = profile.constitution.score;
      this.refreshLocatedWeather();
    }).catch(() => {
      const fallbackProfile = createDefaultHealthProfile();
      this.currentProfile = fallbackProfile;
      this.questionnaireScore = fallbackProfile.constitution.score;
      this.refreshLocatedWeather();
    });
  }

  private handleProfileChanged(profile: HealthProfile): void {
    this.currentProfile = profile;
    this.questionnaireScore = profile.constitution.score;
    this.refreshWeatherAwareSuggestions(this.currentWeather);
  }

  private refreshWeatherAwareSuggestions(weather: WeatherWellness): void {
    this.refreshHomeSuggestion(weather);
    requestWeatherAwareSuggestions('report', weather, this.currentProfile).then((result: SuggestionResult) => {
      this.dataSuggestionSummary = result.summary;
    }).catch(() => {
      this.dataSuggestionSummary = '';
    });
    requestWeatherAwareSuggestions('profile', weather, this.currentProfile).then((result: SuggestionResult) => {
      this.profileSuggestionSummary = result.summary;
    }).catch(() => {
      this.profileSuggestionSummary = '';
    });
  }

  private refreshHomeSuggestion(weather: WeatherWellness): void {
    if (this.homeSuggestionLoading) return;
    this.homeSuggestionLoading = true;
    this.homeSuggestionError = '';
    requestWeatherAwareSuggestions('home', weather, this.currentProfile).then((result: SuggestionResult) => {
      this.homeSuggestion = result;
      this.homeSuggestionLoading = false;
      if (result.plans.length > 0) {
        this.weatherAwarePlans = mapPlanItemsToWellnessPlans(result.plans);
      }
    }).catch((error: Error) => {
      this.homeSuggestionLoading = false;
      this.homeSuggestionError = error.message || '今日建议生成失败，请稍后重试。';
      this.weatherAwarePlans = [];
    });
  }

  private homeSuggestionSource(): string {
    return this.homeSuggestion === null ? '' : this.homeSuggestion.source;
  }

  private homeSuggestionSummary(): string {
    return this.homeSuggestion === null ? '' : this.homeSuggestion.summary;
  }

  private homeSuggestionItems(): string[] {
    return this.homeSuggestion === null ? [] : this.homeSuggestion.suggestions;
  }

  private homeSuggestionRetrievalStatus(): string {
    if (this.homeSuggestion === null || !this.homeSuggestion.retrievalStatus) {
      return '';
    }
    return this.homeSuggestion.retrievalStatus;
  }
}
