import { DeviceStatus } from '../model/WellnessModels';

export function getDeviceSyncSummary(connectedCount: number, pendingCount: number): string {
  if (connectedCount === 0) {
    return '设备同步暂未接入';
  }
  return `已连接${connectedCount}台设备，${pendingCount}台待同步`;
}

export function countPendingDeviceSyncs(devices: DeviceStatus[]): number {
  let pendingCount = 0;
  for (let index = 0; index < devices.length; index++) {
    if (devices[index].status === '待同步') {
      pendingCount += 1;
    }
  }
  return pendingCount;
}

export function getDeviceStatuses(): DeviceStatus[] {
  return [];
}
