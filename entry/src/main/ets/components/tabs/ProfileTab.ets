import { common } from '@kit.AbilityKit';
import { RewardsPanel } from '../profile/RewardsPanel';
import { UserProfileCard } from '../profile/UserProfileCard';
import {
  HealthIndicatorEntry,
  HealthProfile,
  ReminderPreference,
  TongueObservationNote,
  UserProfile
} from '../../model/ProfileModels';
import {
  ArchiveSummary,
  ProfileAction,
  WeatherWellness
} from '../../model/WellnessModels';
import {
  buildArchiveSummariesFromProfile,
  buildHealthArchiveSummary
} from '../../services/HealthDataService';
import { applyReminder, reconcileReminders, formatReminderSummary } from '../../services/NotificationService';
import {
  HealthProfileRepository,
  createDefaultHealthProfile,
  createPreferencesHealthProfileRepository
} from '../../services/ProfileRepository';
import {
  countEnabledReminderPreferences,
  toggleReminderPreference
} from '../../viewmodel/ProfileViewModel';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import { HealthIndicatorForm } from '../profile/HealthIndicatorForm';
import { PrivacyStatusCard } from '../profile/PrivacyStatusCard';
import { ProfileSummary } from '../profile/ProfileSummary';
import { RecentRecordsList } from '../profile/RecentRecordsList';
import { TongueNoteForm } from '../profile/TongueNoteForm';
import { TongueImageView, TongueImageViewMode } from '../profile/TongueImageView';
import { TongueImageRecord } from '../../model/ProfileModels';
import { LoadStateNotice } from '../cards/LoadStateNotice';
import {
  ConsultationThread,
  ConsultationMessageItem,
  fetchConsultationMessages,
  fetchUserConsultations
} from '../../services/ConsultationService';
import {
  UserComplaintItem,
  fetchMyComplaints,
  complaintStatusText,
  categoryText,
  appealStatusText
} from '../../services/ComplaintService';
import { fetchTongueImageList } from '../../services/TongueService';

function copyProfileWithReminders(profile: HealthProfile, reminderPreferences: ReminderPreference[]): HealthProfile {
  return {
    id: profile.id,
    displayName: profile.displayName,
    constitution: profile.constitution,
    questionnaireRecords: profile.questionnaireRecords,
    healthIndicators: profile.healthIndicators,
    tongueNotes: profile.tongueNotes,
    reminderPreferences,
    updatedAt: profile.updatedAt
  };
}

@Component
export struct ProfileTab {
  @Prop isAdmin: boolean = false;
  @Prop questionnaireScore: number;
  @Prop metricCount: number;
  @Prop archiveSummaries: ArchiveSummary[];
  @Prop profileActions: ProfileAction[];
  @Prop weather: WeatherWellness;
  @Prop weatherSuggestionSummary: string;
  @Prop profile: HealthProfile;
  @Prop authPhone: string;
  @Prop authUserId: string;
  onProfileChanged?: (profile: HealthProfile) => void;
  onLogout?: () => void;
  onNavigateFamily?: () => void;

  @State localProfile: HealthProfile = createDefaultHealthProfile();
  @State profileLoadError: string = '';
  @State recordActionText: string = '';
  @State recordActionFailed: boolean = false;
  @State reminderSaveText: string = '';
  @State reminderSaveFailed: boolean = false;
  @State reminderBusy: boolean = false;
  @State reminderReady: boolean = false;
  @State activeSubPage: string = '';
  @State consultations: ConsultationThread[] = [];
  @State consultationLoading: boolean = false;
  @State consultationFeedback: string = '';
  @State selectedConsultationId: string = '';
  @State consultationMessages: ConsultationMessageItem[] = [];
  @State consultationDetailLoading: boolean = false;
  @State consultationDetailFeedback: string = '';
  @State myComplaints: UserComplaintItem[] = [];
  @State myComplaintsLoading: boolean = false;
  @State myComplaintsFeedback: string = '';
  // 舌象照片
  @State tongueImages: TongueImageRecord[] = [];
  @State tongueImagesLoading: boolean = false;
  @State tongueImagesError: string = '';
  @State showTongueImages: boolean = false;
  private profileRepository?: HealthProfileRepository;

  aboutToAppear() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.profileRepository = createPreferencesHealthProfileRepository(context, this.authUserId);
    this.localProfile = this.profile;
    this.profileLoadError = '';
    this.checkSystemReminders();
  }

  build() {
    Column({ space: 14 }) {
      LoadStateNotice({ message: this.profileLoadError })

      if (this.activeSubPage.length === 0) {
        this.MainView()
      } else if (this.activeSubPage === 'editProfile') {
        this.EditProfileView()
      } else if (this.activeSubPage === 'consultation') {
        this.ConsultationRecordsView()
      } else if (this.activeSubPage === 'consultation-detail') {
        this.ConsultationDetailView()
      } else if (this.activeSubPage === 'myComplaints') {
        this.MyComplaintsView()
      } else if (this.activeSubPage === 'healthArchive') {
        this.HealthArchiveView()
      } else if (this.activeSubPage === 'reminders') {
        this.ReminderManagementView()
      } else if (this.activeSubPage === 'privacy') {
        this.PrivacyView()
      } else if (this.activeSubPage === 'help') {
        this.HelpView()
      } else if (this.activeSubPage === 'about') {
        this.AboutView()
      } else if (this.activeSubPage === 'family') {
        this.FamilyEntryView()
      } else {
        this.MainView()
      }
    }
    .margin({ top: 14 })
  }

  // ==================== 主视图 ====================

  @Builder
  MainView() {
    Column({ space: 14 }) {
      // 用户资料卡片
      UserProfileCard({
        userProfile: this.buildUserProfile(),
        phone: this.authPhone,
        isAdmin: this.isAdmin,
        onEditProfile: () => {
          this.activeSubPage = 'editProfile';
        },
        onChangeAvatar: () => {
        }
      })

      RewardsPanel({ isAdmin: this.isAdmin, userId: this.authUserId })

      // 功能菜单列表
      Column({ space: 0 }) {
        this.MenuItem('我的问诊', '查看问诊记录和医生回复', '💬', () => {
          this.activeSubPage = 'consultation';
          this.loadConsultations();
        })
        this.MenuDivider()
        this.MenuItem('我的投诉', '查看投诉记录和处理结果', '📮', () => {
          this.activeSubPage = 'myComplaints';
          this.loadMyComplaints();
        })
        this.MenuDivider()
        this.MenuItem('健康档案', '健康指标、舌象记录、档案摘要', '📋', () => {
          this.activeSubPage = 'healthArchive';
        })
        this.MenuDivider()
        this.MenuItem('我的亲人', '管理亲人关系和共享授权', '👨‍👩‍👧', () => {
          if (this.onNavigateFamily) {
            this.onNavigateFamily();
          } else {
            this.activeSubPage = 'family';
          }
        })
        this.MenuDivider()
        this.MenuItem('提醒管理', '管理健康提醒和通知偏好', '🔔', () => {
          this.activeSubPage = 'reminders';
        })
        this.MenuDivider()
        this.MenuItem('隐私与授权', '数据授权和隐私设置', '🔒', () => {
          this.activeSubPage = 'privacy';
        })
        this.MenuDivider()
        this.MenuItem('帮助与反馈', '使用帮助和意见反馈', '❓', () => {
          this.activeSubPage = 'help';
        })
        this.MenuDivider()
        this.MenuItem('关于我们', '版本信息和服务条款', 'ℹ️', () => {
          this.activeSubPage = 'about';
        })
      }
      .width('100%')
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
    }
    .width('100%')
  }

  // ==================== 我的问诊 ====================

  @Builder
  ConsultationRecordsView() {
    Column({ space: 14 }) {
      // 返回按钮
      Row() {
        Text('← 返回')
          .fontSize(15)
          .fontColor(BRAND_GREEN)
          .onClick(() => { this.activeSubPage = ''; })
        Blank()
        Text('我的问诊')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
      }
      .width('100%')

      if (this.consultationFeedback.length > 0) {
        Text(this.consultationFeedback)
          .fontSize(12)
          .fontColor(WARM_ACCENT)
      }

      if (this.consultationLoading) {
        Column({ space: 8 }) {
          Text('加载中...')
            .fontSize(14)
            .fontColor(MUTED_TEXT)
        }
        .width('100%')
        .padding(40)
        .alignItems(HorizontalAlign.Center)
      } else if (this.consultations.length === 0) {
        Column({ space: 12 }) {
          Text('💬')
            .fontSize(48)
          Text('暂无问诊记录')
            .fontSize(16)
            .fontColor(DEEP_TEXT)
          Text('您还没有发起过问诊，可通过问诊页面向医生咨询')
            .fontSize(13)
            .fontColor(MUTED_TEXT)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding(40)
        .alignItems(HorizontalAlign.Center)
      } else {
        ForEach(this.consultations, (thread: ConsultationThread) => {
          Column({ space: 8 }) {
            Row() {
              Text(thread.symptom)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(DEEP_TEXT)
                .layoutWeight(1)
              Text(thread.statusText)
                .fontSize(11)
                .fontColor(thread.statusCode === 2 ? BRAND_GREEN : WARM_ACCENT)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor(thread.statusCode === 2 ? '#EEF7F1' : '#FFF2E8')
                .borderRadius(10)
            }
            .width('100%')

            Text(thread.description)
              .fontSize(13)
              .fontColor(MUTED_TEXT)
              .maxLines(2)

            Text(`创建时间：${thread.createTime}`)
              .fontSize(11)
              .fontColor(MUTED_TEXT)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding(16)
          .backgroundColor(CARD_BG)
          .borderRadius(CARD_RADIUS)
          .onClick(() => {
            this.openConsultationDetail(thread);
          })
        }, (thread: ConsultationThread) => thread.id)
      }
    }
    .width('100%')
  }

  // ==================== 问诊详情 ====================

  @Builder
  ConsultationDetailView() {
    Column({ space: 14 }) {
      Row() {
        Text('← 返回')
          .fontSize(15)
          .fontColor(BRAND_GREEN)
          .onClick(() => { this.activeSubPage = 'consultation'; })
        Blank()
        Text('问诊详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
      }
      .width('100%')

      if (this.selectedConsultation()) {
        // 问诊基本信息
        Column({ space: 8 }) {
          Row() {
            Text('症状：')
              .fontSize(14)
              .fontColor(MUTED_TEXT)
            Text(this.selectedConsultation()!.symptom)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(DEEP_TEXT)
              .layoutWeight(1)
            Text(this.selectedConsultation()!.statusText)
              .fontSize(11)
              .fontColor(this.selectedConsultation()!.statusCode === 2 ? BRAND_GREEN : WARM_ACCENT)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(this.selectedConsultation()!.statusCode === 2 ? '#EEF7F1' : '#FFF2E8')
              .borderRadius(10)
          }
          .width('100%')

          if (this.selectedConsultation()!.description.length > 0) {
            Text(this.selectedConsultation()!.description)
              .fontSize(13)
              .fontColor(MUTED_TEXT)
              .lineHeight(20)
          }

          Text(`创建时间：${this.selectedConsultation()!.createTime}`)
            .fontSize(11)
            .fontColor(MUTED_TEXT)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(16)
        .backgroundColor(CARD_BG)
        .borderRadius(CARD_RADIUS)
      }

      if (this.consultationDetailFeedback.length > 0) {
        Text(this.consultationDetailFeedback)
          .fontSize(12)
          .fontColor(WARM_ACCENT)
      }

      if (this.consultationDetailLoading) {
        Column({ space: 8 }) {
          Text('加载对话中...')
            .fontSize(14)
            .fontColor(MUTED_TEXT)
        }
        .width('100%')
        .padding(40)
        .alignItems(HorizontalAlign.Center)
      } else if (this.consultationMessages.length === 0) {
        Column({ space: 12 }) {
          Text('💬')
            .fontSize(40)
          Text('暂无对话消息')
            .fontSize(15)
            .fontColor(DEEP_TEXT)
          Text('医生还没有回复，请耐心等待')
            .fontSize(13)
            .fontColor(MUTED_TEXT)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding(40)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.consultationMessages, (message: ConsultationMessageItem) => {
            ListItem() {
              this.ConsultationChatBubble(message)
            }
          }, (message: ConsultationMessageItem) => message.id)
        }
        .width('100%')
        .layoutWeight(1)
      }

      Row({ space: 10 }) {
        Button('刷新消息')
          .fontSize(13)
          .enabled(!this.consultationDetailLoading)
          .onClick(() => { this.loadConsultationMessages(); })
        Blank()
        Text('问诊ID：' + this.selectedConsultationId)
          .fontSize(11)
          .fontColor(MUTED_TEXT)
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  ConsultationChatBubble(message: ConsultationMessageItem) {
    Row() {
      if (message.senderRole !== 'DOCTOR') {
        Blank()
      }
      Column({ space: 4 }) {
        Text(message.senderRole === 'DOCTOR' ? '医生' : '我')
          .fontSize(11)
          .fontColor(message.senderRole === 'DOCTOR' ? BRAND_GREEN : MUTED_TEXT)
        Text(message.content)
          .fontSize(14)
          .fontColor(message.senderRole === 'DOCTOR' ? DEEP_TEXT : '#FFFFFF')
          .lineHeight(21)
        if (message.createTime.length > 0) {
          Text(message.createTime)
            .fontSize(10)
            .fontColor(message.senderRole === 'DOCTOR' ? MUTED_TEXT : '#D8EFE0')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor(message.senderRole === 'DOCTOR' ? '#FFFFFF' : BRAND_GREEN)
      .borderRadius(CARD_RADIUS)
      .constraintSize({ maxWidth: '82%' })
      if (message.senderRole === 'DOCTOR') {
        Blank()
      }
    }
    .width('100%')
  }

  private openConsultationDetail(thread: ConsultationThread): void {
    this.selectedConsultationId = thread.id;
    this.consultationMessages = [];
    this.consultationDetailFeedback = '';
    this.activeSubPage = 'consultation-detail';
    this.loadConsultationMessages();
  }

  private selectedConsultation(): ConsultationThread | null {
    if (this.selectedConsultationId.length === 0) {
      return null;
    }
    for (let i = 0; i < this.consultations.length; i++) {
      if (this.consultations[i].id === this.selectedConsultationId) {
        return this.consultations[i];
      }
    }
    return null;
  }

  private loadConsultationMessages(): void {
    if (this.selectedConsultationId.length === 0) {
      return;
    }
    this.consultationDetailLoading = true;
    this.consultationDetailFeedback = '';
    fetchConsultationMessages(this.selectedConsultationId).then((items: ConsultationMessageItem[]) => {
      this.consultationMessages = items;
      this.consultationDetailLoading = false;
    }).catch(() => {
      this.consultationMessages = [];
      this.consultationDetailLoading = false;
      this.consultationDetailFeedback = '加载对话失败，请稍后重试';
    });
  }

  // ==================== 我的投诉 ====================

  @Builder
  MyComplaintsView() {
    Column({ space: 14 }) {
      Row() {
        Text('← 返回')
          .fontSize(15)
          .fontColor(BRAND_GREEN)
          .onClick(() => { this.activeSubPage = ''; })
        Blank()
        Text('我的投诉')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
      }
      .width('100%')

      if (this.myComplaintsFeedback.length > 0) {
        Text(this.myComplaintsFeedback)
          .fontSize(12)
          .fontColor(WARM_ACCENT)
          .width('100%')
      }

      if (this.myComplaintsLoading) {
        Column({ space: 8 }) {
          Text('加载中...')
            .fontSize(14)
            .fontColor(MUTED_TEXT)
        }
        .width('100%')
        .padding({ top: 40 })
        .alignItems(HorizontalAlign.Center)
      } else if (this.myComplaints.length === 0) {
        Column({ space: 12 }) {
          Text('📮')
            .fontSize(48)
          Text('暂无投诉记录')
            .fontSize(14)
            .fontColor(MUTED_TEXT)
          Text('如对问诊服务不满意，可在问诊结束后提交投诉')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .width('100%')
        .padding({ top: 60 })
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.myComplaints, (c: UserComplaintItem) => {
              this.MyComplaintCard(c)
            }, (c: UserComplaintItem) => `${c.id}`)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 14, right: 14, top: 14, bottom: 20 })
  }

  @Builder
  MyComplaintCard(c: UserComplaintItem) {
    Column({ space: 10 }) {
      // 头部
      Row({ space: 8 }) {
        Column()
          .width(4)
          .height(16)
          .backgroundColor(this.getComplaintStatusColor(c.status))
          .borderRadius(2)
        Text(`投诉 #${c.id}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
        Text(c.createdAt ? c.createdAt.substring(0, 16) : '')
          .fontSize(11)
          .fontColor(MUTED_TEXT)
      }
      .width('100%')

      // 类别 + 状态标签
      Row({ space: 6 }) {
        if (c.category && c.category.length > 0) {
          Text(categoryText(c.category))
            .fontSize(11)
            .fontColor(BRAND_GREEN)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor('#EEF7F1')
            .borderRadius(10)
        }
        Text(complaintStatusText(c.status))
          .fontSize(11)
          .fontColor(this.getComplaintStatusColor(c.status))
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(this.getComplaintStatusBgColor(c.status))
          .borderRadius(10)
      }
      .width('100%')

      // 投诉内容
      Text(c.description)
        .fontSize(14)
        .fontColor(DEEP_TEXT)
        .lineHeight(22)
        .width('100%')

      // 管理员处理结果
      if (c.decisionReason && c.decisionReason.length > 0) {
        Column({ space: 6 }) {
          Row({ space: 6 }) {
            Text('📝')
              .fontSize(13)
            Text('管理员处理结果')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(DEEP_TEXT)
            Blank()
            if (c.decisionAt) {
              Text(c.decisionAt.substring(0, 16))
                .fontSize(11)
                .fontColor(MUTED_TEXT)
            }
          }
          .width('100%')
          Text(c.decisionReason)
            .fontSize(13)
            .fontColor(MUTED_TEXT)
            .lineHeight(20)
            .width('100%')
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#F0F7F2')
        .borderRadius(8)
      }

      // 医生申诉结果
      if (c.appeal && c.appeal.status && c.appeal.status !== 'PENDING') {
        Column({ space: 6 }) {
          Row({ space: 6 }) {
            Text('⚖️')
              .fontSize(13)
            Text('申诉复核结果')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(DEEP_TEXT)
            Blank()
            Text(appealStatusText(c.appeal.status))
              .fontSize(11)
              .fontColor(BRAND_GREEN)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor('#EEF7F1')
              .borderRadius(10)
          }
          .width('100%')
          if (c.appeal.resultReason && c.appeal.resultReason.length > 0) {
            Text(c.appeal.resultReason)
              .fontSize(13)
              .fontColor(MUTED_TEXT)
              .lineHeight(20)
              .width('100%')
          }
          if (c.appeal.reviewedAt) {
            Text(`复核时间：${c.appeal.reviewedAt.substring(0, 16)}`)
              .fontSize(11)
              .fontColor(MUTED_TEXT)
              .width('100%')
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF7E6')
        .borderRadius(8)
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .shadow({ radius: 2, color: '#1A000000', offsetX: 0, offsetY: 1 })
  }

  private getComplaintStatusColor(status: string): string {
    switch (status) {
      case 'SUBMITTED': return '#FFA500';
      case 'REVIEWING': return '#1890FF';
      case 'NEED_INFO': return '#FA8C16';
      case 'UPHELD': return '#E54D42';
      case 'REJECTED': return BRAND_GREEN;
      case 'MERGED': return MUTED_TEXT;
      default: return MUTED_TEXT;
    }
  }

  private getComplaintStatusBgColor(status: string): string {
    switch (status) {
      case 'SUBMITTED': return '#FFF7E6';
      case 'REVIEWING': return '#E6F4FF';
      case 'NEED_INFO': return '#FFF1E6';
      case 'UPHELD': return '#FFEBE9';
      case 'REJECTED': return '#EEF7F1';
      case 'MERGED': return '#F0F0F0';
      default: return '#F0F0F0';
    }
  }

  // ==================== 健康档案 ====================

  @Builder
  HealthArchiveView() {
    Column({ space: 14 }) {
      if (this.showTongueImages) {
        // 舌象照片页面
        TongueImageView({
          onBack: () => {
            this.showTongueImages = false;
          }
        })
      } else {
        // 健康档案主页面
        Row() {
          Text('← 返回')
            .fontSize(15)
            .fontColor(BRAND_GREEN)
            .onClick(() => { this.activeSubPage = ''; })
          Blank()
          Text('健康档案')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          Blank()
        }
        .width('100%')

        Scroll() {
          Column({ space: 14 }) {
            ProfileSummary({ profile: this.localProfile })

            Column({ space: 10 }) {
              Text(this.archiveSummaryText())
                .fontSize(14)
                .fontColor(MUTED_TEXT)
                .lineHeight(22)
              Text(this.weatherAwareProfileText())
                .fontSize(12)
                .fontColor(BRAND_GREEN)
                .lineHeight(18)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(18)
            .backgroundColor(CARD_BG)
            .borderRadius(CARD_RADIUS)

            Grid() {
              ForEach(this.dynamicArchiveSummaries(), (item: ArchiveSummary) => {
                GridItem() {
                  Column() {
                    Text(item.title)
                      .fontSize(13)
                      .fontColor(MUTED_TEXT)
                    Text(item.value)
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(DEEP_TEXT)
                      .margin({ top: 8 })
                    Text(item.description)
                      .fontSize(12)
                      .fontColor(MUTED_TEXT)
                      .lineHeight(18)
                      .margin({ top: 8 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .width('100%')
                  .height(128)
                  .padding(14)
                  .backgroundColor(CARD_BG)
                  .borderRadius(CARD_RADIUS)
                }
              }, (item: ArchiveSummary) => item.title)
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(10)
            .rowsGap(10)
            .height(266)

            // 舌象照片记录入口
            Column({ space: 12 }) {
              Row() {
                Column() {
                  Text('👅 舌象照片分析')
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(DEEP_TEXT)
                  Text('拍照上传，AI智能识别舌象特征')
                    .fontSize(12)
                    .fontColor(MUTED_TEXT)
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Row({ space: 4 }) {
                  Text(`${this.tongueImages.length}张`)
                    .fontSize(12)
                    .fontColor(BRAND_GREEN)
                  Text('›')
                    .fontSize(16)
                    .fontColor(MUTED_TEXT)
                }
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(CARD_BG)
            .borderRadius(CARD_RADIUS)
            .onClick(() => {
              this.showTongueImages = true;
              this.loadTongueImages();
            })

            TongueNoteForm({
              onSave: (note: TongueObservationNote) => {
                if (this.profileRepository) {
                  return this.profileRepository.saveTongueNote(note).then((profile: HealthProfile) => {
                    this.applyProfile(profile);
                    return true;
                  }).catch(() => { return false; });
                }
                return Promise.resolve(false);
              }
            })

            HealthIndicatorForm({
              onSave: (entry: HealthIndicatorEntry) => {
                if (this.profileRepository) {
                  return this.profileRepository.saveHealthIndicator(entry).then((profile: HealthProfile) => {
                    this.applyProfile(profile);
                    return true;
                  }).catch(() => { return false; });
                }
                return Promise.resolve(false);
              }
            })

            RecentRecordsList({
              profile: this.localProfile,
              onDeleteIndicator: (recordedAt: string) => {
                if (this.profileRepository) {
                  this.profileRepository.deleteHealthIndicator(recordedAt).then((profile: HealthProfile) => {
                    this.applyProfile(profile);
                    this.recordActionText = '记录已删除';
                    this.recordActionFailed = false;
                  }).catch(() => {
                    this.recordActionText = '记录删除失败';
                    this.recordActionFailed = true;
                  });
                }
              },
              onDeleteTongueNote: (recordedAt: string) => {
                if (this.profileRepository) {
                  this.profileRepository.deleteTongueNote(recordedAt).then((profile: HealthProfile) => {
                    this.applyProfile(profile);
                    this.recordActionText = '记录已删除';
                    this.recordActionFailed = false;
                  }).catch(() => {
                    this.recordActionText = '记录删除失败';
                    this.recordActionFailed = true;
                  });
                }
              }
            })

            if (this.recordActionText.length > 0) {
              Text(this.recordActionText)
                .fontSize(12)
                .fontColor(this.recordActionFailed ? WARM_ACCENT : BRAND_GREEN)
            }

            this.ModelProfileSuggestionCard()
          }
          .width('100%')
        }
        .scrollBar(BarState.Auto)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 提醒管理 ====================

  @Builder
  ReminderManagementView() {
    Column({ space: 14 }) {
      Row() {
        Text('← 返回')
          .fontSize(15)
          .fontColor(BRAND_GREEN)
          .onClick(() => { this.activeSubPage = ''; })
        Blank()
        Text('提醒管理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
      }
      .width('100%')

      Row() {
        Text('提醒状态')
          .fontSize(16)
          .fontColor(DEEP_TEXT)
          .layoutWeight(1)
        Text(this.reminderSummaryText())
          .fontSize(12)
          .fontColor(MUTED_TEXT)
      }
      .width('100%')

      if (this.reminderSaveText.length > 0) {
        Text(this.reminderSaveText)
          .fontSize(12)
          .fontColor(this.reminderSaveFailed ? WARM_ACCENT : BRAND_GREEN)
      }

      ForEach(this.reminders(), (item: ReminderPreference) => {
        Row() {
          Column() {
            Text(item.title)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(DEEP_TEXT)
            Text(item.time)
              .fontSize(13)
              .fontColor(MUTED_TEXT)
              .margin({ top: 4 })
              .onClick(() => { this.chooseReminderTime(item); })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: item.enabled })
            .selectedColor(BRAND_GREEN)
            .enabled(this.reminderReady && !this.reminderBusy)
            .onChange((isOn: boolean) => {
              this.updateSystemReminder({ title: item.title, time: item.time, enabled: isOn });
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(CARD_BG)
        .borderRadius(CARD_RADIUS)
      }, (item: ReminderPreference) => item.title)

      Row({ space: 10 }) {
        Button('检查提醒状态').fontSize(13).enabled(!this.reminderBusy).onClick(() => { this.checkSystemReminders(); })
      }
    }
    .width('100%')
  }

  // ==================== 隐私与授权 ====================

  @Builder
  PrivacyView() {
    Column({ space: 14 }) {
      Row() {
        Text('← 返回')
          .fontSize(15)
          .fontColor(BRAND_GREEN)
          .onClick(() => { this.activeSubPage = ''; })
        Blank()
        Text('隐私与授权')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
      }
      .width('100%')

      PrivacyStatusCard()
    }
    .width('100%')
  }

  // ==================== 帮助与反馈 ====================

  @Builder
  HelpView() {
    Column({ space: 14 }) {
      Row() {
        Text('← 返回')
          .fontSize(15)
          .fontColor(BRAND_GREEN)
          .onClick(() => { this.activeSubPage = ''; })
        Blank()
        Text('帮助与反馈')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
      }
      .width('100%')

      Column({ space: 10 }) {
        Text('使用帮助')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Text('1. 首页展示当前天气、养生建议和快捷操作\n2. 健康页可录入血压、血糖等健康指标\n3. 问诊页可选择医生发起在线问诊\n4. 亲人页可邀请家人共享健康数据\n5. 我的页可查看个人中心和健康档案')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .lineHeight(22)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(18)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)

      Column({ space: 10 }) {
        Text('意见反馈')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Text('如有问题或建议，请联系客服：health@example.com')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(18)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
    }
    .width('100%')
  }

  // ==================== 关于我们 ====================

  @Builder
  AboutView() {
    Column({ space: 14 }) {
      Row() {
        Text('← 返回')
          .fontSize(15)
          .fontColor(BRAND_GREEN)
          .onClick(() => { this.activeSubPage = ''; })
        Blank()
        Text('关于我们')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
      }
      .width('100%')

      Column({ space: 10 }) {
        Text('养生助手')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Text('版本 1.0.0')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
        Text('基于中医养生理念的健康管理应用，提供健康数据记录、舌象观察、在线问诊、养生建议等功能。')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .lineHeight(22)
          .margin({ top: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(18)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
    }
    .width('100%')
  }

  // ==================== 我的亲人入口 ====================

  @Builder
  FamilyEntryView() {
    Column({ space: 14 }) {
      Row() {
        Text('← 返回')
          .fontSize(15)
          .fontColor(BRAND_GREEN)
          .onClick(() => { this.activeSubPage = ''; })
        Blank()
        Text('我的亲人')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
      }
      .width('100%')

      Column({ space: 12 }) {
        Text('👨‍👩‍👧')
          .fontSize(48)
        Text('亲人管理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Text('点击底部「亲人」标签页，管理亲人关系和共享健康数据')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding(40)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
    }
    .width('100%')
  }

  // ==================== 编辑个人资料 ====================

  @Builder
  EditProfileView() {
    Column({ space: 14 }) {
      Row() {
        Text('← 返回')
          .fontSize(15)
          .fontColor(BRAND_GREEN)
          .onClick(() => { this.activeSubPage = ''; })
        Blank()
        Text('编辑资料')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
      }
      .width('100%')

      // 头像
      Row() {
        Blank()
        Column({ space: 8 }) {
          Circle({ width: 72, height: 72 })
            .fill(BRAND_GREEN)
          Text('点击更换头像')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .alignItems(HorizontalAlign.Center)
        Blank()
      }
      .width('100%')
      .padding({ top: 10 })

      // 昵称
      Column({ space: 8 }) {
        Text('昵称')
          .fontSize(14)
          .fontColor(DEEP_TEXT)
          .fontWeight(FontWeight.Medium)
        TextInput({ placeholder: '请输入昵称', text: this.localProfile.displayName })
          .height(44)
          .fontSize(14)
          .backgroundColor(CARD_BG)
          .borderRadius(CARD_RADIUS)
          .onChange((value: string) => {
            this.localProfile = {
              id: this.localProfile.id,
              displayName: value,
              constitution: this.localProfile.constitution,
              questionnaireRecords: this.localProfile.questionnaireRecords,
              healthIndicators: this.localProfile.healthIndicators,
              tongueNotes: this.localProfile.tongueNotes,
              reminderPreferences: this.localProfile.reminderPreferences,
              updatedAt: new Date().toISOString()
            };
          })
      }
      .width('100%')

      // 手机号
      Column({ space: 8 }) {
        Text('手机号')
          .fontSize(14)
          .fontColor(DEEP_TEXT)
          .fontWeight(FontWeight.Medium)
        Text(this.authPhone.length > 0 ? this.authPhone : '未绑定手机号')
          .fontSize(14)
          .fontColor(MUTED_TEXT)
          .width('100%')
          .height(44)
          .padding({ left: 14, right: 14 })
          .backgroundColor('#F5F5F5')
          .borderRadius(CARD_RADIUS)
      }
      .width('100%')

      // 用户编号
      Column({ space: 8 }) {
        Text('用户编号')
          .fontSize(14)
          .fontColor(DEEP_TEXT)
          .fontWeight(FontWeight.Medium)
        Text(this.formatUserNo(this.authUserId))
          .fontSize(14)
          .fontColor(MUTED_TEXT)
          .width('100%')
          .height(44)
          .padding({ left: 14, right: 14 })
          .backgroundColor('#F5F5F5')
          .borderRadius(CARD_RADIUS)
      }
      .width('100%')

      // 保存按钮
      Button('保存')
        .width('100%')
        .height(46)
        .backgroundColor(BRAND_GREEN)
        .borderRadius(CARD_RADIUS)
        .fontColor(Color.White)
        .onClick(() => {
          if (this.profileRepository) {
            this.profileRepository.saveProfile(this.localProfile).then((saved: HealthProfile) => {
              this.applyProfile(saved);
              this.activeSubPage = '';
            }).catch(() => {
            });
          }
        })

      // 退出登录
      Button('退出登录')
        .width('100%')
        .height(44)
        .backgroundColor('#FFF2E8')
        .fontColor(WARM_ACCENT)
        .borderRadius(CARD_RADIUS)
        .onClick(() => {
          if (this.onLogout) {
            this.onLogout();
          }
        })
    }
    .width('100%')
  }

  @Builder
  MenuItem(title: string, subtitle: string, icon: string, onClick: () => void) {
    Row({ space: 12 }) {
      Text(icon)
        .fontSize(20)

      Column({ space: 2 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(DEEP_TEXT)
        Text(subtitle)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('›')
        .fontSize(18)
        .fontColor(MUTED_TEXT)
    }
    .width('100%')
    .height(60)
    .padding({ left: 16, right: 16 })
    .onClick(() => {
      onClick();
    })
  }

  @Builder
  MenuDivider() {
    Column()
      .width('100%')
      .height(0.5)
      .backgroundColor('#EEEEEE')
      .margin({ left: 48 })
  }

  /**
   * 构建用户个人资料
   */
  private buildUserProfile(): UserProfile | null {
    if (!this.authUserId || this.authUserId.length === 0) {
      return null;
    }
    if (this.localProfile.userProfile) {
      return this.localProfile.userProfile;
    }
    const userProfile: UserProfile = {
      userId: this.authUserId,
      nickname: this.localProfile.displayName && this.localProfile.displayName.length > 0
        ? this.localProfile.displayName
        : undefined,
      userNo: this.formatUserNo(this.authUserId),
      phone: this.authPhone || undefined
    };
    return userProfile;
  }

  private formatUserNo(userId: string): string {
    if (!userId) return '';
    if (userId.length <= 8) return `YS${userId}`;
    return `YS${userId.substring(0, 8)}`;
  }

  private archiveSummaryText(): string {
    return buildHealthArchiveSummary(this.localProfile.healthIndicators.length, this.localProfile.constitution.name);
  }

  private dynamicArchiveSummaries(): ArchiveSummary[] {
    return buildArchiveSummariesFromProfile(this.localProfile);
  }

  private reminders(): ReminderPreference[] {
    return this.localProfile.reminderPreferences;
  }

  private reminderSummaryText(): string {
    if (!this.reminderReady) return '系统提醒待确认';
    return formatReminderSummary(countEnabledReminderPreferences(this.localProfile), this.reminders().length);
  }

  private async checkSystemReminders(): Promise<void> {
    if (this.reminderBusy) return;
    this.reminderBusy = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const next = await reconcileReminders(context, this.authUserId, this.localProfile.reminderPreferences);
      if (this.profileRepository) this.applyProfile(await this.profileRepository.updateReminderPreferences(next));
      this.reminderReady = true;
    } catch (error) {
      this.reminderReady = false; this.reminderSaveFailed = true;
      this.reminderSaveText = '无法确认系统提醒状态';
    } finally { this.reminderBusy = false; }
  }

  private chooseReminderTime(item: ReminderPreference): void {
    if (this.reminderBusy || !this.reminderReady) return;
    const parts = item.time.split(':');
    const selected = new Date(); selected.setHours(Number(parts[0]), Number(parts[1]));
    TimePickerDialog.show({ selected, useMilitaryTime: true,
      onAccept: (value: TimePickerResult) => {
        const time = `${`${value.hour}`.padStart(2, '0')}:${`${value.minute}`.padStart(2, '0')}`;
        this.updateSystemReminder({ title: item.title, time, enabled: item.enabled });
      }
    });
  }

  private async updateSystemReminder(item: ReminderPreference): Promise<void> {
    if (this.reminderBusy || !this.reminderReady || !this.profileRepository) return;
    this.reminderBusy = true; this.reminderSaveText = ''; this.reminderSaveFailed = false;
    const previous = this.localProfile.reminderPreferences.find((entry: ReminderPreference) => entry.title === item.title);
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      await applyReminder(context, this.authUserId, item);
      const next = this.localProfile.reminderPreferences.map((entry: ReminderPreference) => entry.title === item.title ? item : entry);
      try {
        this.applyProfile(await this.profileRepository.updateReminderPreferences(next));
      } catch (error) {
        if (previous) await applyReminder(context, this.authUserId, previous);
        throw new Error((error as Error).message);
      }
      this.reminderSaveText = item.enabled ? `已设置每天 ${item.time} 的提醒` : '提醒已关闭';
    } catch (error) {
      this.reminderSaveText = (error as Error).message || '系统提醒设置失败'; this.reminderSaveFailed = true;
      this.reminderReady = false;
    } finally { this.reminderBusy = false; }
  }

  private weatherAwareProfileText(): string {
    if (this.weatherSuggestionSummary.length > 0) {
      return this.weatherSuggestionSummary;
    }
    return '等待大模型根据当前位置、温度、湿度和健康档案生成建议。';
  }

  private accountText(): string {
    if (this.authPhone.length > 0) {
      return `当前账号：${this.authPhone}`;
    }
    return '当前未登录';
  }

  private applyProfile(profile: HealthProfile): void {
    this.localProfile = profile;
    if (this.onProfileChanged) {
      this.onProfileChanged(profile);
    }
  }

  private loadConsultations(): void {
    if (this.authUserId.length === 0) {
      this.consultationFeedback = '请先登录';
      return;
    }
    this.consultationLoading = true;
    this.consultationFeedback = '';
    fetchUserConsultations(this.authUserId).then((items: ConsultationThread[]) => {
      this.consultations = items;
      this.consultationLoading = false;
    }).catch(() => {
      this.consultations = [];
      this.consultationLoading = false;
      this.consultationFeedback = '加载问诊记录失败，请稍后重试';
    });
  }

  private loadTongueImages(): void {
    this.tongueImagesLoading = true;
    this.tongueImagesError = '';
    fetchTongueImageList().then((items: TongueImageRecord[]) => {
      this.tongueImages = items;
      this.tongueImagesLoading = false;
    }).catch((err: Error) => {
      this.tongueImages = [];
      this.tongueImagesLoading = false;
      this.tongueImagesError = err.message || '加载舌象记录失败，请稍后重试';
    });
  }

  private loadMyComplaints(): void {
    this.myComplaintsLoading = true;
    this.myComplaintsFeedback = '';
    fetchMyComplaints().then((items: UserComplaintItem[]) => {
      this.myComplaints = items;
      this.myComplaintsLoading = false;
    }).catch(() => {
      this.myComplaints = [];
      this.myComplaintsLoading = false;
      this.myComplaintsFeedback = '加载投诉记录失败，请稍后重试';
    });
  }

  @Builder
  ModelProfileSuggestionCard() {
    Column({ space: 8 }) {
      Text('大模型档案建议')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text(this.weatherAwareProfileText())
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .lineHeight(20)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor('#EEF7F1')
    .borderRadius(CARD_RADIUS)
  }

}
