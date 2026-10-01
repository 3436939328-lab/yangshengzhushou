import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import {
  AdminReviewDetail,
  AdminReviewListData,
  DoctorProfileSnapshot,
  DoctorReviewItem,
  fetchAdminReviewDetail,
  fetchAdminReviewQueue,
  submitAdminDecision
} from '../../services/DoctorReviewService';

interface FilterOption {
  key: string;
  label: string;
}

@Component
export struct AdminDoctorReviewTab {
  @State items: DoctorReviewItem[] = [];
  @State total: number = 0;
  @State page: number = 1;
  @State pageSize: number = 20;
  @State statusFilter: string = 'PENDING';
  @State loading: boolean = false;
  @State feedback: string = '';
  @State selectedReviewId: number = 0;
  @State detail: AdminReviewDetail | null = null;
  @State decision: string = 'APPROVED';
  @State decisionReason: string = '';
  @State deciding: boolean = false;

  aboutToAppear() {
    this.refreshList();
  }

  private refreshList(): void {
    this.loading = true;
    this.feedback = '加载中...';
    fetchAdminReviewQueue(this.statusFilter, this.page, this.pageSize).then((data: AdminReviewListData) => {
      this.items = data.items ? data.items : [];
      this.total = data.total ? data.total : 0;
      this.loading = false;
      this.feedback = this.items.length === 0 ? '当前没有匹配的审核记录' : '';
    }).catch((error: Error) => {
      this.loading = false;
      this.feedback = error.message ? error.message : '加载失败';
    });
  }

  private loadDetail(reviewId: number): void {
    this.selectedReviewId = reviewId;
    this.feedback = '加载详情...';
    fetchAdminReviewDetail(reviewId).then((data: AdminReviewDetail) => {
      this.detail = data;
      this.feedback = '';
    }).catch((error: Error) => {
      this.feedback = error.message ? error.message : '加载详情失败';
    });
  }

  private statusLabel(status: string): string {
    switch (status) {
      case 'DRAFT': return '草稿';
      case 'PENDING': return '待审核';
      case 'NEED_INFO': return '需补充';
      case 'APPROVED': return '已通过';
      case 'REJECTED': return '已驳回';
      default: return status;
    }
  }

  private statusColor(status: string): ResourceColor {
    switch (status) {
      case 'APPROVED': return BRAND_GREEN;
      case 'REJECTED': return WARM_ACCENT;
      case 'NEED_INFO': return WARM_ACCENT;
      case 'PENDING': return '#FF9800';
      default: return MUTED_TEXT;
    }
  }

  private formatTime(time?: string): string {
    if (!time || time.length === 0) return '-';
    return time.replace('T', ' ').substring(0, 16);
  }

  private doSubmitDecision(): void {
    if (this.deciding) return;
    if (this.selectedReviewId <= 0) {
      this.feedback = '请先选择一条审核';
      return;
    }
    if (this.decision === 'REJECTED' || this.decision === 'NEED_INFO') {
      if (this.decisionReason.trim().length === 0) {
        this.feedback = '驳回或要求补充时必须填写理由';
        return;
      }
    }
    const review = this.detail && this.detail.review ? this.detail.review : null;
    if (!review || review.version === undefined) {
      this.feedback = '审核记录信息缺失';
      return;
    }
    this.deciding = true;
    this.feedback = '提交决策中...';
    submitAdminDecision(this.selectedReviewId, this.decision, this.decisionReason, review.version)
      .then(() => {
        this.deciding = false;
        this.feedback = '决策已保存';
        this.detail = null;
        this.selectedReviewId = 0;
        this.refreshList();
      })
      .catch((error: Error) => {
        this.deciding = false;
        this.feedback = error.message ? error.message : '提交决策失败';
      });
  }

  build() {
    Column({ space: 14 }) {
      Text('医生资质审核')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('审核医生提交的资质材料，通过后医生才能开启接诊。')
        .fontSize(14)
        .fontColor(MUTED_TEXT)

      this.FilterPanel()
      this.ReviewList()
      if (this.selectedReviewId > 0) {
        this.DetailPanel()
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  FilterPanel() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(
        [
          { key: 'PENDING', label: '待审核' } as FilterOption,
          { key: 'NEED_INFO', label: '需补充' } as FilterOption,
          { key: 'APPROVED', label: '已通过' } as FilterOption,
          { key: 'REJECTED', label: '已驳回' } as FilterOption,
          { key: 'ALL', label: '全部' } as FilterOption
        ],
        (option: FilterOption) => {
          Text(option.label)
            .fontSize(13)
            .fontColor(this.statusFilter === option.key ? Color.White : DEEP_TEXT)
            .backgroundColor(this.statusFilter === option.key ? BRAND_GREEN : CARD_BG)
            .border({ width: 1, color: this.statusFilter === option.key ? BRAND_GREEN : MUTED_TEXT })
            .borderRadius(16)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.statusFilter = option.key;
              this.page = 1;
              this.refreshList();
            })
        },
        (option: FilterOption) => option.key
      )
    }
    .width('100%')
  }

  @Builder
  ReviewList() {
    Column({ space: 10 }) {
      Row() {
        Text('审核队列')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .layoutWeight(1)
        Text(`共 ${this.total} 条`)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
      }
      .width('100%')

      if (this.items.length === 0) {
        Text(this.loading ? '加载中...' : '当前没有匹配的审核记录')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 20, bottom: 20 })
      } else {
        ForEach(this.items, (item: DoctorReviewItem) => {
          Row() {
            Column({ space: 4 }) {
              Text(`医生用户 #${item.doctorUserId}`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(DEEP_TEXT)
              Text(`提交时间：${this.formatTime(item.submittedAt)}`)
                .fontSize(11)
                .fontColor(MUTED_TEXT)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text(this.statusLabel(item.status))
              .fontSize(12)
              .fontColor(this.statusColor(item.status))
              .fontWeight(FontWeight.Medium)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(CARD_BG)
              .borderRadius(8)

            Text('查看')
              .fontSize(12)
              .fontColor(BRAND_GREEN)
              .padding({ left: 8 })
              .onClick(() => {
                if (item.id !== undefined) {
                  this.loadDetail(item.id);
                }
              })
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .backgroundColor(this.selectedReviewId === item.id ? '#EEF7F1' : CARD_BG)
          .borderRadius(CARD_RADIUS)
        }, (item: DoctorReviewItem) => `${item.id}`)
      }

      if (this.total > this.pageSize) {
        Row({ space: 8 }) {
          Button('上一页')
            .height(36)
            .fontSize(13)
            .fontColor(BRAND_GREEN)
            .backgroundColor(CARD_BG)
            .border({ width: 1, color: BRAND_GREEN })
            .borderRadius(CARD_RADIUS)
            .enabled(this.page > 1)
            .onClick(() => {
              this.page = this.page - 1;
              this.refreshList();
            })
          Text(`第 ${this.page} 页 / 共 ${Math.ceil(this.total / this.pageSize)} 页`)
            .fontSize(12)
            .fontColor(MUTED_TEXT)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Button('下一页')
            .height(36)
            .fontSize(13)
            .fontColor(BRAND_GREEN)
            .backgroundColor(CARD_BG)
            .border({ width: 1, color: BRAND_GREEN })
            .borderRadius(CARD_RADIUS)
            .enabled(this.page * this.pageSize < this.total)
            .onClick(() => {
              this.page = this.page + 1;
              this.refreshList();
            })
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
  DetailPanel() {
    Column({ space: 12 }) {
      Row() {
        Text('审核详情')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .layoutWeight(1)
        Text('关闭')
          .fontSize(12)
          .fontColor(WARM_ACCENT)
          .onClick(() => {
            this.selectedReviewId = 0;
            this.detail = null;
            this.feedback = '';
          })
      }
      .width('100%')

      if (this.detail && this.detail.profile) {
        this.ProfileSnapshot(this.detail.profile)
      }

      if (this.detail && this.detail.review) {
        this.ReviewMeta(this.detail.review)
      }

      if (this.detail && this.detail.history && this.detail.history.length > 1) {
        Column({ space: 6 }) {
          Text('历史审核')
            .fontSize(13)
            .fontColor(MUTED_TEXT)
          ForEach(this.detail.history, (h: DoctorReviewItem) => {
            Row() {
              Text(`v${h.version} ${this.statusLabel(h.status)}`)
                .fontSize(12)
                .fontColor(DEEP_TEXT)
                .layoutWeight(1)
              Text(this.formatTime(h.reviewedAt))
                .fontSize(11)
                .fontColor(MUTED_TEXT)
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
          }, (h: DoctorReviewItem) => `${h.id}`)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      // 决策表单
      Column({ space: 8 }) {
        Text('审核决策')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)

        Row({ space: 8 }) {
          this.DecisionButton('通过', 'APPROVED')
          this.DecisionButton('要求补充', 'NEED_INFO')
          this.DecisionButton('驳回', 'REJECTED')
        }
        .width('100%')

        TextArea({ placeholder: '审核意见 / 驳回理由（驳回或要求补充时必填）', text: this.decisionReason })
          .height(72)
          .fontSize(13)
          .backgroundColor('#F6F8F5')
          .borderRadius(CARD_RADIUS)
          .onChange((value: string) => { this.decisionReason = value; })

        Button('提交决策')
          .width('100%')
          .height(42)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(BRAND_GREEN)
          .borderRadius(CARD_RADIUS)
          .enabled(!this.deciding)
          .onClick(() => { this.doSubmitDecision(); })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      if (this.feedback.length > 0) {
        Text(this.feedback)
          .fontSize(12)
          .fontColor(this.feedback.indexOf('成功') >= 0 || this.feedback.indexOf('已保存') >= 0 ? BRAND_GREEN : WARM_ACCENT)
          .width('100%')
          .textAlign(TextAlign.Center)
      }
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 18, bottom: 18 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  DecisionButton(label: string, value: string) {
    Text(label)
      .fontSize(13)
      .fontColor(this.decision === value ? Color.White : DEEP_TEXT)
      .backgroundColor(this.decision === value ? BRAND_GREEN : CARD_BG)
      .border({ width: 1, color: this.decision === value ? BRAND_GREEN : MUTED_TEXT })
      .borderRadius(CARD_RADIUS)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => { this.decision = value; })
  }

  @Builder
  ProfileSnapshot(profile: DoctorProfileSnapshot) {
    Column({ space: 6 }) {
      Text('医生资料')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      this.SnapshotRow('姓名', profile.doctorName ? profile.doctorName : '未填写')
      this.SnapshotRow('职称', profile.title ? profile.title : '未填写')
      this.SnapshotRow('科室', profile.department ? profile.department : '未填写')
      this.SnapshotRow('擅长', profile.specialty ? profile.specialty : '未填写')
      this.SnapshotRow('资格证号', profile.licenseNumber ? profile.licenseNumber : '未填写')

      if (profile.licenseImageUrls && profile.licenseImageUrls.length > 0) {
        Text('资格证照片')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .margin({ top: 6 })
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.licenseImageList(profile.licenseImageUrls), (url: string) => {
            Image(url)
              .width(64)
              .height(64)
              .borderRadius(8)
              .objectFit(ImageFit.Cover)
              .margin({ right: 6, bottom: 6 })
          }, (url: string, index: number) => `${index}-${url}`)
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SnapshotRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(12)
        .fontColor(MUTED_TEXT)
        .layoutWeight(1)
      Text(value)
        .fontSize(12)
        .fontColor(DEEP_TEXT)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding({ top: 2, bottom: 2 })
  }

  @Builder
  ReviewMeta(review: DoctorReviewItem) {
    Column({ space: 4 }) {
      Text(`审核记录 #${review.id} v${review.version}`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text(`状态：${this.statusLabel(review.status)}`)
        .fontSize(12)
        .fontColor(this.statusColor(review.status))
      if (review.reason && review.reason.length > 0) {
        Text(`上次意见：${review.reason}`)
          .fontSize(11)
          .fontColor(MUTED_TEXT)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  private licenseImageList(urls: string): string[] {
    return urls.split(',').filter((s: string) => s.trim().length > 0).map((s: string) => s.trim());
  }
}
