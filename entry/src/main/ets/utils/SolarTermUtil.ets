import { SolarTermInfo } from '../model/WellnessModels';
import { SOLAR_TERM_START_YEAR, SOLAR_TERM_TIMES } from './SolarTermData';

const NAMES: string[] = ['小寒', '大寒', '立春', '雨水', '惊蛰', '春分', '清明', '谷雨',
  '立夏', '小满', '芒种', '夏至', '小暑', '大暑', '立秋', '处暑', '白露', '秋分',
  '寒露', '霜降', '立冬', '小雪', '大雪', '冬至'];
const FOCUS: string[] = ['春日舒展，规律起居', '适度补水，避开高温运动', '秋日润燥，注意温差', '冬日保暖，适度活动'];
const FOODS: string[][] = [['春笋', '菠菜', '山药'], ['冬瓜', '绿豆', '莲子'], ['梨', '百合', '银耳'], ['萝卜', '山药', '杂粮']];
const ROUTINES: string[] = ['适量散步，保持稳定的睡眠时间。', '户外活动避开午间高温，出汗后及时补水。', '早晚及时添衣，保持室内通风。', '运动前充分热身，避免长时间久坐。'];

function currentTermIndex(date: Date): number[] {
  const timestamp = date.getTime();
  const year = new Date(timestamp + 8 * 3600000).getUTCFullYear();
  if (!Number.isFinite(timestamp) || year < 2000 || year > 2100) {
    return [];
  }
  const row = year - SOLAR_TERM_START_YEAR;
  for (let index = 23; index >= 0; index--) {
    if (timestamp >= SOLAR_TERM_TIMES[row][index] * 1000) {
      return [row, index];
    }
  }
  return [row - 1, 23];
}

export function getCurrentSeason(date: Date = new Date()): number {
  const term = currentTermIndex(date);
  if (term.length === 0) {
    return 3;
  }
  const index = term[1];
  return index >= 2 && index < 8 ? 0 : index >= 8 && index < 14 ? 1 : index >= 14 && index < 20 ? 2 : 3;
}

export function getCurrentSolarTerm(date: Date = new Date()): SolarTermInfo {
  const term = currentTermIndex(date);
  if (term.length === 0) {
    return { name: '日期待校准', date: '', focus: '请检查设备日期', foods: [], routine: '历法支持 2000 至 2100 年。' };
  }
  const season = getCurrentSeason(date);
  const instant = new Date(SOLAR_TERM_TIMES[term[0]][term[1]] * 1000 + 8 * 3600000);
  const label = `${instant.getUTCFullYear()}-${`${instant.getUTCMonth() + 1}`.padStart(2, '0')}-${`${instant.getUTCDate()}`.padStart(2, '0')}`;
  return { name: NAMES[term[1]], date: label, focus: FOCUS[season], foods: FOODS[season], routine: ROUTINES[season] };
}
