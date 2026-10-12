import { picker } from '@kit.CoreFileKit';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT,
  PAGE_BG
} from '../../theme/WellnessTheme';
import {
  buildConsultationSaveFailureText,
  ConsultationMessageItem,
  ConsultationThread,
  deleteConsultationMessage,
  fetchConsultationMessages,
  fetchDoctorConsultations,
  fetchUserHealthByConsultation,
  recallConsultationMessage,
  sendConsultationMessage,
  UserHealthArchive
} from '../../services/ConsultationService';
import { uploadImage, UploadResult } from '../../services/AssetService';

interface BloodPressureMetric {
  systolic?: number;
  diastolic?: number;
  state?: string;
  stateText?: string;
  measuredAt?: string;
}

interface ValueMetric {
  value?: number;
  unit?: string;
  type?: string;
  typeText?: string;
  context?: string;
  state?: string;
  stateText?: string;
  measuredAt?: string;
}

interface SleepMetric {
  totalMinutes?: number;
  totalText?: string;
  sleepType?: string;
  state?: string;
  stateText?: string;
  measuredAt?: string;
  source?: string;
}

interface BodyMetric {
  weightKg?: number;
  bmi?: number;
  state?: string;
  stateText?: string;
  measuredAt?: string;
}

interface HealthSnapshotData {
  subjectId?: string;
  subjectName?: string;
  generatedAt?: string;
  attentionCount?: number;
  urgentCount?: number;
  missingCategories?: string[];
  bloodPressure?: BloodPressureMetric;
  bloodSugar?: ValueMetric;
  heartRate?: ValueMetric;
  sleep?: SleepMetric;
  body?: BodyMetric;
}

@Component
export struct DoctorConsultationTab {
  @Prop doctorId: string;
  @Prop title: string = '医生问诊';

  @State consultations: ConsultationThread[] = [];
  @State messages: ConsultationMessageItem[] = [];
  @State selectedConsultationId: string = '';
  @State draftMessage: string = '';
  @State feedback: string = '';
  @State parsedSnapshot: HealthSnapshotData | null = null;
  @State userHealthArchive: UserHealthArchive | null = null;
  @State isLoading: boolean = false;
  @State isUploading: boolean = false;
  @State showChat: boolean = false;
  @State showActionMenu: boolean = false;
  @State actionMenuMessageId: string = '';
  @State filterStatus: string = 'all'; // all / pending / active / closed
  private messageScroller: Scroller = new Scroller();

  // 按状态筛选后的问诊列表
  private getFilteredConsultations(): ConsultationThread[] {
    if (this.filterStatus === 'all') {
      return this.consultations;
    }
    return this.consultations.filter((c: ConsultationThread) => {
      const status = c.statusCode;
      if (this.filterStatus === 'pending') {
        return status === 0; // 进行中=待回复
      }
      if (this.filterStatus === 'active') {
        return status === 0 || status === 1; // 进行中或已回复都算活跃
      }
      if (this.filterStatus === 'closed') {
        return status === 2; // 已关闭
      }
      return true;
    });
  }

  private getPendingCount(): number {
    return this.consultations.filter((c: ConsultationThread) => c.statusCode === 0).length;
  }

  private getOngoingCount(): number {
    return this.consultations.filter((c: ConsultationThread) => c.statusCode === 0 || c.statusCode === 1).length;
  }

  private getClosedCount(): number {
    return this.consultations.filter((c: ConsultationThread) => c.statusCode === 2).length;
  }

  aboutToAppear() {
    this.refreshConsultations();
  }

  build() {
    Stack() {
      Column() {
        if (this.showChat) {
          this.ChatView()
        } else {
          this.ConsultationListView()
        }
      }
      .width('100%')
      .height('100%')

      if (this.showActionMenu) {
        this.ActionMenuOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 问诊列表页 ====================
  @Builder
  ConsultationListView() {
    Column({ space: 0 }) {
      // 顶部标题
      Text(this.title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
        .width('100%')
        .padding({ left: 18, top: 18, bottom: 12 })

      // 状态筛选 Tab
      this.StatusFilterBar()

      if (this.getFilteredConsultations().length === 0) {
        Column({ space: 8 }) {
          Text(this.emptyStateText())
            .fontSize(14)
            .fontColor(MUTED_TEXT)
          Text('暂无此状态的问诊记录')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .width('100%')
        .padding({ top: 60, bottom: 60 })
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 10 }) {
            ForEach(this.getFilteredConsultations(), (thread: ConsultationThread) => {
              this.ConsultationCardItem(thread)
            }, (thread: ConsultationThread) => thread.id)
          }
          .width('100%')
          .padding({ left: 14, right: 14, bottom: 10, top: 10 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  StatusFilterBar() {
    Row() {
      this.FilterTab('全部', `${this.consultations.length}`, 'all')
      this.FilterTab('待回复', `${this.getPendingCount()}`, 'pending')
      this.FilterTab('进行中', `${this.getOngoingCount()}`, 'active')
      this.FilterTab('已结束', `${this.getClosedCount()}`, 'closed')
    }
    .width('100%')
    .padding({ left: 14, right: 14 })
  }

  @Builder
  FilterTab(label: string, count: string, key: string) {
    Column({ space: 6 }) {
      Row({ space: 4 }) {
        Text(label)
          .fontSize(14)
          .fontWeight(this.filterStatus === key ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.filterStatus === key ? BRAND_GREEN : DEEP_TEXT)
        Text(count)
          .fontSize(11)
          .fontColor(this.filterStatus === key ? Color.White : MUTED_TEXT)
          .padding({ left: 5, right: 5, top: 1, bottom: 1 })
          .backgroundColor(this.filterStatus === key ? BRAND_GREEN : '#F0F0F0')
          .borderRadius(8)
      }
      .height(28)

      if (this.filterStatus === key) {
        Column()
          .width(20)
          .height(3)
          .backgroundColor(BRAND_GREEN)
          .borderRadius(2)
      } else {
        Column()
          .width(20)
          .height(3)
          .backgroundColor(Color.Transparent)
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 4, bottom: 4 })
    .onClick(() => {
      this.filterStatus = key;
    })
  }

  private emptyStateText(): string {
    switch (this.filterStatus) {
      case 'pending': return '暂无待回复问诊';
      case 'active': return '暂无进行中的问诊';
      case 'closed': return '暂无已结束的问诊';
      default: return '暂无问诊记录';
    }
  }

  @Builder
  ConsultationCardItem(thread: ConsultationThread) {
    Row({ space: 12 }) {
      // 用户头像
      Column() {
        Text(this.patientInitial(thread))
          .fontSize(20)
          .fontColor(Color.White)
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor('#5BA839')
      .justifyContent(FlexAlign.Center)

      Column({ space: 5 }) {
        Row({ space: 6 }) {
          Text(this.patientDisplayName(thread))
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          Text(thread.statusText)
            .fontSize(11)
            .fontColor(BRAND_GREEN)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .backgroundColor('#EEF7F1')
            .borderRadius(8)
        }
        Text(thread.symptom)
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(thread.description)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('查看 ▶')
        .fontSize(12)
        .fontColor(BRAND_GREEN)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
    .onClick(() => {
      this.selectedConsultationId = thread.id;
      this.parsedSnapshot = this.healthSnapshot();
      this.loadMessages(thread.id);
      this.loadUserHealthArchive(thread.id);
      this.showChat = true;
    })
  }

  // ==================== 微信风格聊天页 ====================
  @Builder
  ChatView() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor(Color.White)
          .onClick(() => { this.exitChat(); })
        Text(this.chatTitle())
          .fontSize(17)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
        Blank()
        Text('用户资料')
          .fontSize(12)
          .fontColor(Color.White)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .border({ width: 1, color: Color.White })
          .borderRadius(10)
          .onClick(() => { this.showUserHealthPanel = !this.showUserHealthPanel; })
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor(BRAND_GREEN)

      // 用户资料卡片（可展开/收起）
      if (this.showUserHealthPanel) {
        this.UserHealthCard()
      }

      // 消息区域
      Scroll(this.messageScroller) {
        Column({ space: 12 }) {
          ForEach(this.messages, (msg: ConsultationMessageItem) => {
            this.ChatBubble(msg)
          }, (msg: ConsultationMessageItem) => msg.id)
          if (this.feedback.length > 0) {
            Text(this.feedback)
              .fontSize(12)
              .fontColor(WARM_ACCENT)
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 8 })
          }
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 12, bottom: 12 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .backgroundColor('#EDEDED')

      // 底部输入栏
      Row({ space: 8 }) {
        Button() {
          Text('📷')
            .fontSize(22)
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .onClick(() => { this.pickAndSendImage(); })

        TextInput({ placeholder: '', text: this.draftMessage })
          .height(36)
          .fontSize(15)
          .layoutWeight(1)
          .backgroundColor('#FFFFFF')
          .borderRadius(6)
          .onChange((value: string) => { this.draftMessage = value; })

        Button('发送')
          .height(36)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(this.draftMessage.trim().length > 0 ? BRAND_GREEN : '#CCCCCC')
          .borderRadius(6)
          .enabled(this.draftMessage.trim().length > 0 && !this.isLoading)
          .onClick(() => { this.sendMessage(); })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#F7F7F7')
      .border({ width: { top: 1 }, color: '#D0D0D0' })
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 用户健康资料卡片 ====================
  @State showUserHealthPanel: boolean = true;

  @Builder
  UserHealthCard() {
    Column({ space: 10 }) {
      // 用户基本信息卡片
      Row({ space: 12 }) {
        Column() {
          Text(this.patientInitial(this.selectedConsultation()!))
            .fontSize(18)
            .fontColor(Color.White)
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('#5BA839')
        .justifyContent(FlexAlign.Center)

        Column({ space: 3 }) {
          Text(this.patientDisplayName(this.selectedConsultation()!))
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          Row({ space: 8 }) {
            if (this.hasSharedGender()) {
              Text(this.sharedGender())
                .fontSize(11)
                .fontColor(MUTED_TEXT)
            }
            if (this.hasSharedAge()) {
              Text(`${this.sharedAge()}岁`)
                .fontSize(11)
                .fontColor(MUTED_TEXT)
            }
            if (this.hasSharedPhone()) {
              Text(this.sharedPhone())
                .fontSize(11)
                .fontColor(MUTED_TEXT)
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.selectedConsultationStatus())
          .fontSize(11)
          .fontColor(BRAND_GREEN)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .backgroundColor('#EEF7F1')
      .borderRadius(CARD_RADIUS)

      // 健康指标快照
      if (this.parsedSnapshot) {
        Column({ space: 6 }) {
          Row() {
            Column()
              .width(3)
              .height(12)
              .backgroundColor(BRAND_GREEN)
              .borderRadius(2)
            Text('近期健康指标')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(DEEP_TEXT)
              .margin({ left: 5 })
          }
          .width('100%')

          Flex({ wrap: FlexWrap.Wrap }) {
            this.HealthTag('血压', this.bloodPressureText())
            this.HealthTag('血糖', this.bloodSugarText())
            this.HealthTag('心率', this.heartRateText())
            this.HealthTag('睡眠', this.sleepText())
            this.HealthTag('体重', this.bodyText())
          }
          .width('100%')

          if (this.parsedSnapshot.attentionCount && this.parsedSnapshot.attentionCount > 0) {
            Text(`⚠ 共 ${this.parsedSnapshot.attentionCount} 项指标需关注`)
              .fontSize(11)
              .fontColor(WARM_ACCENT)
              .width('100%')
          }
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      }

      // 健康档案
      if (this.userHealthArchive) {
        Column({ space: 6 }) {
          Row() {
            Column()
              .width(3)
              .height(12)
              .backgroundColor(BRAND_GREEN)
              .borderRadius(2)
            Text('健康档案')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(DEEP_TEXT)
              .margin({ left: 5 })
          }
          .width('100%')

          Flex({ wrap: FlexWrap.Wrap }) {
            if (this.userHealthArchive.height > 0) {
              this.HealthTag('身高', `${this.userHealthArchive.height}cm`)
            }
            if (this.userHealthArchive.weight > 0) {
              this.HealthTag('体重', `${this.userHealthArchive.weight}kg`)
            }
            if (this.userHealthArchive.height > 0 && this.userHealthArchive.weight > 0) {
              this.HealthTag('BMI', this.bmiText(this.userHealthArchive.height, this.userHealthArchive.weight))
            }
            if (this.userHealthArchive.constitutionType.length > 0) {
              this.HealthTag('体质', this.userHealthArchive.constitutionType)
            }
            if (this.userHealthArchive.allergyHistory.length > 0) {
              this.HealthTag('过敏史', this.userHealthArchive.allergyHistory)
            }
            if (this.userHealthArchive.medicalHistory.length > 0) {
              this.HealthTag('病史', this.userHealthArchive.medicalHistory)
            }
            if (this.userHealthArchive.healthGoal.length > 0) {
              this.HealthTag('健康目标', this.userHealthArchive.healthGoal)
            }
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      }

      // 舌象照片
      if (this.tongueImageUrlList().length > 0) {
        Column({ space: 6 }) {
          Row() {
            Column()
              .width(3)
              .height(12)
              .backgroundColor(BRAND_GREEN)
              .borderRadius(2)
            Text('舌象照片')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(DEEP_TEXT)
              .margin({ left: 5 })
          }
          .width('100%')

          Row({ space: 8 }) {
            ForEach(this.tongueImageUrlList(), (url: string) => {
              Image(url)
                .width(70)
                .height(70)
                .borderRadius(CARD_RADIUS)
                .objectFit(ImageFit.Cover)
            }, (url: string) => url)
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
      }
    }
    .width('100%')
    .backgroundColor(CARD_BG)
    .borderRadius({ bottomLeft: 0, bottomRight: 0 })
  }

  @Builder
  HealthTag(label: string, value: string) {
    Row({ space: 4 }) {
      Text(label)
        .fontSize(11)
        .fontColor(MUTED_TEXT)
      Text(value)
        .fontSize(12)
        .fontColor(DEEP_TEXT)
        .fontWeight(FontWeight.Medium)
    }
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor('#F5F5F5')
    .borderRadius(10)
    .margin({ right: 6, bottom: 4 })
  }

  @Builder
  ChatBubble(message: ConsultationMessageItem) {
    if (message.senderRole === 'DOCTOR') {
      Column({ space: 3 }) {
        Row({ space: 8 }) {
          Column() {
            Text('我')
              .fontSize(14)
              .fontColor(Color.White)
          }
          .width(36)
          .height(36)
          .borderRadius(4)
          .backgroundColor(BRAND_GREEN)
          .justifyContent(FlexAlign.Center)

          if (this.isImageMessage(message.content)) {
            Image(this.extractImageUrl(message.content))
              .width(120)
              .height(120)
              .borderRadius(8)
              .objectFit(ImageFit.Cover)
              .constraintSize({ maxWidth: '72%' })
          } else {
            Text(message.content)
              .fontSize(15)
              .fontColor('#000000')
              .lineHeight(22)
              .padding({ left: 10, right: 10, top: 8, bottom: 8 })
              .backgroundColor('#95EC69')
              .borderRadius(8)
              .constraintSize({ maxWidth: '72%' })
          }
          Blank()
        }
        .width('100%')
        .gesture(
          LongPressGesture()
            .onAction(() => { this.openActionMenu(message.id); })
        )

        if (!this.isImageMessage(message.content) && message.content !== '[已撤回]') {
          Text('以上为根据你口述症状给出的建议，不能替代面诊，必要时请前往医院就诊。')
            .fontSize(10)
            .fontColor(MUTED_TEXT)
            .margin({ left: 44 })
            .constraintSize({ maxWidth: '72%' })
        }
      }
      .width('100%')
    } else {
      Row({ space: 8 }) {
        Blank()
        if (this.isImageMessage(message.content)) {
          Image(this.extractImageUrl(message.content))
            .width(120)
            .height(120)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
            .constraintSize({ maxWidth: '72%' })
        } else {
          Text(message.content)
            .fontSize(15)
            .fontColor('#000000')
            .lineHeight(22)
            .padding({ left: 10, right: 10, top: 8, bottom: 8 })
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .constraintSize({ maxWidth: '72%' })
        }
        Column() {
          Text('患')
            .fontSize(14)
            .fontColor(Color.White)
        }
        .width(36)
        .height(36)
        .borderRadius(4)
        .backgroundColor('#888888')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .gesture(
        LongPressGesture()
          .onAction(() => { this.openActionMenu(message.id); })
      )
    }
  }

  @Builder
  ActionMenuOverlay() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0,0,0,0.5)')
      .onClick(() => { this.closeActionMenu(); })

    Column({ space: 0 }) {
      Text('撤回消息')
        .fontSize(16)
        .fontColor(DEEP_TEXT)
        .width('100%')
        .height(48)
        .textAlign(TextAlign.Center)
        .onClick(() => { this.doRecallMessage(); })
      Divider().color('#E0E0E0')
      Text('删除消息')
        .fontSize(16)
        .fontColor('#FF4444')
        .width('100%')
        .height(48)
        .textAlign(TextAlign.Center)
        .onClick(() => { this.doDeleteMessage(); })
    }
    .width('70%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .position({ x: '15%', y: '40%' })
  }

  // ==================== 业务逻辑 ====================
  private openActionMenu(messageId: string): void {
    this.actionMenuMessageId = messageId;
    this.showActionMenu = true;
  }

  private closeActionMenu(): void {
    this.showActionMenu = false;
    this.actionMenuMessageId = '';
  }

  private doRecallMessage(): void {
    const msgId = this.actionMenuMessageId;
    this.closeActionMenu();
    recallConsultationMessage(msgId).then(() => {
      this.loadMessages(this.selectedConsultationId);
    }).catch((err: Error) => {
      this.feedback = `撤回失败: ${err.message}`;
    });
  }

  private doDeleteMessage(): void {
    const msgId = this.actionMenuMessageId;
    this.closeActionMenu();
    deleteConsultationMessage(msgId).then(() => {
      this.loadMessages(this.selectedConsultationId);
    }).catch((err: Error) => {
      this.feedback = `删除失败: ${err.message}`;
    });
  }

  private chatTitle(): string {
    const thread = this.selectedConsultation();
    if (thread) {
      return this.patientDisplayName(thread);
    }
    return '问诊';
  }

  private patientInitial(thread: ConsultationThread): string {
    const name = this.patientDisplayName(thread);
    return name.length > 0 ? name.charAt(0) : '患';
  }

  private patientDisplayName(thread: ConsultationThread): string {
    if (thread.sharedName && thread.sharedName.length > 0) {
      return thread.sharedName;
    }
    if (this.userHealthArchive && this.userHealthArchive.realName.length > 0) {
      return this.userHealthArchive.realName;
    }
    return '用户' + (thread.userId ? thread.userId.slice(-4) : '');
  }

  private isImageMessage(content: string): boolean {
    return content.startsWith('[IMG]');
  }

  private extractImageUrl(content: string): string {
    return content.substring(5);
  }

  private exitChat(): void {
    this.showChat = false;
    this.selectedConsultationId = '';
    this.messages = [];
    this.refreshConsultations();
  }

  private sendMessage(): void {
    const content = this.draftMessage.trim();
    if (content.length === 0 || this.isLoading) {
      return;
    }
    this.isLoading = true;
    this.draftMessage = '';

    sendConsultationMessage(this.selectedConsultationId, content)
      .then(() => {
        this.loadMessages(this.selectedConsultationId);
      })
      .catch((err: Error) => {
        this.feedback = buildConsultationSaveFailureText(err.message);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  private pickAndSendImage(): void {
    if (this.isUploading) {
      return;
    }
    this.isUploading = true;
    this.feedback = '正在上传图片...';

    const selectOption: picker.PhotoSelectOptions = {
      MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
      maxSelectNumber: 1
    };
    const photoPicker = new picker.PhotoViewPicker();
    photoPicker.select(selectOption).then((result: picker.PhotoSelectResult) => {
      if (result.photoUris && result.photoUris.length > 0) {
        return uploadImage(result.photoUris[0]);
      }
      this.feedback = '';
      throw new Error('未选择图片');
    }).then((uploadResult: UploadResult) => {
      const imageContent = `[IMG]${uploadResult.imageUrl}`;
      this.feedback = '';
      return sendConsultationMessage(this.selectedConsultationId, imageContent)
        .then(() => {
          this.loadMessages(this.selectedConsultationId);
        });
    }).catch((err: Error) => {
      if (err.message === '未选择图片' || err.message.indexOf('cancel') >= 0) {
        this.feedback = '';
      } else {
        this.feedback = `图片上传失败: ${err.message}`;
      }
    }).finally(() => {
      this.isUploading = false;
    });
  }

  private refreshConsultations(): void {
    if (this.doctorId.length === 0) {
      return;
    }
    fetchDoctorConsultations(this.doctorId).then((items: ConsultationThread[]) => {
      this.consultations = items;
      if (this.selectedConsultationId.length === 0 && items.length > 0) {
        this.selectedConsultationId = items[0].id;
        this.parsedSnapshot = this.healthSnapshot();
        this.loadMessages(items[0].id);
        this.loadUserHealthArchive(items[0].id);
      }
    }).catch(() => {
      this.consultations = [];
    });
  }

  private loadMessages(consultationId: string): void {
    fetchConsultationMessages(consultationId).then((items: ConsultationMessageItem[]) => {
      this.messages = items;
      this.scrollMessagesToBottom();
    }).catch(() => {
      this.messages = [];
    });
  }

  private loadUserHealthArchive(consultationId: string): void {
    fetchUserHealthByConsultation(consultationId).then((archive: UserHealthArchive | null) => {
      this.userHealthArchive = archive;
    }).catch(() => {
      this.userHealthArchive = null;
    });
  }

  private selectedConsultation(): ConsultationThread | null {
    for (let index = 0; index < this.consultations.length; index++) {
      const thread = this.consultations[index];
      if (thread.id === this.selectedConsultationId) {
        return thread;
      }
    }
    return null;
  }

  private selectedConsultationStatus(): string {
    const thread = this.selectedConsultation();
    return thread !== null ? thread.statusText : '';
  }

  private sharedName(): string {
    const thread = this.selectedConsultation();
    return thread !== null ? thread.sharedName : '';
  }

  private sharedAge(): number {
    const thread = this.selectedConsultation();
    return thread !== null ? thread.sharedAge : 0;
  }

  private sharedGender(): string {
    const thread = this.selectedConsultation();
    return thread !== null ? thread.sharedGender : '';
  }

  private sharedPhone(): string {
    const thread = this.selectedConsultation();
    return thread !== null ? thread.sharedPhone : '';
  }

  private hasSharedName(): boolean {
    return this.sharedName().length > 0;
  }

  private hasSharedAge(): boolean {
    return this.sharedAge() > 0;
  }

  private hasSharedGender(): boolean {
    return this.sharedGender().length > 0;
  }

  private hasSharedPhone(): boolean {
    return this.sharedPhone().length > 0;
  }

  private healthSnapshot(): HealthSnapshotData | null {
    const thread = this.selectedConsultation();
    if (!thread || !thread.healthSnapshot || thread.healthSnapshot.length === 0) {
      return null;
    }
    try {
      return JSON.parse(thread.healthSnapshot) as HealthSnapshotData;
    } catch (error) {
      return null;
    }
  }

  private tongueImageUrlList(): string[] {
    const thread = this.selectedConsultation();
    if (!thread || !thread.tongueImageUrls || thread.tongueImageUrls.length === 0) {
      return [];
    }
    return thread.tongueImageUrls.split(',').filter((url: string) => url.trim().length > 0);
  }

  private bloodPressureText(): string {
    if (!this.parsedSnapshot || !this.parsedSnapshot.bloodPressure) return '未共享';
    const bp = this.parsedSnapshot.bloodPressure;
    if (bp.systolic === undefined || bp.systolic === null || bp.diastolic === undefined || bp.diastolic === null) {
      return bp.stateText ? bp.stateText : '未共享';
    }
    return `${bp.systolic}/${bp.diastolic}`;
  }

  private bloodSugarText(): string {
    if (!this.parsedSnapshot || !this.parsedSnapshot.bloodSugar) return '未共享';
    const bs = this.parsedSnapshot.bloodSugar;
    if (bs.value === undefined || bs.value === null) return '未共享';
    return `${bs.value}`;
  }

  private heartRateText(): string {
    if (!this.parsedSnapshot || !this.parsedSnapshot.heartRate) return '未共享';
    const hr = this.parsedSnapshot.heartRate;
    if (hr.value === undefined || hr.value === null) return '未共享';
    return `${hr.value}`;
  }

  private sleepText(): string {
    if (!this.parsedSnapshot || !this.parsedSnapshot.sleep) return '未共享';
    const sl = this.parsedSnapshot.sleep;
    if (sl.totalText && sl.totalText.length > 0) return sl.totalText;
    if (sl.totalMinutes !== undefined && sl.totalMinutes !== null) {
      const hours = Math.floor(sl.totalMinutes / 60);
      return `${hours}h`;
    }
    return '未共享';
  }

  private bodyText(): string {
    if (!this.parsedSnapshot || !this.parsedSnapshot.body) return '未共享';
    const bd = this.parsedSnapshot.body;
    if (bd.weightKg === undefined || bd.weightKg === null) return '未共享';
    return `${bd.weightKg}kg`;
  }

  private bmiText(height: number, weight: number): string {
    if (height <= 0 || weight <= 0) {
      return '';
    }
    const heightM = height / 100;
    const bmi = weight / (heightM * heightM);
    return bmi.toFixed(1);
  }

  private scrollMessagesToBottom(): void {
    Promise.resolve().then(() => {
      this.messageScroller.scrollEdge(Edge.Bottom);
    });
  }
}
