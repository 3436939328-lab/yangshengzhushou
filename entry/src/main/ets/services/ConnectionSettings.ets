import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { getApiConfig, normalizeApiBaseUrl, setRuntimeBaseUrl } from './ApiConfig';

export async function loadConnectionSettings(context: common.UIAbilityContext): Promise<void> {
  const store = await preferences.getPreferences(context, { name: 'wellness_connection' });
  const value = store.getSync('baseUrl', '');
  if (typeof value === 'string' && value.length > 0) {
    setRuntimeBaseUrl(value);
  }
}

export async function saveConnectionSettings(context: common.UIAbilityContext, address: string): Promise<void> {
  const normalized = normalizeApiBaseUrl(address);
  if (!/^https?:\/\/([a-zA-Z0-9.-]+|\[[0-9a-fA-F:]+\])(:[0-9]{1,5})?$/.test(normalized)) {
    throw new Error('请输入完整服务器地址，例如 http://192.168.1.7:8181');
  }
  const store = await preferences.getPreferences(context, { name: 'wellness_connection' });
  await store.put('baseUrl', normalized);
  await store.flush();
  setRuntimeBaseUrl(normalized);
}
