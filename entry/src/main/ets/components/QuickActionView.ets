import { common } from '@kit.AbilityKit';
import { HealthProfile, QuestionnaireRecord, TongueObservationNote, TongueImageRecord } from '../model/ProfileModels';
import { createPreferencesHealthProfileRepository } from '../services/ProfileRepository';
import { QuestionnaireFlow } from './questionnaire/QuestionnaireFlow';
import { TongueNoteForm } from './profile/TongueNoteForm';
import { TongueImageView } from './profile/TongueImageView';
import { BRAND_GREEN } from '../theme/WellnessTheme';

@Component
export struct QuickActionView {
  @Prop action: string;
  @Prop userId: string;
  onBack: () => void = () => {};
  onProfileChanged: (profile: HealthProfile) => void = () => {};
  @State feedback: string = '';
  @State tongueImages: TongueImageRecord[] = [];
  @State tongueLoading: boolean = false;
  private activeView: boolean = false;
  aboutToAppear(): void { this.activeView = true; }
  aboutToDisappear(): void { this.activeView = false; }

  build() {
    Column({ space: 14 }) {
      Button('返回首页').onClick(() => { this.onBack(); })
        .fontColor(BRAND_GREEN).backgroundColor(Color.Transparent)
      if (this.action === '体质问卷') {
        QuestionnaireFlow({ onSubmit: async (record: QuestionnaireRecord): Promise<boolean> => {
          try {
            const repository = createPreferencesHealthProfileRepository(this.getUIContext().getHostContext() as common.UIAbilityContext, this.userId);
            const profile = await repository.saveQuestionnaireRecord(record);
            if (!this.activeView) return true;
            this.onProfileChanged(profile);
            this.feedback = '体质记录已保存';
            return true;
          } catch (error) { return false; }
        } })
      } else if (this.action === '舌象记录') {
        TongueImageView({
          images: this.tongueImages,
          isLoading: this.tongueLoading,
          onBack: () => { this.onBack(); },
          onUploadImage: (uri: string, source: 'CAMERA' | 'ALBUM') => {
            this.feedback = `已选择照片（${source === 'CAMERA' ? '拍摄' : '相册'}），分析功能开发中`;
          }
        })
        TongueNoteForm({ onSave: async (note: TongueObservationNote): Promise<boolean> => {
          try {
            const repository = createPreferencesHealthProfileRepository(this.getUIContext().getHostContext() as common.UIAbilityContext, this.userId);
            const profile = await repository.saveTongueNote(note);
            if (!this.activeView) return true;
            this.onProfileChanged(profile);
            this.feedback = '舌象文字记录已保存';
            return true;
          } catch (error) { return false; }
        } })
      } else {
        TongueNoteForm({ onSave: async (note: TongueObservationNote): Promise<boolean> => {
          try {
            const repository = createPreferencesHealthProfileRepository(this.getUIContext().getHostContext() as common.UIAbilityContext, this.userId);
            const profile = await repository.saveTongueNote(note);
            if (!this.activeView) return true;
            this.onProfileChanged(profile);
            this.feedback = '舌象记录已保存';
            return true;
          } catch (error) { return false; }
        } })
      }
      if (this.feedback.length > 0) {
        Text(this.feedback).fontColor(BRAND_GREEN)
      }
    }.width('100%').padding(18)
  }
}
