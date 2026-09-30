import { HealthIndicatorEntry } from '../../model/ProfileModels';
import { buildSaveFailureText, buildSaveSuccessText } from '../../services/SaveFeedbackService';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';

@Component
export struct HealthIndicatorForm {
  @State name: string = '血压';
  @State value: string = '';
  @State unit: string = 'mmHg';
  @State errorText: string = '';
  @State successText: string = '';
  @State isSaving: boolean = false;

  onSave?: (entry: HealthIndicatorEntry) => Promise<boolean>;

  build() {
    Column({ space: 10 }) {
      Text('健康指标手动录入')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('先支持手动记录，后续可替换为设备同步。')
        .fontSize(12)
        .fontColor(MUTED_TEXT)

      Row({ space: 8 }) {
        this.TypeChip('血压', 'mmHg')
        this.TypeChip('血糖', 'mmol/L')
        this.TypeChip('睡眠', '小时')
        this.TypeChip('步数', '步')
      }

      TextInput({ placeholder: `请输入${this.name}数值`, text: this.value })
        .height(42)
        .fontSize(14)
        .onChange((input: string) => {
          this.value = input;
          this.errorText = '';
          this.successText = '';
        })

      if (this.errorText.length > 0) {
        Text(this.errorText)
          .fontSize(12)
          .fontColor(WARM_ACCENT)
      }

      if (this.successText.length > 0) {
        Text(this.successText)
          .fontSize(12)
          .fontColor(BRAND_GREEN)
      }

      Button(this.isSaving ? '保存中...' : '保存健康指标')
        .width('100%')
        .height(40)
        .fontColor('#FFFFFF')
        .backgroundColor(BRAND_GREEN)
        .borderRadius(CARD_RADIUS)
        .enabled(!this.isSaving)
        .onClick(() => {
          if (this.isSaving) {
            return;
          }
          if (this.value.trim().length === 0) {
            this.errorText = '请填写指标数值';
            return;
          }
          const payload: HealthIndicatorEntry = {
            name: this.name,
            value: this.value.trim(),
            unit: this.unit,
            recordedAt: new Date().toISOString()
          };
          if (this.onSave) {
            this.isSaving = true;
            this.onSave(payload).then((saved: boolean) => {
              if (saved) {
                this.value = '';
                this.errorText = '';
                this.successText = buildSaveSuccessText('healthIndicator');
              } else {
                this.errorText = buildSaveFailureText('healthIndicator');
                this.successText = '';
              }
            }).catch(() => {
              this.errorText = buildSaveFailureText('healthIndicator');
              this.successText = '';
            }).finally(() => {
              this.isSaving = false;
            });
            return;
          }
          this.errorText = buildSaveFailureText('healthIndicator');
          this.successText = '';
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  TypeChip(nextName: string, nextUnit: string) {
    Text(nextName)
      .fontSize(12)
      .fontColor(this.name === nextName ? '#FFFFFF' : BRAND_GREEN)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor(this.name === nextName ? BRAND_GREEN : '#EEF7F1')
      .borderRadius(14)
      .onClick(() => {
        this.name = nextName;
        this.unit = nextUnit;
        this.successText = '';
      })
  }
}
