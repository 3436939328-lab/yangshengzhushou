import {
  BRAND_GREEN,
  CARD_BG,
  CARD_RADIUS,
  DEEP_TEXT,
  MUTED_TEXT,
  WARM_ACCENT
} from '../../theme/WellnessTheme';
import { AdminAssistantLogItem, fetchAdminAssistantLogs } from '../../services/AdminAssistantLogService';
import { AdminUserItem, fetchAdminUsers } from '../../services/AdminPeopleService';
import {
  AdminRoleItem,
  AdminUserRoleItem,
  fetchAdminRoles,
  fetchAdminUserRoles
} from '../../services/AdminRoleService';
import { AdminOverviewMetrics, buildAdminOverviewMetrics } from '../../services/AdminOverviewMetricsService';
import { getApiConfig } from '../../services/ApiConfig';
import { ConsultationThread, fetchAdminConsultations } from '../../services/ConsultationService';
import {
  createDefaultNodeAiStatus,
  fetchNodeAiStatus,
  NodeAiStatus
} from '../../services/NodeAiStatusService';

@Component
struct MetricCardView {
  @Prop title: string;
  @Prop value: string;
  @Prop detail: string;

  build() {
    Column({ space: 4 }) {
      Text(this.value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(BRAND_GREEN)
      Text(this.title)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text(this.detail)
        .fontSize(11)
        .fontColor(MUTED_TEXT)
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(96)
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }
}

@Component
struct StatusLineView {
  @Prop title: string;
  @Prop detail: string;

  build() {
    Column({ space: 4 }) {
      Text(this.title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text(this.detail)
        .fontSize(12)
        .fontColor(MUTED_TEXT)
        .lineHeight(18)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor('#FAFCFA')
    .borderRadius(CARD_RADIUS)
  }
}

@Component
struct NodeAiStatusLineView {
  @Prop status: NodeAiStatus;

  build() {
    Column({ space: 4 }) {
      Row({ space: 8 }) {
        Text(this.status.statusText)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
          .layoutWeight(1)
        Text(this.status.badgeText)
          .fontSize(11)
          .fontColor(this.status.available ? BRAND_GREEN : WARM_ACCENT)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(this.status.available ? '#EEF7F1' : '#FFF6E8')
          .borderRadius(999)
      }
      Text(this.status.detail)
        .fontSize(12)
        .fontColor(MUTED_TEXT)
        .lineHeight(18)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .backgroundColor('#FAFCFA')
    .borderRadius(CARD_RADIUS)
  }
}

@Component
export struct AdminOverviewTab {
  @State users: AdminUserItem[] = [];
  @State roles: AdminRoleItem[] = [];
  @State userRoles: AdminUserRoleItem[] = [];
  @State assistantLogs: AdminAssistantLogItem[] = [];
  @State consultations: ConsultationThread[] = [];
  @State nodeAiStatus: NodeAiStatus = createDefaultNodeAiStatus();
  @State totalUsers: number = 0;
  @State normalUsers: number = 0;
  @State adminUsers: number = 0;
  @State doctorUsers: number = 0;
  @State roleBindings: number = 0;
  @State assistantLogCount: number = 0;
  @State consultationCount: number = 0;
  @State refreshToken: number = 0;
  @State isLoading: boolean = false;
  @State feedback: string = '等待加载';
  @State errorSummary: string = '';
  private hasLoaded: boolean = false;

  aboutToAppear() {
    this.refreshOverview();
  }

  build() {
    Column({ space: 14 }) {
      Text('管理员总览')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)
      Text('汇总人员、角色、养生助手问答和一对一问诊数据。')
        .fontSize(14)
        .fontColor(MUTED_TEXT)
        .lineHeight(22)

      Text(this.feedback)
        .fontSize(12)
        .fontColor(this.errorSummary.length > 0 ? WARM_ACCENT : MUTED_TEXT)
        .lineHeight(18)
      if (this.errorSummary.length > 0) {
        Text(this.errorSummary)
          .fontSize(12)
          .fontColor(WARM_ACCENT)
          .lineHeight(18)
      }

      Column({ space: 10 }) {
        Row({ space: 10 }) {
          MetricCardView({ title: '总人员', value: `${this.totalUsers}`, detail: '所有已注册账号' })
          MetricCardView({ title: '普通用户', value: `${this.normalUsers}`, detail: '未绑定管理或医护角色' })
        }
        .width('100%')
        Row({ space: 10 }) {
          MetricCardView({ title: '管理员', value: `${this.adminUsers}`, detail: '后台管理角色' })
          MetricCardView({ title: '医生', value: `${this.doctorUsers}`, detail: '医生角色' })
        }
        .width('100%')
        Row({ space: 10 }) {
          MetricCardView({ title: '角色绑定', value: `${this.roleBindings}`, detail: '用户角色关系记录' })
        }
        .width('100%')
      }
      .width('100%')

      Row({ space: 10 }) {
        MetricCardView({ title: '问答记录', value: `${this.assistantLogCount}`, detail: '养生助手总记录' })
        MetricCardView({ title: '一对一问诊', value: `${this.consultationCount}`, detail: '用户与医生会话' })
      }
      .width('100%')

      Column({ space: 8 }) {
        Row() {
          Text('数据入口')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
            .layoutWeight(1)
          Button(this.isLoading ? '加载中' : '刷新')
            .fontSize(12)
            .fontColor(BRAND_GREEN)
            .backgroundColor('#EEF7F1')
            .borderRadius(12)
            .enabled(!this.isLoading)
            .onClick(() => {
              this.refreshOverview();
            })
        }

        NodeAiStatusLineView({ status: this.nodeAiStatus })
        StatusLineView({ title: '后端地址', detail: getApiConfig().baseUrl })
        StatusLineView({ title: '人员管理', detail: `已加载 ${this.users.length} 人` })
        StatusLineView({ title: '角色数据', detail: `角色 ${this.roles.length} 个，绑定 ${this.userRoles.length} 条` })
        StatusLineView({ title: '问答记录', detail: `已加载 ${this.assistantLogs.length} 条` })
        StatusLineView({ title: '问诊总览', detail: `已加载 ${this.consultations.length} 条` })
        Text(`刷新序号：${this.refreshToken}`)
          .fontSize(11)
          .fontColor(MUTED_TEXT)
      }
      .width('100%')
      .padding(18)
      .backgroundColor(CARD_BG)
      .borderRadius(CARD_RADIUS)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .onAppear(() => {
      if (!this.hasLoaded) {
        this.hasLoaded = true;
        this.refreshOverview();
      }
    })
  }

  private refreshOverview(): void {
    this.isLoading = true;
    this.feedback = '正在加载管理员总览...';
    this.errorSummary = '';
    let pendingCount = 6;
    let failedCount = 0;
    const failedParts: string[] = [];
    const addFailure = (label: string, error: Error) => {
      failedCount++;
      failedParts.push(`${label}: ${error.message.length > 0 ? error.message : 'failed'}`);
    };
    const markDone = () => {
      pendingCount--;
      if (pendingCount <= 0) {
        this.recalculateMetrics();
        this.refreshToken++;
        this.isLoading = false;
        this.errorSummary = failedParts.join('；');
        this.feedback = failedCount > 0 ? `加载完成，${failedCount} 个接口失败` : '加载完成';
      }
    };

    fetchAdminUsers().then((items: AdminUserItem[]) => {
      this.users = items;
    }).catch((error: Error) => {
      addFailure('人员', error);
      this.users = [];
    }).finally(() => {
      markDone();
    });

    fetchAdminRoles().then((items: AdminRoleItem[]) => {
      this.roles = items;
    }).catch((error: Error) => {
      addFailure('角色', error);
      this.roles = [];
    }).finally(() => {
      markDone();
    });

    fetchAdminUserRoles().then((items: AdminUserRoleItem[]) => {
      this.userRoles = items;
    }).catch((error: Error) => {
      addFailure('绑定', error);
      this.userRoles = [];
    }).finally(() => {
      markDone();
    });

    fetchAdminAssistantLogs().then((items: AdminAssistantLogItem[]) => {
      this.assistantLogs = items;
    }).catch((error: Error) => {
      addFailure('问答', error);
      this.assistantLogs = [];
    }).finally(() => {
      markDone();
    });

    fetchAdminConsultations().then((items: ConsultationThread[]) => {
      this.consultations = items;
    }).catch((error: Error) => {
      addFailure('问诊', error);
      this.consultations = [];
    }).finally(() => {
      markDone();
    });

    fetchNodeAiStatus().then((status: NodeAiStatus) => {
      this.nodeAiStatus = status;
    }).catch((error: Error) => {
      addFailure('AI状态', error);
      this.nodeAiStatus = createDefaultNodeAiStatus();
    }).finally(() => {
      markDone();
    });
  }

  private recalculateMetrics(): void {
    const metrics: AdminOverviewMetrics = buildAdminOverviewMetrics(
      this.users,
      this.roles,
      this.userRoles,
      this.assistantLogs,
      this.consultations
    );
    this.totalUsers = metrics.totalUsers;
    this.adminUsers = metrics.adminUsers;
    this.doctorUsers = metrics.doctorUsers;
    this.normalUsers = metrics.normalUsers;
    this.roleBindings = metrics.roleBindings;
    this.assistantLogCount = metrics.assistantLogCount;
    this.consultationCount = metrics.consultationCount;
  }
}
