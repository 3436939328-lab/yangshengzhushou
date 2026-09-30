import { common } from '@kit.AbilityKit';
import { PrivacyStatusItem } from '../model/WellnessModels';
import { createPreferencesPermissionStatusRepository, StoredPermissionState } from './PermissionStatusRepository';

export type PermissionState = 'granted' | 'notGranted' | 'notConfigured' | 'notUsed';

export interface PrivacyPermissionStates {
  location: PermissionState;
  camera: PermissionState;
  notification: PermissionState;
  bluetooth: PermissionState;
}

export function getPrivacySummary(): string {
  return '当前健康档案保存在本地设备，未开启云同步；问卷、舌象、指标和提醒偏好仅用于本机养生建议。';
}

function permissionStatusText(state: PermissionState): string {
  if (state === 'granted') {
    return '已授权';
  }
  if (state === 'notGranted') {
    return '未授权';
  }
  if (state === 'notConfigured') {
    return '未配置';
  }
  return '当前未使用';
}

export function buildPrivacyStatusItemsFromPermissionStates(states: PrivacyPermissionStates): PrivacyStatusItem[] {
  const items: PrivacyStatusItem[] = [
    {
      title: '数据位置',
      detail: '健康档案保存在本机应用数据中。',
      status: '本地'
    },
    {
      title: '云同步',
      detail: '当前版本不上传健康档案，也不提供云端备份。',
      status: '未开启'
    },
    {
      title: '定位权限',
      detail: '用于获取当前位置天气，辅助生成本地化养生建议。',
      status: permissionStatusText(states.location)
    },
    {
      title: '相机权限',
      detail: '预留给舌象拍照能力；当前舌象仍以文字记录为主。',
      status: permissionStatusText(states.camera)
    },
    {
      title: '通知权限',
      detail: '用于饮水、久坐和睡前提醒等本机通知。',
      status: permissionStatusText(states.notification)
    },
    {
      title: '设备连接权限',
      detail: '预留给蓝牙设备管理；当前健康指标仍以手动记录为主。',
      status: permissionStatusText(states.bluetooth)
    },
    {
      title: '数据范围',
      detail: '包括体质问卷、舌象文字、手动指标和提醒偏好。',
      status: '本地使用'
    }
  ];
  return items;
}

export function getPrivacyStatusItems(): PrivacyStatusItem[] {
  return buildPrivacyStatusItemsFromPermissionStates({
    location: 'notGranted',
    camera: 'notUsed',
    notification: 'notConfigured',
    bluetooth: 'notUsed'
  });
}

export function getRuntimePrivacyStatusItems(context: common.UIAbilityContext): Promise<PrivacyStatusItem[]> {
  const permissionRepository = createPreferencesPermissionStatusRepository(context);
  return permissionRepository.loadLocationPermissionState().then((locationState: StoredPermissionState) => {
    return buildPrivacyStatusItemsFromPermissionStates({
      location: locationState,
      camera: 'notUsed',
      notification: 'notConfigured',
      bluetooth: 'notUsed'
    });
  }).catch(() => {
    return getPrivacyStatusItems();
  });
}
