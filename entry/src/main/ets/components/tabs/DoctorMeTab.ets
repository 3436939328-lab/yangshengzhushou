import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import { DoctorProfileForm, fetchDoctorProfile } from '../../services/DoctorProfileService';

interface DoctorMeTabParams {
  userId: string;
  onOpenProfile?: () => void;
  onOpenComplaints?: () => void;
  onOpenRatings?: () => void;
  onOpenRewards?: () => void;
  onLogout?: () => void;
}

interface MenuItem {
  key: string;
  icon: string;
  title: string;
  subtitle: string;
  badge?: string;
}

@Component
export struct DoctorMeTab {
  @Prop userId: string;
  onOpenProfile?: () => void;
  onOpenComplaints?: () => void;
  onOpenRatings?: () => void;
  onOpenRewards?: () => void;
  onLogout?: () => void;

  @State profile: DoctorProfileForm | null = null;
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.refresh();
  }

  aboutToReappear() {
    this.refresh();
  }

  private refresh(): void {
    if (this.userId.length === 0) return;
    this.isLoading = true;
    fetchDoctorProfile(this.userId)
      .then((profile: DoctorProfileForm) => {
        this.profile = profile;
      })
      .catch(() => {
        this.profile = null;
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  private verificationStatusText(status: string): string {
    switch (status) {
      case 'APPROVED': return '已认证';
      case 'PENDING': return '审核中';
      case 'REJECTED': return '未通过';
      case 'NEED_INFO': return '需补充';
      case 'DRAFT': return '草稿';
      default: return '未提交';
    }
  }

  private verificationStatusColor(status: string): string {
    switch (status) {
      case 'APPROVED': return BRAND_GREEN;
      case 'PENDING': return WARM_ACCENT;
      case 'REJECTED': return '#E54D42';
      case 'NEED_INFO': return WARM_ACCENT;
      default: return MUTED_TEXT;
    }
  }

  private menuItems(): MenuItem[] {
    const items: MenuItem[] = [
      {
        key: 'profile',
        icon: '📝',
        title: '医生资料',
        subtitle: '个人信息、资质审核、接诊设置'
      },
      {
        key: 'ratings',
        icon: '⭐',
        title: '我的评价',
        subtitle: '查看患者评价和评分'
      },
      {
        key: 'complaints',
        icon: '📢',
        title: '投诉与申诉',
        subtitle: '投诉处理、处罚记录、申诉'
      },
      {
        key: 'rewards',
        icon: '🎁',
        title: '积分奖励',
        subtitle: '查看积分和奖励'
      }
    ];
    return items;
  }

  private handleMenuClick(key: string): void {
    switch (key) {
      case 'profile':
        if (this.onOpenProfile) this.onOpenProfile();
        break;
      case 'complaints':
        if (this.onOpenComplaints) this.onOpenComplaints();
        break;
      case 'ratings':
        if (this.onOpenRatings) this.onOpenRatings();
        break;
      case 'rewards':
        if (this.onOpenRewards) this.onOpenRewards();
        break;
    }
  }

  build() {
    Column({ space: 0 }) {
      Text('我的')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
        .width('100%')
        .padding({ left: 18, top: 18, bottom: 14 })

      Scroll() {
        Column({ space: 14 }) {
          // 医生信息卡片
          this.ProfileHeaderCard()

          // 功能菜单
          this.MenuSection()

          // 退出登录
          this.LogoutButton()
        }
        .width('100%')
        .padding({ left: 14, right: 14, bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 医生信息卡片 ====================
  @Builder
  ProfileHeaderCard() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        // 头像
        if (this.profile && this.profile.avatar && this.profile.avatar.length > 0) {
          Image(this.profile.avatar)
            .width(60)
            .height(60)
            .borderRadius(30)
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            Text(this.profile && this.profile.doctorName ? this.profile.doctorName.charAt(0) : '医')
              .fontSize(22)
              .fontColor(Color.White)
          }
          .width(60)
          .height(60)
          .borderRadius(30)
          .backgroundColor('#5BA839')
          .justifyContent(FlexAlign.Center)
        }

        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(this.profile && this.profile.doctorName ? this.profile.doctorName : '医生')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(DEEP_TEXT)
            Text(this.profile
              ? this.verificationStatusText(this.profile.verificationStatus)
              : '未认证')
              .fontSize(11)
              .fontColor(this.profile
                ? this.verificationStatusColor(this.profile.verificationStatus)
                : MUTED_TEXT)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
          }
          Text([
            this.profile?.title,
            this.profile?.department
          ].filter(s => s && s.length > 0).join(' · ') || '完善资料后展示')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.profile && this.profile.specialty) {
            Text('擅长：' + this.profile.specialty)
              .fontSize(12)
              .fontColor(MUTED_TEXT)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('编辑')
          .fontSize(13)
          .fontColor(BRAND_GREEN)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#EEF7F1')
          .borderRadius(14)
          .onClick(() => {
            if (this.onOpenProfile) this.onOpenProfile();
          })
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  // ==================== 功能菜单 ====================
  @Builder
  MenuSection() {
    Column({ space: 0 }) {
      ForEach(this.menuItems(), (item: MenuItem) => {
        this.MenuItemRow(item)
        if (item.key !== 'rewards') {
          Divider()
            .color('#F0F0F0')
            .margin({ left: 50 })
        }
      }, (item: MenuItem) => item.key)
    }
    .width('100%')
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  MenuItemRow(item: MenuItem) {
    Row({ space: 12 }) {
      Column() {
        Text(item.icon)
          .fontSize(20)
      }
      .width(32)
      .height(32)
      .justifyContent(FlexAlign.Center)

      Column({ space: 2 }) {
        Text(item.title)
          .fontSize(15)
          .fontColor(DEEP_TEXT)
          .fontWeight(FontWeight.Medium)
        Text(item.subtitle)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (item.badge && item.badge.length > 0) {
        Text(item.badge)
          .fontSize(11)
          .fontColor(Color.White)
          .padding({ left: 6, right: 6, top: 1, bottom: 1 })
          .backgroundColor('#E54D42')
          .borderRadius(8)
          .margin({ right: 4 })
      }

      Text('›')
        .fontSize(20)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .height(56)
    .padding({ left: 14, right: 14 })
    .onClick(() => {
      this.handleMenuClick(item.key);
    })
  }

  // ==================== 退出登录 ====================
  @Builder
  LogoutButton() {
    Row() {
      Text('退出登录')
        .fontSize(15)
        .fontColor('#E54D42')
    }
    .width('100%')
    .height(48)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.onLogout) this.onLogout();
    })
  }
}
