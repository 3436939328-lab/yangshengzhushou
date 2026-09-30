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
  ConsultationMessageItem,
  ConsultationThread,
  fetchAdminConsultations,
  fetchConsultationMessages
} from '../../services/ConsultationService';
import { AdminConsultationMetrics, buildAdminConsultationMetrics } from '../../services/AdminTabMetricsService';

@Component
export struct AdminConsultationsTab {
  @State consultations: ConsultationThread[] = [];
  @State messages: ConsultationMessageItem[] = [];
  @State selectedConsultationId: string = '';
  @State feedback: string = '';
  @State totalConsultationCount: number = 0;
  @State ongoingConsultationCount: number = 0;
  @State repliedConsultationCount: number = 0;

  aboutToAppear() {
    this.refreshConsultations();
  }

  build() {
    Column({ space: 14 }) {
      Text('问诊总览')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('管理员查看全部一对一问诊，并打开某条记录查看双方对话。')
        .fontSize(14)
        .fontColor(MUTED_TEXT)
        .lineHeight(22)

      Row({ space: 10 }) {
        AdminSummaryCard({ title: '总问诊', value: `${this.totalConsultationCount}` })
        AdminSummaryCard({ title: '进行中', value: `${this.ongoingConsultationCount}` })
        AdminSummaryCard({ title: '已回复', value: `${this.repliedConsultationCount}` })
      }
      .width('100%')

      Column({ space: 10 }) {
        Row() {
          Text('全部问诊')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
            .layoutWeight(1)
          Button('刷新')
            .fontSize(12)
            .fontColor(BRAND_GREEN)
            .backgroundColor('#EEF7F1')
            .borderRadius(12)
            .onClick(() => {
              this.refreshConsultations();
            })
        }

        if (this.feedback.length > 0) {
          Text(this.feedback)
            .fontSize(12)
            .fontColor(WARM_ACCENT)
        }

        if (this.consultations.length === 0) {
          Text('暂无一对一问诊记录。')
            .fontSize(13)
            .fontColor(MUTED_TEXT)
        } else {
          ForEach(this.consultations, (thread: ConsultationThread) => {
            Column({ space: 6 }) {
              Row() {
                Column({ space: 4 }) {
                  Text(thread.symptom.length > 0 ? thread.symptom : '未填写症状')
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(DEEP_TEXT)
                  Text(`用户 #${thread.userId} · 医生 #${thread.doctorId}`)
                    .fontSize(12)
                    .fontColor(MUTED_TEXT)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(thread.statusText)
                  .fontSize(12)
                  .fontColor(BRAND_GREEN)
              }

              if (thread.description.length > 0) {
                Text(thread.description)
                  .fontSize(12)
                  .fontColor(MUTED_TEXT)
                  .lineHeight(18)
              }
            }
            .width('100%')
            .padding(14)
            .backgroundColor(this.selectedConsultationId === thread.id ? '#EEF7F1' : '#FAFCFA')
            .borderRadius(CARD_RADIUS)
            .onClick(() => {
              this.selectedConsultationId = thread.id;
              this.loadMessages(thread.id);
            })
          }, (thread: ConsultationThread) => thread.id)
        }
      }
      .width('100%')
      .padding(18)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)

      Column({ space: 10 }) {
        Text('问诊详情')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)

        if (this.selectedConsultationId.length === 0) {
          Text('选择一条问诊后查看对话。')
            .fontSize(13)
            .fontColor(MUTED_TEXT)
        } else {
          Text(this.selectedThreadDescription())
            .fontSize(12)
            .fontColor(MUTED_TEXT)
            .lineHeight(18)

          if (this.messages.length === 0) {
            Text('暂无对话消息。')
              .fontSize(13)
              .fontColor(MUTED_TEXT)
          } else {
            ForEach(this.messages, (message: ConsultationMessageItem) => {
              this.MessageBubble(message)
            }, (message: ConsultationMessageItem) => message.id)
          }
        }
      }
      .width('100%')
      .padding(18)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  MessageBubble(message: ConsultationMessageItem) {
    Column({ space: 4 }) {
      Text(message.senderRole === 'DOCTOR' ? '医生' : '用户')
        .fontSize(11)
        .fontColor(message.senderRole === 'DOCTOR' ? BRAND_GREEN : MUTED_TEXT)
      Text(message.content)
        .fontSize(14)
        .fontColor(DEEP_TEXT)
        .lineHeight(21)
      if (message.createTime.length > 0) {
        Text(message.createTime)
          .fontSize(10)
          .fontColor(MUTED_TEXT)
      }
    }
    .alignItems(message.senderRole === 'DOCTOR' ? HorizontalAlign.End : HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(message.senderRole === 'DOCTOR' ? '#F4FAF6' : '#FFF8F0')
    .borderRadius(CARD_RADIUS)
  }

  private refreshConsultations(): void {
    fetchAdminConsultations().then((items: ConsultationThread[]) => {
      this.consultations = items;
      this.recalculateMetrics();
      this.feedback = '';
      if (items.length > 0 && this.selectedConsultationId.length === 0) {
        this.selectedConsultationId = items[0].id;
        this.loadMessages(items[0].id);
      }
    }).catch((error: Error) => {
      this.consultations = [];
      this.messages = [];
      this.recalculateMetrics();
      this.feedback = error.message.length > 0 ? error.message : '问诊记录暂时加载失败。';
    });
  }

  private loadMessages(consultationId: string): void {
    fetchConsultationMessages(consultationId).then((items: ConsultationMessageItem[]) => {
      this.messages = items;
    }).catch(() => {
      this.messages = [];
    });
  }

  private recalculateMetrics(): void {
    const metrics: AdminConsultationMetrics = buildAdminConsultationMetrics(this.consultations);
    this.totalConsultationCount = metrics.totalConsultations;
    this.ongoingConsultationCount = metrics.ongoingConsultations;
    this.repliedConsultationCount = metrics.repliedConsultations;
  }

  private selectedThreadDescription(): string {
    for (let index = 0; index < this.consultations.length; index++) {
      if (this.consultations[index].id === this.selectedConsultationId) {
        const thread = this.consultations[index];
        return `用户 #${thread.userId} · 医生 #${thread.doctorId} · ${thread.statusText}`;
      }
    }
    return '未找到问诊摘要。';
  }
}
