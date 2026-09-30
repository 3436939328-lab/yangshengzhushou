import { HealthCardSummary } from '../../model/ProfileModels';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

/**
 * 问诊健康快照
 * 用于在发起问诊时，将用户近期的健康数据摘要分享给医生
 */
@Component
export struct ConsultationHealthSnapshot {
  @Prop healthCard: HealthCardSummary | null = null;
  @Prop shareEnabled: boolean = true;
  @Prop includeTongue: boolean = true;
  @Prop includeIndicators: string[] = ['bloodPressure', 'bloodSugar', 'heartRate', 'sleep'];

  onToggleShare?: (enabled: boolean) => void;
  onToggleTongue?: (enabled: boolean) => void;
  onToggleIndicator?: (key: string, enabled: boolean) => void;

  build() {
    Column({ space: 12 }) {
      // 标题 + 开关
      Row() {
        Column({ space: 2 }) {
          Text('健康快照')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          Text('将近期健康数据摘要分享给医生，帮助医生快速了解情况')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
            .maxLines(2)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 开关（简化版，用 Toggle 样式）
        Text(this.shareEnabled ? '已开启' : '已关闭')
          .fontSize(12)
          .fontColor(this.shareEnabled ? BRAND_GREEN : MUTED_TEXT)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.shareEnabled ? 'rgba(76, 175, 80, 0.1)' : '#F0F0F0')
          .borderRadius(14)
          .onClick(() => {
            if (this.onToggleShare) {
              this.onToggleShare(!this.shareEnabled);
            }
          })
      }
      .width('100%')

      if (this.shareEnabled && this.healthCard) {
        // 快照预览
        Column({ space: 10 }) {
          // 摘要信息
          Row({ space: 10 }) {
            if (this.healthCard.attentionCount > 0) {
              Column({ space: 2 }) {
                Text(`${this.healthCard.attentionCount}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(WARM_ACCENT)
                Text('项需关注')
                  .fontSize(11)
                  .fontColor(MUTED_TEXT)
              }
              .alignItems(HorizontalAlign.Center)
              .padding({ top: 8, bottom: 8, left: 12, right: 12 })
              .backgroundColor('rgba(255, 152, 0, 0.1)')
              .borderRadius(10)
            }

            if (this.healthCard.urgentCount > 0) {
              Column({ space: 2 }) {
                Text(`${this.healthCard.urgentCount}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#E53935')
                Text('项需及时处理')
                  .fontSize(11)
                  .fontColor(MUTED_TEXT)
              }
              .alignItems(HorizontalAlign.Center)
              .padding({ top: 8, bottom: 8, left: 12, right: 12 })
              .backgroundColor('rgba(229, 57, 53, 0.1)')
              .borderRadius(10)
            }

            Text('生成时间：' + this.formatTime(this.healthCard.generatedAt))
              .fontSize(11)
              .fontColor(MUTED_TEXT)
              .layoutWeight(1)
              .textAlign(TextAlign.End)
          }

          // 数据指标列表
          Column({ space: 0 }) {
            if (this.healthCard.bloodPressure && this.includeIndicators.includes('bloodPressure')) {
              this.SnapshotRow(
                '血压',
                `${this.healthCard.bloodPressure.systolic}/${this.healthCard.bloodPressure.diastolic} mmHg`,
                this.healthCard.bloodPressure.stateText,
                this.healthCard.bloodPressure.state === 'IN_RANGE' ? BRAND_GREEN : WARM_ACCENT,
                this.healthCard.bloodPressure.measuredAt,
                'bloodPressure'
              )
            }

            if (this.healthCard.bloodSugar && this.includeIndicators.includes('bloodSugar')) {
              this.SnapshotRow(
                '血糖',
                `${this.healthCard.bloodSugar.value} mmol/L · ${this.healthCard.bloodSugar.typeText}`,
                this.healthCard.bloodSugar.stateText,
                this.healthCard.bloodSugar.state === 'IN_RANGE' ? BRAND_GREEN : WARM_ACCENT,
                this.healthCard.bloodSugar.measuredAt,
                'bloodSugar'
              )
            }

            if (this.healthCard.heartRate && this.includeIndicators.includes('heartRate')) {
              this.SnapshotRow(
                '心率',
                `${this.healthCard.heartRate.value} 次/分`,
                this.healthCard.heartRate.stateText,
                this.healthCard.heartRate.state === 'IN_RANGE' ? BRAND_GREEN : WARM_ACCENT,
                this.healthCard.heartRate.measuredAt,
                'heartRate'
              )
            }

            if (this.healthCard.sleep && this.includeIndicators.includes('sleep')) {
              this.SnapshotRow(
                '睡眠',
                this.healthCard.sleep.totalText,
                this.healthCard.sleep.stateText,
                this.healthCard.sleep.state === 'IN_RANGE' ? BRAND_GREEN : WARM_ACCENT,
                this.healthCard.sleep.measuredAt,
                'sleep'
              )
            }

            if (this.healthCard.body && this.includeIndicators.includes('body')) {
              this.SnapshotRow(
                '体重/BMI',
                `${this.healthCard.body.weightKg}kg · BMI ${this.healthCard.body.bmi}`,
                this.healthCard.body.stateText,
                this.healthCard.body.state === 'IN_RANGE' ? BRAND_GREEN : WARM_ACCENT,
                this.healthCard.body.measuredAt,
                'body'
              )
            }
          }

          // 舌象照片
          if (this.includeTongue) {
            Row({ space: 10 }) {
              Text('👅')
                .fontSize(20)
              Column({ space: 2 }) {
                Text('舌象照片')
                  .fontSize(14)
                  .fontColor(DEEP_TEXT)
                  .fontWeight(FontWeight.Medium)
                Text('辅助医生观察舌象特征')
                  .fontSize(11)
                  .fontColor(MUTED_TEXT)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Text(this.includeTongue ? '已包含' : '不包含')
                .fontSize(12)
                .fontColor(this.includeTongue ? BRAND_GREEN : MUTED_TEXT)
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .backgroundColor(this.includeTongue ? 'rgba(76, 175, 80, 0.1)' : '#F0F0F0')
                .borderRadius(12)
                .onClick(() => {
                  if (this.onToggleTongue) {
                    this.onToggleTongue(!this.includeTongue);
                  }
                })
            }
            .width('100%')
            .padding({ top: 10 })
            .border({ width: { top: 0.5 }, color: '#EEEEEE' })
          }

          // 隐私提示
          Text('🔒 健康数据仅本次问诊医生可见，严格保护隐私')
            .fontSize(11)
            .fontColor(MUTED_TEXT)
            .width('100%')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#FAFAFA')
        .borderRadius(CARD_RADIUS)
      } else if (this.shareEnabled && !this.healthCard) {
        Column({ space: 6 }) {
          Text('暂无健康数据')
            .fontSize(13)
            .fontColor(MUTED_TEXT)
          Text('完善健康数据后，可生成健康快照分享给医生')
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FAFAFA')
        .borderRadius(CARD_RADIUS)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  SnapshotRow(
    label: string,
    value: string,
    status: string,
    statusColor: ResourceColor,
    time: string,
    key: string
  ) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .width(60)

      Text(value)
        .fontSize(13)
        .fontColor(DEEP_TEXT)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)

      Text(status)
        .fontSize(11)
        .fontColor(statusColor)
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .backgroundColor('rgba(76, 175, 80, 0.1)')
        .borderRadius(8)
    }
    .width('100%')
    .height(40)
    .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })
  }

  private formatTime(isoTime: string): string {
    if (!isoTime) return '';
    try {
      const date = new Date(isoTime);
      const now = new Date();
      const diffMs = now.getTime() - date.getTime();
      const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
      if (diffHours < 1) return '刚刚';
      if (diffHours < 24) return `${diffHours}小时前`;
      const diffDays = Math.floor(diffHours / 24);
      if (diffDays < 7) return `${diffDays}天前`;
      return isoTime.split('T')[0];
    } catch {
      return isoTime;
    }
  }
}

/**
 * 问诊评价组件
 */
@Component
export struct ConsultationRatingPanel {
  @Prop consultationId: string = '';
  @Prop visible: boolean = false;

  @State rating: number = 0;
  @State hoverRating: number = 0;
  @State content: string = '';
  @State tags: string[] = [];
  @State isSubmitting: boolean = false;
  @State submitResult: string = '';

  private availableTags: string[] = [
    '回复及时', '专业细致', '解释清晰', '建议实用',
    '态度友好', '很有耐心', '值得信赖', '还需改进'
  ];

  onClose?: () => void;
  onSubmit?: (consultationId: string, rating: number, content: string, tags: string[]) => Promise<boolean>;

  build() {
    if (this.visible) {
    Column({ space: 18 }) {
      // 标题
      Row() {
        Text('评价问诊')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .layoutWeight(1)
        Text('关闭')
          .fontSize(14)
          .fontColor(MUTED_TEXT)
          .onClick(() => {
            if (this.onClose) this.onClose();
          })
      }
      .width('100%')

      // 星级评分
      Column({ space: 10 }) {
        Text('请为本次问诊打分')
          .fontSize(15)
          .fontColor(DEEP_TEXT)
          .fontWeight(FontWeight.Medium)

        Row({ space: 8 }) {
          ForEach([1, 2, 3, 4, 5], (star: number) => {
            Text(star <= (this.hoverRating || this.rating) ? '★' : '☆')
              .fontSize(36)
              .fontColor(star <= (this.hoverRating || this.rating) ? '#FFC107' : '#E0E0E0')
              .onClick(() => {
                this.rating = star;
              })
          }, (star: number) => star.toString())
        }

        Text(this.ratingText())
          .fontSize(13)
          .fontColor(WARM_ACCENT)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // 标签选择
      Column({ space: 8 }) {
        Text('选择标签（可多选）')
          .fontSize(14)
          .fontColor(DEEP_TEXT)
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.availableTags, (tag: string) => {
            Text(tag)
              .fontSize(12)
              .fontColor(this.tags.includes(tag) ? BRAND_GREEN : MUTED_TEXT)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .margin({ right: 8, bottom: 8 })
              .backgroundColor(this.tags.includes(tag) ? 'rgba(76, 175, 80, 0.1)' : '#F5F5F5')
              .border({ width: 1, color: this.tags.includes(tag) ? BRAND_GREEN : 'transparent' })
              .borderRadius(14)
              .onClick(() => {
                const idx = this.tags.indexOf(tag);
                if (idx >= 0) {
                  this.tags.splice(idx, 1);
                } else {
                  this.tags.push(tag);
                }
              })
          }, (tag: string) => tag)
        }
      }
      .width('100%')

      // 文字评价
      Column({ space: 8 }) {
        Text('评价内容（可选）')
          .fontSize(14)
          .fontColor(DEEP_TEXT)
        TextArea({ text: this.content, placeholder: '分享您的问诊体验...' })
          .height(100)
          .fontSize(14)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .onChange((value: string) => {
            this.content = value;
          })
      }
      .width('100%')

      // 结果提示
      if (this.submitResult.length > 0) {
        Text(this.submitResult)
          .fontSize(13)
          .fontColor(this.submitResult.indexOf('成功') >= 0 ? BRAND_GREEN : WARM_ACCENT)
      }

      // 提交按钮
      Button() {
        Text(this.isSubmitting ? '提交中...' : '提交评价')
          .fontSize(15)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height(46)
      .backgroundColor(this.rating > 0 ? BRAND_GREEN : '#BDBDBD')
      .borderRadius(23)
      .enabled(this.rating > 0 && !this.isSubmitting)
      .onClick(() => {
        this.handleSubmit();
      })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(CARD_RADIUS)
    }
  }

  private ratingText(): string {
    const rating = this.hoverRating || this.rating;
    switch (rating) {
      case 1: return '很差';
      case 2: return '较差';
      case 3: return '一般';
      case 4: return '满意';
      case 5: return '非常满意';
      default: return '请点击星星评分';
    }
  }

  private handleSubmit(): void {
    if (this.rating === 0 || this.isSubmitting) return;

    this.isSubmitting = true;
    this.submitResult = '';

    if (this.onSubmit) {
      this.onSubmit(this.consultationId, this.rating, this.content, this.tags)
        .then((success: boolean) => {
          if (success) {
            this.submitResult = '评价提交成功，感谢您的反馈！';
          } else {
            this.submitResult = '提交失败，请稍后重试';
          }
        })
        .catch(() => {
          this.submitResult = '提交失败，请稍后重试';
        })
        .finally(() => {
          this.isSubmitting = false;
        });
    }
  }
}
