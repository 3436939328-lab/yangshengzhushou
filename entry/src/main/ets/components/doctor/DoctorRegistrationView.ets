import { picker } from '@kit.CoreFileKit';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import {
  DoctorProfileSnapshot,
  DoctorQualificationData,
  DoctorReviewItem,
  ensureDraft,
  fetchMyQualification,
  saveDraft,
  submitForReview
} from '../../services/DoctorReviewService';
import { uploadImage } from '../../services/AssetService';

interface RegistrationStep {
  key: string;
  label: string;
}

interface DraftFormState {
  doctorName: string;
  title: string;
  department: string;
  specialty: string;
  introduction: string;
  avatar: string;
  licenseNumber: string;
  licenseImageUrls: string;
}

function emptyForm(): DraftFormState {
  return {
    doctorName: '',
    title: '',
    department: '',
    specialty: '',
    introduction: '',
    avatar: '',
    licenseNumber: '',
    licenseImageUrls: ''
  };
}

function formFromProfile(profile?: DoctorProfileSnapshot): DraftFormState {
  if (!profile) {
    return emptyForm();
  }
  return {
    doctorName: profile.doctorName ? profile.doctorName : '',
    title: profile.title ? profile.title : '',
    department: profile.department ? profile.department : '',
    specialty: profile.specialty ? profile.specialty : '',
    introduction: profile.introduction ? profile.introduction : '',
    avatar: profile.avatar ? profile.avatar : '',
    licenseNumber: profile.licenseNumber ? profile.licenseNumber : '',
    licenseImageUrls: profile.licenseImageUrls ? profile.licenseImageUrls : ''
  };
}

@Component
export struct DoctorRegistrationView {
  onCompleted?: () => void;
  onExit?: () => void;

  @State step: number = 0;
  @State form: DraftFormState = emptyForm();
  @State review: DoctorReviewItem | null = null;
  @State feedback: string = '';
  @State submitting: boolean = false;
  @State uploadingLicenseImage: boolean = false;
  @State uploadingAvatar: boolean = false;

  aboutToAppear() {
    this.loadQualification();
  }

  private loadQualification(): void {
    this.feedback = '加载中...';
    fetchMyQualification().then((data: DoctorQualificationData) => {
      this.form = formFromProfile(data.profile);
      this.review = data.review ? data.review : null;
      this.feedback = '';
    }).catch((error: Error) => {
      // 还没有 qualification 记录，尝试创建草稿
      ensureDraft().then((draft: DoctorReviewItem) => {
        this.review = draft;
        this.feedback = '';
      }).catch((draftError: Error) => {
        this.feedback = draftError.message ? draftError.message : '加载失败';
      });
    });
  }

  private updateForm(patch: Partial<DraftFormState>): void {
    this.form = {
      doctorName: patch.doctorName !== undefined ? patch.doctorName : this.form.doctorName,
      title: patch.title !== undefined ? patch.title : this.form.title,
      department: patch.department !== undefined ? patch.department : this.form.department,
      specialty: patch.specialty !== undefined ? patch.specialty : this.form.specialty,
      introduction: patch.introduction !== undefined ? patch.introduction : this.form.introduction,
      avatar: patch.avatar !== undefined ? patch.avatar : this.form.avatar,
      licenseNumber: patch.licenseNumber !== undefined ? patch.licenseNumber : this.form.licenseNumber,
      licenseImageUrls: patch.licenseImageUrls !== undefined ? patch.licenseImageUrls : this.form.licenseImageUrls
    };
  }

  private async pickAvatarImage(): Promise<void> {
    if (this.uploadingAvatar) return;
    try {
      const photoViewPicker = new picker.PhotoViewPicker();
      const selectOption: picker.PhotoSelectOptions = {
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      };
      const result = await photoViewPicker.select(selectOption);
      if (result.photoUris.length > 0) {
        this.uploadAvatar(result.photoUris[0]);
      }
    } catch {
      this.feedback = '选择图片失败';
    }
  }

  private uploadAvatar(uri: string): void {
    this.uploadingAvatar = true;
    this.feedback = '头像上传中...';
    uploadImage(uri)
      .then((result) => {
        this.updateForm({ avatar: result.imageUrl });
        this.uploadingAvatar = false;
        this.feedback = '头像上传成功';
      })
      .catch((err: Error) => {
        this.uploadingAvatar = false;
        this.feedback = `头像上传失败: ${err.message}`;
      });
  }

  private async pickLicenseImage(): Promise<void> {
    if (this.uploadingLicenseImage) return;
    try {
      const photoViewPicker = new picker.PhotoViewPicker();
      const selectOption: picker.PhotoSelectOptions = {
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 9
      };
      const result = await photoViewPicker.select(selectOption);
      if (result.photoUris.length > 0) {
        this.uploadLicenseImages(result.photoUris);
      }
    } catch {
      this.feedback = '选择图片失败';
    }
  }

  private uploadLicenseImages(uris: string[]): void {
    this.uploadingLicenseImage = true;
    this.feedback = `上传中 (0/${uris.length})...`;
    let uploaded = 0;
    let failed = 0;
    const uploadNext = () => {
      if (uploaded + failed >= uris.length) {
        this.uploadingLicenseImage = false;
        if (failed > 0) {
          this.feedback = `${uploaded} 张上传成功，${failed} 张失败`;
        } else {
          this.feedback = `${uploaded} 张上传成功`;
        }
        return;
      }
      const index = uploaded + failed;
      uploadImage(uris[index])
        .then((result) => {
          const existing = this.form.licenseImageUrls.length > 0
            ? this.form.licenseImageUrls.split(',').filter((s: string) => s.trim().length > 0)
            : [];
          existing.push(result.imageUrl);
          this.updateForm({ licenseImageUrls: existing.join(',') });
          uploaded += 1;
          this.feedback = `上传中 (${uploaded}/${uris.length})...`;
          uploadNext();
        })
        .catch((err: Error) => {
          failed += 1;
          uploadNext();
        });
    };
    uploadNext();
  }

  private removeLicenseImageUrl(url: string): void {
    const existing = this.form.licenseImageUrls.split(',').filter((s: string) => s.trim() !== url.trim());
    this.updateForm({ licenseImageUrls: existing.join(',') });
  }

  private licenseImageUrlList(): string[] {
    if (this.form.licenseImageUrls.length === 0) return [];
    return this.form.licenseImageUrls.split(',').filter((s: string) => s.trim().length > 0);
  }

  private validate(): string {
    if (this.form.doctorName.trim().length === 0) {
      return '请填写医生姓名';
    }
    if (this.form.specialty.trim().length === 0) {
      return '请填写擅长方向';
    }
    if (this.form.licenseNumber.trim().length === 0) {
      return '请填写医师资格证编号';
    }
    if (this.licenseImageUrlList().length === 0) {
      return '请上传至少一张医师资格证照片';
    }
    return '';
  }

  private doSaveDraft(): void {
    if (this.submitting) return;
    if (this.review === null || this.review.id === undefined) {
      this.feedback = '草稿尚未初始化，请稍后重试';
      return;
    }
    this.submitting = true;
    this.feedback = '保存中...';
    saveDraft(this.review.id, {
      doctorName: this.form.doctorName,
      title: this.form.title,
      specialty: this.form.specialty,
      introduction: this.form.introduction,
      avatar: this.form.avatar.length > 0 ? this.form.avatar : undefined,
      department: this.form.department.length > 0 ? this.form.department : undefined,
      licenseNumber: this.form.licenseNumber,
      licenseImageUrls: this.form.licenseImageUrls.length > 0 ? this.form.licenseImageUrls : undefined
    }).then((ok: boolean) => {
      this.submitting = false;
      this.feedback = ok ? '草稿已保存' : '保存失败';
    }).catch((error: Error) => {
      this.submitting = false;
      this.feedback = error.message ? error.message : '保存失败';
    });
  }

  private doSubmitForReview(): void {
    if (this.submitting) return;
    const validation = this.validate();
    if (validation.length > 0) {
      this.feedback = validation;
      return;
    }
    if (this.review === null || this.review.id === undefined) {
      this.feedback = '草稿尚未初始化，请先保存';
      return;
    }
    this.submitting = true;
    this.feedback = '正在提交审核...';
    saveDraft(this.review.id, {
      doctorName: this.form.doctorName,
      title: this.form.title,
      specialty: this.form.specialty,
      introduction: this.form.introduction,
      avatar: this.form.avatar.length > 0 ? this.form.avatar : undefined,
      department: this.form.department.length > 0 ? this.form.department : undefined,
      licenseNumber: this.form.licenseNumber,
      licenseImageUrls: this.form.licenseImageUrls.length > 0 ? this.form.licenseImageUrls : undefined
    }).then((ok: boolean) => {
      if (!ok) {
        this.submitting = false;
        this.feedback = '保存草稿失败';
        return;
      }
      submitForReview(this.review!.id).then((updated: DoctorReviewItem) => {
        this.submitting = false;
        this.review = updated;
        this.feedback = '已提交审核，请等待管理员审核';
        if (this.onCompleted) this.onCompleted();
      }).catch((error: Error) => {
        this.submitting = false;
        this.feedback = error.message ? error.message : '提交审核失败';
      });
    }).catch((error: Error) => {
      this.submitting = false;
      this.feedback = error.message ? error.message : '保存草稿失败';
    });
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor(Color.White)
          .onClick(() => {
            if (this.onExit) this.onExit();
          })
        Text('医生入驻')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .layoutWeight(1)
          .margin({ left: 12 })
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 12, bottom: 12 })
      .backgroundColor(BRAND_GREEN)

      Scroll() {
        Column({ space: 14 }) {
          // 步骤指示
          this.StepsIndicator()

          // 步骤 1：基本资料
          if (this.step === 0) {
            this.BasicInfoSection()
          } else if (this.step === 1) {
            this.LicenseSection()
          } else {
            this.SubmitSection()
          }

          // 反馈
          if (this.feedback.length > 0) {
            Text(this.feedback)
              .fontSize(12)
              .fontColor(this.feedback.indexOf('失败') >= 0 || this.feedback.indexOf('请') >= 0 ? WARM_ACCENT : BRAND_GREEN)
              .width('100%')
              .textAlign(TextAlign.Center)
          }

          // 底部操作按钮
          this.ActionBar()
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 14, bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F9F8')
  }

  @Builder
  StepsIndicator() {
    Row({ space: 8 }) {
      ForEach(
        [
          { key: '0', label: '基本资料' } as RegistrationStep,
          { key: '1', label: '资质材料' } as RegistrationStep,
          { key: '2', label: '提交审核' } as RegistrationStep
        ],
        (item: RegistrationStep) => {
          Column({ space: 4 }) {
            Text(item.label)
              .fontSize(12)
              .fontColor(this.step.toString() === item.key ? Color.White : MUTED_TEXT)
            Column()
              .width(this.step.toString() === item.key ? 24 : 0)
              .height(3)
              .backgroundColor(Color.White)
              .borderRadius(1.5)
          }
          .layoutWeight(1)
          .padding({ top: 8, bottom: 8 })
          .backgroundColor(this.step.toString() === item.key ? BRAND_GREEN : CARD_BG)
          .borderRadius(12)
          .onClick(() => {
            this.step = Number(item.key);
          })
        },
        (item: RegistrationStep) => item.key
      )
    }
    .width('100%')
  }

  @Builder
  BasicInfoSection() {
    Column({ space: 10 }) {
      Text('基本资料')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      Row({ space: 12 }) {
        if (this.form.avatar.length > 0) {
          Image(this.form.avatar)
            .width(64)
            .height(64)
            .borderRadius(32)
            .objectFit(ImageFit.Cover)
        } else {
          Column() {
            Text('📷')
              .fontSize(22)
            Text('点击上传')
              .fontSize(11)
              .fontColor(MUTED_TEXT)
          }
          .width(64)
          .height(64)
          .borderRadius(32)
          .backgroundColor('#F5F5F5')
          .justifyContent(FlexAlign.Center)
          .onClick(() => { this.pickAvatarImage(); })
        }

        Button(this.uploadingAvatar ? '上传中...' : '从相册选择头像')
          .height(38)
          .fontSize(13)
          .fontColor(BRAND_GREEN)
          .backgroundColor('#EEF7F1')
          .border({ width: 1, color: BRAND_GREEN })
          .borderRadius(CARD_RADIUS)
          .enabled(!this.uploadingAvatar)
          .onClick(() => { this.pickAvatarImage(); })
      }
      .width('100%')

      TextInput({ placeholder: '医生姓名 *', text: this.form.doctorName })
        .height(42)
        .fontSize(14)
        .backgroundColor('#F6F8F5')
        .borderRadius(CARD_RADIUS)
        .onChange((value: string) => { this.updateForm({ doctorName: value }); })

      TextInput({ placeholder: '职称，例如：主治医师', text: this.form.title })
        .height(42)
        .fontSize(14)
        .backgroundColor('#F6F8F5')
        .borderRadius(CARD_RADIUS)
        .onChange((value: string) => { this.updateForm({ title: value }); })

      TextInput({ placeholder: '科室', text: this.form.department })
        .height(42)
        .fontSize(14)
        .backgroundColor('#F6F8F5')
        .borderRadius(CARD_RADIUS)
        .onChange((value: string) => { this.updateForm({ department: value }); })

      TextInput({ placeholder: '擅长方向 *', text: this.form.specialty })
        .height(42)
        .fontSize(14)
        .backgroundColor('#F6F8F5')
        .borderRadius(CARD_RADIUS)
        .onChange((value: string) => { this.updateForm({ specialty: value }); })

      TextArea({ placeholder: '服务说明（50-1000字，禁止保证疗效）', text: this.form.introduction })
        .height(80)
        .fontSize(14)
        .backgroundColor('#F6F8F5')
        .borderRadius(CARD_RADIUS)
        .onChange((value: string) => { this.updateForm({ introduction: value }); })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  LicenseSection() {
    Column({ space: 10 }) {
      Text('医师资格证')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      TextInput({ placeholder: '资格证编号 *', text: this.form.licenseNumber })
        .height(42)
        .fontSize(14)
        .backgroundColor('#F6F8F5')
        .borderRadius(CARD_RADIUS)
        .onChange((value: string) => { this.updateForm({ licenseNumber: value }); })

      Button() {
        Row({ space: 8 }) {
          Text('+')
            .fontSize(18)
            .fontColor(BRAND_GREEN)
          Text(this.uploadingLicenseImage ? '上传中...' : '从相册选择资格证照片')
            .fontSize(14)
            .fontColor(BRAND_GREEN)
        }
      }
      .width('100%')
      .height(48)
      .backgroundColor('#EEF7F1')
      .border({ width: 1, color: BRAND_GREEN, style: BorderStyle.Dashed })
      .borderRadius(CARD_RADIUS)
      .enabled(!this.uploadingLicenseImage)
      .onClick(() => { this.pickLicenseImage(); })

      if (this.licenseImageUrlList().length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.licenseImageUrlList(), (url: string, index: number) => {
            Stack({ alignContent: Alignment.TopEnd }) {
              Image(url)
                .width(80)
                .height(80)
                .borderRadius(8)
                .objectFit(ImageFit.Cover)
                .margin({ right: 8, bottom: 8 })
              Text('×')
                .fontSize(14)
                .fontColor(Color.White)
                .width(20)
                .height(20)
                .textAlign(TextAlign.Center)
                .backgroundColor('rgba(0,0,0,0.5)')
                .borderRadius(10)
                .margin({ top: 2, right: 10 })
                .onClick(() => { this.removeLicenseImageUrl(url); })
            }
            .width(80)
            .height(80)
            .margin({ right: 8, bottom: 8 })
          }, (url: string, index: number) => `${index}-${url}`)
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  SubmitSection() {
    Column({ space: 10 }) {
      Text('确认并提交')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      Text('请核对以下信息后提交审核，提交后将进入管理员审核队列。')
        .fontSize(12)
        .fontColor(MUTED_TEXT)
        .lineHeight(20)

      this.SummaryRow('医生姓名', this.form.doctorName)
      this.SummaryRow('职称', this.form.title)
      this.SummaryRow('科室', this.form.department)
      this.SummaryRow('擅长方向', this.form.specialty)
      this.SummaryRow('资格证编号', this.form.licenseNumber)
      this.SummaryRow('资格证照片', `${this.licenseImageUrlList().length} 张`)
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  SummaryRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(MUTED_TEXT)
        .layoutWeight(1)
      Text(value.length > 0 ? value : '未填写')
        .fontSize(13)
        .fontColor(value.length > 0 ? DEEP_TEXT : MUTED_TEXT)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
  }

  @Builder
  ActionBar() {
    Row({ space: 8 }) {
      Button(this.step === 0 ? '上一页' : (this.step === 1 ? '上一步' : '返回'))
        .height(42)
        .fontSize(14)
        .fontColor(BRAND_GREEN)
        .backgroundColor(CARD_BG)
        .border({ width: 1, color: BRAND_GREEN })
        .borderRadius(CARD_RADIUS)
        .layoutWeight(1)
        .onClick(() => {
          if (this.step > 0) {
            this.step = this.step - 1;
          } else {
            if (this.onExit) this.onExit();
          }
        })

      if (this.step < 2) {
        Button('保存草稿')
          .height(42)
          .fontSize(14)
          .fontColor(BRAND_GREEN)
          .backgroundColor(CARD_BG)
          .border({ width: 1, color: BRAND_GREEN })
          .borderRadius(CARD_RADIUS)
          .layoutWeight(1)
          .enabled(!this.submitting)
          .onClick(() => { this.doSaveDraft(); })

        Button('下一步')
          .height(42)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(BRAND_GREEN)
          .borderRadius(CARD_RADIUS)
          .layoutWeight(1)
          .enabled(!this.submitting)
          .onClick(() => {
            this.doSaveDraft();
            this.step = this.step + 1;
          })
      } else {
        Button('提交审核')
          .height(42)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(BRAND_GREEN)
          .borderRadius(CARD_RADIUS)
          .layoutWeight(2)
          .enabled(!this.submitting)
          .onClick(() => { this.doSubmitForReview(); })
      }
    }
    .width('100%')
    .margin({ top: 10 })
  }
}
