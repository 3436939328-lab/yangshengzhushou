import { picker } from '@kit.CoreFileKit';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import { uploadImage } from '../../services/AssetService';
import {
  buildDoctorProfileIdentityText,
  buildDoctorProfileSaveFailureText,
  buildDoctorProfileValidationText,
  createEmptyDoctorProfile,
  DoctorProfileForm,
  fetchDoctorProfile,
  saveDoctorProfile
} from '../../services/DoctorProfileService';
import {
  DoctorQualificationData,
  DoctorReviewItem,
  ensureDraft,
  fetchMyQualification,
  resubmitReview,
  submitForReview,
  updateAccepting
} from '../../services/DoctorReviewService';

@Component
export struct DoctorProfileTab {
  @Prop userId: string;
  onOpenRegistration?: () => void;

  @State profile: DoctorProfileForm = createEmptyDoctorProfile('');
  @State feedback: string = '';
  @State uploadingLicenseImage: boolean = false;
  @State uploadingAvatar: boolean = false;
  @State reviewId: number = 0;
  @State reviewStatus: string = '';
  @State submitting: boolean = false;

  aboutToAppear() {
    this.profile = createEmptyDoctorProfile(this.userId);
    this.loadProfile();
    this.loadQualification();
  }

  private loadQualification(): void {
    fetchMyQualification().then((data: DoctorQualificationData) => {
      if (data.review) {
        this.reviewId = data.review.id ? data.review.id : 0;
        this.reviewStatus = data.review.status ? data.review.status : '';
      }
      if (data.profile) {
        const p = data.profile;
        // 用 review 流程的 profile 同步本地 form 关键状态
        if (p.verificationStatus) {
          this.updateProfile({ verificationStatus: p.verificationStatus });
        }
        if (p.verificationRemark) {
          this.updateProfile({ verificationRemark: p.verificationRemark });
        }
        if (p.accepting !== undefined) {
          this.updateProfile({ accepting: p.accepting });
        }
      }
    }).catch(() => {
      // 资质接口尚未创建草稿，保持空状态
    });
  }

  private updateProfile(patch: Partial<DoctorProfileForm>): void {
    this.profile = {
      id: this.profile.id,
      userId: this.profile.userId,
      doctorName: patch.doctorName !== undefined ? patch.doctorName : this.profile.doctorName,
      title: patch.title !== undefined ? patch.title : this.profile.title,
      specialty: patch.specialty !== undefined ? patch.specialty : this.profile.specialty,
      introduction: patch.introduction !== undefined ? patch.introduction : this.profile.introduction,
      avatar: patch.avatar !== undefined ? patch.avatar : this.profile.avatar,
      department: patch.department !== undefined ? patch.department : this.profile.department,
      licenseNumber: patch.licenseNumber !== undefined ? patch.licenseNumber : this.profile.licenseNumber,
      licenseImageUrls: patch.licenseImageUrls !== undefined ? patch.licenseImageUrls : this.profile.licenseImageUrls,
      verificationStatus: patch.verificationStatus !== undefined ? patch.verificationStatus : this.profile.verificationStatus,
      verificationRemark: patch.verificationRemark !== undefined ? patch.verificationRemark : this.profile.verificationRemark,
      accepting: patch.accepting !== undefined ? patch.accepting : this.profile.accepting
    };
  }

  private verificationStatusText(): string {
    switch (this.profile.verificationStatus) {
      case 'APPROVED': return '已通过';
      case 'REJECTED': return '未通过';
      case 'NEED_INFO': return '需补充';
      case 'DRAFT': return '草稿中';
      case 'PENDING':
      default: return '待审核';
    }
  }

  private verificationStatusColor(): ResourceColor {
    switch (this.profile.verificationStatus) {
      case 'APPROVED': return BRAND_GREEN;
      case 'REJECTED': return WARM_ACCENT;
      case 'NEED_INFO': return WARM_ACCENT;
      case 'DRAFT': return MUTED_TEXT;
      default: return MUTED_TEXT;
    }
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
        this.updateProfile({ avatar: result.imageUrl });
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
          const existing = this.profile.licenseImageUrls.length > 0
            ? this.profile.licenseImageUrls.split(',').filter((s: string) => s.trim().length > 0)
            : [];
          existing.push(result.imageUrl);
          this.updateProfile({ licenseImageUrls: existing.join(',') });
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
    const existing = this.profile.licenseImageUrls.split(',').filter((s: string) => s.trim() !== url.trim());
    this.updateProfile({ licenseImageUrls: existing.join(',') });
  }

  private licenseImageUrlList(): string[] {
    if (this.profile.licenseImageUrls.length === 0) return [];
    return this.profile.licenseImageUrls.split(',').filter((s: string) => s.trim().length > 0);
  }

  build() {
    Column({ space: 14 }) {
      Text('医生资料')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('维护用户可选择的医生展示信息，保存后会出现在普通用户的一对一问诊医生列表中。上传医师资格证后将进入审核流程。')
        .fontSize(14)
        .fontColor(MUTED_TEXT)
        .lineHeight(22)

      this.VerificationStatusCard()
      this.ProfileForm()
      this.LicenseSection()
      this.AcceptingToggle()
      this.PreviewPanel()
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  VerificationStatusCard() {
    Column({ space: 8 }) {
      Row() {
        Text('资质审核状态')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Blank()
        Text(this.verificationStatusText())
          .fontSize(14)
          .fontColor(this.verificationStatusColor())
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')

      if (this.profile.verificationRemark.length > 0) {
        Text(`审核意见：${this.profile.verificationRemark}`)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .width('100%')
      }

      if (this.profile.verificationStatus === 'PENDING') {
        Text('请完善医师资格证信息并保存，提交后将进入审核队列。')
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .width('100%')
      } else if (this.profile.verificationStatus === 'REJECTED') {
        Text('资质审核未通过，请根据审核意见补充材料后重新提交。')
          .fontSize(12)
          .fontColor(WARM_ACCENT)
          .width('100%')
      } else if (this.profile.verificationStatus === 'NEED_INFO') {
        Text('请根据审核意见补充材料后重新提交。')
          .fontSize(12)
          .fontColor(WARM_ACCENT)
          .width('100%')
      } else if (this.profile.verificationStatus === 'DRAFT') {
        Text('当前为草稿状态，完善资料后请点击"提交审核"。')
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .width('100%')
      } else if (this.profile.verificationStatus === 'APPROVED') {
        Text('资质已通过审核，您可以正常接诊。')
          .fontSize(12)
          .fontColor(BRAND_GREEN)
          .width('100%')
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  ProfileForm() {
    Column({ space: 10 }) {
      Text('基本资料')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      Row({ space: 12 }) {
        if (this.profile.avatar.length > 0) {
          Image(this.profile.avatar)
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

      TextInput({ placeholder: '医生姓名', text: this.profile.doctorName })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => { this.updateProfile({ doctorName: value }); })

      TextInput({ placeholder: '职称，例如：主治医师', text: this.profile.title })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => { this.updateProfile({ title: value }); })

      TextInput({ placeholder: '科室，例如：中医科、内科', text: this.profile.department })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => { this.updateProfile({ department: value }); })

      TextInput({ placeholder: '擅长方向，例如：睡眠调理、慢病养生', text: this.profile.specialty })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => { this.updateProfile({ specialty: value }); })

      TextArea({ placeholder: '服务说明', text: this.profile.introduction })
        .height(80)
        .fontSize(14)
        .onChange((value: string) => { this.updateProfile({ introduction: value }); })

      Row({ space: 8 }) {
        Button('保存草稿')
          .height(42)
          .fontSize(14)
          .fontColor(BRAND_GREEN)
          .backgroundColor(CARD_BG)
          .border({ width: 1, color: BRAND_GREEN })
          .borderRadius(CARD_RADIUS)
          .layoutWeight(1)
          .enabled(!this.submitting)
          .onClick(() => { this.saveProfile(); })

        if (this.reviewStatus === 'PENDING') {
          Button('审核中')
            .height(42)
            .fontSize(14)
            .fontColor(MUTED_TEXT)
            .backgroundColor(CARD_BG)
            .border({ width: 1, color: MUTED_TEXT })
            .borderRadius(CARD_RADIUS)
            .layoutWeight(1)
            .enabled(false)
        } else if (this.reviewStatus === 'REJECTED' || this.reviewStatus === 'NEED_INFO') {
          Button('重新提交审核')
            .height(42)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor(BRAND_GREEN)
            .borderRadius(CARD_RADIUS)
            .layoutWeight(1)
            .enabled(!this.submitting)
            .onClick(() => { this.doResubmit(); })
        } else if (this.reviewStatus === 'APPROVED') {
          Button('已通过')
            .height(42)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor(BRAND_GREEN)
            .borderRadius(CARD_RADIUS)
            .layoutWeight(1)
            .enabled(false)
        } else {
          Button('提交审核')
            .height(42)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor(BRAND_GREEN)
            .borderRadius(CARD_RADIUS)
            .layoutWeight(1)
            .enabled(!this.submitting)
            .onClick(() => { this.doSubmitForReview(); })
        }
      }
      .width('100%')

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
  LicenseSection() {
    Column({ space: 10 }) {
      Text('医师资格证明')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('请上传医师资格证等资质材料，支持 JPEG/PNG 格式。材料将用于资质审核，不会公开展示。')
        .fontSize(12)
        .fontColor(MUTED_TEXT)
        .lineHeight(18)

      TextInput({ placeholder: '医师资格证编号', text: this.profile.licenseNumber })
        .height(42)
        .fontSize(14)
        .onChange((value: string) => { this.updateProfile({ licenseNumber: value }); })

      Text('资质照片')
        .fontSize(14)
        .fontColor(DEEP_TEXT)
        .fontWeight(FontWeight.Medium)

      Button() {
        Row({ space: 8 }) {
          Text('+')
            .fontSize(18)
            .fontColor(BRAND_GREEN)
          Text(this.uploadingLicenseImage ? '上传中...' : '从相册选择照片')
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

      Text('支持 jpg、png、gif、webp 等格式，最多上传 9 张。')
        .fontSize(11)
        .fontColor(MUTED_TEXT)
        .width('100%')
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  AcceptingToggle() {
    if (this.profile.verificationStatus === 'APPROVED') {
      Column({ space: 8 }) {
        Text('接诊设置')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Row() {
          Column({ space: 4 }) {
            Text('是否开启接诊')
              .fontSize(14)
              .fontColor(DEEP_TEXT)
            Text(this.profile.accepting ? '当前已开启接诊，用户可向您发起问诊' : '当前已关闭接诊，用户无法向您发起新问诊')
              .fontSize(12)
              .fontColor(MUTED_TEXT)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Toggle({ type: ToggleType.Switch, isOn: this.profile.accepting })
            .selectedColor(BRAND_GREEN)
            .onChange((isOn: boolean) => {
              this.updateProfile({ accepting: isOn });
              this.doUpdateAccepting(isOn);
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 18, bottom: 18 })
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
    }
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
      if (this.profile.department.length > 0) {
        Text(this.profile.department)
          .fontSize(13)
          .fontColor(MUTED_TEXT)
      }
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
      introduction: this.profile.introduction.trim(),
      avatar: this.profile.avatar.trim(),
      department: this.profile.department.trim(),
      licenseNumber: this.profile.licenseNumber.trim(),
      licenseImageUrls: this.profile.licenseImageUrls,
      verificationStatus: this.profile.id.length > 0 && this.profile.verificationStatus === 'APPROVED'
        ? this.profile.verificationStatus
        : (this.profile.licenseImageUrls.length > 0 ? 'PENDING' : this.profile.verificationStatus),
      verificationRemark: this.profile.verificationRemark,
      accepting: this.profile.accepting
    };
    saveDoctorProfile(profile).then((saved: boolean) => {
      this.feedback = saved ? '草稿已保存。' : buildDoctorProfileSaveFailureText('');
      if (saved) {
        this.profile = profile;
      }
    }).catch((error: Error) => {
      this.feedback = buildDoctorProfileSaveFailureText(error.message);
    });
  }

  private doSubmitForReview(): void {
    if (this.submitting) return;
    const validation = buildDoctorProfileValidationText(this.profile);
    if (validation.length > 0) {
      this.feedback = validation;
      return;
    }
    if (this.profile.licenseNumber.trim().length === 0) {
      this.feedback = '请填写医师资格证编号';
      return;
    }
    if (this.profile.licenseImageUrls.trim().length === 0) {
      this.feedback = '请上传至少一张资质照片';
      return;
    }
    this.submitting = true;
    this.feedback = '正在保存资料...';
    saveDoctorProfile(this.profile).then((saved: boolean) => {
      if (!saved) {
        this.submitting = false;
        this.feedback = '保存资料失败';
        return;
      }
      this.feedback = '正在提交审核...';
      if (this.reviewId <= 0) {
        ensureDraft().then((review: DoctorReviewItem) => {
          this.reviewId = review.id ? review.id : 0;
          this.reviewStatus = review.status ? review.status : '';
          if (this.reviewId <= 0) {
            this.submitting = false;
            this.feedback = '创建审核记录失败，请重试';
            return;
          }
          this.doSubmitDraft(this.reviewId);
        }).catch((error: Error) => {
          this.submitting = false;
          this.feedback = error.message ? error.message : '创建审核记录失败';
        });
      } else {
        this.doSubmitDraft(this.reviewId);
      }
    }).catch((error: Error) => {
      this.submitting = false;
      this.feedback = buildDoctorProfileSaveFailureText(error.message);
    });
  }

  private doSubmitDraft(reviewId: number): void {
    submitForReview(reviewId).then((updated: DoctorReviewItem) => {
      this.submitting = false;
      this.reviewStatus = updated.status ? updated.status : 'PENDING';
      this.updateProfile({ verificationStatus: this.reviewStatus });
      this.feedback = '已提交审核，请等待管理员审核';
    }).catch((error: Error) => {
      this.submitting = false;
      this.feedback = error.message ? error.message : '提交审核失败';
    });
  }

  private doResubmit(): void {
    if (this.submitting) return;
    this.submitting = true;
    this.feedback = '正在保存资料...';
    saveDoctorProfile(this.profile).then((saved: boolean) => {
      if (!saved) {
        this.submitting = false;
        this.feedback = '保存资料失败';
        return;
      }
      this.feedback = '正在重新提交...';
      resubmitReview().then((updated: DoctorReviewItem) => {
        this.submitting = false;
        this.reviewStatus = updated.status ? updated.status : 'PENDING';
        this.updateProfile({ verificationStatus: this.reviewStatus });
        this.feedback = '已重新提交审核';
      }).catch((error: Error) => {
        this.submitting = false;
        this.feedback = error.message ? error.message : '重新提交失败';
      });
    }).catch((error: Error) => {
      this.submitting = false;
      this.feedback = buildDoctorProfileSaveFailureText(error.message);
    });
  }

  private doUpdateAccepting(accepting: boolean): void {
    updateAccepting(accepting).then((ok: boolean) => {
      this.feedback = ok ? '接诊设置已更新' : '接诊设置失败';
    }).catch((error: Error) => {
      this.feedback = error.message ? error.message : '接诊设置失败';
    });
  }
}
