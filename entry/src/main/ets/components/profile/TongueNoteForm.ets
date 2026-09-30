import { TongueObservationNote } from '../../model/ProfileModels';
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
export struct TongueNoteForm {
  @State color: string = '淡红';
  @State colorIndex: number = 0;
  @State coating: string = '薄白';
  @State coatingIndex: number = 0;
  @State dryness: string = '适中';
  @State drynessIndex: number = 0;
  @State note: string = '';
  @State errorText: string = '';
  @State successText: string = '';
  @State isSaving: boolean = false;

  onSave?: (note: TongueObservationNote) => Promise<boolean>;

  build() {
    Column({ space: 10 }) {
      Text('舌象文字记录')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('仅记录观察文字，不涉及拍照或识别。')
        .fontSize(12)
        .fontColor(MUTED_TEXT)

      this.SelectField('舌色', this.color, [
        { value: '淡红' },
        { value: '偏红' },
        { value: '偏淡' }
      ], this.colorIndex, (index: number, value: string) => {
        this.colorIndex = index;
        this.color = value;
        this.successText = '';
      })

      this.SelectField('舌苔', this.coating, [
        { value: '薄白' },
        { value: '厚腻' },
        { value: '少苔' }
      ], this.coatingIndex, (index: number, value: string) => {
        this.coatingIndex = index;
        this.coating = value;
        this.successText = '';
      })

      this.SelectField('干湿', this.dryness, [
        { value: '适中' },
        { value: '偏干' },
        { value: '偏湿' }
      ], this.drynessIndex, (index: number, value: string) => {
        this.drynessIndex = index;
        this.dryness = value;
        this.successText = '';
      })

      TextInput({ placeholder: '补充备注', text: this.note })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => {
          this.note = value;
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

      Button(this.isSaving ? '保存中...' : '保存舌象记录')
        .width('100%')
        .height(40)
        .fontColor('#FFFFFF')
        .backgroundColor(BRAND_GREEN)
        .borderRadius(CARD_RADIUS)
        .enabled(!this.isSaving)
        .onClick(() => {
          this.saveTongueNote();
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  SelectField(
    label: string,
    currentValue: string,
    options: SelectOption[],
    selectedIndex: number,
    onPicked: (index: number, value: string) => void
  ) {
    Row({ space: 10 }) {
      Text(label)
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .width(48)
      Select(options)
        .selected(selectedIndex)
        .value(currentValue)
        .selectedOptionFont({ size: 14, weight: FontWeight.Medium })
        .optionFont({ size: 14 })
        .backgroundColor('#EEF7F1')
        .borderRadius(14)
        .layoutWeight(1)
        .onSelect((index: number, value?: string) => {
          onPicked(index, value ? value : currentValue);
        })
    }
    .width('100%')
  }

  private saveTongueNote(): void {
    if (this.isSaving) {
      return;
    }
    if (this.note.trim().length === 0) {
      this.errorText = '请填写一条简短备注。';
      return;
    }
    const payload: TongueObservationNote = {
      color: this.color,
      coating: this.coating,
      dryness: this.dryness,
      note: this.note.trim(),
      recordedAt: new Date().toISOString()
    };
    if (this.onSave) {
      this.isSaving = true;
      this.onSave(payload).then((saved: boolean) => {
        if (saved) {
          this.note = '';
          this.errorText = '';
          this.successText = buildSaveSuccessText('tongueNote');
        } else {
          this.errorText = buildSaveFailureText('tongueNote');
          this.successText = '';
        }
      }).catch(() => {
        this.errorText = buildSaveFailureText('tongueNote');
        this.successText = '';
      }).finally(() => {
        this.isSaving = false;
      });
      return;
    }
    this.errorText = buildSaveFailureText('tongueNote');
    this.successText = '';
  }
}
