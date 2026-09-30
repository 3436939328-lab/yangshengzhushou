import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';
import { http } from '@kit.NetworkKit';
import { WeatherWellness } from '../model/WellnessModels';
import {
  buildApiUrlWithBase,
  getApiConfig,
  setRuntimeBaseUrl,
  uniqueCandidateBaseUrls
} from './ApiConfig';
import { createPreferencesPermissionStatusRepository } from './PermissionStatusRepository';

const LOCATION_PERMISSION_DENIED_MESSAGE = 'location permission denied';
const LOCATION_SWITCH_OFF_MESSAGE = 'location switch off';
const LOCATION_COORDINATE_UNAVAILABLE_MESSAGE = 'location coordinate unavailable';

export function getCurrentWeatherWellness(): WeatherWellness {
  return buildWeatherLocationUnavailableFallback();
}

export function buildWeatherLocationUnavailableFallback(): WeatherWellness {
  const weather: WeatherWellness = {
    city: '定位未获取',
    condition: '天气未获取',
    temperature: '--℃',
    humidity: '--',
    advice: '暂未获取当前位置，请检查定位权限和系统定位开关，当前建议不会结合实时温湿度。',
    riskLevel: '定位待开启',
    sourceLabel: '定位未获取',
    isFallback: true
  };
  return weather;
}

export function buildWeatherLocationPermissionDeniedFallback(): WeatherWellness {
  const weather: WeatherWellness = {
    city: '定位未授权',
    condition: '天气未获取',
    temperature: '--℃',
    humidity: '--',
    advice: 'APP定位权限还未授权，请在系统设置中允许本应用使用定位后再刷新天气。',
    riskLevel: '定位权限待开启',
    sourceLabel: '定位权限未授权',
    isFallback: true
  };
  return weather;
}

export function buildWeatherLocationSwitchOffFallback(): WeatherWellness {
  const weather: WeatherWellness = {
    city: '定位未开启',
    condition: '天气未获取',
    temperature: '--℃',
    humidity: '--',
    advice: '系统定位服务当前未开启，请打开手机定位服务后再刷新天气。',
    riskLevel: '系统定位待开启',
    sourceLabel: '系统定位未开启',
    isFallback: true
  };
  return weather;
}

export function buildWeatherCoordinateUnavailableFallback(): WeatherWellness {
  const weather: WeatherWellness = {
    city: '定位获取中',
    condition: '天气未获取',
    temperature: '--℃',
    humidity: '--',
    advice: '已获得定位权限，但系统暂未返回当前位置坐标，请稍后刷新，或到室外/网络较好的位置重试。',
    riskLevel: '定位信号待获取',
    sourceLabel: '坐标暂未获取',
    isFallback: true
  };
  return weather;
}

export function buildWeatherBackendUnavailableFallback(): WeatherWellness {
  const weather: WeatherWellness = {
    city: '当前位置',
    condition: '天气未获取',
    temperature: '--℃',
    humidity: '--',
    advice: '已尝试获取定位，但 Spring Boot 天气接口暂不可用，请确认 8181 后端和网络状态。',
    riskLevel: '天气待连接',
    sourceLabel: 'Spring Boot天气未连接',
    isFallback: true
  };
  return weather;
}

interface BackendWeatherPayload {
  city?: string;
  condition?: string;
  temperature?: string;
  humidity?: string;
  advice?: string;
  riskLevel?: string;
  sourceLabel?: string;
  isFallback?: boolean;
}

export interface LocationCoordinate {
  latitude: number;
  longitude: number;
  accuracy?: number;
  timestamp?: number;
  city?: string;
  province?: string;
  district?: string;
  address?: string;
  manual?: boolean;
}

interface PermissionRequestResult {
  authResults: number[];
}

export function buildCurrentLocationRequest(): geoLocationManager.CurrentLocationRequest {
  const request: geoLocationManager.CurrentLocationRequest = {
    priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
    scenario: geoLocationManager.LocationRequestScenario.DAILY_LIFE_SERVICE,
    timeoutMs: 10000,
    maxAccuracy: 1000
  };
  return request;
}

function buildCoordinateFromLocation(location: geoLocationManager.Location): LocationCoordinate {
  const coordinate: LocationCoordinate = {
    latitude: location.latitude,
    longitude: location.longitude,
    accuracy: location.accuracy,
    timestamp: location.timeStamp < 1000000000000 ? location.timeStamp * 1000 : location.timeStamp
  };
  return coordinate;
}

function isSystemLocationEnabled(): boolean {
  try {
    return geoLocationManager.isLocationEnabled();
  } catch (error) {
    return true;
  }
}

function buildWeatherLocationFailureFallback(message: string): WeatherWellness {
  if (message === LOCATION_PERMISSION_DENIED_MESSAGE) {
    return buildWeatherLocationPermissionDeniedFallback();
  }
  if (message === LOCATION_SWITCH_OFF_MESSAGE) {
    return buildWeatherLocationSwitchOffFallback();
  }
  if (message === LOCATION_COORDINATE_UNAVAILABLE_MESSAGE) {
    return buildWeatherCoordinateUnavailableFallback();
  }
  return buildWeatherLocationUnavailableFallback();
}

export function buildWeatherFromBackendPayload(payload: string): WeatherWellness {
  const data = JSON.parse(payload) as BackendWeatherPayload;
  if (!data.condition || !data.temperature || !data.humidity || !data.sourceLabel) {
    return buildWeatherBackendUnavailableFallback();
  }
  const weather: WeatherWellness = {
    city: data.city ? data.city : '当前位置',
    condition: data.condition,
    temperature: data.temperature ? data.temperature : '--℃',
    humidity: data.humidity ? data.humidity : '--',
    advice: data.advice ? data.advice : '已获取当前位置，暂无详细天气建议。',
    riskLevel: data.riskLevel ? data.riskLevel : '位置天气',
    sourceLabel: data.sourceLabel ? data.sourceLabel : '定位天气',
    isFallback: data.isFallback === true || data.temperature.indexOf('--') >= 0 || data.humidity.indexOf('--') >= 0
  };
  return weather;
}

function requestLocationPermission(context: common.UIAbilityContext): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager();
  const permissionRepository = createPreferencesPermissionStatusRepository(context);
  const permissions: Permissions[] = [
    'ohos.permission.APPROXIMATELY_LOCATION',
    'ohos.permission.LOCATION'
  ];
  return atManager.requestPermissionsFromUser(context, permissions).then((result: PermissionRequestResult) => {
    for (let index = 0; index < result.authResults.length; index++) {
      if (result.authResults[index] === 0) {
        return permissionRepository.saveLocationPermissionState('granted').then(() => {
          return true;
        });
      }
    }
    return permissionRepository.saveLocationPermissionState('notGranted').then(() => {
      return false;
    });
  }).catch(() => {
    return permissionRepository.saveLocationPermissionState('notGranted').then(() => {
      return false;
    }).catch(() => {
      return false;
    });
  });
}

function requestCurrentCoordinate(context: common.UIAbilityContext): Promise<LocationCoordinate> {
  return requestLocationPermission(context).then((granted: boolean) => {
    if (!granted) {
      return Promise.reject(new Error(LOCATION_PERMISSION_DENIED_MESSAGE));
    }
    if (!isSystemLocationEnabled()) {
      return Promise.reject(new Error(LOCATION_SWITCH_OFF_MESSAGE));
    }
    return geoLocationManager.getCurrentLocation(buildCurrentLocationRequest()).catch(() => {
      try {
        return geoLocationManager.getLastLocation();
      } catch (error) {
        return Promise.reject(new Error(LOCATION_COORDINATE_UNAVAILABLE_MESSAGE));
      }
    });
  }).then((location: geoLocationManager.Location) => {
    const coordinate = buildCoordinateFromLocation(location);
    if (!isFreshCoordinate(coordinate)) {
      throw new Error(LOCATION_COORDINATE_UNAVAILABLE_MESSAGE);
    }
    return coordinate;
  });
}

export function requestLocatedWeatherWellness(context: common.UIAbilityContext): Promise<WeatherWellness> {
  return requestCurrentCoordinate(context).then((coordinate: LocationCoordinate) => {
    return resolveCoordinateAddress(coordinate).then((located: LocationCoordinate) => requestWeatherAtLocation(located));
  }).catch((error: Error) => {
    return buildWeatherLocationFailureFallback(error.message);
  });
}

export function buildLocatedWeatherUrl(baseUrl: string, weatherPath: string, latitude: number, longitude: number): string {
  return `${buildApiUrlWithBase(baseUrl, weatherPath)}?latitude=${latitude}&longitude=${longitude}`;
}

function requestLocatedWeatherFromCandidates(
  baseUrls: string[],
  index: number,
  coordinate: LocationCoordinate
): Promise<WeatherWellness> {
  if (index >= baseUrls.length) {
    return Promise.resolve(buildWeatherBackendUnavailableFallback());
  }
  const config = getApiConfig();
  const baseUrl = baseUrls[index];
  const weatherUrl = buildLocatedWeatherUrl(baseUrl, config.weatherPath, coordinate.latitude, coordinate.longitude)
    + `&city=${encodeURIComponent(coordinate.city || '')}`;
  const request = http.createHttp();
  return request.request(weatherUrl, {
    method: http.RequestMethod.GET,
    connectTimeout: config.timeoutMs,
    readTimeout: config.timeoutMs
  }).then((response: http.HttpResponse) => {
    request.destroy();
    if (response.responseCode < 200 || response.responseCode >= 300) {
      return requestLocatedWeatherFromCandidates(baseUrls, index + 1, coordinate);
    }
    setRuntimeBaseUrl(baseUrl);
    return attachLocation(buildWeatherFromBackendPayload(`${response.result}`), coordinate);
  }).catch(() => {
    request.destroy();
    return requestLocatedWeatherFromCandidates(baseUrls, index + 1, coordinate);
  });
}

export function isFreshCoordinate(coordinate: LocationCoordinate, now: number = Date.now()): boolean {
  return Number.isFinite(coordinate.latitude) && Number.isFinite(coordinate.longitude)
    && coordinate.latitude >= -90 && coordinate.latitude <= 90
    && coordinate.longitude >= -180 && coordinate.longitude <= 180
    && coordinate.timestamp !== undefined && Math.abs(now - coordinate.timestamp) <= 300000
    && coordinate.accuracy !== undefined && coordinate.accuracy >= 0 && coordinate.accuracy <= 5000;
}

function attachLocation(weather: WeatherWellness, coordinate: LocationCoordinate): WeatherWellness {
  weather.city = coordinate.city || '位置已获取';
  weather.province = coordinate.province || '';
  weather.district = coordinate.district || '';
  weather.address = coordinate.address || `${coordinate.latitude.toFixed(4)}, ${coordinate.longitude.toFixed(4)}`;
  weather.latitude = coordinate.latitude;
  weather.longitude = coordinate.longitude;
  weather.locationAccuracy = coordinate.accuracy;
  weather.locationTimestamp = coordinate.timestamp;
  weather.sourceLabel = `${coordinate.manual ? '手动位置' : '系统定位'} · ${weather.sourceLabel}`;
  return weather;
}

function coordinateFromAddress(address: geoLocationManager.GeoAddress, coordinate: LocationCoordinate): LocationCoordinate {
  coordinate.city = address.locality || address.administrativeArea || '';
  coordinate.province = address.administrativeArea || '';
  coordinate.district = address.subLocality || '';
  coordinate.address = address.descriptions && address.descriptions.length > 0
    ? address.descriptions.join(' ') : `${coordinate.province}${coordinate.city}${coordinate.district}`;
  return coordinate;
}

async function resolveCoordinateAddress(coordinate: LocationCoordinate): Promise<LocationCoordinate> {
  try {
    const addresses = await geoLocationManager.getAddressesFromLocation({
      latitude: coordinate.latitude, longitude: coordinate.longitude, locale: 'zh-CN', maxItems: 1
    });
    if (addresses.length > 0) {
      return coordinateFromAddress(addresses[0], coordinate);
    }
  } catch (error) {
    // A geocoder failure does not invalidate the device coordinate or weather request.
  }
  return coordinate;
}

export async function searchLocations(query: string): Promise<LocationCoordinate[]> {
  if (query.trim().length < 2) {
    throw new Error('请输入至少两个字的城市或地址');
  }
  const addresses = await geoLocationManager.getAddressesFromLocationName({
    description: query.trim(), locale: 'zh-CN', maxItems: 8
  });
  const results: LocationCoordinate[] = [];
  for (let index = 0; index < addresses.length; index++) {
    const address = addresses[index];
    if (address.latitude !== undefined && address.longitude !== undefined) {
      results.push(coordinateFromAddress(address, {
        latitude: address.latitude, longitude: address.longitude, manual: true, timestamp: Date.now()
      }));
    }
  }
  return results;
}

export async function requestWeatherAtLocation(coordinate: LocationCoordinate): Promise<WeatherWellness> {
  const weather = await requestLocatedWeatherFromCandidates([getApiConfig().baseUrl], 0, coordinate);
  if (weather.latitude === undefined) {
    return attachLocation(weather, coordinate);
  }
  return weather;
}
