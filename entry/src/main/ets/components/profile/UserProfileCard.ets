import { UserProfile } from '../../model/ProfileModels';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

/**
 * 用户资料卡片
 * 展示头像、昵称、用户编号等基本信息
 */
@Component
export struct UserProfileCard {
  @Prop userProfile: UserProfile | null = null;
  @Prop phone: string = '';
  @Prop isAdmin: boolean = false;

  onEditProfile?: () => void;
  onChangeAvatar?: () => void;

  build() {
    Column({ space: 14 }) {
      Row({ space: 14 }) {
        // 头像
        this.AvatarSection()

        // 用户信息
        Column({ space: 4 }) {
          Text(this.displayName())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)

          if (this.userProfile?.userNo) {
            Text(`用户编号：${this.userProfile.userNo}`)
              .fontSize(12)
              .fontColor(MUTED_TEXT)
          }

          if (this.phone.length > 0) {
            Text(this.maskedPhone())
              .fontSize(12)
              .fontColor(MUTED_TEXT)
          }

          if (this.isAdmin) {
            Text('管理员')
              .fontSize(11)
              .fontColor(Color.White)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor(WARM_ACCENT)
              .borderRadius(8)
              .margin({ top: 4 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 编辑按钮
        Button() {
          Text('编辑')
            .fontSize(13)
            .fontColor(BRAND_GREEN)
        }
        .height(32)
        .backgroundColor('rgba(76, 175, 80, 0.1)')
        .borderRadius(16)
        .onClick(() => {
          if (this.onEditProfile) {
            this.onEditProfile();
          }
        })
      }
      .width('100%')

      // 个人信息摘要
      if (this.hasProfileInfo()) {
        Row({ space: 16 }) {
          if (this.userProfile?.gender) {
            this.InfoItem('性别', this.genderText())
          }
          if (this.userProfile?.birthday) {
            this.InfoItem('生日', this.formatBirthday())
          }
          if (this.userProfile?.realName) {
            this.InfoItem('真实姓名', this.userProfile.realName)
          }
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  AvatarSection() {
    Stack() {
      // 头像
      if (this.userProfile?.avatarUrl) {
        Image(this.userProfile.avatarUrl)
          .width(64)
          .height(64)
          .borderRadius(32)
          .objectFit(ImageFit.Cover)
      } else {
        // 默认头像
        Column() {
          Text(this.avatarInitial())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(64)
        .height(64)
        .borderRadius(32)
        .backgroundColor(BRAND_GREEN)
        .justifyContent(FlexAlign.Center)
      }

      // 相机图标（点击换头像）
      Column() {
        Text('📷')
          .fontSize(12)
      }
      .width(24)
      .height(24)
      .borderRadius(12)
      .backgroundColor(Color.White)
      .border({ width: 2, color: CARD_BG })
      .position({ right: 0, bottom: 0 })
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        if (this.onChangeAvatar) {
          this.onChangeAvatar();
        }
      })
    }
    .width(64)
    .height(64)
  }

  @Builder
  InfoItem(label: string, value: string) {
    Column({ space: 2 }) {
      Text(label)
        .fontSize(11)
        .fontColor(MUTED_TEXT)
      Text(value)
        .fontSize(13)
        .fontColor(DEEP_TEXT)
        .fontWeight(FontWeight.Medium)
    }
    .alignItems(HorizontalAlign.Start)
  }

  private displayName(): string {
    if (this.userProfile?.nickname && this.userProfile.nickname.length > 0) {
      return this.userProfile.nickname;
    }
    return '养生达人';
  }

  private avatarInitial(): string {
    const name = this.displayName();
    return name.charAt(0);
  }

  private maskedPhone(): string {
    if (this.phone.length === 11) {
      return this.phone.substring(0, 3) + '****' + this.phone.substring(7);
    }
    return this.phone;
  }

  private hasProfileInfo(): boolean {
    return !!(this.userProfile?.gender || this.userProfile?.birthday || this.userProfile?.realName);
  }

  private genderText(): string {
    switch (this.userProfile?.gender) {
      case 'MALE': return '男';
      case 'FEMALE': return '女';
      case 'OTHER': return '其他';
      default: return '未设置';
    }
  }

  private formatBirthday(): string {
    if (!this.userProfile?.birthday) return '';
    const birthday = this.userProfile.birthday;
    // 计算年龄
    try {
      const birthDate = new Date(birthday);
      const today = new Date();
      let age = today.getFullYear() - birthDate.getFullYear();
      const monthDiff = today.getMonth() - birthDate.getMonth();
      if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
        age--;
      }
      return `${age}岁`;
    } catch {
      return birthday;
    }
  }
}
