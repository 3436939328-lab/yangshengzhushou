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
  createConsultation,
  deleteConsultationMessage,
  DoctorOption,
  DoctorRecommendation,
  fetchConsultationMessages,
  fetchDoctorOptions,
  fetchRecommendedDoctor,
  fetchUserConsultations,
  recallConsultationMessage,
  sendConsultationMessage
} from '../../services/ConsultationService';
import { submitComplaint } from '../../services/ComplaintService';
import { uploadImage, UploadResult } from '../../services/AssetService';
import {
  HealthCardSummary,
  HealthProfile,
  HealthMeasurement,
  BloodPressureMeasurement,
  BloodSugarMeasurement,
  HeartRateMeasurement,
  SleepMeasurement,
  BodyMeasurement,
  BloodPressureSummary,
  BloodSugarSummary,
  HeartRateSummary,
  SleepSummary,
  BodySummary,
  AssessmentState,
  BloodSugarType,
  HeartRateContext,
  SleepType
} from '../../model/ProfileModels';
import { createDefaultHealthProfile } from '../../services/ProfileRepository';

@Component
export struct UserConsultationTab {
  @Prop userId: string;
  @Prop userName: string = '';
  @Prop userPhone: string = '';
  @Prop profile: HealthProfile = createDefaultHealthProfile();

  @State doctors: DoctorOption[] = [];
  @State consultations: ConsultationThread[] = [];
  @State messages: ConsultationMessageItem[] = [];
  @State selectedDoctor: DoctorOption | null = null;
  @State selectedConsultationId: string = '';
  @State draftMessage: string = '';
  @State feedback: string = '';
  @State isLoading: boolean = false;
  @State isUploading: boolean = false;
  @State showChat: boolean = false;
  @State showDetail: boolean = false;
  @State showActionMenu: boolean = false;
  @State actionMenuMessageId: string = '';
  @State recommendedDoctorId: string = '';
  @State recommendReason: string = '';
  @State showEvaluation: boolean = false;
  @State evalCategory: string = 'SERVICE';
  @State evalDescription: string = '';
  @State evalFeedback: string = '';
  private messageScroller: Scroller = new Scroller();

  aboutToAppear() {
    this.refreshDoctors();
    this.refreshConsultations();
    this.loadRecommendation();
  }

  private loadRecommendation(): void {
    fetchRecommendedDoctor().then((rec: DoctorRecommendation | null) => {
      if (rec && rec.doctorId) {
        this.recommendedDoctorId = rec.doctorId;
        this.recommendReason = rec.reason;
        this.reorderDoctors();
      }
    }).catch(() => {});
  }

  private reorderDoctors(): void {
    if (this.recommendedDoctorId.length === 0) {
      return;
    }
    const recommended: DoctorOption[] = [];
    const others: DoctorOption[] = [];
    for (let i = 0; i < this.doctors.length; i++) {
      if (this.doctors[i].userId === this.recommendedDoctorId) {
        recommended.push(this.doctors[i]);
      } else {
        others.push(this.doctors[i]);
      }
    }
    this.doctors = recommended.concat(others);
  }

  build() {
    Stack() {
      Column() {
        if (this.showChat) {
          this.ChatView()
        } else if (this.showDetail) {
          this.DoctorDetailView()
        } else {
          this.DoctorListView()
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

  // ==================== 医生列表页（按科室分组）====================
  @Builder
  DoctorListView() {
    Column({ space: 12 }) {
      Text('选择问诊医生')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
        .width('100%')
        .padding({ left: 18, top: 18, bottom: 4 })

      if (this.doctors.length === 0) {
        Column({ space: 8 }) {
          Text('暂无可选医生')
            .fontSize(14)
            .fontColor(MUTED_TEXT)
          Text('请稍后再试或联系管理员')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .width('100%')
        .padding({ top: 60, bottom: 60 })
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            ForEach(this.groupedDepartments(), (dept: string) => {
              this.DepartmentSection(dept)
            }, (dept: string) => dept)
          }
          .width('100%')
          .padding({ left: 14, right: 14, bottom: 20 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  DepartmentSection(dept: string) {
    Column({ space: 10 }) {
      Row() {
        Column()
          .width(3)
          .height(16)
          .backgroundColor(BRAND_GREEN)
          .borderRadius(2)
        Text(dept)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .margin({ left: 6 })
        Blank()
        Text(`${this.doctorsInDept(dept).length} 位医生`)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
      }
      .width('100%')

      ForEach(this.doctorsInDept(dept), (doctor: DoctorOption) => {
        this.DoctorCardItem(doctor)
      }, (doctor: DoctorOption) => doctor.userId)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  DoctorCardItem(doctor: DoctorOption) {
    Row({ space: 12 }) {
      // 头像 + 可咨询徽章
      Stack({ alignContent: Alignment.BottomStart }) {
        if (doctor.avatar.length > 0) {
          Image(doctor.avatar)
            .width(56)
            .height(56)
            .borderRadius(28)
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            Text(doctor.name.charAt(0))
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .width(56)
          .height(56)
          .borderRadius(28)
          .backgroundColor(BRAND_GREEN)
          .justifyContent(FlexAlign.Center)
        }
        Text(doctor.accepting ? '可咨询' : '休息中')
          .fontSize(9)
          .fontColor(Color.White)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .backgroundColor(doctor.accepting ? WARM_ACCENT : '#999999')
          .borderRadius(4)
          .offset({ x: -4, y: 4 })
      }
      .width(56)
      .height(62)

      Column({ space: 5 }) {
        Row({ space: 6 }) {
          Text(doctor.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(BRAND_GREEN)
          if (doctor.userId === this.recommendedDoctorId) {
            Text('AI推荐')
              .fontSize(9)
              .fontColor(Color.White)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .backgroundColor(WARM_ACCENT)
              .borderRadius(4)
          }
          if (doctor.title.length > 0) {
            Text(doctor.title)
              .fontSize(12)
              .fontColor(DEEP_TEXT)
          }
        }
        if (doctor.department.length > 0) {
          Text(doctor.department)
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        if (doctor.specialty.length > 0) {
          Row() {
            Text('擅长：')
              .fontSize(12)
              .fontColor(MUTED_TEXT)
            Text(doctor.specialty)
              .fontSize(12)
              .fontColor(DEEP_TEXT)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 继续问诊 / 开始问诊
      Text(this.hasExistingWithDoctor(doctor) ? '继续问诊' : '开始问诊')
        .fontSize(13)
        .fontColor(Color.White)
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(doctor.accepting || this.hasExistingWithDoctor(doctor) ? BRAND_GREEN : '#CCCCCC')
        .borderRadius(14)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
    .onClick(() => {
      this.enterDetail(doctor);
    })
  }

  // ==================== 医生详情页 ====================
  @Builder
  DoctorDetailView() {
    Column() {
      // 顶部绿色 banner
      Column({ space: 8 }) {
        Row() {
          Text('←')
            .fontSize(20)
            .fontColor(Color.White)
            .onClick(() => { this.exitDetail(); })
          Blank()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8 })

        Row({ space: 14 }) {
          if (this.selectedDoctor && this.selectedDoctor.avatar.length > 0) {
            Image(this.selectedDoctor.avatar)
              .width(70)
              .height(70)
              .borderRadius(35)
              .objectFit(ImageFit.Cover)
              .border({ width: 2, color: Color.White })
          } else if (this.selectedDoctor) {
            Column() {
              Text(this.selectedDoctor.name.charAt(0))
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(BRAND_GREEN)
            }
            .width(70)
            .height(70)
            .borderRadius(35)
            .backgroundColor(Color.White)
            .justifyContent(FlexAlign.Center)
          }

          Column({ space: 4 }) {
            if (this.selectedDoctor) {
              Row({ space: 6 }) {
                Text(this.selectedDoctor.name)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                if (this.selectedDoctor.title.length > 0) {
                  Text(this.selectedDoctor.title)
                    .fontSize(13)
                    .fontColor(Color.White)
                  Text('已认证')
                    .fontSize(10)
                    .fontColor(BRAND_GREEN)
                    .backgroundColor(Color.White)
                    .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                    .borderRadius(4)
                }
              }
              if (this.selectedDoctor.department.length > 0) {
                Text(this.selectedDoctor.department)
                  .fontSize(13)
                  .fontColor(Color.White)
              }
              Row({ space: 6 }) {
                Text(this.selectedDoctor.accepting ? '可咨询' : '休息中')
                  .fontSize(10)
                  .fontColor(Color.White)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .backgroundColor(this.selectedDoctor.accepting ? WARM_ACCENT : '#999999')
                  .borderRadius(8)
                if (this.hasExistingWithDoctor(this.selectedDoctor)) {
                  Text('有问诊记录')
                    .fontSize(10)
                    .fontColor(BRAND_GREEN)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .backgroundColor(Color.White)
                    .borderRadius(8)
                }
              }
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .width('100%')
      .linearGradient({
        angle: 180,
        colors: [[BRAND_GREEN, 0.1], ['#5BA839', 1.0]]
      })

      // 详情内容
      Scroll() {
        Column({ space: 14 }) {
          // 医生介绍
          if (this.selectedDoctor && this.selectedDoctor.specialty.length > 0) {
            this.DetailSection('擅长方向', this.selectedDoctor.specialty)
          }

          // 个人简介
          if (this.selectedDoctor && this.selectedDoctor.introduction.length > 0) {
            this.DetailSection('个人简介', this.selectedDoctor.introduction)
          }

          // 接诊状态
          if (this.selectedDoctor) {
            this.DetailSection('接诊状态', this.selectedDoctor.accepting ? '当前可接诊，可立即发起问诊' : '当前休息中，暂无法接诊')
          }

          // 问诊须知
          Column({ space: 6 }) {
            Row() {
              Column()
                .width(3)
                .height(14)
                .backgroundColor(BRAND_GREEN)
                .borderRadius(2)
              Text('问诊须知')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(DEEP_TEXT)
                .margin({ left: 6 })
            }
            Text('1. 问诊时将自动共享您的姓名、性别、年龄、手机号等基本信息给医生\n2. 问诊时将自动共享您最新的健康指标（血压、血糖、心率等）给医生\n3. 舌象照片也会共享给医生辅助诊断\n4. 您可以在个人中心修改共享信息\n5. 医生回复可能存在延迟，请耐心等待')
              .fontSize(12)
              .fontColor(MUTED_TEXT)
              .lineHeight(20)
          }
          .width('100%')
          .padding(14)
          .backgroundColor(CARD_BG)
          .borderRadius(CARD_RADIUS)

          // 开始问诊按钮
          if (this.selectedDoctor && this.selectedDoctor.accepting) {
            Button(this.hasExistingWithDoctor(this.selectedDoctor) ? '继续问诊' : '开始问诊')
              .width('100%')
              .height(46)
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor(BRAND_GREEN)
              .borderRadius(23)
              .margin({ top: 8 })
              .onClick(() => { this.enterChat(this.selectedDoctor!); })
          } else if (this.selectedDoctor && this.hasExistingWithDoctor(this.selectedDoctor)) {
            Button('继续问诊')
              .width('100%')
              .height(46)
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor(BRAND_GREEN)
              .borderRadius(23)
              .margin({ top: 8 })
              .onClick(() => { this.enterChat(this.selectedDoctor!); })
          } else {
            Column({ space: 6 }) {
              Text('医生休息中')
                .fontSize(14)
                .fontColor(MUTED_TEXT)
              Text('休息期间无法发起新问诊')
                .fontSize(12)
                .fontColor(MUTED_TEXT)
            }
            .width('100%')
            .padding(14)
            .alignItems(HorizontalAlign.Center)
          }
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 14, bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .backgroundColor(PAGE_BG)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  DetailSection(title: string, content: string) {
    Column({ space: 6 }) {
      Row() {
        Column()
          .width(3)
          .height(14)
          .backgroundColor(BRAND_GREEN)
          .borderRadius(2)
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .margin({ left: 6 })
      }
      Text(content)
        .fontSize(13)
        .fontColor(DEEP_TEXT)
        .lineHeight(20)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
    .alignItems(HorizontalAlign.Start)
  }

  // ==================== 评价/投诉弹窗 ====================
  @Builder
  EvaluationDialog() {
    Column() {
      Column({ space: 14 }) {
        Text('问诊评价')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)

        Text('您对本次问诊满意吗？如不满意可提交投诉，我们会及时处理。')
          .fontSize(13)
          .fontColor(MUTED_TEXT)

        Column({ space: 8 }) {
          Text('投诉类型')
            .fontSize(14)
            .fontColor(DEEP_TEXT)
          Row({ space: 8 }) {
            this.CategoryChip('SERVICE', '服务态度')
            this.CategoryChip('PROFESSIONAL', '专业水平')
            this.CategoryChip('RESPONSE', '回复速度')
            this.CategoryChip('OTHER', '其他')
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 6 }) {
          Text('详细描述')
            .fontSize(14)
            .fontColor(DEEP_TEXT)
          TextArea({ placeholder: '请描述您的问题或不满...', text: this.evalDescription })
            .fontSize(14)
            .height(100)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .onChange((value: string) => { this.evalDescription = value; })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        if (this.evalFeedback.length > 0) {
          Text(this.evalFeedback)
            .fontSize(12)
            .fontColor(this.evalFeedback.startsWith('提交成功') ? BRAND_GREEN : WARM_ACCENT)
        }

        Row({ space: 12 }) {
          Button('取消')
            .height(40)
            .fontSize(14)
            .layoutWeight(1)
            .backgroundColor('#F0F0F0')
            .fontColor(DEEP_TEXT)
            .borderRadius(20)
            .onClick(() => {
              this.showEvaluation = false;
              this.evalDescription = '';
              this.evalFeedback = '';
            })
          Button('提交投诉')
            .height(40)
            .fontSize(14)
            .layoutWeight(1)
            .backgroundColor(WARM_ACCENT)
            .fontColor(Color.White)
            .borderRadius(20)
            .onClick(() => {
              if (this.evalDescription.trim().length === 0) {
                this.evalFeedback = '请填写投诉描述';
                return;
              }
              this.evalFeedback = '正在提交...';
              submitComplaint(
                this.selectedConsultationId,
                this.doctorUserId(),
                this.evalCategory,
                this.evalDescription.trim()
              ).then(() => {
                this.evalFeedback = '提交成功，管理员将尽快处理您的投诉';
                setTimeout(() => {
                  this.showEvaluation = false;
                  this.evalDescription = '';
                  this.evalFeedback = '';
                  this.exitChat();
                }, 1500);
              }).catch((err: Error) => {
                this.evalFeedback = `提交失败: ${err.message}`;
              });
            })
        }
        .width('100%')
      }
      .width('85%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.5)')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  CategoryChip(value: string, label: string) {
    Text(label)
      .fontSize(12)
      .fontColor(this.evalCategory === value ? Color.White : DEEP_TEXT)
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .backgroundColor(this.evalCategory === value ? WARM_ACCENT : '#F0F0F0')
      .borderRadius(12)
      .onClick(() => { this.evalCategory = value; })
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
        Text(this.doctorName())
          .fontSize(17)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
        Blank()
        Text('结束问诊')
          .fontSize(12)
          .fontColor(Color.White)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .border({ width: 1, color: Color.White })
          .borderRadius(10)
          .onClick(() => { this.showEvaluation = true; })
      }
      .width('100%')
      .height(48)
      .padding({ left: 16, right: 16 })
      .backgroundColor(BRAND_GREEN)

      if (this.showEvaluation) {
        this.EvaluationDialog()
      }

      // 消息区域
      Scroll(this.messageScroller) {
        Column({ space: 12 }) {
          if (this.selectedConsultationId.length === 0) {
            Text('请描述您的症状和情况，医生将为您解答')
              .fontSize(12)
              .fontColor(MUTED_TEXT)
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 16, bottom: 8 })
          }
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
        // 图片按钮
        Button() {
          Text('📷')
            .fontSize(22)
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .onClick(() => { this.pickAndSendImage(); })

        // 文本输入框
        TextInput({ placeholder: '', text: this.draftMessage })
          .height(36)
          .fontSize(15)
          .layoutWeight(1)
          .backgroundColor('#FFFFFF')
          .borderRadius(6)
          .onChange((value: string) => { this.draftMessage = value; })

        // 语音按钮
        Button() {
          Text('🎤')
            .fontSize(22)
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .borderRadius(0)
        .onClick(() => { this.feedback = '语音功能暂未开放'; })

        // 发送按钮
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

  @Builder
  ChatBubble(msg: ConsultationMessageItem) {
    if (msg.senderRole === 'DOCTOR') {
      Column({ space: 3 }) {
        Row({ space: 8 }) {
          this.DoctorAvatar()
          this.BubbleContent(msg, false)
          Blank()
        }
        .width('100%')
        .gesture(
          LongPressGesture()
            .onAction(() => { this.openActionMenu(msg.id); })
        )

        if (!this.isImageMessage(msg.content) && msg.content !== '[已撤回]') {
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
        this.BubbleContent(msg, true)
        this.UserAvatar()
      }
      .width('100%')
      .gesture(
        LongPressGesture()
          .onAction(() => { this.openActionMenu(msg.id); })
      )
    }
  }

  @Builder
  DoctorAvatar() {
    if (this.selectedDoctor && this.selectedDoctor.avatar.length > 0) {
      Image(this.selectedDoctor.avatar)
        .width(36)
        .height(36)
        .borderRadius(4)
        .objectFit(ImageFit.Cover)
    } else {
      Column() {
        Text('医')
          .fontSize(14)
          .fontColor(Color.White)
      }
      .width(36)
      .height(36)
      .borderRadius(4)
      .backgroundColor(BRAND_GREEN)
      .justifyContent(FlexAlign.Center)
    }
  }

  @Builder
  UserAvatar() {
    Column() {
      Text('我')
        .fontSize(14)
        .fontColor(Color.White)
    }
    .width(36)
    .height(36)
    .borderRadius(4)
    .backgroundColor('#888888')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  BubbleContent(msg: ConsultationMessageItem, isUser: boolean) {
    if (this.isImageMessage(msg.content)) {
      Image(this.extractImageUrl(msg.content))
        .width(120)
        .height(120)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
        .constraintSize({ maxWidth: '72%' })
    } else {
      Text(msg.content)
        .fontSize(15)
        .fontColor('#000000')
        .lineHeight(22)
        .padding({ left: 10, right: 10, top: 8, bottom: 8 })
        .backgroundColor(isUser ? '#95EC69' : '#FFFFFF')
        .borderRadius(8)
        .constraintSize({ maxWidth: '72%' })
    }
  }

  // ==================== 业务逻辑 ====================
  private doctorName(): string {
    return this.selectedDoctor ? this.selectedDoctor.name : '问诊';
  }

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

  private doctorUserId(): string {
    return this.selectedDoctor ? this.selectedDoctor.userId : '';
  }

  private groupedDepartments(): string[] {
    const depts: string[] = [];
    for (let i = 0; i < this.doctors.length; i++) {
      const dept = this.doctors[i].department.length > 0 ? this.doctors[i].department : '其他科室';
      if (depts.indexOf(dept) < 0) {
        depts.push(dept);
      }
    }
    return depts;
  }

  private doctorsInDept(dept: string): DoctorOption[] {
    const result: DoctorOption[] = [];
    for (let i = 0; i < this.doctors.length; i++) {
      const d = this.doctors[i];
      const dDept = d.department.length > 0 ? d.department : '其他科室';
      if (dDept === dept) {
        result.push(d);
      }
    }
    return result;
  }

  private isImageMessage(content: string): boolean {
    return content.startsWith('[IMG]');
  }

  private extractImageUrl(content: string): string {
    return content.substring(5);
  }

  private hasExistingWithDoctor(doctor: DoctorOption): boolean {
    for (let i = 0; i < this.consultations.length; i++) {
      if (this.consultations[i].doctorId === doctor.userId) {
        return true;
      }
    }
    return false;
  }

  private enterDetail(doctor: DoctorOption): void {
    this.selectedDoctor = doctor;
    this.showDetail = true;
  }

  private exitDetail(): void {
    this.showDetail = false;
    this.selectedDoctor = null;
    this.refreshConsultations();
  }

  private enterChat(doctor: DoctorOption): void {
    this.selectedDoctor = doctor;
    this.selectedConsultationId = '';
    this.messages = [];
    this.draftMessage = '';
    this.feedback = '';

    for (let i = 0; i < this.consultations.length; i++) {
      if (this.consultations[i].doctorId === doctor.userId) {
        this.selectedConsultationId = this.consultations[i].id;
        this.loadMessages(this.consultations[i].id);
        break;
      }
    }
    this.showChat = true;
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

    this.ensureConsultation(content)
      .then((consultationId: string) => {
        return sendConsultationMessage(consultationId, content);
      })
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
      return this.ensureConsultation('[图片问诊]')
        .then((consultationId: string) => {
          return sendConsultationMessage(consultationId, imageContent);
        })
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

  private ensureConsultation(firstSymptom: string): Promise<string> {
    if (this.selectedConsultationId.length > 0) {
      return Promise.resolve(this.selectedConsultationId);
    }

    let healthSnapshotJson = '';
    const snapshot = this.buildHealthCardSummary();
    if (snapshot) {
      healthSnapshotJson = JSON.stringify(snapshot);
    }

    return createConsultation(
      this.userId,
      this.doctorUserId(),
      firstSymptom,
      '',
      this.userName,
      0,
      '',
      this.userPhone,
      healthSnapshotJson,
      this.buildTongueImageUrls()
    ).then(() => {
      return fetchUserConsultations(this.userId);
    }).then((threads: ConsultationThread[]) => {
      this.consultations = threads;
      for (let i = 0; i < threads.length; i++) {
        if (threads[i].doctorId === this.doctorUserId()) {
          this.selectedConsultationId = threads[i].id;
          return threads[i].id;
        }
      }
      throw new Error('consultation not found after creation');
    });
  }

  private refreshDoctors(): void {
    fetchDoctorOptions().then((items: DoctorOption[]) => {
      this.doctors = items;
      this.reorderDoctors();
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

  private buildHealthCardSummary(): HealthCardSummary | null {
    if (this.userId.length === 0) {
      return null;
    }
    const measurements = this.profile.measurements;
    let bloodPressure: BloodPressureSummary | null = null;
    let bloodSugar: BloodSugarSummary | null = null;
    let heartRate: HeartRateSummary | null = null;
    let sleep: SleepSummary | null = null;
    let body: BodySummary | null = null;
    let attentionCount = 0;

    if (measurements) {
      for (const m of measurements) {
        if (m.metricCode === 'BLOOD_PRESSURE' && !bloodPressure) {
          const bp = m as BloodPressureMeasurement;
          const outOfRange = bp.systolic >= 140 || bp.diastolic >= 90;
          if (outOfRange) attentionCount++;
          bloodPressure = {
            systolic: bp.systolic,
            diastolic: bp.diastolic,
            state: outOfRange ? AssessmentState.ATTENTION : AssessmentState.IN_RANGE,
            stateText: outOfRange ? '偏高' : '正常',
            measuredAt: bp.measuredAt
          };
        } else if (m.metricCode === 'BLOOD_SUGAR' && !bloodSugar) {
          const bs = m as BloodSugarMeasurement;
          const outOfRange = bs.value > 7 || bs.value < 3.9;
          if (outOfRange) attentionCount++;
          bloodSugar = {
            value: bs.value,
            unit: 'mmol/L',
            type: bs.sugarType,
            typeText: bs.sugarType === BloodSugarType.FASTING ? '空腹' : (bs.sugarType === BloodSugarType.POST_MEAL_2H ? '餐后2h' : '随机'),
            state: outOfRange ? AssessmentState.ATTENTION : AssessmentState.IN_RANGE,
            stateText: outOfRange ? '异常' : '正常',
            measuredAt: bs.measuredAt
          };
        } else if (m.metricCode === 'HEART_RATE' && !heartRate) {
          const hr = m as HeartRateMeasurement;
          const outOfRange = hr.value > 100 || hr.value < 60;
          if (outOfRange) attentionCount++;
          heartRate = {
            value: hr.value,
            unit: '次/分',
            context: hr.context,
            state: outOfRange ? AssessmentState.ATTENTION : AssessmentState.IN_RANGE,
            stateText: outOfRange ? '异常' : '正常',
            measuredAt: hr.measuredAt
          };
        } else if (m.metricCode === 'SLEEP' && !sleep) {
          const sl = m as SleepMeasurement;
          const hours = sl.totalSleepMinutes / 60;
          const outOfRange = hours < 6 || hours > 9;
          if (outOfRange) attentionCount++;
          sleep = {
            totalMinutes: sl.totalSleepMinutes,
            totalText: `${Math.round(hours * 10) / 10}小时`,
            sleepType: sl.sleepType,
            state: outOfRange ? AssessmentState.ATTENTION : AssessmentState.IN_RANGE,
            stateText: outOfRange ? '异常' : '正常',
            measuredAt: sl.measuredAt,
            source: sl.subjectiveFeeling || 'manual'
          };
        } else if (m.metricCode === 'BODY' && !body) {
          const bd = m as BodyMeasurement;
          if (bd.weightKg !== undefined) {
            body = {
              weightKg: bd.weightKg,
              bmi: bd.bmi !== undefined ? bd.bmi : 0,
              state: AssessmentState.IN_RANGE,
              stateText: '正常',
              measuredAt: bd.measuredAt
            };
          }
        }
      }
    }

    return {
      subjectId: this.userId,
      subjectName: this.userName || '我',
      generatedAt: new Date().toISOString(),
      attentionCount,
      urgentCount: 0,
      missingCategories: [],
      bloodPressure: bloodPressure || undefined,
      bloodSugar: bloodSugar || undefined,
      heartRate: heartRate || undefined,
      sleep: sleep || undefined,
      body: body || undefined
    };
  }

  private buildTongueImageUrls(): string {
    if (!this.profile.tongueImages || this.profile.tongueImages.length === 0) {
      return '';
    }
    const urls: string[] = [];
    for (const img of this.profile.tongueImages) {
      if (img.imageUrl && img.imageUrl.length > 0) {
        urls.push(img.imageUrl);
      } else if (img.thumbnailUrl && img.thumbnailUrl.length > 0) {
        urls.push(img.thumbnailUrl);
      }
    }
    return urls.join(',');
  }

  private scrollMessagesToBottom(): void {
    Promise.resolve().then(() => {
      this.messageScroller.scrollEdge(Edge.Bottom);
    });
  }
}
