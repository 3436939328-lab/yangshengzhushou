import {
  ShareCategory,
  FamilyRelationStatus,
  FamilyMemberCard,
  ShareGroup,
  ShareCategoryConfigItem
} from '../../model/FamilyModels';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import { SectionTitle } from '../cards/CommonCards';

/**
 * 共享类别配置
 */
const SHARE_CATEGORY_CONFIG: ShareCategoryConfigItem[] = [
  { category: ShareCategory.BLOOD_PRESSURE, label: '血压', description: '收缩压、舒张压、脉搏', icon: '🩺', group: 'vital' },
  { category: ShareCategory.BLOOD_SUGAR, label: '血糖', description: '血糖值及测量类型', icon: '🩸', group: 'vital' },
  { category: ShareCategory.HEART_RATE, label: '心率', description: '心率测量记录', icon: '❤️', group: 'vital' },
  { category: ShareCategory.BLOOD_OXYGEN, label: '血氧', description: '血氧饱和度', icon: '💧', group: 'vital' },
  { category: ShareCategory.TEMPERATURE, label: '体温', description: '体温测量记录', icon: '🌡️', group: 'vital' },
  { category: ShareCategory.BODY, label: '体格', description: '身高、体重、BMI', icon: '📏', group: 'vital' },
  { category: ShareCategory.SLEEP, label: '睡眠', description: '睡眠时长及分期', icon: '😴', group: 'lifestyle' },
  { category: ShareCategory.EXERCISE, label: '运动', description: '运动时长及类型', icon: '🏃', group: 'lifestyle' },
  { category: ShareCategory.WATER, label: '饮水', description: '每日饮水量', icon: '💦', group: 'lifestyle' },
  { category: ShareCategory.TONGUE, label: '舌象照片', description: '舌象照片及AI分析', icon: '👅', group: 'analysis' },
  { category: ShareCategory.AI_ANALYSIS, label: 'AI分析', description: '体质分析、养生建议', icon: '🤖', group: 'analysis' },
  { category: ShareCategory.ABNORMAL_NOTIFY, label: '异常提醒', description: '异常指标实时通知', icon: '🔔', group: 'notify' },
];

/**
 * 亲人授权管理组件
 * 用于管理对某位亲人的共享授权
 */
@Component
export struct FamilyShareSettings {
  @Prop member: FamilyMemberCard | null = null;
  @Prop isViewMode: boolean = true;

  @State grantedCategories: ShareCategory[] = [];
  @State historyWindowDays: number = 7;
  @State isSaving: boolean = false;
  @State saveFeedback: string = '';

  onSave?: (categories: ShareCategory[], historyDays: number) => Promise<boolean>;
  onClose?: () => void;

  aboutToAppear() {
    if (this.member) {
      this.grantedCategories = this.member.grantedCategories;
      this.historyWindowDays = this.member.historyWindowDays;
    }
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        if (this.onClose) {
          Text('← 返回')
            .fontSize(15)
            .fontColor(BRAND_GREEN)
            .onClick(() => {
              if (this.onClose) this.onClose();
            })
        }
        Text(this.isViewMode ? '对方对我的授权' : '共享设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .margin({ left: this.onClose ? 12 : 0 })
          .layoutWeight(1)
      }
      .width('100%')

      if (!this.member) {
        Text('暂无数据')
          .fontSize(14)
          .fontColor(MUTED_TEXT)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            this.MemberInfoCard()
            this.ShareCategoriesSection()
            this.HistoryWindowSection()
            this.NoteSection()

            if (!this.isViewMode) {
              if (this.saveFeedback.length > 0) {
                Text(this.saveFeedback)
                  .fontSize(13)
                  .fontColor(this.saveFeedback.indexOf('成功') >= 0 ? BRAND_GREEN : WARM_ACCENT)
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }

              Button() {
                Text(this.isSaving ? '保存中...' : '保存设置')
                  .fontSize(16)
                  .fontColor(Color.White)
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')
              .height(48)
              .backgroundColor(BRAND_GREEN)
              .borderRadius(24)
              .enabled(!this.isSaving)
              .margin({ top: 8, bottom: 20 })
              .onClick(() => {
                this.handleSave();
              })
            }
          }
          .width('100%')
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 18, right: 18, top: 14 })
  }

  @Builder
  MemberInfoCard() {
    if (this.member) {
      Row({ space: 12 }) {
        Circle({ width: 48, height: 48 })
          .fill(BRAND_GREEN)

        Column({ space: 4 }) {
          Text(this.member.displayName)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          Text(`关系：${this.member.relationLabel}`)
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.member.status === FamilyRelationStatus.ACTIVE ? '已确认' : '待确认')
          .fontSize(12)
          .fontColor(this.member.status === FamilyRelationStatus.ACTIVE ? BRAND_GREEN : WARM_ACCENT)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor(
            this.member.status === FamilyRelationStatus.ACTIVE
              ? 'rgba(76, 175, 80, 0.1)'
              : 'rgba(255, 152, 0, 0.1)'
          )
          .borderRadius(12)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
    }
  }

  @Builder
  ShareCategoriesSection() {
    Column({ space: 12 }) {
      SectionTitle('共享数据类别')
      this.CategoryGroup('生命体征', 'vital')
      this.CategoryGroup('生活方式', 'lifestyle')
      this.CategoryGroup('分析结果', 'analysis')
      this.CategoryGroup('通知设置', 'notify')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  CategoryGroup(title: string, group: string) {
    Column({ space: 0 }) {
      Text(title)
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 6 })

      Column({ space: 0 }) {
        ForEach(SHARE_CATEGORY_CONFIG.filter((c: ShareCategoryConfigItem) => c.group === group), (item: ShareCategoryConfigItem) => {
          this.CategoryRow(item)
        }, (item: ShareCategoryConfigItem) => item.category)
      }
    }
    .width('100%')
    .margin({ top: 8 })
  }

  @Builder
  CategoryRow(item: ShareCategoryConfigItem) {
    Row({ space: 12 }) {
      Text(item.icon)
        .fontSize(20)

      Column({ space: 2 }) {
        Text(item.label)
          .fontSize(14)
          .fontColor(DEEP_TEXT)
          .fontWeight(FontWeight.Medium)
        Text(item.description)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.grantedCategories.includes(item.category) ? '已开启' : '未开启')
        .fontSize(12)
        .fontColor(this.grantedCategories.includes(item.category) ? BRAND_GREEN : MUTED_TEXT)
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor(this.grantedCategories.includes(item.category) ? 'rgba(76, 175, 80, 0.1)' : '#F0F0F0')
        .borderRadius(12)
        .enabled(!this.isViewMode)
        .onClick(() => {
          if (!this.isViewMode) {
            this.toggleCategory(item.category);
          }
        })
    }
    .width('100%')
    .height(52)
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
  }

  private toggleCategory(category: ShareCategory): void {
    const idx = this.grantedCategories.indexOf(category);
    if (idx >= 0) {
      this.grantedCategories.splice(idx, 1);
    } else {
      this.grantedCategories.push(category);
    }
  }

  @Builder
  HistoryWindowSection() {
    Column({ space: 10 }) {
      Text('可查看历史范围')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(DEEP_TEXT)

      Text('对方可查看在此时间范围内的历史数据')
        .fontSize(12)
        .fontColor(MUTED_TEXT)

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach([7, 30, 90, 0], (days: number) => {
          Text(days === 0 ? '全部' : `${days}天`)
            .fontSize(13)
            .fontColor(this.historyWindowDays === days ? Color.White : DEEP_TEXT)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .margin({ right: 8, bottom: 8 })
            .backgroundColor(this.historyWindowDays === days ? BRAND_GREEN : '#F0F0F0')
            .borderRadius(16)
            .enabled(!this.isViewMode)
            .onClick(() => {
              if (!this.isViewMode) {
                this.historyWindowDays = days;
              }
            })
        }, (days: number) => days.toString())
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  NoteSection() {
    Column({ space: 8 }) {
      Text('🔒 隐私说明')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(DEEP_TEXT)
      Text('• 仅您授权的数据类别会对对方可见')
        .fontSize(12)
        .fontColor(MUTED_TEXT)
      Text('• 您可以随时修改或撤销共享授权')
        .fontSize(12)
        .fontColor(MUTED_TEXT)
      Text('• 解除关系后，所有共享数据将立即失效')
        .fontSize(12)
        .fontColor(MUTED_TEXT)
      Text('• 健康数据仅用于亲友间健康关怀，不得用于其他用途')
        .fontSize(12)
        .fontColor(MUTED_TEXT)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('rgba(76, 175, 80, 0.05)')
    .borderRadius(CARD_RADIUS)
    .alignItems(HorizontalAlign.Start)
  }

  private handleSave(): void {
    if (this.isSaving || !this.onSave) return;

    this.isSaving = true;
    this.saveFeedback = '';

    this.onSave(this.grantedCategories, this.historyWindowDays)
      .then((success: boolean) => {
        this.saveFeedback = success ? '设置已保存' : '保存失败，请稍后重试';
      })
      .catch(() => {
        this.saveFeedback = '保存失败，请稍后重试';
      })
      .finally(() => {
        this.isSaving = false;
      });
  }
}
