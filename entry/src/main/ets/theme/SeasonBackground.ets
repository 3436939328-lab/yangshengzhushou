import { getCurrentSeason } from '../utils/SolarTermUtil';

export function seasonBackground(date: Date = new Date()): Resource {
  const season = getCurrentSeason(date);
  if (season === 0) return $r('app.media.season_spring');
  if (season === 1) return $r('app.media.season_summer');
  if (season === 2) return $r('app.media.season_autumn');
  return $r('app.media.season_winter');
}
