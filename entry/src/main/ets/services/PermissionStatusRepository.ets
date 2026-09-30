import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

export type StoredPermissionState = 'granted' | 'notGranted';

const LOCATION_PERMISSION_KEY: string = 'location_permission_state';

export interface PermissionStatusStorageAdapter {
  read(key: string): Promise<string>;
  write(key: string, value: string): Promise<void>;
}

export class MemoryPermissionStatusStorageAdapter implements PermissionStatusStorageAdapter {
  private values: Map<string, string> = new Map<string, string>();

  async read(key: string): Promise<string> {
    return this.values.get(key) || '';
  }

  async write(key: string, value: string): Promise<void> {
    this.values.set(key, value);
  }
}

export class PreferencesPermissionStatusStorageAdapter implements PermissionStatusStorageAdapter {
  private context: common.UIAbilityContext;
  private storeName: string;

  constructor(context: common.UIAbilityContext, storeName: string = 'wellness_permissions') {
    this.context = context;
    this.storeName = storeName;
  }

  async read(key: string): Promise<string> {
    try {
      const store = await preferences.getPreferences(this.context, { name: this.storeName });
      const value = store.getSync(key, '');
      return typeof value === 'string' ? value : '';
    } catch (error) {
      return '';
    }
  }

  async write(key: string, value: string): Promise<void> {
    try {
      const store = await preferences.getPreferences(this.context, { name: this.storeName });
      store.putSync(key, value);
      await store.flush();
    } catch (error) {
    }
  }
}

function isStoredPermissionState(value: string): boolean {
  return value === 'granted' || value === 'notGranted';
}

export class PermissionStatusRepository {
  private storage: PermissionStatusStorageAdapter;

  constructor(storage: PermissionStatusStorageAdapter) {
    this.storage = storage;
  }

  async loadLocationPermissionState(): Promise<StoredPermissionState> {
    const stored = await this.storage.read(LOCATION_PERMISSION_KEY);
    if (isStoredPermissionState(stored)) {
      return stored as StoredPermissionState;
    }
    return 'notGranted';
  }

  async saveLocationPermissionState(state: StoredPermissionState): Promise<StoredPermissionState> {
    const nextState: StoredPermissionState = state === 'granted' ? 'granted' : 'notGranted';
    await this.storage.write(LOCATION_PERMISSION_KEY, nextState);
    return nextState;
  }
}

export function createPreferencesPermissionStatusRepository(context: common.UIAbilityContext): PermissionStatusRepository {
  return new PermissionStatusRepository(new PreferencesPermissionStatusStorageAdapter(context));
}
