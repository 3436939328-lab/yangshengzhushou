import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import {
  buildDoctorProfileIdentityText,
  buildDoctorProfileSaveFailureText,
  buildDoctorProfileValidationText,
  createEmptyDoctorProfile,
  DoctorProfileForm,
  fetchDoctorProfile,
  saveDoctorProfile
} from '../../services/DoctorProfileService';

@Component
export struct DoctorProfileTab {
  @Prop userId: string;

  @State profile: DoctorProfileForm = createEmptyDoctorProfile('');
  @State feedback: string = '';

  aboutToAppear() {
    this.profile = createEmptyDoctorProfile(this.userId);
    this.loadProfile();
  }

  build() {
    Column({ space: 14 }) {
      Text('医生资料')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('维护用户可选择的医生展示信息，保存后会出现在普通用户的一对一问诊医生列表中。')
        .fontSize(14)
        .fontColor(MUTED_TEXT)
        .lineHeight(22)

      this.ProfileForm()
      this.PreviewPanel()
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  ProfileForm() {
    Column({ space: 10 }) {
      Text('资料编辑')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      TextInput({ placeholder: '医生姓名', text: this.profile.doctorName })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => {
          this.profile = {
            id: this.profile.id,
            userId: this.profile.userId,
            doctorName: value,
            title: this.profile.title,
            specialty: this.profile.specialty,
            introduction: this.profile.introduction
          };
        })
      TextInput({ placeholder: '职称，例如：主治医师', text: this.profile.title })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => {
          this.profile = {
            id: this.profile.id,
            userId: this.profile.userId,
            doctorName: this.profile.doctorName,
            title: value,
            specialty: this.profile.specialty,
            introduction: this.profile.introduction
          };
        })
      TextInput({ placeholder: '擅长方向，例如：睡眠调理、慢病养生', text: this.profile.specialty })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => {
          this.profile = {
            id: this.profile.id,
            userId: this.profile.userId,
            doctorName: this.profile.doctorName,
            title: this.profile.title,
            specialty: value,
            introduction: this.profile.introduction
          };
        })
      TextInput({ placeholder: '服务说明', text: this.profile.introduction })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => {
          this.profile = {
            id: this.profile.id,
            userId: this.profile.userId,
            doctorName: this.profile.doctorName,
            title: this.profile.title,
            specialty: this.profile.specialty,
            introduction: value
          };
        })
      Button('保存资料')
        .width('100%')
        .height(42)
        .fontColor('#FFFFFF')
        .backgroundColor(BRAND_GREEN)
        .borderRadius(CARD_RADIUS)
        .onClick(() => {
          this.saveProfile();
        })
      if (this.feedback.length > 0) {
        Text(this.feedback)
          .fontSize(12)
          .fontColor(this.feedback.indexOf('成功') >= 0 ? BRAND_GREEN : WARM_ACCENT)
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  PreviewPanel() {
    Column({ space: 8 }) {
      Text('展示预览')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text(this.profile.doctorName.length > 0 ? this.profile.doctorName : '未填写姓名')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text(this.profile.title.length > 0 ? this.profile.title : '未填写职称')
        .fontSize(13)
        .fontColor(BRAND_GREEN)
      Text(this.profile.specialty.length > 0 ? this.profile.specialty : '未填写擅长方向')
        .fontSize(13)
        .fontColor(MUTED_TEXT)
      Text(this.profile.introduction.length > 0 ? this.profile.introduction : '未填写服务说明')
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .lineHeight(20)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  private loadProfile(): void {
    if (this.userId.length === 0) {
      return;
    }
    fetchDoctorProfile(this.userId).then((profile: DoctorProfileForm) => {
      this.profile = profile;
    }).catch(() => {
      this.profile = createEmptyDoctorProfile(this.userId);
      this.feedback = '医生资料暂时加载失败。';
    });
  }

  private saveProfile(): void {
    const identityText = buildDoctorProfileIdentityText(this.userId);
    if (identityText.length > 0) {
      this.feedback = identityText;
      return;
    }
    const validationText = buildDoctorProfileValidationText(this.profile);
    if (validationText.length > 0) {
      this.feedback = validationText;
      return;
    }
    const profile: DoctorProfileForm = {
      id: this.profile.id,
      userId: this.userId,
      doctorName: this.profile.doctorName.trim(),
      title: this.profile.title.trim(),
      specialty: this.profile.specialty.trim(),
      introduction: this.profile.introduction.trim()
    };
    saveDoctorProfile(profile).then((saved: boolean) => {
      this.feedback = saved ? '医生资料保存成功。' : buildDoctorProfileSaveFailureText('');
      if (saved) {
        this.profile = profile;
      }
    }).catch((error: Error) => {
      this.feedback = buildDoctorProfileSaveFailureText(error.message);
    });
  }
}
