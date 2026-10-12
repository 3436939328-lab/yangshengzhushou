import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT,
  DANGER_RED
} from '../../theme/WellnessTheme';
import {
  DoctorWorkbenchData,
  DoctorTodoItem,
  DoctorQuickAction,
  fetchDoctorWorkbench,
  toggleDoctorAccepting
} from '../../services/DoctorWorkbenchService';

@Component
export struct DoctorWorkbenchTab {
  onNavigateTab?: (tabKey: string) => void;

  @State workbenchData: DoctorWorkbenchData | null = null;
  @State isLoading: boolean = true;
  @State feedback: string = '';
  @State togglingAccepting: boolean = false;

  aboutToAppear() {
    this.refresh();
  }

  aboutToReappear() {
    this.refresh();
  }

  private refresh(): void {
    this.isLoading = true;
    this.feedback = '';
    fetchDoctorWorkbench()
      .then((data: DoctorWorkbenchData) => {
        this.workbenchData = data;
      })
      .catch((err: Error) => {
        this.feedback = err.message;
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  private handleToggleAccepting(): void {
    if (this.togglingAccepting || !this.workbenchData) return;
    const nextState = !this.workbenchData.profile.accepting;
    this.togglingAccepting = true;
    toggleDoctorAccepting(nextState)
      .then((result: boolean) => {
        if (this.workbenchData) {
          this.workbenchData.profile.accepting = result;
        }
        this.feedback = result ? '已开启接诊' : '已暂停接诊';
      })
      .catch((err: Error) => {
        this.feedback = err.message;
      })
      .finally(() => {
        this.togglingAccepting = false;
      });
  }

  private verificationStatusText(status: string): string {
    switch (status) {
      case 'APPROVED': return '已认证';
      case 'PENDING': return '审核中';
      case 'REJECTED': return '未通过';
      case 'DRAFT': return '草稿';
      default: return '未提交';
    }
  }

  private verificationStatusColor(status: string): string {
    switch (status) {
      case 'APPROVED': return BRAND_GREEN;
      case 'PENDING': return WARM_ACCENT;
      case 'REJECTED': return DANGER_RED;
      default: return MUTED_TEXT;
    }
  }

  build() {
    Column({ space: 14 }) {
      // 顶部标题
      Row() {
        Text('医生工作台')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
        if (!this.isLoading) {
          Text('🔄')
            .fontSize(18)
            .onClick(() => { this.refresh(); })
        }
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 18 })

      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(14)
            .fontColor(MUTED_TEXT)
        }
        .width('100%')
        .padding({ top: 80 })
        .alignItems(HorizontalAlign.Center)
      } else if (!this.workbenchData) {
        Column({ space: 8 }) {
          Text('加载失败')
            .fontSize(14)
            .fontColor(MUTED_TEXT)
          Text(this.feedback)
            .fontSize(12)
            .fontColor(DANGER_RED)
          Text('点击重试')
            .fontSize(14)
            .fontColor(BRAND_GREEN)
            .padding({ top: 8 })
            .onClick(() => { this.refresh(); })
        }
        .width('100%')
        .padding({ top: 80 })
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column({ space: 14 }) {
            // 医生信息卡片
            this.ProfileCard()
            // 数据统计
            this.StatsCard()
            // 待办提醒
            this.TodoCard()
            // 快捷入口
            this.QuickActionsCard()
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

  // ==================== 医生信息卡片 ====================
  @Builder
  ProfileCard() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        // 头像
        Column() {
          if (this.workbenchData!.profile.avatar && this.workbenchData!.profile.avatar.length > 0) {
            Image(this.workbenchData!.profile.avatar)
              .width(56)
              .height(56)
              .borderRadius(28)
              .objectFit(ImageFit.Cover)
          } else {
            Text(this.workbenchData!.profile.name ? this.workbenchData!.profile.name.charAt(0) : '医')
              .fontSize(22)
              .fontColor(Color.White)
          }
        }
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor('#5BA839')
        .justifyContent(FlexAlign.Center)

        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(this.workbenchData!.profile.name || '医生')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(DEEP_TEXT)
            Text(this.verificationStatusText(this.workbenchData!.profile.verificationStatus))
              .fontSize(11)
              .fontColor(this.verificationStatusColor(this.workbenchData!.profile.verificationStatus))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor(this.workbenchData!.profile.verificationStatus === 'APPROVED' ? '#EEF7F1' : '#FFF4E6')
              .borderRadius(8)
          }
          Text([this.workbenchData!.profile.title, this.workbenchData!.profile.department, this.workbenchData!.profile.specialty].filter((s: string) => s && s.length > 0).join(' · '))
            .fontSize(12)
            .fontColor(MUTED_TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }

      // 接诊开关
      Row() {
        Column({ space: 2 }) {
          Text(this.workbenchData!.profile.accepting ? '接诊中' : '已暂停接诊')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.workbenchData!.profile.accepting ? BRAND_GREEN : MUTED_TEXT)
          Text(this.workbenchData!.profile.accepting ? '患者可以向你发起问诊' : '暂停后患者无法发起新问诊')
            .fontSize(11)
            .fontColor(MUTED_TEXT)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row() {
          Text(this.workbenchData!.profile.accepting ? '暂停接诊' : '开启接诊')
            .fontSize(13)
            .fontColor(this.workbenchData!.profile.accepting ? MUTED_TEXT : Color.White)
        }
        .padding({ left: 14, right: 14, top: 7, bottom: 7 })
        .backgroundColor(this.workbenchData!.profile.accepting ? '#F0F0F0' : BRAND_GREEN)
        .borderRadius(18)
        .opacity(this.togglingAccepting ? 0.6 : 1)
        .onClick(() => { this.handleToggleAccepting(); })
      }
      .width('100%')
      .padding({ top: 10 })
      .border({ width: { top: 1 }, color: '#F0F0F0' })
    }
    .width('100%')
    .padding(14)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  // ==================== 数据统计卡片 ====================
  @Builder
  StatsCard() {
    Column({ space: 12 }) {
      Row() {
        Column()
          .width(3)
          .height(14)
          .backgroundColor(BRAND_GREEN)
          .borderRadius(2)
        Text('数据概览')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .margin({ left: 6 })
      }
      .width('100%')

      Column({ space: 10 }) {
        Row({ space: 10 }) {
          this.StatItem('今日问诊', `${this.workbenchData!.stats.todayConsultations}`, '📋', BRAND_GREEN)
          this.StatItem('待回复', `${this.workbenchData!.stats.pendingReplies}`, '💬', WARM_ACCENT)
        }
        .width('100%')

        Row({ space: 10 }) {
          this.StatItem('累计患者', `${this.workbenchData!.stats.totalPatients}`, '👥', '#5B8FF9')
          this.StatItem('好评率', `${this.workbenchData!.stats.goodRate}%`, '⭐', '#F6BD16')
        }
        .width('100%')
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  StatItem(label: string, value: string, icon: string, color: string) {
    Column({ space: 4 }) {
      Row() {
        Text(icon)
          .fontSize(18)
        Text(value)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(color)
          .margin({ left: 4 })
      }
      .width('100%')

      Text(label)
        .fontSize(12)
        .fontColor(MUTED_TEXT)
        .width('100%')
    }
    .layoutWeight(1)
    .padding(12)
    .backgroundColor('#F9FAF9')
    .borderRadius(CARD_RADIUS)
    .alignItems(HorizontalAlign.Start)
  }

  // ==================== 待办提醒卡片 ====================
  @Builder
  TodoCard() {
    Column({ space: 10 }) {
      Row() {
        Column()
          .width(3)
          .height(14)
          .backgroundColor(BRAND_GREEN)
          .borderRadius(2)
        Text('待办提醒')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .margin({ left: 6 })
        Blank()
        if (this.workbenchData!.todos.length > 0 && this.workbenchData!.todos[0].type !== 'all_clear') {
          Text(`${this.workbenchData!.todos.length} 项`)
            .fontSize(12)
            .fontColor(WARM_ACCENT)
        }
      }
      .width('100%')

      Column({ space: 8 }) {
        ForEach(this.workbenchData!.todos, (todo: DoctorTodoItem) => {
          this.TodoItem(todo)
        }, (todo: DoctorTodoItem) => todo.type)
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  TodoItem(todo: DoctorTodoItem) {
    Row({ space: 12 }) {
      Column() {
        Text(todo.icon)
          .fontSize(20)
      }
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(todo.type === 'all_clear' ? '#EEF7F1' : '#FFF4E6')
      .justifyContent(FlexAlign.Center)

      Column({ space: 3 }) {
        Row() {
          Text(todo.title)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(DEEP_TEXT)
          if (todo.count > 0) {
            Text(`${todo.count}`)
              .fontSize(11)
              .fontColor(Color.White)
              .padding({ left: 6, right: 6, top: 1, bottom: 1 })
              .backgroundColor(todo.type === 'active_sanction' || todo.type === 'review_rejected' ? DANGER_RED : WARM_ACCENT)
              .borderRadius(8)
              .margin({ left: 6 })
          }
        }
        Text(todo.description)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (todo.actionTab && todo.actionTab.length > 0) {
        Text('去处理 ▶')
          .fontSize(12)
          .fontColor(BRAND_GREEN)
          .onClick(() => {
            if (this.onNavigateTab) {
              this.onNavigateTab(todo.actionTab);
            }
          })
      }
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#F9FAF9')
    .borderRadius(CARD_RADIUS)
  }

  // ==================== 快捷入口卡片 ====================
  @Builder
  QuickActionsCard() {
    Column({ space: 10 }) {
      Row() {
        Column()
          .width(3)
          .height(14)
          .backgroundColor(BRAND_GREEN)
          .borderRadius(2)
        Text('快捷入口')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .margin({ left: 6 })
      }
      .width('100%')

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(this.workbenchData!.quickActions, (action: DoctorQuickAction) => {
          this.QuickActionItem(action)
        }, (action: DoctorQuickAction) => action.key)
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  QuickActionItem(action: DoctorQuickAction) {
    Column({ space: 6 }) {
      Column() {
        Text(action.icon)
          .fontSize(24)
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor('#F0F7F2')
      .justifyContent(FlexAlign.Center)

      Text(action.title)
        .fontSize(12)
        .fontColor(DEEP_TEXT)
    }
    .width('25%')
    .padding({ top: 8, bottom: 8 })
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (this.onNavigateTab) {
        this.onNavigateTab(action.tab);
      }
    })
  }
}
