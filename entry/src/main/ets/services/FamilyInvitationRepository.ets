import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { FamilyInvitation, FamilyRelationStatus, FamilyRelationType } from '../model/FamilyModels';

const STORE_NAME = 'wellness_family_invitations';
const KEY_INVITATIONS = 'invitations';

export interface StoredFamilyInvitation {
  id: string;
  inviterId: string;
  inviterPhone: string;
  inviterName: string;
  inviteePhone: string;
  relationType: FamilyRelationType;
  relationLabel: string;
  status: FamilyRelationStatus;
  expiresAt: string;
  createdAt: string;
}

export class FamilyInvitationRepository {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  private async getStore(): Promise<preferences.Preferences> {
    return preferences.getPreferences(this.context, { name: STORE_NAME });
  }

  async loadAll(): Promise<StoredFamilyInvitation[]> {
    const store = await this.getStore();
    const raw = store.getSync(KEY_INVITATIONS, '');
    if (typeof raw !== 'string' || raw.length === 0) return [];
    try {
      const list = JSON.parse(raw) as StoredFamilyInvitation[];
      return Array.isArray(list) ? list : [];
    } catch {
      return [];
    }
  }

  private async saveAll(invitations: StoredFamilyInvitation[]): Promise<void> {
    const store = await this.getStore();
    await store.put(KEY_INVITATIONS, JSON.stringify(invitations));
    await store.flush();
  }

  async addInvitation(invitation: StoredFamilyInvitation): Promise<void> {
    const list = await this.loadAll();
    list.unshift(invitation);
    await this.saveAll(list);
  }

  async updateStatus(invitationId: string, status: FamilyRelationStatus): Promise<void> {
    const list = await this.loadAll();
    for (let i = 0; i < list.length; i++) {
      if (list[i].id === invitationId) {
        list[i].status = status;
        break;
      }
    }
    await this.saveAll(list);
  }

  async removeInvitation(invitationId: string): Promise<void> {
    const list = await this.loadAll();
    const filtered = list.filter((item: StoredFamilyInvitation) => item.id !== invitationId);
    await this.saveAll(filtered);
  }

  async getInvitationsForInvitee(phone: string): Promise<StoredFamilyInvitation[]> {
    const list = await this.loadAll();
    return list.filter((item: StoredFamilyInvitation) =>
      item.inviteePhone === phone && item.status === FamilyRelationStatus.PENDING
    );
  }

  async getInvitationsByInviter(inviterId: string): Promise<StoredFamilyInvitation[]> {
    const list = await this.loadAll();
    return list.filter((item: StoredFamilyInvitation) => item.inviterId === inviterId);
  }
}

export function createFamilyInvitationRepository(context: common.UIAbilityContext): FamilyInvitationRepository {
  return new FamilyInvitationRepository(context);
}
