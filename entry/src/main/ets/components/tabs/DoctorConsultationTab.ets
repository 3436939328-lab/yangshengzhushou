import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import {
  buildConsultationSaveFailureText,
  buildDoctorPendingNoticeTitle,
  ConsultationMessageItem,
  ConsultationThread,
  fetchConsultationMessages,
  fetchDoctorConsultations,
  sendConsultationMessage
} from '../../services/ConsultationService';

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
  @State listExpanded: boolean = false;
  private messageScroller: Scroller = new Scroller();

  aboutToAppear() {
    this.refreshConsultations();
  }

  build() {
    Column({ space: 14 }) {
      Text(this.title)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      this.PendingNotice()
      this.ThreadList()
      this.MessagePanel()
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  PendingNotice() {
    Column() {
      Text(buildDoctorPendingNoticeTitle(this.consultations))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.consultations.length > 0 ? BRAND_GREEN : MUTED_TEXT)
      Text(this.consultations.length > 0 ? `共 ${this.consultations.length} 条问诊记录，请优先处理待回复内容。` : '用户向你发起问诊后，这里会首先提醒。')
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .margin({ top: 6 })
      if (this.feedback.length > 0) {
        Text(this.feedback)
          .fontSize(12)
          .fontColor(this.feedback.indexOf('成功') >= 0 ? BRAND_GREEN : MUTED_TEXT)
          .margin({ top: 8 })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  ThreadList() {
    Column({ space: 10 }) {
      Row() {
        Text('问诊列表')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .layoutWeight(1)
        if (this.consultations.length > 0) {
          Text(this.listExpanded ? '收起 ▲' : `展开 ▼ ${this.consultations.length} 条`)
            .fontSize(12)
            .fontColor(BRAND_GREEN)
            .onClick(() => {
              this.listExpanded = !this.listExpanded;
            })
        }
      }
      .width('100%')

      if (this.consultations.length === 0) {
        Text('没有用户向你提问。')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
      } else if (this.listExpanded) {
        ForEach(this.consultations, (thread: ConsultationThread) => {
          Column() {
            Row() {
              Text(thread.symptom)
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(DEEP_TEXT)
                .layoutWeight(1)
              Text(thread.statusText)
                .fontSize(12)
                .fontColor(BRAND_GREEN)
            }
            Text(thread.description)
              .fontSize(12)
              .fontColor(MUTED_TEXT)
              .margin({ top: 4 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .backgroundColor(this.selectedConsultationId === thread.id ? '#EEF7F1' : '#FAFCFA')
          .borderRadius(CARD_RADIUS)
          .onClick(() => {
            this.selectedConsultationId = thread.id;
            this.parsedSnapshot = this.healthSnapshot();
            this.loadMessages(thread.id);
            this.listExpanded = false;
          })
        }, (thread: ConsultationThread) => thread.id)
      } else {
        Text(`当前共 ${this.consultations.length} 条问诊记录，点击右上角展开查看`)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  MessagePanel() {
    Column({ space: 12 }) {
      Text('对话回复')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      if (this.selectedConsultationId.length === 0) {
        Text('选择一条问诊后开始回复用户。')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
      } else {
        Column({ space: 12 }) {
          this.ConversationSummary()
          Scroll(this.messageScroller) {
            Column({ space: 10 }) {
              ForEach(this.messages, (message: ConsultationMessageItem) => {
                this.ChatBubble(message)
              }, (message: ConsultationMessageItem) => message.id)
            }
            .width('100%')
          }
          .width('100%')
          .height(320)
          .scrollBar(BarState.Auto)

          Row({ space: 8 }) {
            TextInput({ placeholder: '输入给用户的回复', text: this.draftMessage })
              .height(44)
              .fontSize(14)
              .layoutWeight(1)
              .backgroundColor('#F7F7F7')
              .borderRadius(12)
              .onChange((value: string) => {
                this.draftMessage = value;
              })
            Button('回复')
              .height(44)
              .fontColor('#FFFFFF')
              .backgroundColor(BRAND_GREEN)
              .borderRadius(12)
              .onClick(() => {
                this.sendMessage();
              })
          }
          .width('100%')
          .padding({ top: 10 })
          .border({
            width: { top: 1 },
            color: '#E4EBE6'
          })
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#F8FBF9')
        .borderRadius(CARD_RADIUS)
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  ConversationSummary() {
    if (this.hasSelectedConsultation()) {
      Column({ space: 12 }) {
        Row() {
          Column({ space: 4 }) {
            Text(this.selectedConsultationSymptom())
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(DEEP_TEXT)
            Text(this.selectedConsultationDescription())
              .fontSize(12)
              .fontColor(MUTED_TEXT)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          Text(this.selectedConsultationStatus())
            .fontSize(12)
            .fontColor(BRAND_GREEN)
        }
        .width('100%')

        // 用户健康资料卡片
        this.UserHealthSnapshot()
      }
      .width('100%')
    }
  }

  @Builder
  UserHealthSnapshot() {
    Column({ space: 10 }) {
      Row({ space: 6 }) {
        Text('📋')
          .fontSize(14)
        Text('用户健康资料')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
      }
      .width('100%')

      // 用户共享的个人信息（由用户自定义选择）
      Column({ space: 6 }) {
        Row({ space: 6 }) {
          Text('👤')
            .fontSize(14)
          Text('用户共享信息')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
        }
        .width('100%')

        Row({ space: 16 }) {
          if (this.hasSharedName()) {
            this.HealthInfoItem('姓名', this.sharedName())
          }
          if (this.hasSharedGender()) {
            this.HealthInfoItem('性别', this.sharedGender())
          }
          if (this.hasSharedAge()) {
            this.HealthInfoItem('年龄', `${this.sharedAge()}`)
          }
          if (this.hasSharedPhone()) {
            this.HealthInfoItem('手机号', this.sharedPhone())
          }
          if (!this.hasSharedName() && !this.hasSharedGender() && !this.hasSharedAge() && !this.hasSharedPhone()) {
            Text('用户未共享个人信息')
              .fontSize(12)
              .fontColor(MUTED_TEXT)
          }
        }
        .width('100%')
      }
      .width('100%')
      .padding({ top: 8 })

      // 健康指标
      Column({ space: 6 }) {
        Text('近期健康指标')
          .fontSize(12)
          .fontColor(MUTED_TEXT)
        if (this.parsedSnapshot) {
          Column({ space: 8 }) {
            Row({ space: 12 }) {
              this.HealthInfoItem('血压', this.bloodPressureText())
              this.HealthInfoItem('血糖', this.bloodSugarText())
              this.HealthInfoItem('心率', this.heartRateText())
            }
            .width('100%')
            Row({ space: 12 }) {
              this.HealthInfoItem('睡眠', this.sleepText())
              this.HealthInfoItem('体重', this.bodyText())
            }
            .width('100%')
            if (this.parsedSnapshot.attentionCount && this.parsedSnapshot.attentionCount > 0) {
              Text(`共 ${this.parsedSnapshot.attentionCount} 项指标需关注`)
                .fontSize(12)
                .fontColor(WARM_ACCENT)
                .width('100%')
            }
          }
          .width('100%')
        } else {
          Text('用户未共享健康指标数据')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
      }
      .width('100%')
      .padding({ top: 8 })

      // 舌象照片
      Column({ space: 6 }) {
        Text('舌象照片')
          .fontSize(12)
          .fontColor(MUTED_TEXT)
        if (this.tongueImageUrlList().length > 0) {
          Row({ space: 10 }) {
            ForEach(this.tongueImageUrlList(), (url: string) => {
              Image(url)
                .width(70)
                .height(70)
                .borderRadius(CARD_RADIUS)
                .objectFit(ImageFit.Cover)
            }, (url: string) => url)
          }
          .width('100%')
        } else {
          Row({ space: 12 }) {
            Column() {
              Text('👅')
                .fontSize(32)
            }
            .width(60)
            .height(60)
            .backgroundColor('#F5F5F5')
            .borderRadius(CARD_RADIUS)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Text('本次未分享舌象照片')
              .fontSize(13)
              .fontColor(MUTED_TEXT)
              .layoutWeight(1)
          }
          .width('100%')
        }
      }
      .width('100%')
      .padding({ top: 8 })

      Text('以上为用户授权共享的健康数据')
        .fontSize(11)
        .fontColor(MUTED_TEXT)
        .width('100%')
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FAFCFA')
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  HealthInfoItem(label: string, value: string) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(11)
        .fontColor(MUTED_TEXT)
      Text(value)
        .fontSize(14)
        .fontColor(DEEP_TEXT)
        .fontWeight(FontWeight.Medium)
    }
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  ChatBubble(message: ConsultationMessageItem) {
    Row() {
      if (message.senderRole === 'DOCTOR') {
        Blank()
      }
      Column({ space: 4 }) {
        Text(message.senderRole === 'DOCTOR' ? '我' : '用户')
          .fontSize(11)
          .fontColor(message.senderRole === 'DOCTOR' ? MUTED_TEXT : BRAND_GREEN)
        Text(message.content)
          .fontSize(14)
          .fontColor(message.senderRole === 'DOCTOR' ? '#FFFFFF' : DEEP_TEXT)
          .lineHeight(21)
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor(message.senderRole === 'DOCTOR' ? BRAND_GREEN : '#FFFFFF')
      .borderRadius(CARD_RADIUS)
      .constraintSize({ maxWidth: '82%' })
      if (message.senderRole !== 'DOCTOR') {
        Blank()
      }
    }
    .width('100%')
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

  private sendMessage(): void {
    if (this.selectedConsultationId.length === 0 || this.draftMessage.trim().length === 0) {
      return;
    }
    sendConsultationMessage(this.selectedConsultationId, this.draftMessage.trim()).then((saved: boolean) => {
      if (saved) {
        this.draftMessage = '';
        this.feedback = '回复已发送。';
        this.loadMessages(this.selectedConsultationId);
        this.refreshConsultations();
        this.scrollMessagesToBottom();
      } else {
        this.feedback = buildConsultationSaveFailureText('');
      }
    }).catch((error: Error) => {
      this.feedback = buildConsultationSaveFailureText(error.message);
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

  private hasSelectedConsultation(): boolean {
    return this.selectedConsultation() !== null;
  }

  private selectedConsultationSymptom(): string {
    const thread = this.selectedConsultation();
    return thread !== null ? thread.symptom : '';
  }

  private selectedConsultationDescription(): string {
    const thread = this.selectedConsultation();
    return thread !== null ? thread.description : '';
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
    const text = `${bp.systolic}/${bp.diastolic}`;
    return bp.stateText && bp.stateText.length > 0 ? `${text} (${bp.stateText})` : text;
  }

  private bloodSugarText(): string {
    if (!this.parsedSnapshot || !this.parsedSnapshot.bloodSugar) return '未共享';
    const bs = this.parsedSnapshot.bloodSugar;
    if (bs.value === undefined || bs.value === null) return '未共享';
    const valueText = `${bs.value}`;
    const unitText = bs.unit ? ` ${bs.unit}` : '';
    const typeText = bs.typeText && bs.typeText.length > 0 ? ` (${bs.typeText})` : '';
    return `${valueText}${unitText}${typeText}`;
  }

  private heartRateText(): string {
    if (!this.parsedSnapshot || !this.parsedSnapshot.heartRate) return '未共享';
    const hr = this.parsedSnapshot.heartRate;
    if (hr.value === undefined || hr.value === null) return '未共享';
    const valueText = `${hr.value}`;
    const unitText = hr.unit ? ` ${hr.unit}` : '';
    return `${valueText}${unitText}`;
  }

  private sleepText(): string {
    if (!this.parsedSnapshot || !this.parsedSnapshot.sleep) return '未共享';
    const sl = this.parsedSnapshot.sleep;
    if (sl.totalText && sl.totalText.length > 0) {
      return sl.stateText && sl.stateText.length > 0 ? `${sl.totalText} (${sl.stateText})` : sl.totalText;
    }
    if (sl.totalMinutes !== undefined && sl.totalMinutes !== null) {
      const hours = Math.floor(sl.totalMinutes / 60);
      const minutes = sl.totalMinutes % 60;
      const text = hours > 0 ? `${hours}小时${minutes > 0 ? minutes + '分钟' : ''}` : `${minutes}分钟`;
      return sl.stateText && sl.stateText.length > 0 ? `${text} (${sl.stateText})` : text;
    }
    return '未共享';
  }

  private bodyText(): string {
    if (!this.parsedSnapshot || !this.parsedSnapshot.body) return '未共享';
    const bd = this.parsedSnapshot.body;
    if (bd.weightKg === undefined || bd.weightKg === null) return '未共享';
    const weightText = `${bd.weightKg}kg`;
    const bmiText = bd.bmi !== undefined && bd.bmi !== null ? ` (BMI ${bd.bmi})` : '';
    return `${weightText}${bmiText}`;
  }

  private scrollMessagesToBottom(): void {
    Promise.resolve().then(() => {
      this.messageScroller.scrollEdge(Edge.Bottom);
    });
  }
}
