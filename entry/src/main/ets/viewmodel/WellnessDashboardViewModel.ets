import {
  ArchiveSummary,
  DeviceStatus,
  GuideSlide,
  HealthMetric,
  ProfileAction,
  QuickAction,
  ReminderItem,
  SolarTermInfo,
  WeatherWellness,
  WellnessPlan
} from '../model/WellnessModels';
import { getDeviceStatuses } from '../services/DeviceService';
import { getArchiveSummaries } from '../services/HealthDataService';
import {
  getDailyPlans,
  getGuideSlides,
  getHealthMetrics,
  getProfileActions,
  getQuickActions,
  getReminderItems
} from '../services/WellnessContentService';
import { getCurrentWeatherWellness } from '../services/WeatherService';
import { getCurrentSolarTerm } from '../utils/SolarTermUtil';

export interface WellnessDashboardData {
  guideSlides: GuideSlide[];
  weather: WeatherWellness;
  solarTerm: SolarTermInfo;
  plans: WellnessPlan[];
  quickActions: QuickAction[];
  metrics: HealthMetric[];
  devices: DeviceStatus[];
  archiveSummaries: ArchiveSummary[];
  profileActions: ProfileAction[];
  reminders: ReminderItem[];
}

export function createWellnessDashboardData(): WellnessDashboardData {
  return {
    guideSlides: getGuideSlides(),
    weather: getCurrentWeatherWellness(),
    solarTerm: getCurrentSolarTerm(),
    plans: getDailyPlans(),
    quickActions: getQuickActions(),
    metrics: getHealthMetrics(),
    devices: getDeviceStatuses(),
    archiveSummaries: getArchiveSummaries(),
    profileActions: getProfileActions(),
    reminders: getReminderItems()
  };
}
