export interface WeatherWellness {
  city: string;
  condition: string;
  temperature: string;
  humidity: string;
  advice: string;
  riskLevel: string;
  sourceLabel: string;
  isFallback?: boolean;
  province?: string;
  district?: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  locationAccuracy?: number;
  locationTimestamp?: number;
}

export interface WellnessLocation {
  city: string;
  district: string;
  address: string;
  province?: string;
  latitude?: number;
  longitude?: number;
}

export interface SolarTermInfo {
  name: string;
  date: string;
  focus: string;
  foods: string[];
  routine: string;
}

export interface WellnessPlan {
  title: string;
  time: string;
  detail: string;
  tag: string;
}

export interface QuickAction {
  title: string;
  description: string;
}

export interface ChatMessage {
  id?: string;
  role: string;
  content: string;
  source?: string;
  suggestions?: string[];
  plan?: WellnessPlanItem[];
  riskLevel?: string;
}

export interface WellnessPlanItem {
  timeOfDay: string;
  title: string;
  action: string;
  reason: string;
}

export interface SuggestionResult {
  source: string;
  riskLevel: string;
  scenario: string;
  summary: string;
  suggestions: string[];
  plans: WellnessPlanItem[];
  disclaimer: string;
  retrievalStatus?: string;
}

export interface HealthMetric {
  name: string;
  value: string;
  unit: string;
  status: string;
  trend: number[];
}

export interface ProfileAction {
  title: string;
  description: string;
  status: string;
}

export interface ConstitutionResult {
  name: string;
  score: number;
  suggestion: string;
}

export interface HerbalRecipe {
  name: string;
  ingredients: string;
  effect: string;
  suitableFor: string;
}

export interface AcupointGuide {
  name: string;
  location: string;
  method: string;
}

export interface RecommendationPlan {
  recipe: HerbalRecipe;
  acupoint: AcupointGuide;
  warning: string;
}

export interface HealthRiskSummary {
  level: string;
  message: string;
  actions: string[];
}

export interface GuideSlide {
  title: string;
  description: string;
}

export interface ReminderItem {
  title: string;
  time: string;
  enabled: boolean;
}

export interface DeviceStatus {
  name: string;
  type: string;
  status: string;
  lastSync: string;
}

export interface ArchiveSummary {
  title: string;
  value: string;
  description: string;
}

export interface FoodContraindication {
  food: string;
  crowd: string;
  property: string;
  warning: string;
}

export interface PlanSegment {
  title: string;
  detail: string;
  reason: string;
}

export interface PersonalPlan {
  diet: PlanSegment;
  exercise: PlanSegment;
  sleep: PlanSegment;
}

export interface IndicatorItem {
  name: string;
  value: string;
  reference: string;
  status: string;
  advice: string;
}

export interface MedicalReportInterpretation {
  summary: string;
  abnormalItems: IndicatorItem[];
  normalItems: IndicatorItem[];
}

export interface MonthlyReport {
  title: string;
  summary: string;
  suggestion: string;
}

export interface PrivacyStatusItem {
  title: string;
  detail: string;
  status: string;
}

export interface EmptyStateInfo {
  title: string;
  detail: string;
}
