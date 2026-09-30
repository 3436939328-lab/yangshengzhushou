import { common } from '@kit.AbilityKit';
import { HealthProfile, QuestionnaireRecord } from '../../model/ProfileModels';
import {
  ChatMessage,
  WeatherWellness,
  WellnessPlanItem
} from '../../model/WellnessModels';
import {
  AssistantReplyResult,
  buildAssistantReplyFromBackendPayload,
  recoverChatReply,
  buildUnavailableAssistantReply,
  requestAssistantReplyRemoteFirst
} from '../../services/AssistantReplyService';
import { newRequestId, getRewardAccount, RewardAccount, RemoteRequestError } from '../../services/RewardsService';
import { BackendStatus, checkBackendHealth, getBackendStatus } from '../../services/BackendStatusService';
import {
  ChatHistoryRepository,
  createPreferencesChatHistoryRepository
} from '../../services/ChatHistoryRepository';
import { getAssistantMessages } from '../../services/WellnessContentService';
import {
  appendAssistantReplyResult,
  appendUserQuestion,
  buildAssistantSourceText,
  canSendAssistantQuestion
} from '../../viewmodel/ProfileViewModel';
import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import {
  HealthProfileRepository,
  createDefaultHealthProfile,
  createPreferencesHealthProfileRepository
} from '../../services/ProfileRepository';
import { LoadStateNotice } from '../cards/LoadStateNotice';
import { QuestionnaireFlow } from '../questionnaire/QuestionnaireFlow';
import { SectionTitle } from '../cards/CommonCards';

@Component
export struct AssistantTab {
  @Link questionnaireScore: number;
  @Prop weather: WeatherWellness;
  @Prop authUserId: string;
  @Prop profile: HealthProfile;
  @Prop initialQuestion: string = '';
  onDraftConsumed?: () => void;
  onProfileChanged?: (profile: HealthProfile) => void;

  @State localProfile: HealthProfile = createDefaultHealthProfile();
  @State profileLoadError: string = '';
  @State messages: ChatMessage[] = getAssistantMessages();
  @State draftQuestion: string = '';
  @State backendStatus: BackendStatus = getBackendStatus();
  @State isSending: boolean = false;
  @State pendingClearChat: boolean = false;
  @State replyError: string = '';
  @State pendingRequestId: string = '';
  @State pointsText: string = '';
  @State historyReady: boolean = false;
  private messageScroller: Scroller = new Scroller();
  private active: boolean = false;
  private profileRepository?: HealthProfileRepository;
  private chatHistoryRepository?: ChatHistoryRepository;

  aboutToAppear() {
    this.active = true;
    this.draftQuestion = this.initialQuestion;
    if (this.onDraftConsumed) this.onDraftConsumed();
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.profileRepository = createPreferencesHealthProfileRepository(context, this.authUserId);
    this.chatHistoryRepository = createPreferencesChatHistoryRepository(context, this.authUserId);
    this.localProfile = this.profile;
    this.questionnaireScore = this.profile.constitution.score;
    this.profileLoadError = '';
    checkBackendHealth().then((status: BackendStatus) => {
      this.backendStatus = status;
    });
    this.restoreConversation();
    this.refreshPoints();
  }

  aboutToDisappear(): void { this.active = false; }

  private async restoreConversation(): Promise<void> {
    this.historyReady = false;
    if (!this.chatHistoryRepository) return;
    try {
      const messages = await this.chatHistoryRepository.loadMessages();
      const pending = await this.chatHistoryRepository.loadPending();
      if (!this.active) return;
      this.messages = messages;
      this.pendingRequestId = pending ? pending.id : '';
      this.replyError = pending ? '有一条问答等待确认结果' : '';
      this.historyReady = true;
      this.scrollMessagesToBottom();
    } catch (error) {
      if (this.active) this.replyError = '无法恢复会话，请检查设备存储后重试';
    }
  }

  build() {
    Column({ space: 14 }) {
      SectionTitle('大模型养生问答')
      Text(this.weatherStatusText())
        .fontSize(12)
        .fontColor(this.weather.isFallback === true ? WARM_ACCENT : BRAND_GREEN)
        .lineHeight(18)
      Row() {
        Blank()
        Text(this.pendingClearChat ? '确认清空' : '清空对话')
          .fontSize(12)
          .fontColor(this.pendingClearChat ? WARM_ACCENT : MUTED_TEXT)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(this.pendingClearChat ? '#FFF2E8' : '#F7F7F7')
          .borderRadius(12)
          .onClick(() => {
            this.handleClearChat();
          })
      }
      .width('100%')
      LoadStateNotice({ message: this.profileLoadError })
      this.ChatPanel()
      if (this.pointsText.length > 0) {
        Text(this.pointsText).fontSize(12).fontColor(MUTED_TEXT)
      }
      if (this.replyError.length > 0) {
        Text(this.replyError).fontSize(13).fontColor(WARM_ACCENT)
      }
      if (!this.historyReady) {
        Button('恢复会话').onClick(() => { this.restoreConversation(); })
      }
      if (this.pendingRequestId.length > 0 && !this.isSending) {
        Button('查询上次回答').onClick(() => { this.recoverPending(); })
      }
      Text(buildAssistantSourceText(this.latestAssistantSource(), this.backendStatus.mode))
        .fontSize(12)
        .fontColor(this.backendStatus.available ? BRAND_GREEN : MUTED_TEXT)
        .lineHeight(18)

      QuestionnaireFlow({
        onSubmit: (record: QuestionnaireRecord) => {
          this.questionnaireScore = record.totalScore;
          if (this.profileRepository) {
            return this.profileRepository.saveQuestionnaireRecord(record).then((profile: HealthProfile) => {
              this.applyProfile(profile);
              return true;
            }).catch(() => {
              return false;
            });
          }
          return Promise.resolve(false);
        }
      })

    }
    .margin({ top: 14 })
  }


  @Builder
  ChatPanel() {
    Column({ space: 12 }) {
      Scroll(this.messageScroller) {
        Column({ space: 10 }) {
          if (this.messages.length === 0 && this.draftQuestion.length === 0 && !this.isSending) {
            Text('今天有什么想聊的？').fontSize(16).fontColor(MUTED_TEXT).padding(20)
          }
          ForEach(this.messages, (message: ChatMessage) => {
            this.MessageBubble(message)
          }, (message: ChatMessage, index: number) => message.id || `message-${index}`)
          if (this.isSending) {
            Text('正在回答…').fontSize(13).fontColor(MUTED_TEXT).padding(12)
          }
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)

      Row({ space: 8 }) {
        TextInput({ placeholder: this.draftQuestion.length === 0 ? '输入你的养生问题' : '', text: this.draftQuestion })
          .fontSize(14)
          .height(44)
          .layoutWeight(1)
          .backgroundColor('#F7F7F7')
          .borderRadius(12)
          .onChange((value: string) => {
            this.draftQuestion = value;
            this.pendingClearChat = false;
          })
        Button(this.isSending ? '生成中' : '发送')
          .fontSize(14)
          .height(44)
          .fontColor('#FFFFFF')
          .enabled(this.canSendQuestion())
          .backgroundColor(this.canSendQuestion() ? BRAND_GREEN : '#C8D8CF')
          .borderRadius(12)
          .onClick(() => {
            this.sendLocalQuestion();
          })
      }
      .width('100%')
      .padding({ top: 10 })
      .border({
        width: { top: 1 },
        color: '#E4EBE6'
      })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height(520)
    .padding(14)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  MessageBubble(message: ChatMessage) {
    Row() {
      if (message.role === 'user') {
        Blank()
      }
      Column({ space: 8 }) {
        if (this.messageRiskTitle(message).length > 0) {
          Text(this.messageRiskTitle(message))
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(WARM_ACCENT)
        }
        Text(message.content)
          .fontSize(14)
          .fontColor(message.role === 'user' ? '#FFFFFF' : DEEP_TEXT)
          .lineHeight(22)
        if (message.role !== 'user' && this.messageSuggestions(message).length > 0) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.messageSuggestions(message), (suggestion: string) => {
              Text(suggestion)
                .fontSize(11)
                .fontColor(this.isUrgentMessage(message) ? WARM_ACCENT : BRAND_GREEN)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .margin({ right: 6, bottom: 6 })
                .backgroundColor(this.isUrgentMessage(message) ? '#FFF2E8' : '#EEF7F1')
                .borderRadius(10)
            }, (suggestion: string) => suggestion)
          }
        }
        if (message.role !== 'user' && this.messagePlan(message).length > 0) {
          this.MessagePlanCard(this.messagePlan(message))
        }
      }
      .alignItems(HorizontalAlign.Start)
      .padding(12)
      .backgroundColor(message.role === 'user' ? BRAND_GREEN : this.messageBackgroundColor(message))
      .borderRadius(CARD_RADIUS)
      .constraintSize({ maxWidth: '88%' })
      if (message.role !== 'user') {
        Blank()
      }
    }
    .width('100%')
  }

  private messageSuggestions(message: ChatMessage): string[] {
    return message.suggestions ? message.suggestions : [];
  }

  private messagePlan(message: ChatMessage): WellnessPlanItem[] {
    return message.plan ? message.plan : [];
  }

  private planTimeLabel(timeOfDay: string): string {
    if (timeOfDay === 'morning') {
      return '早';
    }
    if (timeOfDay === 'afternoon') {
      return '午';
    }
    if (timeOfDay === 'evening') {
      return '晚';
    }
    if (timeOfDay === 'urgent') {
      return '急';
    }
    return '计';
  }

  private isUrgentMessage(message: ChatMessage): boolean {
    return message.riskLevel === 'urgent';
  }

  private messageBackgroundColor(message: ChatMessage): string {
    return this.isUrgentMessage(message) ? '#FFF9F2' : CARD_BG;
  }

  private messageRiskTitle(message: ChatMessage): string {
    return this.isUrgentMessage(message) ? '风险提醒' : '';
  }

  @Builder
  MessagePlanCard(plan: WellnessPlanItem[]) {
    Column({ space: 8 }) {
      Text(plan.length === 1 && plan[0].timeOfDay === 'urgent' ? '风险处置' : '今日计划')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      ForEach(plan, (item: WellnessPlanItem) => {
        Row({ space: 8 }) {
          Text(this.planTimeLabel(item.timeOfDay))
            .fontSize(11)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
            .width(24)
            .height(24)
            .backgroundColor(item.timeOfDay === 'urgent' ? WARM_ACCENT : BRAND_GREEN)
            .borderRadius(12)
          Column({ space: 3 }) {
            Text(item.title)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(DEEP_TEXT)
            Text(item.action)
              .fontSize(12)
              .fontColor(MUTED_TEXT)
              .lineHeight(18)
            Text(item.reason)
              .fontSize(11)
              .fontColor(MUTED_TEXT)
              .lineHeight(16)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .alignItems(VerticalAlign.Top)
      }, (item: WellnessPlanItem) => `${item.timeOfDay}-${item.title}`)
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
  }

  private latestAssistantSource(): string {
    for (let index = this.messages.length - 1; index >= 0; index--) {
      const message = this.messages[index];
      if (message.role === 'assistant' && message.source && message.source.length > 0) {
        return message.source;
      }
    }
    return this.backendStatus.available ? '后端优先' : '大模型未连接';
  }

  private canSendQuestion(): boolean {
    return this.historyReady && canSendAssistantQuestion(this.draftQuestion, this.isSending) && this.pendingRequestId.length === 0;
  }

  private weatherStatusText(): string {
    if (this.weather.isFallback === true) {
      return '实时天气暂未获取，本次问答不使用实时温湿度。';
    }
    return `当前问答已结合定位天气：${this.weather.city} · ${this.weather.temperature} · 湿度${this.weather.humidity}`;
  }

  private async sendLocalQuestion(): Promise<void> {
    const question = this.draftQuestion.trim();
    if (!this.canSendQuestion()) {
      return;
    }
    this.pendingClearChat = false;
    this.replyError = '';
    const history = this.messages.slice();
    this.pendingRequestId = newRequestId();
    this.isSending = true;
    if (this.chatHistoryRepository) {
      try {
        await this.chatHistoryRepository.savePending({ id: this.pendingRequestId, question });
      } catch (error) {
        this.pendingRequestId = ''; this.isSending = false;
        this.replyError = '无法保存本次请求，请检查设备存储后重试';
        return;
      }
    }
    if (!this.active) { this.isSending = false; return; }
    this.messages = appendUserQuestion(this.messages, question);
    this.scrollMessagesToBottom();
    this.saveChatMessages();
    this.draftQuestion = '';
    requestAssistantReplyRemoteFirst(question, this.profile, history, this.weather, this.pendingRequestId).then(async (reply: AssistantReplyResult) => {
      if (!this.active) return;
      await this.acceptReply(reply);
      this.isSending = false;
      this.refreshPoints();
    }).catch((error: Error) => {
      if (!this.active) return;
      this.replyError = error.message || '连接中断，可查询原请求的回答';
      this.isSending = false;
      this.recoverPending();
    });
  }

  private async clearPendingRequest(): Promise<void> {
    if (this.chatHistoryRepository) await this.chatHistoryRepository.clearPending();
    this.pendingRequestId = '';
  }

  private async acceptReply(reply: AssistantReplyResult): Promise<void> {
    const id = `reply-${this.pendingRequestId}`;
    if (!this.messages.some((message: ChatMessage) => message.id === id)) {
      const next = appendAssistantReplyResult(this.messages, reply);
      if (next.length > this.messages.length) next[next.length - 1].id = id;
      this.messages = next;
    }
    if (this.chatHistoryRepository) await this.chatHistoryRepository.saveMessages(this.messages);
    await this.clearPendingRequest();
    this.scrollMessagesToBottom();
    this.replyError = '';
  }

  private refreshPoints(): void {
    getRewardAccount().then((account: RewardAccount) => {
      if (!this.active) return;
      this.pointsText = `可用 ${account.available} 积分 · 每次回答 ${account.chatCost} 积分`;
    }).catch(() => { this.pointsText = ''; });
  }

  private async recoverPending(): Promise<void> {
    if (!this.active || this.pendingRequestId.length === 0 || this.isSending) return;
    this.isSending = true;
    try {
      const result = await recoverChatReply(this.pendingRequestId);
      if (!this.active) return;
      if (result.status === 'SUCCEEDED' && result.reply) {
        await this.acceptReply(buildAssistantReplyFromBackendPayload(JSON.stringify(result.reply)));
        this.replyError = '';
      } else if (result.status === 'FAILED') {
        this.replyError = '本次回答未完成，未扣积分，可以重新发送';
        await this.clearPendingRequest();
      } else {
        this.replyError = '回答仍在生成，稍后可再次查询';
      }
      this.refreshPoints();
    } catch (error) {
      if (!this.active) return;
      const message = (error as Error).message;
      if (error instanceof RemoteRequestError && error.statusCode === 404) {
        await this.clearPendingRequest();
        this.replyError = '上次请求未被受理，未扣积分，可以重新发送';
        return;
      }
      this.replyError = message || '暂时无法查询，请恢复网络后重试';
    } finally { this.isSending = false; }
  }

  private applyProfile(profile: HealthProfile): void {
    this.localProfile = profile;
    this.questionnaireScore = profile.constitution.score;
    if (this.onProfileChanged) {
      this.onProfileChanged(profile);
    }
  }

  private saveChatMessages(): void {
    if (this.chatHistoryRepository) {
      this.chatHistoryRepository.saveMessages(this.messages);
    }
  }

  private handleClearChat(): void {
    if (!this.historyReady || this.isSending || this.pendingRequestId.length > 0) return;
    if (!this.pendingClearChat) {
      this.pendingClearChat = true;
      return;
    }
    if (this.chatHistoryRepository) {
      this.chatHistoryRepository.clearMessages().then((messages: ChatMessage[]) => {
        this.messages = messages;
        this.pendingClearChat = false;
        this.scrollMessagesToBottom();
      });
    } else {
      this.messages = getAssistantMessages();
      this.pendingClearChat = false;
      this.scrollMessagesToBottom();
    }
  }

  private scrollMessagesToBottom(): void {
    Promise.resolve().then(() => {
      this.messageScroller.scrollEdge(Edge.Bottom);
    });
  }

  @Builder
  ModelOnlyNotice() {
    Column({ space: 10 }) {
      Text('大模型问答')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('本页建议内容只展示后端大模型返回结果；如果后端或 Ollama 未连接，不使用本地规则生成替代建议。')
        .fontSize(14)
        .fontColor(MUTED_TEXT)
        .lineHeight(22)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor('#F8FBF9')
    .borderRadius(CARD_RADIUS)
  }

}
