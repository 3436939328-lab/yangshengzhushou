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
  ConsultationMessageItem,
  ConsultationThread,
  createConsultation,
  DoctorOption,
  fetchConsultationMessages,
  fetchDoctorOptions,
  fetchUserConsultations,
  sendConsultationMessage
} from '../../services/ConsultationService';
import { ConsultationHealthSnapshot } from '../consultation/ConsultationHealthSnapshot';
import { HealthCardSummary } from '../../model/ProfileModels';

@Component
export struct UserConsultationTab {
  @Prop userId: string;
  @Prop userName: string = '';
  @Prop userPhone: string = '';

  @State doctors: DoctorOption[] = [];
  @State consultations: ConsultationThread[] = [];
  @State messages: ConsultationMessageItem[] = [];
  @State selectedDoctorId: string = '';
  @State selectedConsultationId: string = '';
  @State symptom: string = '';
  @State description: string = '';
  @State draftMessage: string = '';
  @State feedback: string = '';
  @State isLoading: boolean = false;
  @State isDoctorPickerExpanded: boolean = false;
  @State shareHealthCard: boolean = true;
  @State showChat: boolean = false;
  // 用户自定义分享给医生的个人信息开关
  @State shareName: boolean = false;
  @State shareAge: boolean = false;
  @State shareGender: boolean = false;
  @State sharePhone: boolean = false;
  @State customName: string = '';
  @State customAge: string = '';
  @State customGender: string = '';
  private messageScroller: Scroller = new Scroller();

  aboutToAppear() {
    this.refreshDoctors();
    this.refreshConsultations();
  }

  build() {
    Column({ space: 14 }) {
      if (this.showChat) {
        // 问诊对话模式
        Row() {
          Text('← 返回')
            .fontSize(15)
            .fontColor(BRAND_GREEN)
            .onClick(() => { this.showChat = false; })
          Blank()
          Text('问诊对话')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          Blank()
        }
        .width('100%')

        this.MessagePanel()

        // 刷新消息按钮（获取医生回复）
        Row() {
          Blank()
          Button() {
            Text('🔄 刷新消息')
              .fontSize(13)
              .fontColor(BRAND_GREEN)
          }
          .height(36)
          .backgroundColor('rgba(76, 175, 80, 0.1)')
          .borderRadius(18)
          .onClick(() => {
            if (this.selectedConsultationId.length > 0) {
              this.loadMessages(this.selectedConsultationId);
            }
          })
        }
        .width('100%')
      } else {
        // 发起问诊模式
        Text('一对一问诊')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Text('选择已注册医生，提交症状后进入对话式问诊。')
          .fontSize(14)
          .fontColor(MUTED_TEXT)

        this.DoctorPicker()
        this.IntakePanel()

        Text('问诊记录可在「我的 → 我的问诊」中查看')
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  DoctorPicker() {
    Column({ space: 10 }) {
      Text('选择医生')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      if (this.doctors.length === 0) {
        Text('暂无可选医生，请先在后台或医生端完善医生资料。')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
      } else {
        Column({ space: 8 }) {
          Row() {
            Column({ space: 4 }) {
              Text(this.selectedDoctorTitle())
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(DEEP_TEXT)
              Text(this.selectedDoctorSubtitle())
                .fontSize(12)
                .fontColor(MUTED_TEXT)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            Text(this.isDoctorPickerExpanded ? '▲' : '▼')
              .fontSize(12)
              .fontColor(BRAND_GREEN)
          }
          .width('100%')
          .height(52)
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .backgroundColor('#FFFFFF')
          .border({
            width: 1,
            color: this.isDoctorPickerExpanded ? BRAND_GREEN : '#DCE8DF'
          })
          .borderRadius(CARD_RADIUS)
          .onClick(() => {
            this.isDoctorPickerExpanded = !this.isDoctorPickerExpanded;
          })

          if (this.isDoctorPickerExpanded) {
            Scroll() {
              Column({ space: 8 }) {
                ForEach(this.doctors, (doctor: DoctorOption) => {
                  Column({ space: 4 }) {
                    Text(`${doctor.name}${doctor.title.length > 0 ? ' | ' + doctor.title : ''}`)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.selectedDoctorId === doctor.userId ? BRAND_GREEN : DEEP_TEXT)
                    Text(doctor.specialty.length > 0 ? doctor.specialty : '暂未填写擅长方向')
                      .fontSize(12)
                      .fontColor(MUTED_TEXT)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .width('100%')
                  .padding({ left: 14, right: 14, top: 10, bottom: 10 })
                  .backgroundColor(this.selectedDoctorId === doctor.userId ? '#EEF7F1' : '#FFFFFF')
                  .borderRadius(CARD_RADIUS)
                  .onClick(() => {
                    this.selectedDoctorId = doctor.userId;
                    this.feedback = '';
                    this.isDoctorPickerExpanded = false;
                  })
                }, (doctor: DoctorOption) => doctor.userId)
              }
              .width('100%')
            }
            .width('100%')
            .height(180)
            .padding(2)
            .backgroundColor('#F7FBF8')
            .borderRadius(CARD_RADIUS)
          }
        }
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  IntakePanel() {
    Column({ space: 10 }) {
      Text('问诊描述')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      TextInput({ placeholder: '症状，例如：头晕、乏力、睡眠差', text: this.symptom })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => {
          this.symptom = value;
          this.feedback = '';
        })
      TextInput({ placeholder: '补充描述：持续时间、饮食作息、既往情况', text: this.description })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => {
          this.description = value;
          this.feedback = '';
        })

      // 健康资料卡片
      ConsultationHealthSnapshot({
        healthCard: this.buildHealthCardSummary(),
        shareEnabled: this.shareHealthCard,
        onToggleShare: (enabled: boolean) => {
          this.shareHealthCard = enabled;
        }
      })

      // 个人信息共享（用户可自定义）
      this.PersonalInfoSharePanel()

      Button(this.isLoading ? '提交中...' : '提交问诊')
        .width('100%')
        .height(42)
        .fontColor('#FFFFFF')
        .backgroundColor(BRAND_GREEN)
        .borderRadius(CARD_RADIUS)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.submitConsultation();
        })
      if (this.feedback.length > 0) {
        Text(this.feedback)
          .fontSize(12)
          .fontColor(this.feedback.indexOf('成功') >= 0 ? BRAND_GREEN : WARM_ACCENT)
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  PersonalInfoSharePanel() {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 2 }) {
          Text('个人信息共享')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          Text('选择向医生展示的个人信息，未选择则不展示')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 姓名
      Row({ space: 10 }) {
        Toggle({ type: ToggleType.Switch, isOn: this.shareName })
          .selectedColor(BRAND_GREEN)
          .onChange((isOn: boolean) => { this.shareName = isOn; })
        Text('姓名')
          .fontSize(14)
          .fontColor(DEEP_TEXT)
          .width(50)
        if (this.shareName) {
          TextInput({ placeholder: '请输入姓名', text: this.customName.length > 0 ? this.customName : this.userName })
            .height(36)
            .fontSize(13)
            .layoutWeight(1)
            .onChange((value: string) => { this.customName = value; })
        } else {
          Text('不展示')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
            .layoutWeight(1)
        }
      }
      .width('100%')

      // 年龄
      Row({ space: 10 }) {
        Toggle({ type: ToggleType.Switch, isOn: this.shareAge })
          .selectedColor(BRAND_GREEN)
          .onChange((isOn: boolean) => { this.shareAge = isOn; })
        Text('年龄')
          .fontSize(14)
          .fontColor(DEEP_TEXT)
          .width(50)
        if (this.shareAge) {
          TextInput({ placeholder: '请输入年龄', text: this.customAge })
            .height(36)
            .fontSize(13)
            .layoutWeight(1)
            .type(InputType.Number)
            .onChange((value: string) => { this.customAge = value; })
        } else {
          Text('不展示')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
            .layoutWeight(1)
        }
      }
      .width('100%')

      // 性别
      Row({ space: 10 }) {
        Toggle({ type: ToggleType.Switch, isOn: this.shareGender })
          .selectedColor(BRAND_GREEN)
          .onChange((isOn: boolean) => { this.shareGender = isOn; })
        Text('性别')
          .fontSize(14)
          .fontColor(DEEP_TEXT)
          .width(50)
        if (this.shareGender) {
          TextInput({ placeholder: '请输入性别', text: this.customGender })
            .height(36)
            .fontSize(13)
            .layoutWeight(1)
            .onChange((value: string) => { this.customGender = value; })
        } else {
          Text('不展示')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
            .layoutWeight(1)
        }
      }
      .width('100%')

      // 手机号
      Row({ space: 10 }) {
        Toggle({ type: ToggleType.Switch, isOn: this.sharePhone })
          .selectedColor(BRAND_GREEN)
          .onChange((isOn: boolean) => { this.sharePhone = isOn; })
        Text('手机号')
          .fontSize(14)
          .fontColor(DEEP_TEXT)
          .width(50)
        if (this.sharePhone) {
          Text(this.userPhone.length > 0 ? this.userPhone : '未绑定手机号')
            .fontSize(13)
            .fontColor(MUTED_TEXT)
            .layoutWeight(1)
        } else {
          Text('不展示')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
            .layoutWeight(1)
        }
      }
      .width('100%')

      Text('🔒 仅本次问诊医生可见，严格保护隐私')
        .fontSize(11)
        .fontColor(MUTED_TEXT)
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FAFAFA')
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  ThreadList() {
    Column({ space: 10 }) {
      Text('我的问诊')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      if (this.consultations.length === 0) {
        Text('暂无问诊记录。')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
      } else {
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
            this.loadMessages(thread.id);
          })
        }, (thread: ConsultationThread) => thread.id)
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
      if (this.selectedConsultationId.length === 0) {
        Text('选择一条问诊后查看和发送消息。')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
      } else {
        Column({ space: 12 }) {
          this.ConversationSummary()
          Scroll(this.messageScroller) {
            Column({ space: 10 }) {
              // 若无消息，显示用户提交的问诊内容作为首条对话
              if (this.messages.length === 0) {
                this.InitialSubmissionBubble()
                Column({ space: 4 }) {
                  Text('⏳ 等待医生回复...')
                    .fontSize(12)
                    .fontColor(MUTED_TEXT)
                  Text('医生回复后将显示在此处，可点击「刷新消息」获取最新回复')
                    .fontSize(11)
                    .fontColor(MUTED_TEXT)
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)
                .padding({ top: 8 })
              } else {
                ForEach(this.messages, (message: ConsultationMessageItem) => {
                  this.ChatBubble(message)
                }, (message: ConsultationMessageItem) => message.id)
              }
            }
            .width('100%')
          }
          .width('100%')
          .height(320)
          .scrollBar(BarState.Auto)

          Row({ space: 8 }) {
            TextInput({ placeholder: '继续补充问诊消息', text: this.draftMessage })
              .height(44)
              .fontSize(14)
              .layoutWeight(1)
              .backgroundColor('#F7F7F7')
              .borderRadius(12)
              .onChange((value: string) => {
                this.draftMessage = value;
              })
            Button('发送')
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

      if (this.feedback.length > 0) {
        Text(this.feedback)
          .fontSize(12)
          .fontColor(this.feedback.indexOf('成功') >= 0 ? BRAND_GREEN : WARM_ACCENT)
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
    }
  }

  @Builder
  InitialSubmissionBubble() {
    Row() {
      Blank()
      Column({ space: 6 }) {
        Text('我')
          .fontSize(11)
          .fontColor('#FFFFFF')
        Text(`症状：${this.selectedConsultationSymptom()}`)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .lineHeight(21)
        if (this.selectedConsultationDescription().length > 0) {
          Text(this.selectedConsultationDescription())
            .fontSize(13)
            .fontColor('#FFFFFF')
            .lineHeight(20)
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor(BRAND_GREEN)
      .borderRadius(CARD_RADIUS)
      .constraintSize({ maxWidth: '82%' })
    }
    .width('100%')
  }

  @Builder
  ChatBubble(message: ConsultationMessageItem) {
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

  private refreshDoctors(): void {
    fetchDoctorOptions().then((items: DoctorOption[]) => {
      this.doctors = items;
      if (this.selectedDoctorId.length === 0 && items.length > 0) {
        this.selectedDoctorId = items[0].userId;
      }
    }).catch(() => {
      this.doctors = [];
    });
  }

  private refreshConsultations(): void {
    if (this.userId.length === 0) {
      return;
    }
    fetchUserConsultations(this.userId).then((items: ConsultationThread[]) => {
      this.consultations = items;
      if (this.selectedConsultationId.length === 0 && items.length > 0) {
        this.selectedConsultationId = items[0].id;
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

  private submitConsultation(): void {
    if (this.selectedDoctorId.length === 0 || this.symptom.trim().length === 0 || this.description.trim().length === 0) {
      this.feedback = '请选择医生并填写症状和描述。';
      return;
    }
    this.isLoading = true;
    const sharedName = this.shareName
      ? (this.customName.length > 0 ? this.customName : this.userName)
      : '';
    const sharedAgeText = this.shareAge ? this.customAge : '';
    const sharedAge = sharedAgeText.length > 0 ? Number(sharedAgeText) : 0;
    const sharedGender = this.shareGender ? this.customGender : '';
    const sharedPhone = this.sharePhone ? this.userPhone : '';
    createConsultation(
      this.userId, this.selectedDoctorId, this.symptom.trim(), this.description.trim(),
      sharedName, sharedAge, sharedGender, sharedPhone
    ).then((saved: boolean) => {
      this.feedback = saved ? '问诊提交成功。' : '问诊提交失败。';
      if (saved) {
        this.symptom = '';
        this.description = '';
        this.refreshConsultationsAndOpenChat();
      }
    }).catch((error: Error) => {
      this.feedback = buildConsultationSaveFailureText(error.message);
    }).finally(() => {
      this.isLoading = false;
    });
  }

  private refreshConsultationsAndOpenChat(): void {
    if (this.userId.length === 0) {
      return;
    }
    fetchUserConsultations(this.userId).then((items: ConsultationThread[]) => {
      this.consultations = items;
      if (items.length > 0) {
        this.selectedConsultationId = items[0].id;
        this.loadMessages(items[0].id);
      }
      this.showChat = true;
    }).catch(() => {
      this.consultations = [];
      this.showChat = true;
    });
  }

  private sendMessage(): void {
    if (this.selectedConsultationId.length === 0 || this.draftMessage.trim().length === 0) {
      return;
    }
    sendConsultationMessage(this.selectedConsultationId, this.draftMessage.trim()).then((saved: boolean) => {
      if (saved) {
        this.draftMessage = '';
        this.feedback = '消息发送成功。';
        this.loadMessages(this.selectedConsultationId);
        this.scrollMessagesToBottom();
      } else {
        this.feedback = buildConsultationSaveFailureText('');
      }
    }).catch((error: Error) => {
      this.feedback = buildConsultationSaveFailureText(error.message);
    });
  }

  private selectedDoctor(): DoctorOption | null {
    for (let index = 0; index < this.doctors.length; index++) {
      const doctor = this.doctors[index];
      if (doctor.userId === this.selectedDoctorId) {
        return doctor;
      }
    }
    return null;
  }

  private selectedDoctorTitle(): string {
    const doctor = this.selectedDoctor();
    if (doctor === null) {
      return '请选择医生';
    }
    return `${doctor.name}${doctor.title.length > 0 ? ' | ' + doctor.title : ''}`;
  }

  private selectedDoctorSubtitle(): string {
    const doctor = this.selectedDoctor();
    if (doctor === null) {
      return '点击展开医生列表';
    }
    return doctor.specialty.length > 0 ? doctor.specialty : '暂未填写擅长方向';
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

  private buildHealthCardSummary(): HealthCardSummary | null {
    if (this.userId.length === 0) {
      return null;
    }
    return {
      subjectId: this.userId,
      subjectName: '我',
      generatedAt: new Date().toISOString(),
      attentionCount: 0,
      urgentCount: 0,
      missingCategories: []
    };
  }

  private scrollMessagesToBottom(): void {
    Promise.resolve().then(() => {
      this.messageScroller.scrollEdge(Edge.Bottom);
    });
  }
}
