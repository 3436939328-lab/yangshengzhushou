import { http } from '@kit.NetworkKit';
import { HealthProfile } from '../model/ProfileModels';
import { SuggestionResult, WeatherWellness, WellnessLocation, WellnessPlanItem } from '../model/WellnessModels';
import { buildSuggestionApiUrl, getApiConfig } from './ApiConfig';
import { buildAuthorizedJsonHeaders } from './AuthService';
import { checkBackendHealth } from './BackendStatusService';
import { buildHttpFailureText, normalizeNetworkErrorMessage } from './RequestErrorService';

export interface SuggestionRequestPayload {
  scenario: string;
  weather: WeatherWellness;
  profile: HealthProfile;
  location: WellnessLocation;
}

interface BackendSuggestionPayload {
  source?: string;
  riskLevel?: string;
  scenario?: string;
  summary?: string;
  suggestions?: string[];
  plans?: WellnessPlanItem[];
  disclaimer?: string;
  retrievalStatus?: string;
}

export function buildSuggestionLocation(weather: WeatherWellness): WellnessLocation {
  const city = weather.city && weather.city.length > 0 ? weather.city : '当前位置';
  return {
    city,
    district: weather.district || '',
    address: weather.address || city,
    province: weather.province,
    latitude: weather.latitude,
    longitude: weather.longitude
  };
}

export function buildSuggestionRequestPayload(
  scenario: string,
  weather: WeatherWellness,
  profile: HealthProfile
): SuggestionRequestPayload {
  return {
    scenario,
    weather,
    profile,
    location: buildSuggestionLocation(weather)
  };
}

export function buildSuggestionResultFromBackendPayload(payload: string): SuggestionResult {
  const data = JSON.parse(payload) as BackendSuggestionPayload;
  return {
    source: data.source ? data.source : '后端',
    riskLevel: data.riskLevel ? data.riskLevel : 'normal',
    scenario: data.scenario ? data.scenario : 'home',
    summary: data.summary ? data.summary : '',
    suggestions: data.suggestions ? data.suggestions : [],
    plans: data.plans ? data.plans : [],
    disclaimer: data.disclaimer ? data.disclaimer : '',
    retrievalStatus: data.retrievalStatus ? data.retrievalStatus : ''
  };
}

export function requestWeatherAwareSuggestions(
  scenario: string,
  weather: WeatherWellness,
  profile: HealthProfile
): Promise<SuggestionResult> {
    const config = getApiConfig();
    const request = http.createHttp();
    const body = JSON.stringify(buildSuggestionRequestPayload(scenario, weather, profile));
    return request.request(buildSuggestionApiUrl(config.suggestionsPath), {
      method: http.RequestMethod.POST,
      header: buildAuthorizedJsonHeaders(),
      extraData: body,
      connectTimeout: config.timeoutMs,
      readTimeout: config.aiTimeoutMs
    }).then((response: http.HttpResponse) => {
      request.destroy();
      if (response.responseCode < 200 || response.responseCode >= 300) {
        return Promise.reject(new Error(buildHttpFailureText(response.responseCode, `${response.result}`)));
      }
      return buildSuggestionResultFromBackendPayload(`${response.result}`);
    }).catch((error: Error) => {
      request.destroy();
      return Promise.reject(new Error(normalizeNetworkErrorMessage(error.message)));
    });
}
