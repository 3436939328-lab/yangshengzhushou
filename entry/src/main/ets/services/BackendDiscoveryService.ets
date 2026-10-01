import { connection } from '@kit.NetworkKit';
import { http } from '@kit.NetworkKit';
import { normalizeApiBaseUrl } from './ApiConfig';

const BACKEND_PORT: number = 8181;
const HEALTH_PATH: string = '/api/health';
const PROBE_TIMEOUT_MS: number = 1800;
const BATCH_SIZE: number = 12;

/**
 * 获取设备当前局域网 IP，用于推导同网段候选地址。
 */
async function getLocalIpAddress(): Promise<string> {
  try {
    const netHandle = await connection.getDefaultNet();
    const props = await connection.getConnectionProperties(netHandle);
    const linkAddresses = props.linkAddresses;
    for (let i = 0; i < linkAddresses.length; i++) {
      const ip = linkAddresses[i].address.address;
      if (ip && ip.indexOf('.') > 0 && ip.indexOf('127.') !== 0 && ip.indexOf('169.254.') !== 0) {
        return ip;
      }
    }
  } catch (error) {
  }
  return '';
}

/**
 * 根据本机 IP 推导同网段候选列表（1-254）。
 */
function buildCandidatesFromLocalIp(localIp: string): string[] {
  const parts = localIp.split('.');
  if (parts.length !== 4) {
    return [];
  }
  const prefix = `${parts[0]}.${parts[1]}.${parts[2]}.`;
  const candidates: string[] = [];
  for (let last = 1; last <= 254; last++) {
    const ip = `${prefix}${last}`;
    if (ip !== localIp) {
      candidates.push(ip);
    }
  }
  // 把常用的网关/小地址优先
  const prioritized: string[] = [];
  const preferred = [1, 2, 100, 101, 102];
  for (let p = 0; p < preferred.length; p++) {
    const ip = `${prefix}${preferred[p]}`;
    if (ip !== localIp && candidates.indexOf(ip) >= 0) {
      prioritized.push(ip);
    }
  }
  for (let i = 0; i < candidates.length; i++) {
    if (prioritized.indexOf(candidates[i]) < 0) {
      prioritized.push(candidates[i]);
    }
  }
  return prioritized;
}

/**
 * 常见家用网段兜底列表。
 */
function buildFallbackCandidates(): string[] {
  const subnets: string[] = ['192.168.1.', '192.168.0.', '192.168.5.', '10.0.0.', '10.0.2.'];
  const result: string[] = [];
  for (let s = 0; s < subnets.length; s++) {
    for (let last = 1; last <= 254; last++) {
      result.push(`${subnets[s]}${last}`);
    }
  }
  return result;
}

/**
 * 探测单个 IP 是否运行后端服务。
 */
function probeBackend(ip: string): Promise<string> {
  const url = `http://${ip}:${BACKEND_PORT}${HEALTH_PATH}`;
  const request = http.createHttp();
  return request.request(url, {
    method: http.RequestMethod.GET,
    connectTimeout: PROBE_TIMEOUT_MS,
    readTimeout: PROBE_TIMEOUT_MS
  }).then((response: http.HttpResponse) => {
    request.destroy();
    if (response.responseCode === 200) {
      return `http://${ip}:${BACKEND_PORT}`;
    }
    return '';
  }).catch(() => {
    request.destroy();
    return '';
  });
}

/**
 * 并行批量探测，找到第一个可用后端即返回。
 */
async function scanCandidates(candidates: string[]): Promise<string> {
  let index = 0;
  while (index < candidates.length) {
    const batch: string[] = [];
    for (let i = 0; i < BATCH_SIZE && index < candidates.length; i++, index++) {
      batch.push(candidates[index]);
    }
    const results = await Promise.all(batch.map((ip: string) => probeBackend(ip)));
    for (let r = 0; r < results.length; r++) {
      if (results[r].length > 0) {
        return results[r];
      }
    }
  }
  return '';
}

/**
 * 自动发现局域网中的养生助手后端。
 * 返回可用的 baseUrl，找不到则返回空字符串。
 */
export async function discoverBackendOnLan(): Promise<string> {
  const localIp = await getLocalIpAddress();
  let candidates: string[];
  if (localIp.length > 0) {
    candidates = buildCandidatesFromLocalIp(localIp);
  } else {
    candidates = buildFallbackCandidates();
  }
  // 限制最多扫描 256 个地址，避免耗时过长
  if (candidates.length > 256) {
    candidates = candidates.slice(0, 256);
  }
  return scanCandidates(candidates);
}

/**
 * 检查指定 baseUrl 是否可用。
 */
export function checkBackendAvailable(baseUrl: string): Promise<boolean> {
  const normalized = normalizeApiBaseUrl(baseUrl);
  if (normalized.length === 0) {
    return Promise.resolve(false);
  }
  const url = `${normalized}${HEALTH_PATH}`;
  const request = http.createHttp();
  return request.request(url, {
    method: http.RequestMethod.GET,
    connectTimeout: 4000,
    readTimeout: 4000
  }).then((response: http.HttpResponse) => {
    request.destroy();
    return response.responseCode === 200;
  }).catch(() => {
    request.destroy();
    return false;
  });
}
