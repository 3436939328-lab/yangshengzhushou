import {
  QuestionnaireAnswer,
  QuestionnaireOption,
  QuestionnaireQuestion,
  QuestionnaireRecord
} from '../../model/ProfileModels';
import {
  buildQuestionnaireRecord,
  getConstitutionQuestions
} from '../../services/QuestionnaireService';
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
export struct QuestionnaireFlow {
  @State selectedScores: number[] = [0, 0, 0, 0, 0, 0];
  @State resultText: string = '';
  @State saveFeedbackText: string = '';
  @State saveFeedbackFailed: boolean = false;
  @State isSaving: boolean = false;

  private questions: QuestionnaireQuestion[] = getConstitutionQuestions();
  onSubmit?: (record: QuestionnaireRecord) => Promise<boolean>;

  build() {
    Column({ space: 12 }) {
      Text('体质问卷')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('根据近两周感受选择最接近的一项，结果仅用于日常养生参考。')
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .lineHeight(20)

      ForEach(this.questions, (question: QuestionnaireQuestion) => {
        this.QuestionBlock(question, this.questionIndexOf(question.id))
      }, (question: QuestionnaireQuestion) => question.id)

      Button(this.isSaving ? '保存中...' : '生成体质结果')
        .width('100%')
        .height(42)
        .fontSize(15)
        .fontColor('#FFFFFF')
        .backgroundColor(BRAND_GREEN)
        .borderRadius(CARD_RADIUS)
        .enabled(!this.isSaving)
        .onClick(() => {
          if (this.isSaving) {
            return;
          }
          const answers: QuestionnaireAnswer[] = [];
          for (let index = 0; index < this.questions.length; index++) {
            const score = this.selectedScores[index];
            answers.push({
              questionId: this.questions[index].id,
              score,
              label: this.questions[index].options[score].label
            });
          }
          const record = buildQuestionnaireRecord(answers, new Date().toISOString());
          this.resultText = `问卷初筛：${record.constitution.name}`;
          if (this.onSubmit) {
            this.isSaving = true;
            this.onSubmit(record).then((saved: boolean) => {
              if (saved) {
                this.saveFeedbackText = buildSaveSuccessText('questionnaire');
                this.saveFeedbackFailed = false;
              } else {
                this.saveFeedbackText = buildSaveFailureText('questionnaire');
                this.saveFeedbackFailed = true;
              }
            }).catch(() => {
              this.saveFeedbackText = buildSaveFailureText('questionnaire');
              this.saveFeedbackFailed = true;
            }).finally(() => {
              this.isSaving = false;
            });
          } else {
            this.saveFeedbackText = buildSaveFailureText('questionnaire');
            this.saveFeedbackFailed = true;
          }
        })

      if (this.resultText.length > 0) {
        Text(this.resultText)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(BRAND_GREEN)
        Text('问卷结果已保存后，可由大模型结合实时天气和健康档案生成调理建议。')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .lineHeight(20)
        if (this.saveFeedbackText.length > 0) {
          Text(this.saveFeedbackText)
            .fontSize(12)
            .fontColor(this.saveFeedbackFailed ? WARM_ACCENT : BRAND_GREEN)
            .lineHeight(18)
        }
        Text('本结果不能替代医生诊断，明显不适请及时就医。')
          .fontSize(12)
          .fontColor(WARM_ACCENT)
          .lineHeight(18)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  private questionIndexOf(questionId: string): number {
    for (let index = 0; index < this.questions.length; index++) {
      if (this.questions[index].id === questionId) {
        return index;
      }
    }
    return 0;
  }

  @Builder
  QuestionBlock(question: QuestionnaireQuestion, questionIndex: number) {
    Column({ space: 8 }) {
      Text(question.title)
        .fontSize(14)
        .fontColor(DEEP_TEXT)
        .lineHeight(20)
      Row({ space: 8 }) {
        ForEach(question.options, (option: QuestionnaireOption) => {
          Text(option.label)
            .fontSize(12)
            .fontColor(this.selectedScores[questionIndex] === option.score ? '#FFFFFF' : BRAND_GREEN)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(this.selectedScores[questionIndex] === option.score ? BRAND_GREEN : '#EEF7F1')
            .borderRadius(14)
            .onClick(() => {
              const nextScores = this.selectedScores.slice();
              nextScores[questionIndex] = option.score;
              this.selectedScores = nextScores;
              this.saveFeedbackText = '';
              this.saveFeedbackFailed = false;
            })
        }, (option: QuestionnaireOption) => `${question.id}-${option.score}`)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}
