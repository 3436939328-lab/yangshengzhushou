import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  PAGE_BG,
  WARM_ACCENT,
  DANGER_RED
} from '../../theme/WellnessTheme';
import {
  appealStatusText,
  complaintStatusText,
  DoctorAppealItem,
  DoctorSanctionItem,
  fetchDoctorAppeals,
  fetchDoctorComplaints,
  fetchDoctorSanctions,
  SanctionsResult,
  sanctionStatusText,
  sanctionTypeText,
  submitAppeal,
  UserComplaintItem,
  categoryText
} from '../../services/ComplaintService';

@Component
export struct DoctorComplaintTab {
  @Prop doctorId: string;

  @State complaints: UserComplaintItem[] = [];
  @State sanctions: DoctorSanctionItem[] = [];
  @State activeSanctions: DoctorSanctionItem[] = [];
  @State appeals: DoctorAppealItem[] = [];
  @State blocked: boolean = false;
  @State showAppealDialog: boolean = false;
  @State appealDecisionId: number = 0;
  @State appealReason: string = '';
  @State feedback: string = '';
  @State appealType: 'complaint' | 'sanction' = 'complaint';
  @State currentTab: number = 0; // 0:投诉 1:处罚 2:申诉

  aboutToAppear() {
    this.refresh();
  }

  private refresh(): void {
    fetchDoctorComplaints().then((items: UserComplaintItem[]) => {
      this.complaints = items;
    });
    fetchDoctorSanctions().then((data: SanctionsResult) => {
      this.sanctions = data.all;
      this.activeSanctions = data.active;
      this.blocked = data.blocked;
    });
    fetchDoctorAppeals().then((items: DoctorAppealItem[]) => {
      this.appeals = items;
    });
  }

  private openComplaintAppeal(complaint: UserComplaintItem): void {
    if (!complaint.decisionId) {
      this.feedback = '该投诉尚未处理，暂无法申诉';
      return;
    }
    this.appealDecisionId = complaint.decisionId;
    this.appealType = 'complaint';
    this.appealReason = '';
    this.feedback = '';
    this.showAppealDialog = true;
  }

  build() {
    Column({ space: 0 }) {
      // 顶部标题
      Column({ space: 8 }) {
        Text('投诉与申诉')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .width('100%')
          .padding({ left: 18, top: 18, bottom: 2 })

        if (this.blocked) {
          Row({ space: 8 }) {
            Text('⚠')
              .fontSize(16)
              .fontColor(WARM_ACCENT)
            Text('您当前被暂停接诊，在此期间无法接受新问诊。如有异议请提交申诉。')
              .fontSize(13)
              .fontColor(WARM_ACCENT)
              .layoutWeight(1)
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFF4E6')
          .borderRadius(CARD_RADIUS)
          .margin({ left: 14, right: 14, top: 8 })
        }

        // Tab 切换
        Row() {
          this.TabItem(0, '收到的投诉', this.complaints.length)
          this.TabItem(1, '处罚记录', this.sanctions.length)
          this.TabItem(2, '我的申诉', this.appeals.length)
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 12 })
      }
      .width('100%')
      .backgroundColor(PAGE_BG)

      // 内容区域
      Scroll() {
        Column({ space: 12 }) {
          if (this.currentTab === 0) {
            this.ComplaintsSection()
          } else if (this.currentTab === 1) {
            this.SanctionsSection()
          } else {
            this.AppealsSection()
          }
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 14, bottom: 24 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .backgroundColor(PAGE_BG)

      if (this.showAppealDialog) {
        this.AppealDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(PAGE_BG)
  }

  @Builder
  TabItem(index: number, title: string, count: number) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(14)
        .fontColor(this.currentTab === index ? BRAND_GREEN : MUTED_TEXT)
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
      if (count > 0) {
        Text(`${count}`)
          .fontSize(10)
          .fontColor(Color.White)
          .padding({ left: 6, right: 6, top: 1, bottom: 1 })
          .backgroundColor(this.currentTab === index ? BRAND_GREEN : '#CCCCCC')
          .borderRadius(10)
      }
      Column()
        .width('100%')
        .height(2)
        .backgroundColor(this.currentTab === index ? BRAND_GREEN : Color.Transparent)
        .borderRadius(1)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 8, bottom: 4 })
    .onClick(() => {
      this.currentTab = index;
    })
  }

  @Builder
  ComplaintsSection() {
    if (this.complaints.length === 0) {
      Column({ space: 12 }) {
        Text('📋')
          .fontSize(48)
        Text('暂无投诉记录')
          .fontSize(14)
          .fontColor(MUTED_TEXT)
      }
      .width('100%')
      .padding({ top: 60 })
      .alignItems(HorizontalAlign.Center)
    } else {
      ForEach(this.complaints, (c: UserComplaintItem) => {
        this.ComplaintCard(c)
      }, (c: UserComplaintItem) => `${c.id}`)
    }
  }

  @Builder
  ComplaintCard(c: UserComplaintItem) {
    Column({ space: 10 }) {
      // 头部：编号 + 状态 + 时间
      Row({ space: 8 }) {
        Column()
          .width(4)
          .height(16)
          .backgroundColor(this.getStatusColor(c.status))
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

      // 类别标签
      if (c.category && c.category.length > 0) {
        Row({ space: 6 }) {
          Text(categoryText(c.category))
            .fontSize(11)
            .fontColor(BRAND_GREEN)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor('#EEF7F1')
            .borderRadius(10)
          Text(complaintStatusText(c.status))
            .fontSize(11)
            .fontColor(this.getStatusColor(c.status))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor(this.getStatusBgColor(c.status))
            .borderRadius(10)
        }
        .width('100%')
      }

      // 投诉内容
      Text(c.description)
        .fontSize(14)
        .fontColor(DEEP_TEXT)
        .lineHeight(22)
        .width('100%')

      // 处理结果
      if (c.decisionReason && c.decisionReason.length > 0) {
        Column({ space: 4 }) {
          Row({ space: 6 }) {
            Text('📝')
              .fontSize(12)
            Text('管理员处理结果')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(DEEP_TEXT)
          }
          Text(c.decisionReason)
            .fontSize(13)
            .fontColor(MUTED_TEXT)
            .lineHeight(20)
            .padding({ left: 18 })
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#F8F9FA')
        .borderRadius(8)
      }

      // 申诉状态
      if (c.appeal && c.appeal.status) {
        Column({ space: 4 }) {
          Row({ space: 6 }) {
            Text('⚖️')
              .fontSize(12)
            Text('申诉状态')
              .fontSize(12)
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
          if (c.appeal.reason && c.appeal.reason.length > 0) {
            Text(`申诉理由：${c.appeal.reason}`)
              .fontSize(12)
              .fontColor(MUTED_TEXT)
              .lineHeight(18)
              .padding({ left: 18 })
          }
          if (c.appeal.resultReason && c.appeal.resultReason.length > 0) {
            Text(`复核结果：${c.appeal.resultReason}`)
              .fontSize(12)
              .fontColor(MUTED_TEXT)
              .lineHeight(18)
              .padding({ left: 18 })
          }
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#FFF7E6')
        .borderRadius(8)
      }

      // 底部操作区
      Row() {
        Blank()
        // 只有已处理且未申诉过的投诉才能申诉
        if ((c.status === 'UPHELD' || c.status === 'REJECTED') &&
            (!c.appeal || !c.appeal.status)) {
          Text('申诉')
            .fontSize(13)
            .fontColor(BRAND_GREEN)
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .backgroundColor('#F0F7F2')
            .borderRadius(16)
            .onClick(() => {
              this.openComplaintAppeal(c);
            })
        }
        if (c.appeal && c.appeal.status) {
          Text('已申诉')
            .fontSize(13)
            .fontColor(MUTED_TEXT)
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .backgroundColor('#F0F0F0')
            .borderRadius(16)
        }
      }
      .width('100%')
      .margin({ top: 4 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(CARD_RADIUS)
    .shadow({ radius: 2, color: '#1A000000', offsetX: 0, offsetY: 1 })
  }

  @Builder
  SanctionsSection() {
    if (this.sanctions.length === 0) {
      Column({ space: 12 }) {
        Text('⚖️')
          .fontSize(48)
        Text('暂无处罚记录')
          .fontSize(14)
          .fontColor(MUTED_TEXT)
      }
      .width('100%')
      .padding({ top: 60 })
      .alignItems(HorizontalAlign.Center)
    } else {
      ForEach(this.sanctions, (s: DoctorSanctionItem) => {
        this.SanctionCard(s)
      }, (s: DoctorSanctionItem) => `${s.id}`)
    }
  }

  @Builder
  SanctionCard(s: DoctorSanctionItem) {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Column()
          .width(4)
          .height(16)
          .backgroundColor(s.status === 'ACTIVE' ? WARM_ACCENT : MUTED_TEXT)
          .borderRadius(2)
        Text(sanctionTypeText(s.type))
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(s.status === 'ACTIVE' ? WARM_ACCENT : DEEP_TEXT)
        Blank()
        Text(sanctionStatusText(s.status))
          .fontSize(11)
          .fontColor(s.status === 'ACTIVE' ? WARM_ACCENT : MUTED_TEXT)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(s.status === 'ACTIVE' ? '#FFF4E6' : '#F0F0F0')
          .borderRadius(10)
      }
      .width('100%')

      if (s.reason && s.reason.length > 0) {
        Text(s.reason)
          .fontSize(13)
          .fontColor(DEEP_TEXT)
          .lineHeight(22)
          .width('100%')
      }

      Row({ space: 16 }) {
        Text(`开始：${s.startsAt ? s.startsAt.substring(0, 10) : '未知'}`)
          .fontSize(11)
          .fontColor(MUTED_TEXT)
        if (s.endsAt) {
          Text(`结束：${s.endsAt.substring(0, 10)}`)
            .fontSize(11)
            .fontColor(MUTED_TEXT)
        }
      }
      .width('100%')

      // 申诉按钮
      Row() {
        Blank()
        if (s.status === 'ACTIVE') {
          Text('申诉')
            .fontSize(13)
            .fontColor(BRAND_GREEN)
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .backgroundColor('#F0F7F2')
            .borderRadius(16)
            .onClick(() => {
              this.appealDecisionId = s.decisionId;
              this.appealType = 'sanction';
              this.appealReason = '';
              this.feedback = '';
              this.showAppealDialog = true;
            })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(CARD_RADIUS)
    .shadow({ radius: 2, color: '#1A000000', offsetX: 0, offsetY: 1 })
  }

  @Builder
  AppealsSection() {
    if (this.appeals.length === 0) {
      Column({ space: 12 }) {
        Text('📨')
          .fontSize(48)
        Text('暂无申诉记录')
          .fontSize(14)
          .fontColor(MUTED_TEXT)
      }
      .width('100%')
      .padding({ top: 60 })
      .alignItems(HorizontalAlign.Center)
    } else {
      ForEach(this.appeals, (a: DoctorAppealItem) => {
        this.AppealCard(a)
      }, (a: DoctorAppealItem) => `${a.id}`)
    }
  }

  @Builder
  AppealCard(a: DoctorAppealItem) {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Column()
          .width(4)
          .height(16)
          .backgroundColor(BRAND_GREEN)
          .borderRadius(2)
        Text(`申诉 #${a.id}`)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
        Text(appealStatusText(a.status))
          .fontSize(11)
          .fontColor(BRAND_GREEN)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor('#EEF7F1')
          .borderRadius(10)
      }
      .width('100%')

      Column({ space: 4 }) {
        Text('申诉理由')
          .fontSize(12)
          .fontColor(MUTED_TEXT)
        Text(a.reason)
          .fontSize(13)
          .fontColor(DEEP_TEXT)
          .lineHeight(22)
      }
      .width('100%')

      if (a.resultReason && a.resultReason.length > 0) {
        Column({ space: 4 }) {
          Text('处理结果')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
          Text(a.resultReason)
            .fontSize(13)
            .fontColor(DEEP_TEXT)
            .lineHeight(22)
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#F8F9FA')
        .borderRadius(8)
      }

      Text(a.createdAt ? a.createdAt.substring(0, 16) : '')
        .fontSize(11)
        .fontColor(MUTED_TEXT)
        .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(CARD_RADIUS)
    .shadow({ radius: 2, color: '#1A000000', offsetX: 0, offsetY: 1 })
  }

  @Builder
  AppealDialog() {
    Column() {
      Column({ space: 16 }) {
        Text('提交申诉')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .width('100%')

        Column({ space: 8 }) {
          Text('申诉理由')
            .fontSize(14)
            .fontColor(DEEP_TEXT)
            .fontWeight(FontWeight.Medium)
          TextArea({ placeholder: '请详细说明申诉理由，我们将尽快审核', text: this.appealReason })
            .fontSize(14)
            .height(120)
            .backgroundColor('#F5F5F5')
            .borderRadius(10)
            .padding(10)
            .onChange((value: string) => { this.appealReason = value; })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        if (this.feedback.length > 0) {
          Text(this.feedback)
            .fontSize(12)
            .fontColor(DANGER_RED)
            .width('100%')
        }

        Row({ space: 12 }) {
          Button('取消')
            .height(44)
            .fontSize(14)
            .layoutWeight(1)
            .backgroundColor('#F0F0F0')
            .fontColor(DEEP_TEXT)
            .borderRadius(22)
            .onClick(() => {
              this.showAppealDialog = false;
              this.appealReason = '';
              this.feedback = '';
            })
          Button('提交申诉')
            .height(44)
            .fontSize(14)
            .layoutWeight(1)
            .backgroundColor(BRAND_GREEN)
            .fontColor(Color.White)
            .borderRadius(22)
            .onClick(() => {
              if (this.appealReason.trim().length === 0) {
                this.feedback = '请填写申诉理由';
                return;
              }
              submitAppeal(this.appealDecisionId, this.appealReason.trim()).then(() => {
                this.showAppealDialog = false;
                this.appealReason = '';
                this.feedback = '';
                this.refresh();
              }).catch((err: Error) => {
                this.feedback = `申诉失败: ${err.message}`;
              });
            })
        }
        .width('100%')
      }
      .width('88%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.5)')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // 点击遮罩关闭
      this.showAppealDialog = false;
      this.appealReason = '';
      this.feedback = '';
    })
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case 'SUBMITTED': return '#FFA500';
      case 'REVIEWING': return '#1890FF';
      case 'NEED_INFO': return '#FA8C16';
      case 'UPHELD': return WARM_ACCENT;
      case 'REJECTED': return BRAND_GREEN;
      case 'MERGED': return MUTED_TEXT;
      default: return MUTED_TEXT;
    }
  }

  private getStatusBgColor(status: string): string {
    switch (status) {
      case 'SUBMITTED': return '#FFF7E6';
      case 'REVIEWING': return '#E6F4FF';
      case 'NEED_INFO': return '#FFF1E6';
      case 'UPHELD': return '#FFF4E6';
      case 'REJECTED': return '#EEF7F1';
      case 'MERGED': return '#F0F0F0';
      default: return '#F0F0F0';
    }
  }
}
