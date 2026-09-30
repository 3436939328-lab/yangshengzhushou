import { common } from '@kit.AbilityKit';
import { BRAND_GREEN, CARD_BG, CARD_RADIUS, DEEP_TEXT, MUTED_TEXT, WARM_ACCENT } from '../../theme/WellnessTheme';
import { SectionTitle } from '../cards/CommonCards';
import { EmptyStateBlock } from '../cards/EmptyStateBlock';
import { getEmptyStateInfo } from '../../services/EmptyStateService';
import { FamilyMemberDetail } from '../family/FamilyMemberDetail';
import {
  createFamilyInvitationRepository,
  FamilyInvitationRepository,
  StoredFamilyInvitation
} from '../../services/FamilyInvitationRepository';

/**
 * 亲人关系状态
 */
export enum FamilyRelationStatus {
  PENDING = 'PENDING',      // 待确认
  ACTIVE = 'ACTIVE',        // 已确认
  REJECTED = 'REJECTED',    // 已拒绝
  EXPIRED = 'EXPIRED',      // 已过期
  REMOVED = 'REMOVED'       // 已解除
}

/**
 * 亲人关系类型
 */
export enum FamilyRelationType {
  PARENT = 'PARENT',          // 父母
  SPOUSE = 'SPOUSE',          // 配偶
  CHILD = 'CHILD',            // 子女
  SIBLING = 'SIBLING',        // 兄弟姐妹
  OTHER = 'OTHER'             // 其他
}

/**
 * 共享类别
 */
export enum ShareCategory {
  BLOOD_PRESSURE = 'BLOOD_PRESSURE',
  BLOOD_SUGAR = 'BLOOD_SUGAR',
  HEART_RATE = 'HEART_RATE',
  BLOOD_OXYGEN = 'BLOOD_OXYGEN',
  TEMPERATURE = 'TEMPERATURE',
  BODY = 'BODY',
  SLEEP = 'SLEEP',
  EXERCISE = 'EXERCISE',
  WATER = 'WATER',
  TONGUE = 'TONGUE',
  AI_ANALYSIS = 'AI_ANALYSIS',
  ABNORMAL_NOTIFY = 'ABNORMAL_NOTIFY'
}

interface FamilyBloodPressureInfo {
  systolic: number;
  diastolic: number;
  measuredAt: string;
  status: string;
}

interface FamilyBloodSugarInfo {
  value: number;
  unit: string;
  type: string;
  measuredAt: string;
  status: string;
}

interface FamilyHeartRateInfo {
  value: number;
  unit: string;
  measuredAt: string;
  status: string;
}

interface FamilySleepInfo {
  totalMinutes: number;
  measuredAt: string;
  source: string;
}

interface FamilyWeightInfo {
  value: number;
  bmi?: number;
  measuredAt: string;
}

interface RelationTypeOption {
  type: FamilyRelationType;
  label: string;
}

/**
 * 亲人健康卡数据
 */
export interface FamilyMemberCard {
  id: string;
  relationId: string;
  displayName: string;
  relationType: FamilyRelationType;
  relationLabel: string;
  avatar?: string;
  lastUpdateTime: string;
  attentionCount: number;
  status: FamilyRelationStatus;
  grantedCategories: ShareCategory[];
  historyWindowDays: number;
  // 摘要数据
  bloodPressure?: FamilyBloodPressureInfo;
  bloodSugar?: FamilyBloodSugarInfo;
  heartRate?: FamilyHeartRateInfo;
  sleep?: FamilySleepInfo;
  weight?: FamilyWeightInfo;
}

/**
 * 亲人邀请
 */
export interface FamilyInvitation {
  id: string;
  inviterId: string;
  inviteePhone: string;
  relationType: FamilyRelationType;
  relationLabel: string;
  status: FamilyRelationStatus;
  expiresAt: string;
  createdAt: string;
}

@Component
export struct FamilyTab {
  @Prop userId: string;
  @Prop userPhone: string = '';

  @State members: FamilyMemberCard[] = [];
  @State sentInvitations: StoredFamilyInvitation[] = [];
  @State receivedInvitations: StoredFamilyInvitation[] = [];
  @State isLoading: boolean = false;
  @State showInviteSheet: boolean = false;
  @State invitePhone: string = '';
  @State inviteRelation: FamilyRelationType = FamilyRelationType.PARENT;
  @State inviteRelationLabel: string = '';
  @State inviteError: string = '';
  @State inviteSubmitting: boolean = false;
  @State showMemberDetail: boolean = false;
  @State selectedMember: FamilyMemberCard | null = null;
  @State careMessage: string = '';
  @State toastMessage: string = '';
  private invitationRepository?: FamilyInvitationRepository;

  aboutToAppear() {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.invitationRepository = createFamilyInvitationRepository(context);
    this.loadFamilyData();
  }

  private loadFamilyData(): void {
    this.isLoading = true;
    this.members = this.getMockMembers();
    this.loadInvitations();
  }

  private loadInvitations(): void {
    if (!this.invitationRepository) {
      this.isLoading = false;
      return;
    }
    Promise.all([
      this.invitationRepository.getInvitationsByInviter(this.userId),
      this.invitationRepository.getInvitationsForInvitee(this.userPhone)
    ]).then((results: StoredFamilyInvitation[][]) => {
      this.sentInvitations = results[0];
      this.receivedInvitations = results[1];
      this.isLoading = false;
    }).catch(() => {
      this.sentInvitations = [];
      this.receivedInvitations = [];
      this.isLoading = false;
    });
  }

  private getMockMembers(): FamilyMemberCard[] {
    return [];
  }

  private relationTypeOptions(): RelationTypeOption[] {
    return [
      { type: FamilyRelationType.PARENT, label: '父母' } as RelationTypeOption,
      { type: FamilyRelationType.SPOUSE, label: '配偶' } as RelationTypeOption,
      { type: FamilyRelationType.CHILD, label: '子女' } as RelationTypeOption,
      { type: FamilyRelationType.SIBLING, label: '兄弟姐妹' } as RelationTypeOption,
      { type: FamilyRelationType.OTHER, label: '其他' } as RelationTypeOption
    ];
  }

  private statusColor(status: string): ResourceColor {
    if (status === 'URGENT') return '#E53935';
    if (status === 'ATTENTION') return WARM_ACCENT;
    return BRAND_GREEN;
  }

  private statusText(status: string): string {
    if (status === 'URGENT') return '需及时处理';
    if (status === 'ATTENTION') return '需要关注';
    if (status === 'IN_RANGE') return '正常';
    return '未监测';
  }

  private handleInviteSubmit(): void {
    if (this.invitePhone.trim().length !== 11) {
      this.inviteError = '请输入正确的手机号';
      return;
    }
    if (this.invitePhone.trim() === this.userPhone) {
      this.inviteError = '不能邀请自己';
      return;
    }
    this.inviteSubmitting = true;
    this.inviteError = '';

    const now = new Date();
    const expiresAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    const invitation: StoredFamilyInvitation = {
      id: `inv_${now.getTime()}_${Math.floor(Math.random() * 10000)}`,
      inviterId: this.userId,
      inviterPhone: this.userPhone,
      inviterName: '我',
      inviteePhone: this.invitePhone.trim(),
      relationType: this.inviteRelation,
      relationLabel: this.inviteRelationLabel.length > 0 ? this.inviteRelationLabel : this.relationLabelForType(this.inviteRelation),
      status: FamilyRelationStatus.PENDING,
      expiresAt: expiresAt.toISOString(),
      createdAt: now.toISOString()
    };

    if (this.invitationRepository) {
      this.invitationRepository.addInvitation(invitation).then(() => {
        this.inviteSubmitting = false;
        this.showInviteSheet = false;
        this.invitePhone = '';
        this.inviteRelationLabel = '';
        this.toastMessage = '邀请已发送，等待对方确认';
        setTimeout(() => { this.toastMessage = ''; }, 2000);
        this.loadInvitations();
      }).catch(() => {
        this.inviteSubmitting = false;
        this.inviteError = '邀请发送失败，请稍后重试';
      });
    } else {
      this.inviteSubmitting = false;
      this.inviteError = '邀请发送失败，请稍后重试';
    }
  }

  private relationLabelForType(type: FamilyRelationType): string {
    switch (type) {
      case FamilyRelationType.PARENT: return '父母';
      case FamilyRelationType.SPOUSE: return '配偶';
      case FamilyRelationType.CHILD: return '子女';
      case FamilyRelationType.SIBLING: return '兄弟姐妹';
      default: return '其他';
    }
  }

  private acceptInvitation(invitation: StoredFamilyInvitation): void {
    if (!this.invitationRepository) return;
    this.invitationRepository.updateStatus(invitation.id, FamilyRelationStatus.ACTIVE).then(() => {
      this.toastMessage = '已接受邀请';
      setTimeout(() => { this.toastMessage = ''; }, 2000);
      this.loadInvitations();
    }).catch(() => {
      this.toastMessage = '操作失败，请稍后重试';
      setTimeout(() => { this.toastMessage = ''; }, 2000);
    });
  }

  private rejectInvitation(invitation: StoredFamilyInvitation): void {
    if (!this.invitationRepository) return;
    this.invitationRepository.updateStatus(invitation.id, FamilyRelationStatus.REJECTED).then(() => {
      this.toastMessage = '已拒绝邀请';
      setTimeout(() => { this.toastMessage = ''; }, 2000);
      this.loadInvitations();
    }).catch(() => {
      this.toastMessage = '操作失败，请稍后重试';
      setTimeout(() => { this.toastMessage = ''; }, 2000);
    });
  }

  private cancelInvitation(invitation: StoredFamilyInvitation): void {
    if (!this.invitationRepository) return;
    this.invitationRepository.removeInvitation(invitation.id).then(() => {
      this.toastMessage = '已取消邀请';
      setTimeout(() => { this.toastMessage = ''; }, 2000);
      this.loadInvitations();
    }).catch(() => {
      this.toastMessage = '操作失败，请稍后重试';
      setTimeout(() => { this.toastMessage = ''; }, 2000);
    });
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column({ space: 14 }) {
        this.HeaderSection()

        if (this.isLoading) {
          this.LoadingSection()
        } else if (this.members.length === 0 && this.receivedInvitations.length === 0 && this.sentInvitations.length === 0) {
          this.EmptySection()
        } else {
          if (this.receivedInvitations.length > 0) {
            this.ReceivedInvitationsSection()
          }
          if (this.sentInvitations.length > 0) {
            this.SentInvitationsSection()
          }
          if (this.members.length > 0) {
            this.MembersListSection()
          }
        }
      }
      .margin({ top: 14 })
      .width('100%')

      if (this.showInviteSheet) {
        Column() {
          Column()
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('rgba(0, 0, 0, 0.5)')
            .onClick(() => {
              this.showInviteSheet = false;
            })

          Column() {
            this.InviteSheet()
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 20, topRight: 20 })
        }
        .width('100%')
        .height('100%')
      }

      if (this.showMemberDetail && this.selectedMember !== null) {
        Column() {
          Column()
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('rgba(0, 0, 0, 0.5)')
            .onClick(() => {
              this.showMemberDetail = false;
            })

          Column() {
            FamilyMemberDetail({
              member: this.selectedMember,
              healthCard: null,
              isLoading: false,
              onBack: () => {
                this.showMemberDetail = false;
              },
              onSendCare: async (message: string): Promise<boolean> => {
                this.careMessage = message;
                return true;
              }
            })
          }
          .width('100%')
          .height('85%')
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 20, topRight: 20 })
        }
        .width('100%')
        .height('100%')
      }

      if (this.careMessage.length > 0) {
        Column() {
          Text(this.careMessage)
            .fontSize(14)
            .fontColor(Color.White)
            .padding({ left: 20, right: 20, top: 12, bottom: 12 })
            .backgroundColor('rgba(0, 0, 0, 0.8)')
            .borderRadius(24)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 100 })
      }

      if (this.toastMessage.length > 0) {
        Column() {
          Text(this.toastMessage)
            .fontSize(14)
            .fontColor(Color.White)
            .padding({ left: 20, right: 20, top: 12, bottom: 12 })
            .backgroundColor('rgba(0, 0, 0, 0.8)')
            .borderRadius(24)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 100 })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  HeaderSection() {
    Row() {
      Column({ space: 4 }) {
        Text('亲人关怀')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(DEEP_TEXT)
        Text('经本人授权，可查看亲人健康动态')
          .fontSize(13)
          .fontColor(MUTED_TEXT)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button() {
        Text('+ 邀请亲人')
          .fontSize(14)
          .fontColor(Color.White)
      }
      .height(36)
      .backgroundColor(BRAND_GREEN)
      .borderRadius(18)
      .onClick(() => {
        this.showInviteSheet = true;
      })
    }
    .width('100%')
  }

  @Builder
  LoadingSection() {
    Column() {
      EmptyStateBlock({ info: { title: '加载中...', detail: '正在加载亲人信息' } })
    }
    .width('100%')
  }

  @Builder
  EmptySection() {
    Column({ space: 16 }) {
      EmptyStateBlock({ info: getEmptyStateInfo('family') })

      Button() {
        Text('邀请亲人')
          .fontSize(15)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .width(200)
      .height(44)
      .backgroundColor(BRAND_GREEN)
      .borderRadius(22)
      .onClick(() => {
        this.showInviteSheet = true;
      })
    }
    .width('100%')
    .margin({ top: 40 })
  }

  @Builder
  ReceivedInvitationsSection() {
    Column({ space: 10 }) {
      SectionTitle('收到的邀请')
      ForEach(this.receivedInvitations, (invitation: StoredFamilyInvitation) => {
        this.ReceivedInvitationCard(invitation)
      }, (invitation: StoredFamilyInvitation) => invitation.id)
    }
    .width('100%')
  }

  @Builder
  ReceivedInvitationCard(invitation: StoredFamilyInvitation) {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 4 }) {
          Text(`${invitation.inviterName}（${invitation.inviterPhone}）`)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(DEEP_TEXT)
          Text(`邀请您成为其${invitation.relationLabel}`)
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('待确认')
          .fontSize(12)
          .fontColor(WARM_ACCENT)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('rgba(255, 152, 0, 0.1)')
          .borderRadius(10)
      }

      Row({ space: 10 }) {
        Button() {
          Text('接受')
            .fontSize(13)
            .fontColor(Color.White)
        }
        .height(34)
        .backgroundColor(BRAND_GREEN)
        .borderRadius(17)
        .layoutWeight(1)
        .onClick(() => {
          this.acceptInvitation(invitation);
        })

        Button() {
          Text('拒绝')
            .fontSize(13)
            .fontColor(WARM_ACCENT)
        }
        .height(34)
        .backgroundColor('rgba(255, 152, 0, 0.1)')
        .borderRadius(17)
        .layoutWeight(1)
        .onClick(() => {
          this.rejectInvitation(invitation);
        })
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  @Builder
  SentInvitationsSection() {
    Column({ space: 10 }) {
      SectionTitle('已发送的邀请')
      ForEach(this.sentInvitations, (invitation: StoredFamilyInvitation) => {
        this.SentInvitationCard(invitation)
      }, (invitation: StoredFamilyInvitation) => invitation.id)
    }
    .width('100%')
  }

  @Builder
  SentInvitationCard(invitation: StoredFamilyInvitation) {
    Column({ space: 10 }) {
      Row() {
        Column({ space: 4 }) {
          Text(invitation.inviteePhone)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(DEEP_TEXT)
          Text(`关系：${invitation.relationLabel}`)
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.statusLabel(invitation.status))
          .fontSize(12)
          .fontColor(this.statusLabelColor(invitation.status))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(this.statusLabelBg(invitation.status))
          .borderRadius(10)
      }

      Row({ space: 10 }) {
        Text('邀请时间：' + this.formatDate(invitation.createdAt))
          .fontSize(12)
          .fontColor(MUTED_TEXT)
        Blank()
        if (invitation.status === FamilyRelationStatus.PENDING) {
          Text('取消邀请')
            .fontSize(12)
            .fontColor(WARM_ACCENT)
            .onClick(() => {
              this.cancelInvitation(invitation);
            })
        }
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
  }

  private statusLabel(status: FamilyRelationStatus): string {
    switch (status) {
      case FamilyRelationStatus.PENDING: return '待确认';
      case FamilyRelationStatus.ACTIVE: return '已接受';
      case FamilyRelationStatus.REJECTED: return '已拒绝';
      default: return '已过期';
    }
  }

  private statusLabelColor(status: FamilyRelationStatus): ResourceColor {
    switch (status) {
      case FamilyRelationStatus.ACTIVE: return BRAND_GREEN;
      case FamilyRelationStatus.REJECTED: return '#E53935';
      default: return WARM_ACCENT;
    }
  }

  private statusLabelBg(status: FamilyRelationStatus): string {
    switch (status) {
      case FamilyRelationStatus.ACTIVE: return '#EEF7F1';
      case FamilyRelationStatus.REJECTED: return '#FFEBEE';
      default: return 'rgba(255, 152, 0, 0.1)';
    }
  }

  private formatDate(isoString: string): string {
    try {
      const date = new Date(isoString);
      const month = `${date.getMonth() + 1}`.padStart(2, '0');
      const day = `${date.getDate()}`.padStart(2, '0');
      return `${date.getFullYear()}-${month}-${day}`;
    } catch {
      return isoString;
    }
  }

  @Builder
  MembersListSection() {
    Column({ space: 10 }) {
      SectionTitle('我的亲人')
      ForEach(this.members, (member: FamilyMemberCard) => {
        this.FamilyMemberCard(member)
      }, (member: FamilyMemberCard) => member.id)
    }
    .width('100%')
  }

  @Builder
  FamilyMemberCard(member: FamilyMemberCard) {
    Column({ space: 12 }) {
      // 头部：头像、称呼、状态
      Row() {
        // 头像
        Circle({ width: 44, height: 44 })
          .fill(CARD_BG)
          .stroke(BRAND_GREEN)
          .strokeWidth(2)

        Column({ space: 2 }) {
          Text(member.displayName)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(DEEP_TEXT)
          Text(`最近更新：${member.lastUpdateTime}`)
            .fontSize(12)
            .fontColor(MUTED_TEXT)
        }
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (member.attentionCount > 0) {
          Column({ space: 2 }) {
            Text(`${member.attentionCount} 项`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(WARM_ACCENT)
            Text('需要关注')
              .fontSize(11)
              .fontColor(MUTED_TEXT)
          }
          .alignItems(HorizontalAlign.Center)
        }
      }

      // 健康数据摘要
      Column({ space: 8 }) {
        if (member.bloodPressure) {
          Row() {
            Text('血压')
              .fontSize(14)
              .fontColor(MUTED_TEXT)
              .width(60)
            Text(`${member.bloodPressure.systolic}/${member.bloodPressure.diastolic} mmHg`)
              .fontSize(14)
              .fontColor(DEEP_TEXT)
              .layoutWeight(1)
            Text(this.statusText(member.bloodPressure.status))
              .fontSize(12)
              .fontColor(this.statusColor(member.bloodPressure.status))
          }
        }

        if (member.bloodSugar) {
          Row() {
            Text('血糖')
              .fontSize(14)
              .fontColor(MUTED_TEXT)
              .width(60)
            Text(`${member.bloodSugar.value} ${member.bloodSugar.unit} · ${member.bloodSugar.type}`)
              .fontSize(14)
              .fontColor(DEEP_TEXT)
              .layoutWeight(1)
            Text(this.statusText(member.bloodSugar.status))
              .fontSize(12)
              .fontColor(this.statusColor(member.bloodSugar.status))
          }
        }

        if (member.heartRate) {
          Row() {
            Text('心率')
              .fontSize(14)
              .fontColor(MUTED_TEXT)
              .width(60)
            Text(`${member.heartRate.value} ${member.heartRate.unit}`)
              .fontSize(14)
              .fontColor(DEEP_TEXT)
              .layoutWeight(1)
            Text(this.statusText(member.heartRate.status))
              .fontSize(12)
              .fontColor(this.statusColor(member.heartRate.status))
          }
        }

        if (member.sleep) {
          Row() {
            Text('睡眠')
              .fontSize(14)
              .fontColor(MUTED_TEXT)
              .width(60)
            Text(`${Math.floor(member.sleep.totalMinutes / 60)}小时${member.sleep.totalMinutes % 60}分 · ${member.sleep.measuredAt}`)
              .fontSize(14)
              .fontColor(DEEP_TEXT)
              .layoutWeight(1)
            Text(member.sleep.source)
              .fontSize(12)
              .fontColor(MUTED_TEXT)
          }
        }
      }
      .width('100%')

      // 操作按钮
      Row({ space: 10 }) {
        Button() {
          Text('查看全部已共享数据')
            .fontSize(13)
            .fontColor(BRAND_GREEN)
        }
        .height(34)
        .backgroundColor('rgba(76, 175, 80, 0.1)')
        .borderRadius(17)
        .layoutWeight(1)
        .onClick(() => {
          this.selectedMember = member;
          this.showMemberDetail = true;
        })

        Button() {
          Text('发送关怀')
            .fontSize(13)
            .fontColor(Color.White)
        }
        .height(34)
        .backgroundColor(BRAND_GREEN)
        .borderRadius(17)
        .layoutWeight(1)
        .onClick(() => {
          this.careMessage = `已向${member.displayName}发送关怀提醒`;
          setTimeout(() => { this.careMessage = ''; }, 2000);
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(CARD_BG)
    .borderRadius(CARD_RADIUS)
    .onClick(() => {
      this.selectedMember = member;
      this.showMemberDetail = true;
    })
  }

  // 邀请弹窗（简化版，实际可用 Sheet 组件）
  @Builder
  InviteSheet() {
    Column({ space: 20 }) {
      Text('邀请亲人')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(DEEP_TEXT)

      Column({ space: 8 }) {
        Text('对方手机号')
          .fontSize(14)
          .fontColor(DEEP_TEXT)
        TextInput({ text: this.invitePhone, placeholder: '请输入亲人手机号' })
          .height(44)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .onChange((value: string) => {
            this.invitePhone = value;
          })
      }

      Column({ space: 8 }) {
        Text('关系')
          .fontSize(14)
          .fontColor(DEEP_TEXT)
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.relationTypeOptions(), (option: RelationTypeOption) => {
            Text(option.label)
              .fontSize(13)
              .fontColor(this.inviteRelation === option.type ? Color.White : DEEP_TEXT)
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .margin({ right: 8, bottom: 8 })
              .backgroundColor(this.inviteRelation === option.type ? BRAND_GREEN : '#F5F5F5')
              .borderRadius(16)
              .onClick(() => {
                this.inviteRelation = option.type;
                this.inviteRelationLabel = option.label;
              })
          }, (option: RelationTypeOption) => option.label)
        }
      }

      Column({ space: 8 }) {
        Text('称呼（可选）')
          .fontSize(14)
          .fontColor(DEEP_TEXT)
        TextInput({ text: this.inviteRelationLabel, placeholder: '如：妈妈、爸爸、老公' })
          .height(44)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .onChange((value: string) => {
            this.inviteRelationLabel = value;
          })
      }

      if (this.inviteError.length > 0) {
        Text(this.inviteError)
          .fontSize(13)
          .fontColor('#E53935')
      }

      Button() {
        Text(this.inviteSubmitting ? '发送中...' : '发送邀请')
          .fontSize(15)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height(48)
      .backgroundColor(BRAND_GREEN)
      .borderRadius(24)
      .enabled(!this.inviteSubmitting)
      .onClick(() => {
        this.handleInviteSubmit();
      })

      Text('对方需在 App 中确认后，您才可以查看其授权的健康数据')
        .fontSize(12)
        .fontColor(MUTED_TEXT)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(24)
  }
}
