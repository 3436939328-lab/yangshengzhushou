import { common } from '@kit.AbilityKit';
import { BRAND_GREEN, CARD_BG, CARD_RADIUS, DEEP_TEXT, MUTED_TEXT, WARM_ACCENT } from '../../theme/WellnessTheme';
import { SectionTitle } from '../cards/CommonCards';
import { EmptyStateBlock } from '../cards/EmptyStateBlock';
import { getEmptyStateInfo } from '../../services/EmptyStateService';
import { FamilyMemberDetail } from '../family/FamilyMemberDetail';
import { FamilyShareSettings } from '../family/FamilyShareSettings';
import {
  createFamilyInvitationRepository,
  FamilyInvitationRepository,
  StoredFamilyInvitation
} from '../../services/FamilyInvitationRepository';
import { fetchFamilyHealthSummary, FamilyMemberInfo } from '../../services/FamilyService';
import {
  FamilyRelationStatus,
  FamilyRelationType,
  ShareCategory,
  FamilyMemberCard,
  FamilyBloodPressureInfo,
  FamilyBloodSugarInfo,
  FamilyHeartRateInfo,
  FamilySleepInfo,
  FamilyWeightInfo,
  FamilyInvitation
} from '../../model/FamilyModels';

// 重新导出，保持对外接口不变
export { FamilyRelationStatus, FamilyRelationType, ShareCategory, FamilyMemberCard, FamilyInvitation };

interface RelationTypeOption {
  type: FamilyRelationType;
  label: string;
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
  @State showShareSettings: boolean = false;
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
    this.members = [];
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
      this.buildMembersFromInvitations(results[0], results[1]);
      this.isLoading = false;
    }).catch(() => {
      this.sentInvitations = [];
      this.receivedInvitations = [];
      this.isLoading = false;
    });
  }

  private buildMembersFromInvitations(sent: StoredFamilyInvitation[], received: StoredFamilyInvitation[]): void {
    const members: FamilyMemberCard[] = [];
    const activeSent = sent.filter((item: StoredFamilyInvitation) => item.status === FamilyRelationStatus.ACTIVE);
    for (const inv of activeSent) {
      members.push({
        id: `member_sent_${inv.id}`,
        relationId: inv.id,
        displayName: inv.inviteePhone,
        relationType: inv.relationType,
        relationLabel: inv.relationLabel,
        lastUpdateTime: this.formatDate(inv.createdAt),
        attentionCount: 0,
        status: FamilyRelationStatus.ACTIVE,
        grantedCategories: [],
        historyWindowDays: 30,
        healthCard: null
      });
    }
    const activeReceived = received.filter((item: StoredFamilyInvitation) => item.status === FamilyRelationStatus.ACTIVE);
    for (const inv of activeReceived) {
      members.push({
        id: `member_recv_${inv.id}`,
        relationId: inv.id,
        displayName: inv.inviterName.length > 0 ? inv.inviterName : inv.inviterPhone,
        relationType: inv.relationType,
        relationLabel: inv.relationLabel,
        lastUpdateTime: this.formatDate(inv.createdAt),
        attentionCount: 0,
        status: FamilyRelationStatus.ACTIVE,
        grantedCategories: [],
        historyWindowDays: 30,
        healthCard: null
      });
    }
    this.members = members;
    this.fetchHealthForMembers(members);
  }

  private fetchHealthForMembers(members: FamilyMemberCard[]): void {
    for (const member of members) {
      const phone = this.memberPhoneForFetch(member, members);
      if (phone.length === 0) continue;
      fetchFamilyHealthSummary(phone).then((info: FamilyMemberInfo) => {
        const updated = this.members.map((m: FamilyMemberCard) => {
          if (m.id === member.id) {
            return this.applyHealthInfo(m, info);
          }
          return m;
        });
        this.members = updated;
        if (this.selectedMember && this.selectedMember.id === member.id) {
          const found = updated.find((m: FamilyMemberCard) => m.id === member.id);
          if (found) {
            this.selectedMember = found;
          }
        }
      }).catch(() => {
        // 静默失败，成员仍显示但无健康数据
      });
    }
  }

  private memberPhoneForFetch(member: FamilyMemberCard, _all: FamilyMemberCard[]): string {
    // 对方手机号：sent 邀请对应 inviteePhone
    if (member.id.indexOf('member_sent_') === 0) {
      const inv = this.sentInvitations.find((item: StoredFamilyInvitation) => `member_sent_${item.id}` === member.id);
      return inv ? inv.inviteePhone : '';
    }
    // received 邀请对应 inviterPhone
    if (member.id.indexOf('member_recv_') === 0) {
      const inv = this.receivedInvitations.find((item: StoredFamilyInvitation) => `member_recv_${item.id}` === member.id);
      return inv ? inv.inviterPhone : '';
    }
    return '';
  }

  private applyHealthInfo(member: FamilyMemberCard, info: FamilyMemberInfo): FamilyMemberCard {
    const card = info.healthCard;
    const updated: FamilyMemberCard = {
      id: member.id,
      relationId: member.relationId,
      displayName: info.realName.length > 0 ? info.realName : member.displayName,
      relationType: member.relationType,
      relationLabel: member.relationLabel,
      avatar: member.avatar,
      lastUpdateTime: new Date().toLocaleString(),
      attentionCount: card ? card.attentionCount : 0,
      status: member.status,
      grantedCategories: member.grantedCategories,
      historyWindowDays: member.historyWindowDays,
      bloodPressure: card && card.bloodPressure ? {
        systolic: card.bloodPressure.systolic,
        diastolic: card.bloodPressure.diastolic,
        measuredAt: card.bloodPressure.measuredAt,
        status: card.bloodPressure.stateText
      } : undefined,
      bloodSugar: card && card.bloodSugar ? {
        value: card.bloodSugar.value,
        unit: card.bloodSugar.unit,
        type: card.bloodSugar.typeText,
        measuredAt: card.bloodSugar.measuredAt,
        status: card.bloodSugar.stateText
      } : undefined,
      heartRate: card && card.heartRate ? {
        value: card.heartRate.value,
        unit: card.heartRate.unit,
        measuredAt: card.heartRate.measuredAt,
        status: card.heartRate.stateText
      } : undefined,
      sleep: card && card.sleep ? {
        totalMinutes: card.sleep.totalMinutes,
        measuredAt: card.sleep.measuredAt,
        source: card.sleep.source
      } : undefined,
      weight: card && card.body && card.body.weightKg ? {
        value: card.body.weightKg,
        bmi: card.body.bmi,
        measuredAt: card.body.measuredAt
      } : undefined,
      healthCard: card
    };
    return updated;
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
              healthCard: this.selectedMember && this.selectedMember.healthCard ? this.selectedMember.healthCard : null,
              isLoading: false,
              onBack: () => {
                this.showMemberDetail = false;
              },
              onViewSettings: () => {
                this.showShareSettings = true;
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

      if (this.showShareSettings && this.selectedMember !== null) {
        Column() {
          FamilyShareSettings({
            member: this.selectedMember,
            isViewMode: false,
            onClose: () => {
              this.showShareSettings = false;
            },
            onSave: async (categories: ShareCategory[], historyDays: number): Promise<boolean> => {
              if (this.selectedMember) {
                const updated: FamilyMemberCard = {
                  id: this.selectedMember.id,
                  relationId: this.selectedMember.relationId,
                  displayName: this.selectedMember.displayName,
                  relationType: this.selectedMember.relationType,
                  relationLabel: this.selectedMember.relationLabel,
                  avatar: this.selectedMember.avatar,
                  lastUpdateTime: this.selectedMember.lastUpdateTime,
                  attentionCount: this.selectedMember.attentionCount,
                  status: this.selectedMember.status,
                  grantedCategories: categories,
                  historyWindowDays: historyDays,
                  bloodPressure: this.selectedMember.bloodPressure,
                  bloodSugar: this.selectedMember.bloodSugar,
                  heartRate: this.selectedMember.heartRate,
                  sleep: this.selectedMember.sleep,
                  weight: this.selectedMember.weight,
                  healthCard: this.selectedMember.healthCard
                };
                this.selectedMember = updated;
                const memberIdx = this.members.findIndex((m: FamilyMemberCard) => m.id === updated.id);
                if (memberIdx >= 0) {
                  const newList = [...this.members];
                  newList[memberIdx] = updated;
                  this.members = newList;
                }
              }
              return true;
            }
          })
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)
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
