import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import { AdminSummaryCard } from '../cards/AdminSummaryCard';
import {
  AppealDetail,
  AppealItem,
  AppealListData,
  ComplaintDecisionItem,
  ComplaintDetail,
  ComplaintEventItem,
  ComplaintEvidenceItem,
  ComplaintItem,
  ComplaintListData,
  DoctorSanctionItem,
  SanctionPayload,
  fetchAdminAppealDetail,
  fetchAdminAppeals,
  fetchAdminComplaintDetail,
  fetchAdminComplaints,
  submitAppealReview,
  submitComplaintAction,
  submitComplaintDecision
} from '../../services/AdminComplaintService';

interface FilterOption {
  key: string;
  label: string;
}

interface SanctionTypeOption {
  key: string;
  label: string;
}

interface SeverityOption {
  key: string;
  label: string;
}

@Component
export struct AdminComplaintsTab {
  @State activeSection: string = 'complaints';
  @State complaints: ComplaintItem[] = [];
  @State complaintTotal: number = 0;
  @State complaintPage: number = 1;
  @State complaintPageSize: number = 20;
  @State complaintStatusFilter: string = 'SUBMITTED';
  @State selectedComplaintId: number = 0;
  @State complaintDetail: ComplaintDetail | null = null;
  @State loadingComplaints: boolean = false;
  @State complaintError: string = '';
  @State complaintFeedback: string = '';
  @State decisionResult: string = 'UPHELD';
  @State decisionSeverity: string = 'GENERAL';
  @State decisionReason: string = '';
  @State sanctionType: string = '';
  @State submittingDecision: boolean = false;

  @State appeals: AppealItem[] = [];
  @State appealTotal: number = 0;
  @State appealPage: number = 1;
  @State appealPageSize: number = 20;
  @State appealStatusFilter: string = 'PENDING';
  @State selectedAppealId: number = 0;
  @State appealDetail: AppealDetail | null = null;
  @State loadingAppeals: boolean = false;
  @State appealError: string = '';
  @State appealFeedback: string = '';
  @State appealDecision: string = 'MAINTAIN';
  @State appealReason: string = '';
  @State submittingAppeal: boolean = false;

  aboutToAppear() {
    this.refreshComplaints();
  }

  private refreshComplaints(): void {
    this.loadingComplaints = true;
    this.complaintError = '';
    this.complaintFeedback = '加载中...';
    fetchAdminComplaints(this.complaintStatusFilter, this.complaintPage, this.complaintPageSize)
      .then((data: ComplaintListData) => {
        this.complaints = data.items ? data.items : [];
        this.complaintTotal = data.total ? data.total : 0;
        this.loadingComplaints = false;
        this.complaintFeedback = this.complaints.length === 0 ? '当前没有匹配的投诉记录' : '';
      })
      .catch((error: Error) => {
        this.loadingComplaints = false;
        this.complaintFeedback = '';
        this.complaintError = error.message ? error.message : '加载失败';
      });
  }

  private refreshAppeals(): void {
    this.loadingAppeals = true;
    this.appealError = '';
    this.appealFeedback = '加载中...';
    fetchAdminAppeals(this.appealStatusFilter, this.appealPage, this.appealPageSize)
      .then((data: AppealListData) => {
        this.appeals = data.items ? data.items : [];
        this.appealTotal = data.total ? data.total : 0;
        this.loadingAppeals = false;
        this.appealFeedback = this.appeals.length === 0 ? '当前没有匹配的申诉记录' : '';
      })
      .catch((error: Error) => {
        this.loadingAppeals = false;
        this.appealFeedback = '';
        this.appealError = error.message ? error.message : '加载失败';
      });
  }

  private loadComplaintDetail(complaintId: number): void {
    this.selectedComplaintId = complaintId;
    this.complaintFeedback = '加载详情...';
    fetchAdminComplaintDetail(complaintId)
      .then((data: ComplaintDetail) => {
        this.complaintDetail = data;
        this.complaintFeedback = '';
        if (data.complaint) {
          this.decisionReason = '';
          this.sanctionType = '';
        }
      })
      .catch((error: Error) => {
        this.complaintFeedback = error.message ? error.message : '加载详情失败';
      });
  }

  private loadAppealDetail(appealId: number): void {
    this.selectedAppealId = appealId;
    this.appealFeedback = '加载详情...';
    fetchAdminAppealDetail(appealId)
      .then((data: AppealDetail) => {
        this.appealDetail = data;
        this.appealFeedback = '';
        this.appealReason = '';
      })
      .catch((error: Error) => {
        this.appealFeedback = error.message ? error.message : '加载详情失败';
      });
  }

  private complaintStatusLabel(status: string): string {
    switch (status) {
      case 'SUBMITTED': return '待处理';
      case 'REVIEWING': return '审核中';
      case 'NEED_INFO': return '需补充';
      case 'UPHELD': return '已成立';
      case 'REJECTED': return '已驳回';
      case 'MERGED': return '已合并';
      default: return status;
    }
  }

  private complaintStatusColor(status: string): ResourceColor {
    switch (status) {
      case 'UPHELD': return WARM_ACCENT;
      case 'REJECTED': return MUTED_TEXT;
      case 'REVIEWING': return '#FF9800';
      case 'NEED_INFO': return '#FF9800';
      case 'SUBMITTED': return '#2196F3';
      default: return MUTED_TEXT;
    }
  }

  private appealStatusLabel(status: string): string {
    switch (status) {
      case 'PENDING': return '待审核';
      case 'REVIEWING': return '审核中';
      case 'MAINTAINED': return '已维持';
      case 'REDUCED': return '已减轻';
      case 'REVOKED': return '已撤销';
      default: return status;
    }
  }

  private appealStatusColor(status: string): ResourceColor {
    switch (status) {
      case 'PENDING': return '#FF9800';
      case 'MAINTAINED': return WARM_ACCENT;
      case 'REDUCED': return '#FF9800';
      case 'REVOKED': return BRAND_GREEN;
      default: return MUTED_TEXT;
    }
  }

  private sanctionTypeLabel(type: string): string {
    switch (type) {
      case 'WARNING': return '警告';
      case 'SUSPEND_1D': return '暂停1天';
      case 'SUSPEND_7D': return '暂停7天';
      case 'SUSPEND_30D': return '暂停30天';
      case 'PERMANENT_BAN': return '永久封禁';
      default: return type;
    }
  }

  private sanctionStatusLabel(status: string): string {
    switch (status) {
      case 'ACTIVE': return '生效中';
      case 'EXPIRED': return '已过期';
      case 'REVOKED': return '已撤销';
      default: return status;
    }
  }

  private formatTime(time?: string): string {
    if (!time || time.length === 0) return '-';
    return time.replace('T', ' ').substring(0, 16);
  }

  private doSubmitComplaintAction(action: string): void {
    const complaint = this.complaintDetail && this.complaintDetail.complaint ? this.complaintDetail.complaint : null;
    if (!complaint) {
      this.complaintFeedback = '投诉记录信息缺失';
      return;
    }
    this.complaintFeedback = `${action === 'CLAIM' ? '受理' : '要求补充'}中...`;
    submitComplaintAction(this.selectedComplaintId, action, this.decisionReason, complaint.version)
      .then(() => {
        this.complaintFeedback = '操作完成';
        this.loadComplaintDetail(this.selectedComplaintId);
        this.refreshComplaints();
      })
      .catch((error: Error) => {
        this.complaintFeedback = error.message ? error.message : '操作失败';
      });
  }

  private doSubmitDecision(): void {
    if (this.submittingDecision) return;
    const complaint = this.complaintDetail && this.complaintDetail.complaint ? this.complaintDetail.complaint : null;
    if (!complaint) {
      this.complaintFeedback = '投诉记录信息缺失';
      return;
    }
    if (this.decisionReason.trim().length === 0) {
      this.complaintFeedback = '请填写审核理由';
      return;
    }
    this.submittingDecision = true;
    this.complaintFeedback = '提交决策中...';
    let sanction: SanctionPayload | undefined = undefined;
    if (this.decisionResult === 'UPHELD' && this.sanctionType.length > 0) {
      const payload: SanctionPayload = { type: this.sanctionType };
      sanction = payload;
    }
    submitComplaintDecision(this.selectedComplaintId, this.decisionResult, this.decisionSeverity, this.decisionReason, complaint.version, sanction)
      .then(() => {
        this.submittingDecision = false;
        this.complaintFeedback = '决策已保存';
        this.complaintDetail = null;
        this.selectedComplaintId = 0;
        this.decisionReason = '';
        this.sanctionType = '';
        this.refreshComplaints();
      })
      .catch((error: Error) => {
        this.submittingDecision = false;
        this.complaintFeedback = error.message ? error.message : '提交决策失败';
      });
  }

  private doSubmitAppealReview(): void {
    if (this.submittingAppeal) return;
    const appeal = this.appealDetail && this.appealDetail.appeal ? this.appealDetail.appeal : null;
    if (!appeal) {
      this.appealFeedback = '申诉记录信息缺失';
      return;
    }
    if (this.appealReason.trim().length === 0) {
      this.appealFeedback = '请填写复核理由';
      return;
    }
    this.submittingAppeal = true;
    this.appealFeedback = '提交复核中...';
    submitAppealReview(this.selectedAppealId, this.appealDecision, this.appealReason, appeal.version)
      .then(() => {
        this.submittingAppeal = false;
        this.appealFeedback = '复核已完成';
        this.appealDetail = null;
        this.selectedAppealId = 0;
        this.appealReason = '';
        this.refreshAppeals();
      })
      .catch((error: Error) => {
        this.submittingAppeal = false;
        this.appealFeedback = error.message ? error.message : '提交复核失败';
      });
  }

  build() {
    Column({ space: 14 }) {
      Text('投诉管理')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('管理员处理用户投诉、做出判定、审核医生申诉。')
        .fontSize(14)
        .fontColor(MUTED_TEXT)
        .lineHeight(22)

      this.SectionSwitch()

      if (this.activeSection === 'complaints') {
        this.ComplaintsSection()
      } else {
        this.AppealsSection()
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  SectionSwitch() {
    Row({ space: 0 }) {
      Text('投诉处理')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.activeSection === 'complaints' ? Color.White : DEEP_TEXT)
        .backgroundColor(this.activeSection === 'complaints' ? BRAND_GREEN : CARD_BG)
        .borderRadius({ topLeft: 8, bottomLeft: 8 })
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (this.activeSection !== 'complaints') {
            this.activeSection = 'complaints';
            if (this.complaints.length === 0) {
              this.refreshComplaints();
            }
          }
        })
      Text('申诉审核')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.activeSection === 'appeals' ? Color.White : DEEP_TEXT)
        .backgroundColor(this.activeSection === 'appeals' ? BRAND_GREEN : CARD_BG)
        .borderRadius({ topRight: 8, bottomRight: 8 })
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          if (this.activeSection !== 'appeals') {
            this.activeSection = 'appeals';
            if (this.appeals.length === 0) {
              this.refreshAppeals();
            }
          }
        })
    }
    .width('100%')
    .border({ width: 1, color: MUTED_TEXT, radius: 8 })
  }

  @Builder
  ComplaintsSection() {
    Column({ space: 14 }) {
      this.ComplaintFilterPanel()
      this.ComplaintListPanel()
      if (this.selectedComplaintId > 0) {
        this.ComplaintDetailPanel()
      }
    }
    .width('100%')
  }

  @Builder
  ComplaintFilterPanel() {
    Column({ space: 10 }) {
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(
          [
            { key: 'SUBMITTED', label: '待处理' } as FilterOption,
            { key: 'REVIEWING', label: '审核中' } as FilterOption,
            { key: 'NEED_INFO', label: '需补充' } as FilterOption,
            { key: 'UPHELD', label: '已成立' } as FilterOption,
            { key: 'REJECTED', label: '已驳回' } as FilterOption,
            { key: 'ALL', label: '全部' } as FilterOption
          ],
          (option: FilterOption) => {
            Text(option.label)
              .fontSize(13)
              .fontColor(this.complaintStatusFilter === option.key ? Color.White : DEEP_TEXT)
              .backgroundColor(this.complaintStatusFilter === option.key ? BRAND_GREEN : CARD_BG)
              .border({ width: 1, color: this.complaintStatusFilter === option.key ? BRAND_GREEN : MUTED_TEXT })
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.complaintStatusFilter = option.key;
                this.complaintPage = 1;
                this.refreshComplaints();
              })
          },
          (option: FilterOption) => option.key
        )
      }
      .width('100%')

      Row({ space: 10 }) {
        AdminSummaryCard({ title: '总投诉', value: `${this.complaintTotal}` })
        AdminSummaryCard({ title: '待处理', value: `${this.countByStatus('SUBMITTED')}` })
        AdminSummaryCard({ title: '已成立', value: `${this.countByStatus('UPHELD')}` })
      }
      .width('100%')
    }
    .width('100%')
  }

  private countByStatus(status: string): number {
    if (this.complaintStatusFilter === status || this.complaintStatusFilter === 'ALL') {
      return this.complaintTotal;
    }
    return 0;
  }

  @Builder
  ComplaintListPanel() {
    Column({ space: 10 }) {
      Row() {
        Text('投诉列表')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .layoutWeight(1)
        Button('刷新')
          .height(28)
          .fontSize(12)
          .fontColor(BRAND_GREEN)
          .backgroundColor('#EEF7F1')
          .borderRadius(12)
          .onClick(() => { this.refreshComplaints(); })
      }
      .width('100%')

      if (this.loadingComplaints) {
        Text('加载中...')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 20, bottom: 20 })
      } else if (this.complaintError.length > 0) {
        Column({ space: 8 }) {
          Text(this.complaintError)
            .fontSize(13)
            .fontColor(WARM_ACCENT)
            .textAlign(TextAlign.Center)
          Button('重试')
            .height(32)
            .fontSize(12)
            .fontColor(BRAND_GREEN)
            .backgroundColor(CARD_BG)
            .border({ width: 1, color: BRAND_GREEN })
            .borderRadius(CARD_RADIUS)
            .onClick(() => { this.refreshComplaints(); })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 20, bottom: 20 })
      } else if (this.complaints.length === 0) {
        Text('暂无投诉记录')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 20, bottom: 20 })
      } else {
        ForEach(this.complaints, (item: ComplaintItem) => {
          Row() {
            Column({ space: 4 }) {
              Text(`投诉 #${item.id}`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(DEEP_TEXT)
              if (item.description && item.description.length > 0) {
                Text(item.description.length > 40 ? `${item.description.substring(0, 40)}...` : item.description)
                  .fontSize(11)
                  .fontColor(MUTED_TEXT)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              Text(`提交时间：${this.formatTime(item.createdAt)}`)
                .fontSize(11)
                .fontColor(MUTED_TEXT)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text(this.complaintStatusLabel(item.status))
              .fontSize(12)
              .fontColor(this.complaintStatusColor(item.status))
              .fontWeight(FontWeight.Medium)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(CARD_BG)
              .borderRadius(8)

            Text('查看')
              .fontSize(12)
              .fontColor(BRAND_GREEN)
              .padding({ left: 8 })
              .onClick(() => {
                this.loadComplaintDetail(item.id);
              })
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .backgroundColor(this.selectedComplaintId === item.id ? '#EEF7F1' : CARD_BG)
          .borderRadius(CARD_RADIUS)
        }, (item: ComplaintItem) => `${item.id}`)
      }

      if (this.complaintTotal > this.complaintPageSize) {
        Row({ space: 8 }) {
          Button('上一页')
            .height(36)
            .fontSize(13)
            .fontColor(BRAND_GREEN)
            .backgroundColor(CARD_BG)
            .border({ width: 1, color: BRAND_GREEN })
            .borderRadius(CARD_RADIUS)
            .enabled(this.complaintPage > 1)
            .onClick(() => {
              this.complaintPage = this.complaintPage - 1;
              this.refreshComplaints();
            })
          Text(`第 ${this.complaintPage} 页 / 共 ${Math.ceil(this.complaintTotal / this.complaintPageSize)} 页`)
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
            .enabled(this.complaintPage * this.complaintPageSize < this.complaintTotal)
            .onClick(() => {
              this.complaintPage = this.complaintPage + 1;
              this.refreshComplaints();
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
  ComplaintDetailPanel() {
    Column({ space: 12 }) {
      Row() {
        Text('投诉详情')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .layoutWeight(1)
        Text('关闭')
          .fontSize(12)
          .fontColor(WARM_ACCENT)
          .onClick(() => {
            this.selectedComplaintId = 0;
            this.complaintDetail = null;
            this.complaintFeedback = '';
          })
      }
      .width('100%')

      if (this.complaintDetail && this.complaintDetail.complaint) {
        this.ComplaintInfo(this.complaintDetail.complaint)
      }

      if (this.complaintDetail && this.complaintDetail.event) {
        this.EventInfo(this.complaintDetail.event)
      }

      if (this.complaintDetail && this.complaintDetail.evidence && this.complaintDetail.evidence.length > 0) {
        Column({ space: 6 }) {
          Text('证据材料')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          ForEach(this.complaintDetail.evidence, (ev: ComplaintEvidenceItem) => {
            Row() {
              Text(`证据 #${ev.id}`)
                .fontSize(12)
                .fontColor(DEEP_TEXT)
                .layoutWeight(1)
              Text(ev.summary ? ev.summary : '无摘要')
                .fontSize(11)
                .fontColor(MUTED_TEXT)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
          }, (ev: ComplaintEvidenceItem) => `${ev.id}`)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      if (this.complaintDetail && this.complaintDetail.decisions && this.complaintDetail.decisions.length > 0) {
        Column({ space: 6 }) {
          Text('判定记录')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          ForEach(this.complaintDetail.decisions, (dec: ComplaintDecisionItem) => {
            Row() {
              Text(dec.result === 'UPHELD' ? '成立' : '驳回')
                .fontSize(12)
                .fontColor(dec.result === 'UPHELD' ? WARM_ACCENT : MUTED_TEXT)
                .layoutWeight(1)
              if (dec.severity) {
                Text(dec.severity === 'SERIOUS' ? '严重' : '一般')
                  .fontSize(11)
                  .fontColor(MUTED_TEXT)
              }
              Text(this.formatTime(dec.createdAt))
                .fontSize(11)
                .fontColor(MUTED_TEXT)
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
            if (dec.reason && dec.reason.length > 0) {
              Text(`理由：${dec.reason}`)
                .fontSize(11)
                .fontColor(MUTED_TEXT)
            }
          }, (dec: ComplaintDecisionItem) => `${dec.id}`)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      if (this.complaintDetail && this.complaintDetail.sanctions && this.complaintDetail.sanctions.length > 0) {
        Column({ space: 6 }) {
          Text('处罚记录')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          ForEach(this.complaintDetail.sanctions, (s: DoctorSanctionItem) => {
            Row() {
              Text(this.sanctionTypeLabel(s.type))
                .fontSize(12)
                .fontColor(WARM_ACCENT)
                .layoutWeight(1)
              Text(this.sanctionStatusLabel(s.status))
                .fontSize(11)
                .fontColor(s.status === 'ACTIVE' ? WARM_ACCENT : MUTED_TEXT)
              Text(this.formatTime(s.startsAt))
                .fontSize(11)
                .fontColor(MUTED_TEXT)
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
          }, (s: DoctorSanctionItem) => `${s.id}`)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      if (this.complaintDetail && this.complaintDetail.complaint &&
          (this.complaintDetail.complaint.status === 'SUBMITTED' ||
           this.complaintDetail.complaint.status === 'REVIEWING' ||
           this.complaintDetail.complaint.status === 'NEED_INFO')) {
        this.ComplaintActionPanel(this.complaintDetail.complaint.status)
        this.ComplaintDecisionForm()
      }

      if (this.complaintFeedback.length > 0) {
        Text(this.complaintFeedback)
          .fontSize(12)
          .fontColor(this.complaintFeedback.indexOf('完成') >= 0 || this.complaintFeedback.indexOf('已保存') >= 0 ? BRAND_GREEN : WARM_ACCENT)
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
  ComplaintInfo(complaint: ComplaintItem) {
    Column({ space: 4 }) {
      Text(`投诉 #${complaint.id}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text(`状态：${this.complaintStatusLabel(complaint.status)}`)
        .fontSize(12)
        .fontColor(this.complaintStatusColor(complaint.status))
      Text(`投诉人：用户 #${complaint.reporterId}`)
        .fontSize(12)
        .fontColor(MUTED_TEXT)
      Text(`提交时间：${this.formatTime(complaint.createdAt)}`)
        .fontSize(12)
        .fontColor(MUTED_TEXT)
      if (complaint.description && complaint.description.length > 0) {
        Text(`描述：${complaint.description}`)
          .fontSize(12)
          .fontColor(DEEP_TEXT)
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  EventInfo(event: ComplaintEventItem) {
    Column({ space: 4 }) {
      Text('投诉事件')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text(`被投诉医生：用户 #${event.doctorId}`)
        .fontSize(12)
        .fontColor(MUTED_TEXT)
      Text(`投诉类别：${event.category}`)
        .fontSize(12)
        .fontColor(MUTED_TEXT)
      if (event.effectiveDecision) {
        Text(`最终判定：${event.effectiveDecision === 'UPHELD' ? '成立' : '驳回'}`)
          .fontSize(12)
          .fontColor(event.effectiveDecision === 'UPHELD' ? WARM_ACCENT : MUTED_TEXT)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 4 })
  }

  @Builder
  ComplaintActionPanel(status: string) {
    Column({ space: 8 }) {
      Text('快速操作')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      Row({ space: 8 }) {
        if (status === 'SUBMITTED' || status === 'REVIEWING') {
          Button('受理')
            .height(36)
            .fontSize(13)
            .fontColor(Color.White)
            .backgroundColor(BRAND_GREEN)
            .borderRadius(CARD_RADIUS)
            .layoutWeight(1)
            .onClick(() => { this.doSubmitComplaintAction('CLAIM'); })
        }
        if (status === 'SUBMITTED' || status === 'REVIEWING') {
          Button('要求补充')
            .height(36)
            .fontSize(13)
            .fontColor(WARM_ACCENT)
            .backgroundColor(CARD_BG)
            .border({ width: 1, color: WARM_ACCENT })
            .borderRadius(CARD_RADIUS)
            .layoutWeight(1)
            .onClick(() => { this.doSubmitComplaintAction('REQUEST_INFO'); })
        }
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 8 })
  }

  @Builder
  ComplaintDecisionForm() {
    Column({ space: 8 }) {
      Text('审核决策')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      Row({ space: 8 }) {
        this.DecisionButton('成立', 'UPHELD')
        this.DecisionButton('驳回', 'REJECTED')
      }
      .width('100%')

      if (this.decisionResult === 'UPHELD') {
        Row({ space: 8 }) {
          this.SeverityButton('一般', 'GENERAL')
          this.SeverityButton('严重', 'SERIOUS')
        }
        .width('100%')

        Text('处罚措施')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(
            [
              { key: '', label: '不处罚' } as SanctionTypeOption,
              { key: 'WARNING', label: '警告' } as SanctionTypeOption,
              { key: 'SUSPEND_1D', label: '暂停1天' } as SanctionTypeOption,
              { key: 'SUSPEND_7D', label: '暂停7天' } as SanctionTypeOption,
              { key: 'SUSPEND_30D', label: '暂停30天' } as SanctionTypeOption,
              { key: 'PERMANENT_BAN', label: '永久封禁' } as SanctionTypeOption
            ],
            (option: SanctionTypeOption) => {
              Text(option.label)
                .fontSize(12)
                .fontColor(this.sanctionType === option.key ? Color.White : DEEP_TEXT)
                .backgroundColor(this.sanctionType === option.key ? WARM_ACCENT : CARD_BG)
                .border({ width: 1, color: this.sanctionType === option.key ? WARM_ACCENT : MUTED_TEXT })
                .borderRadius(12)
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .margin({ right: 6, bottom: 6 })
                .onClick(() => { this.sanctionType = option.key; })
            },
            (option: SanctionTypeOption) => option.key
          )
        }
        .width('100%')
      }

      TextArea({ placeholder: '审核理由（必填）', text: this.decisionReason })
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
        .enabled(!this.submittingDecision)
        .onClick(() => { this.doSubmitDecision(); })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 8 })
  }

  @Builder
  DecisionButton(label: string, value: string) {
    Text(label)
      .fontSize(13)
      .fontColor(this.decisionResult === value ? Color.White : DEEP_TEXT)
      .backgroundColor(this.decisionResult === value ? (value === 'UPHELD' ? WARM_ACCENT : BRAND_GREEN) : CARD_BG)
      .border({ width: 1, color: this.decisionResult === value ? (value === 'UPHELD' ? WARM_ACCENT : BRAND_GREEN) : MUTED_TEXT })
      .borderRadius(CARD_RADIUS)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => { this.decisionResult = value; })
  }

  @Builder
  SeverityButton(label: string, value: string) {
    Text(label)
      .fontSize(13)
      .fontColor(this.decisionSeverity === value ? Color.White : DEEP_TEXT)
      .backgroundColor(this.decisionSeverity === value ? WARM_ACCENT : CARD_BG)
      .border({ width: 1, color: this.decisionSeverity === value ? WARM_ACCENT : MUTED_TEXT })
      .borderRadius(CARD_RADIUS)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => { this.decisionSeverity = value; })
  }

  @Builder
  AppealsSection() {
    Column({ space: 14 }) {
      this.AppealFilterPanel()
      this.AppealListPanel()
      if (this.selectedAppealId > 0) {
        this.AppealDetailPanel()
      }
    }
    .width('100%')
  }

  @Builder
  AppealFilterPanel() {
    Column({ space: 10 }) {
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(
          [
            { key: 'PENDING', label: '待审核' } as FilterOption,
            { key: 'REVIEWING', label: '审核中' } as FilterOption,
            { key: 'MAINTAINED', label: '已维持' } as FilterOption,
            { key: 'REDUCED', label: '已减轻' } as FilterOption,
            { key: 'REVOKED', label: '已撤销' } as FilterOption,
            { key: 'ALL', label: '全部' } as FilterOption
          ],
          (option: FilterOption) => {
            Text(option.label)
              .fontSize(13)
              .fontColor(this.appealStatusFilter === option.key ? Color.White : DEEP_TEXT)
              .backgroundColor(this.appealStatusFilter === option.key ? BRAND_GREEN : CARD_BG)
              .border({ width: 1, color: this.appealStatusFilter === option.key ? BRAND_GREEN : MUTED_TEXT })
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.appealStatusFilter = option.key;
                this.appealPage = 1;
                this.refreshAppeals();
              })
          },
          (option: FilterOption) => option.key
        )
      }
      .width('100%')

      Row({ space: 10 }) {
        AdminSummaryCard({ title: '总申诉', value: `${this.appealTotal}` })
        AdminSummaryCard({ title: '待审核', value: `${this.appealTotal}` })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  AppealListPanel() {
    Column({ space: 10 }) {
      Row() {
        Text('申诉列表')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .layoutWeight(1)
        Button('刷新')
          .height(28)
          .fontSize(12)
          .fontColor(BRAND_GREEN)
          .backgroundColor('#EEF7F1')
          .borderRadius(12)
          .onClick(() => { this.refreshAppeals(); })
      }
      .width('100%')

      if (this.loadingAppeals) {
        Text('加载中...')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 20, bottom: 20 })
      } else if (this.appealError.length > 0) {
        Column({ space: 8 }) {
          Text(this.appealError)
            .fontSize(13)
            .fontColor(WARM_ACCENT)
            .textAlign(TextAlign.Center)
          Button('重试')
            .height(32)
            .fontSize(12)
            .fontColor(BRAND_GREEN)
            .backgroundColor(CARD_BG)
            .border({ width: 1, color: BRAND_GREEN })
            .borderRadius(CARD_RADIUS)
            .onClick(() => { this.refreshAppeals(); })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 20, bottom: 20 })
      } else if (this.appeals.length === 0) {
        Text('暂无申诉记录')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 20, bottom: 20 })
      } else {
        ForEach(this.appeals, (item: AppealItem) => {
          Row() {
            Column({ space: 4 }) {
              Text(`申诉 #${item.id}`)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(DEEP_TEXT)
              Text(`医生 #${item.doctorId}`)
                .fontSize(11)
                .fontColor(MUTED_TEXT)
              Text(`提交时间：${this.formatTime(item.createdAt)}`)
                .fontSize(11)
                .fontColor(MUTED_TEXT)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Text(this.appealStatusLabel(item.status))
              .fontSize(12)
              .fontColor(this.appealStatusColor(item.status))
              .fontWeight(FontWeight.Medium)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(CARD_BG)
              .borderRadius(8)

            Text('查看')
              .fontSize(12)
              .fontColor(BRAND_GREEN)
              .padding({ left: 8 })
              .onClick(() => {
                this.loadAppealDetail(item.id);
              })
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .backgroundColor(this.selectedAppealId === item.id ? '#EEF7F1' : CARD_BG)
          .borderRadius(CARD_RADIUS)
        }, (item: AppealItem) => `${item.id}`)
      }

      if (this.appealTotal > this.appealPageSize) {
        Row({ space: 8 }) {
          Button('上一页')
            .height(36)
            .fontSize(13)
            .fontColor(BRAND_GREEN)
            .backgroundColor(CARD_BG)
            .border({ width: 1, color: BRAND_GREEN })
            .borderRadius(CARD_RADIUS)
            .enabled(this.appealPage > 1)
            .onClick(() => {
              this.appealPage = this.appealPage - 1;
              this.refreshAppeals();
            })
          Text(`第 ${this.appealPage} 页 / 共 ${Math.ceil(this.appealTotal / this.appealPageSize)} 页`)
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
            .enabled(this.appealPage * this.appealPageSize < this.appealTotal)
            .onClick(() => {
              this.appealPage = this.appealPage + 1;
              this.refreshAppeals();
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
  AppealDetailPanel() {
    Column({ space: 12 }) {
      Row() {
        Text('申诉详情')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .layoutWeight(1)
        Text('关闭')
          .fontSize(12)
          .fontColor(WARM_ACCENT)
          .onClick(() => {
            this.selectedAppealId = 0;
            this.appealDetail = null;
            this.appealFeedback = '';
          })
      }
      .width('100%')

      if (this.appealDetail && this.appealDetail.appeal) {
        this.AppealInfo(this.appealDetail.appeal)
      }

      if (this.appealDetail && this.appealDetail.originalDecision) {
        this.OriginalDecisionInfo(this.appealDetail.originalDecision)
      }

      if (this.appealDetail && this.appealDetail.complaint) {
        Column({ space: 4 }) {
          Text('原投诉')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          Text(`投诉 #${this.appealDetail.complaint.id} 状态：${this.complaintStatusLabel(this.appealDetail.complaint.status)}`)
            .fontSize(12)
            .fontColor(MUTED_TEXT)
          if (this.appealDetail.complaint.description) {
            Text(this.appealDetail.complaint.description)
              .fontSize(12)
              .fontColor(DEEP_TEXT)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 4 })
      }

      if (this.appealDetail && this.appealDetail.sanctions && this.appealDetail.sanctions.length > 0) {
        Column({ space: 6 }) {
          Text('相关处罚')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          ForEach(this.appealDetail.sanctions, (s: DoctorSanctionItem) => {
            Row() {
              Text(this.sanctionTypeLabel(s.type))
                .fontSize(12)
                .fontColor(WARM_ACCENT)
                .layoutWeight(1)
              Text(this.sanctionStatusLabel(s.status))
                .fontSize(11)
                .fontColor(s.status === 'ACTIVE' ? WARM_ACCENT : MUTED_TEXT)
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
          }, (s: DoctorSanctionItem) => `${s.id}`)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      if (this.appealDetail && this.appealDetail.appeal &&
          (this.appealDetail.appeal.status === 'PENDING' ||
           this.appealDetail.appeal.status === 'REVIEWING')) {
        this.AppealReviewForm()
      }

      if (this.appealFeedback.length > 0) {
        Text(this.appealFeedback)
          .fontSize(12)
          .fontColor(this.appealFeedback.indexOf('完成') >= 0 ? BRAND_GREEN : WARM_ACCENT)
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
  AppealInfo(appeal: AppealItem) {
    Column({ space: 4 }) {
      Text(`申诉 #${appeal.id}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text(`状态：${this.appealStatusLabel(appeal.status)}`)
        .fontSize(12)
        .fontColor(this.appealStatusColor(appeal.status))
      Text(`申诉医生：用户 #${appeal.doctorId}`)
        .fontSize(12)
        .fontColor(MUTED_TEXT)
      Text(`提交时间：${this.formatTime(appeal.createdAt)}`)
        .fontSize(12)
        .fontColor(MUTED_TEXT)
      if (appeal.reason && appeal.reason.length > 0) {
        Text(`申诉理由：${appeal.reason}`)
          .fontSize(12)
          .fontColor(DEEP_TEXT)
          .margin({ top: 4 })
      }
      if (appeal.resultReason && appeal.resultReason.length > 0) {
        Text(`复核结论：${appeal.resultReason}`)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  OriginalDecisionInfo(decision: ComplaintDecisionItem) {
    Column({ space: 4 }) {
      Text('原判定')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text(`判定结果：${decision.result === 'UPHELD' ? '成立' : '驳回'}`)
        .fontSize(12)
        .fontColor(decision.result === 'UPHELD' ? WARM_ACCENT : MUTED_TEXT)
      if (decision.severity) {
        Text(`严重程度：${decision.severity === 'SERIOUS' ? '严重' : '一般'}`)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
      }
      if (decision.reason) {
        Text(`判定理由：${decision.reason}`)
          .fontSize(12)
          .fontColor(MUTED_TEXT)
      }
      Text(`判定时间：${this.formatTime(decision.createdAt)}`)
        .fontSize(12)
        .fontColor(MUTED_TEXT)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 4 })
  }

  @Builder
  AppealReviewForm() {
    Column({ space: 8 }) {
      Text('申诉复核')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      Row({ space: 8 }) {
        this.ReviewButton('维持', 'MAINTAIN')
        this.ReviewButton('减轻', 'REDUCE')
        this.ReviewButton('撤销', 'REVOKE')
      }
      .width('100%')

      TextArea({ placeholder: '复核理由（必填）', text: this.appealReason })
        .height(72)
        .fontSize(13)
        .backgroundColor('#F6F8F5')
        .borderRadius(CARD_RADIUS)
        .onChange((value: string) => { this.appealReason = value; })

      Button('提交复核')
        .width('100%')
        .height(42)
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor(BRAND_GREEN)
        .borderRadius(CARD_RADIUS)
        .enabled(!this.submittingAppeal)
        .onClick(() => { this.doSubmitAppealReview(); })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 8 })
  }

  @Builder
  ReviewButton(label: string, value: string) {
    Text(label)
      .fontSize(13)
      .fontColor(this.appealDecision === value ? Color.White : DEEP_TEXT)
      .backgroundColor(this.appealDecision === value ? (value === 'REVOKE' ? BRAND_GREEN : WARM_ACCENT) : CARD_BG)
      .border({ width: 1, color: this.appealDecision === value ? (value === 'REVOKE' ? BRAND_GREEN : WARM_ACCENT) : MUTED_TEXT })
      .borderRadius(CARD_RADIUS)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => { this.appealDecision = value; })
  }
}
