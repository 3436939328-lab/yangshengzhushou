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
  AdminAssistantLogGroup,
  AdminAssistantLogItem,
  buildAdminAssistantLogGroups,
  fetchAdminAssistantLogs
} from '../../services/AdminAssistantLogService';
import { AdminAssistantLogMetrics, buildAdminAssistantLogMetrics } from '../../services/AdminTabMetricsService';

@Component
export struct AdminAssistantLogsTab {
  @State logs: AdminAssistantLogItem[] = [];
  @State groups: AdminAssistantLogGroup[] = [];
  @State selectedUserId: string = '';
  @State feedback: string = '';
  @State totalLogCount: number = 0;
  @State logUserCount: number = 0;
  @State answeredLogCount: number = 0;

  aboutToAppear() {
    this.refreshLogs();
  }

  build() {
    Column({ space: 14 }) {
      Text('问答记录')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('管理员查看所有用户的养生助手问答总记录，点击用户后显示完整对话。')
        .fontSize(14)
        .fontColor(MUTED_TEXT)
        .lineHeight(22)

      Row({ space: 10 }) {
        AdminSummaryCard({ title: '总记录', value: `${this.totalLogCount}` })
        AdminSummaryCard({ title: '用户数', value: `${this.logUserCount}` })
        AdminSummaryCard({ title: '已回答', value: `${this.answeredLogCount}` })
      }
      .width('100%')

      if (this.selectedUserId.length > 0) {
        this.ConversationPanel()
      }

      Column({ space: 10 }) {
        Row() {
          Text('用户问答总览')
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
              this.refreshLogs();
            })
        }

        if (this.feedback.length > 0) {
          Text(this.feedback)
            .fontSize(12)
            .fontColor(WARM_ACCENT)
        }

        if (this.groups.length === 0) {
          Text('暂无养生助手问答记录。')
            .fontSize(13)
            .fontColor(MUTED_TEXT)
        } else {
          ForEach(this.groups, (group: AdminAssistantLogGroup) => {
            Column({ space: 6 }) {
              Row() {
                Column({ space: 4 }) {
                  Text(`用户 #${group.userId}`)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(DEEP_TEXT)
                  Text(group.latestQuestion.length > 0 ? group.latestQuestion : '暂无问题内容')
                    .fontSize(12)
                    .fontColor(MUTED_TEXT)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(`${group.answeredCount}/${group.totalCount}`)
                  .fontSize(12)
                  .fontColor(BRAND_GREEN)
              }

              if (group.latestTime.length > 0) {
                Text(group.latestTime)
                  .fontSize(11)
                  .fontColor(MUTED_TEXT)
              }
            }
            .width('100%')
            .padding(14)
            .backgroundColor(this.selectedUserId === group.userId ? '#EEF7F1' : '#FAFCFA')
            .borderRadius(CARD_RADIUS)
            .onClick(() => {
              this.selectedUserId = group.userId;
            })
          }, (group: AdminAssistantLogGroup) => group.userId)
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
  ConversationPanel() {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 4 }) {
          Text(`用户 #${this.selectedUserId} 的问答`)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          Text(`${this.selectedLogs().length} 条记录`)
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button('关闭')
          .fontSize(12)
          .fontColor(MUTED_TEXT)
          .backgroundColor('#F1F3F1')
          .borderRadius(12)
          .onClick(() => {
            this.selectedUserId = '';
          })
      }

      ForEach(this.selectedLogs(), (log: AdminAssistantLogItem) => {
        Column({ space: 8 }) {
          this.ChatBubble('用户', log.question, false)
          this.ChatBubble('助手', log.answer.length > 0 ? log.answer : '暂未回答', true)
        }
        .width('100%')
      }, (log: AdminAssistantLogItem) => log.id)
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(CARD_RADIUS)
    .border({ width: 1, color: '#D9E6DD' })
  }

  @Builder
  ChatBubble(role: string, content: string, isAssistant: boolean) {
    Column({ space: 4 }) {
      Text(role)
        .fontSize(11)
        .fontColor(isAssistant ? BRAND_GREEN : MUTED_TEXT)
      Text(content)
        .fontSize(14)
        .fontColor(DEEP_TEXT)
        .lineHeight(21)
    }
    .alignItems(isAssistant ? HorizontalAlign.Start : HorizontalAlign.End)
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor(isAssistant ? '#F4FAF6' : '#FFF8F0')
    .borderRadius(CARD_RADIUS)
  }

  private refreshLogs(): void {
    fetchAdminAssistantLogs().then((items: AdminAssistantLogItem[]) => {
      this.logs = items;
      this.groups = buildAdminAssistantLogGroups(items);
      this.recalculateMetrics();
      this.feedback = '';
      if (this.selectedUserId.length > 0 && this.selectedLogs().length === 0) {
        this.selectedUserId = '';
      }
    }).catch((error: Error) => {
      this.logs = [];
      this.groups = [];
      this.recalculateMetrics();
      this.feedback = error.message.length > 0 ? error.message : '问答记录暂时加载失败。';
    });
  }

  private selectedLogs(): AdminAssistantLogItem[] {
    for (let index = 0; index < this.groups.length; index++) {
      if (this.groups[index].userId === this.selectedUserId) {
        return this.groups[index].logs;
      }
    }
    return [];
  }

  private recalculateMetrics(): void {
    const metrics: AdminAssistantLogMetrics = buildAdminAssistantLogMetrics(this.logs, this.groups);
    this.totalLogCount = metrics.totalLogs;
    this.logUserCount = metrics.userCount;
    this.answeredLogCount = metrics.answeredLogs;
  }
}
