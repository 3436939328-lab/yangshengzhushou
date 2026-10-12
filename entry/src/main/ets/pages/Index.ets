import { common } from '@kit.AbilityKit';
import { seasonBackground } from '../theme/SeasonBackground';
import { getCurrentSolarTerm } from '../utils/SolarTermUtil';
import { loadConnectionSettings, saveConnectionSettings } from '../services/ConnectionSettings';
import { discoverBackendOnLan } from '../services/BackendDiscoveryService';
import { QuickActionView } from '../components/QuickActionView';
import { cancelUserReminders } from '../services/NotificationService';
import { AdminAssistantLogsTab } from '../components/tabs/AdminAssistantLogsTab';
import { AdminConsultationsTab } from '../components/tabs/AdminConsultationsTab';
import { AdminComplaintsTab } from '../components/tabs/AdminComplaintsTab';
import { AdminOverviewTab } from '../components/tabs/AdminOverviewTab';
import { AdminPeopleTab } from '../components/tabs/AdminPeopleTab';
import { AdminDoctorReviewTab } from '../components/admin/AdminDoctorReviewTab';
import { AppHeader } from '../components/AppHeader';
import { AuthView } from '../components/AuthView';
import { GuideView } from '../components/GuideView';
import { AssistantTab } from '../components/tabs/AssistantTab';
import { DataTab } from '../components/tabs/DataTab';
import { FamilyTab } from '../components/tabs/FamilyTab';
import { DoctorConsultationTab } from '../components/tabs/DoctorConsultationTab';
import { DoctorComplaintTab } from '../components/tabs/DoctorComplaintTab';
import { DoctorProfileTab } from '../components/tabs/DoctorProfileTab';
import { DoctorWorkbenchTab } from '../components/tabs/DoctorWorkbenchTab';
import { DoctorPatientTab } from '../components/tabs/DoctorPatientTab';
import { DoctorMeTab } from '../components/tabs/DoctorMeTab';
import { DoctorRegistrationView } from '../components/doctor/DoctorRegistrationView';
import { HomeTab } from '../components/tabs/HomeTab';
import { ProfileTab } from '../components/tabs/ProfileTab';
import { UserConsultationTab } from '../components/tabs/UserConsultationTab';
import { WellnessTabBar } from '../components/TabBar';
import { BRAND_GREEN, CARD_BG, DEEP_TEXT, MUTED_TEXT } from '../theme/WellnessTheme';
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
  @State showDoctorRegistration: boolean = false;
  // 医生端"我的"子页面：''=主页 'profile'=资料 'complaints'=投诉 'ratings'=评价 'rewards'=积分
  @State doctorMeSubPage: string = '';
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
          // 医生角色首次登录后引导完善资料
          const primary = this.primaryRole();
          if (primary === 'DOCTOR') {
            this.showDoctorRegistration = true;
          }
        }
      })
    } else if (!this.hasEnteredApp) {
      GuideView({
        guideIndex: $guideIndex,
        hasEnteredApp: $hasEnteredApp,
        guideSlides: this.dashboard.guideSlides
      })
    } else if (this.showDoctorRegistration) {
      DoctorRegistrationView({
        onCompleted: () => {
          this.showDoctorRegistration = false;
        },
        onExit: () => {
          this.showDoctorRegistration = false;
        }
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
                  onBack: () => { this.showTongueView = false; }
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
              userName: this.authDisplayName(),
        userPhone: this.authPhoneText(),
              profile: this.currentProfile
            })
          } else if (this.currentTabKey() === 'doctorWorkbench') {
            DoctorWorkbenchTab({
              onNavigateTab: (tabKey: string) => {
                this.doctorNavigateToTab(tabKey);
              }
            })
          } else if (this.currentTabKey() === 'doctorConsultation') {
            DoctorConsultationTab({ doctorId: this.authUserId(), title: '我的问诊' })
          } else if (this.currentTabKey() === 'doctorPatient') {
            DoctorPatientTab({
              doctorId: this.authUserId(),
              onOpenConsultation: (consultationId: string) => {
                // 跳转到问诊Tab
                this.currentTab = resolveAuthorizedTabIndex(this.primaryRole(), 'doctorConsultation');
              }
            })
          } else if (this.currentTabKey() === 'doctorMe') {
            if (this.doctorMeSubPage === 'profile') {
              // 医生资料编辑页
              Column() {
                Row() {
                  Text('←')
                    .fontSize(20)
                    .fontColor(DEEP_TEXT)
                    .onClick(() => { this.doctorMeSubPage = ''; })
                  Text('医生资料')
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(DEEP_TEXT)
                    .margin({ left: 8 })
                  Blank()
                }
                .width('100%')
                .height(48)
                .padding({ left: 16, right: 16 })

                Scroll() {
                  DoctorProfileTab({ userId: this.authUserId() })
                    .width('100%')
                }
                .layoutWeight(1)
                .scrollBar(BarState.Auto)
              }
              .width('100%')
              .height('100%')
              .backgroundColor('#F6F8F5')
            } else if (this.doctorMeSubPage === 'complaints') {
              // 投诉与申诉页
              Column() {
                Row() {
                  Text('←')
                    .fontSize(20)
                    .fontColor(DEEP_TEXT)
                    .onClick(() => { this.doctorMeSubPage = ''; })
                  Text('投诉与申诉')
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(DEEP_TEXT)
                    .margin({ left: 8 })
                  Blank()
                }
                .width('100%')
                .height(48)
                .padding({ left: 16, right: 16 })

                DoctorComplaintTab({ doctorId: this.authUserId() })
                  .layoutWeight(1)
              }
              .width('100%')
              .height('100%')
              .backgroundColor('#F6F8F5')
            } else if (this.doctorMeSubPage === 'ratings') {
              // 我的评价页（暂时用占位，后续可完善）
              Column() {
                Row() {
                  Text('←')
                    .fontSize(20)
                    .fontColor(DEEP_TEXT)
                    .onClick(() => { this.doctorMeSubPage = ''; })
                  Text('我的评价')
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(DEEP_TEXT)
                    .margin({ left: 8 })
                  Blank()
                }
                .width('100%')
                .height(48)
                .padding({ left: 16, right: 16 })

                Column({ space: 8 }) {
                  Text('功能开发中')
                    .fontSize(16)
                    .fontColor(DEEP_TEXT)
                    .fontWeight(FontWeight.Bold)
                  Text('患者评价功能即将上线，敬请期待')
                    .fontSize(13)
                    .fontColor(MUTED_TEXT)
                }
                .layoutWeight(1)
                .width('100%')
                .alignItems(HorizontalAlign.Center)
                .justifyContent(FlexAlign.Center)
              }
              .width('100%')
              .height('100%')
              .backgroundColor('#F6F8F5')
            } else if (this.doctorMeSubPage === 'rewards') {
              // 积分奖励页（暂时用占位，后续可完善）
              Column() {
                Row() {
                  Text('←')
                    .fontSize(20)
                    .fontColor(DEEP_TEXT)
                    .onClick(() => { this.doctorMeSubPage = ''; })
                  Text('积分奖励')
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(DEEP_TEXT)
                    .margin({ left: 8 })
                  Blank()
                }
                .width('100%')
                .height(48)
                .padding({ left: 16, right: 16 })

                Column({ space: 8 }) {
                  Text('功能开发中')
                    .fontSize(16)
                    .fontColor(DEEP_TEXT)
                    .fontWeight(FontWeight.Bold)
                  Text('医生积分奖励功能即将上线')
                    .fontSize(13)
                    .fontColor(MUTED_TEXT)
                }
                .layoutWeight(1)
                .width('100%')
                .alignItems(HorizontalAlign.Center)
                .justifyContent(FlexAlign.Center)
              }
              .width('100%')
              .height('100%')
              .backgroundColor('#F6F8F5')
            } else {
              // "我的"主页
              DoctorMeTab({
                userId: this.authUserId(),
                onOpenProfile: () => { this.doctorMeSubPage = 'profile'; },
                onOpenComplaints: () => { this.doctorMeSubPage = 'complaints'; },
                onOpenRatings: () => { this.doctorMeSubPage = 'ratings'; },
                onOpenRewards: () => { this.doctorMeSubPage = 'rewards'; },
                onLogout: () => { this.logout(); }
              })
            }
          } else if (this.currentTabKey() === 'adminOverview') {
            AdminOverviewTab()
          } else if (this.currentTabKey() === 'adminPeople') {
            AdminPeopleTab()
          } else if (this.currentTabKey() === 'adminAssistantLogs') {
            AdminAssistantLogsTab()
          } else if (this.currentTabKey() === 'adminDoctorReview') {
            AdminDoctorReviewTab()
          } else if (this.currentTabKey() === 'adminConsultations') {
            AdminConsultationsTab()
          } else if (this.currentTabKey() === 'adminComplaints') {
            AdminComplaintsTab()
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
    }).catch((error: Error) => {
      // 网络错误时尝试自动发现后端，避免因换网络导致已登录用户被踢下线
      if (this.isNetworkError(error.message)) {
        this.tryAutoDiscoverForSession(session);
      } else {
        this.clearStoredSession();
      }
    });
  }

  private tryAutoDiscoverForSession(session: AuthSession): void {
    discoverBackendOnLan().then((found: string) => {
      if (found.length === 0) {
        this.clearStoredSession();
        return;
      }
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      saveConnectionSettings(context, found).then(() => {
        // 重新校验 session
        requestCurrentAuthSession(session).then((validatedSession: AuthSession) => {
          this.applyAuthenticatedSession(validatedSession, true);
          this.isAuthChecked = true;
          this.loadCurrentProfileAndRefreshWeather();
        }).catch(() => {
          this.clearStoredSession();
        });
      }).catch(() => {
        this.clearStoredSession();
      });
    }).catch(() => {
      this.clearStoredSession();
    });
  }

  private clearStoredSession(): void {
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
  }

  private isNetworkError(message: string): boolean {
    const lower = message.toLowerCase();
    return lower.indexOf('无法连接') >= 0
      || lower.indexOf('响应超时') >= 0
      || lower.indexOf('timeout') >= 0
      || lower.indexOf('econnrefused') >= 0
      || lower.indexOf('connection refused') >= 0
      || lower.indexOf('failed to fetch') >= 0
      || lower.indexOf('network') >= 0;
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

  private authDisplayName(): string {
    if (this.authSession !== null) {
      const name = this.authSession.user.realName;
      if (name && name.length > 0) {
        return name;
      }
    }
    return this.currentProfile.displayName;
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
    // 切换Tab时重置医生端"我的"子页面
    if (finalKey !== 'doctorMe' && this.doctorMeSubPage !== '') {
      this.doctorMeSubPage = '';
    }
    return finalKey;
  }

  private doctorNavigateToTab(tabKey: string): void {
    const index = resolveAuthorizedTabIndex(this.primaryRole(), tabKey);
    if (index >= 0) {
      this.currentTab = index;
    }
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
