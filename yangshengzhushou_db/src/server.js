const http = require('http');
const os = require('os');
const { loadDotEnv } = require('./envLoader');
const { buildRuleBasedAssistantReply } = require('./ruleAssistant');
const { requestDeepSeekAssistantReply } = require('./llmClient');
const { runHealthAssistantGraph } = require('./agent/healthAssistantGraph');
const { AuthService, FileUserStore } = require('./authService');

loadDotEnv();

const DEFAULT_PORT = 8787;
const OPEN_METEO_FORECAST_URL = 'https://api.open-meteo.com/v1/forecast';
const KNOWN_CITY_COORDINATES = [
  { name: '北京', latitude: 39.9042, longitude: 116.4074 },
  { name: '上海', latitude: 31.2304, longitude: 121.4737 },
  { name: '杭州', latitude: 30.2741, longitude: 120.1551 },
  { name: '南京', latitude: 32.0603, longitude: 118.7969 },
  { name: '苏州', latitude: 31.2989, longitude: 120.5853 },
  { name: '广州', latitude: 23.1291, longitude: 113.2644 },
  { name: '深圳', latitude: 22.5431, longitude: 114.0579 },
  { name: '成都', latitude: 30.5728, longitude: 104.0668 },
  { name: '武汉', latitude: 30.5928, longitude: 114.3055 },
  { name: '西安', latitude: 34.3416, longitude: 108.9398 },
  { name: '济宁', latitude: 35.4239, longitude: 116.5873 },
  { name: '济南', latitude: 36.6512, longitude: 117.1201 },
  { name: '青岛', latitude: 36.0671, longitude: 120.3826 },
  { name: '烟台', latitude: 37.4638, longitude: 121.4479 },
  { name: '临沂', latitude: 35.1045, longitude: 118.3564 },
  { name: '潍坊', latitude: 36.7069, longitude: 119.1620 },
  { name: '泰安', latitude: 36.2000, longitude: 117.1500 },
  { name: '淄博', latitude: 36.4135, longitude: 118.0120 },
  { name: '德州', latitude: 37.4359, longitude: 116.3575 },
  { name: '聊城', latitude: 36.4567, longitude: 115.9871 },
  { name: '菏泽', latitude: 35.2332, longitude: 115.4838 },
  { name: '滨州', latitude: 37.3835, longitude: 117.2389 },
  { name: '东营', latitude: 37.4835, longitude: 118.6609 },
  { name: '威海', latitude: 37.5128, longitude: 122.1201 },
  { name: '日照', latitude: 35.3824, longitude: 119.5269 },
  { name: '枣庄', latitude: 34.8105, longitude: 117.3235 },
  { name: '济宁曲阜', latitude: 35.5835, longitude: 116.9860 }
];

function sendJson(response, statusCode, payload) {
  response.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
  });
  response.end(JSON.stringify(payload));
}

function readJsonBody(request) {
  return new Promise((resolve) => {
    let body = '';
    request.on('data', (chunk) => {
      body += chunk;
    });
    request.on('end', () => {
      if (body.trim().length === 0) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(body));
      } catch (error) {
        resolve({});
      }
    });
  });
}

function buildDefaultWeather(coordinate = null, cityParam = '') {
  const cityName = (cityParam && cityParam.length > 0)
    ? cityParam
    : (coordinate ? inferNearestCityName(coordinate) : '当前位置');
  return {
    city: cityName,
    condition: '多云',
    temperature: '27℃',
    humidity: '68%',
    advice: '湿度偏高，今日宜健脾祛湿，饮食清淡。',
    riskLevel: '湿热提醒',
    sourceLabel: '后端兜底',
    isFallback: true
  };
}

function isValidCoordinateValue(value, min, max) {
  return Number.isFinite(value) && value >= min && value <= max;
}

function parseCoordinatePair(query = {}) {
  const latitude = typeof query.latitude === 'string' ? Number(query.latitude) : NaN;
  const longitude = typeof query.longitude === 'string' ? Number(query.longitude) : NaN;
  if (!isValidCoordinateValue(latitude, -90, 90) || !isValidCoordinateValue(longitude, -180, 180)) {
    return null;
  }
  return { latitude, longitude };
}

function distanceScore(first, second) {
  const latitudeDelta = first.latitude - second.latitude;
  const longitudeDelta = first.longitude - second.longitude;
  return latitudeDelta * latitudeDelta + longitudeDelta * longitudeDelta;
}

function inferNearestCityName(coordinate) {
  if (!coordinate) {
    return '当前位置';
  }
  let nearestCity = KNOWN_CITY_COORDINATES[0];
  let nearestDistance = distanceScore(coordinate, nearestCity);
  for (let index = 1; index < KNOWN_CITY_COORDINATES.length; index++) {
    const candidate = KNOWN_CITY_COORDINATES[index];
    const candidateDistance = distanceScore(coordinate, candidate);
    if (candidateDistance < nearestDistance) {
      nearestCity = candidate;
      nearestDistance = candidateDistance;
    }
  }
  return nearestDistance <= 4 ? nearestCity.name : '当前位置';
}

function getWeatherCondition(weatherCode) {
  if (weatherCode === 0) {
    return '晴';
  }
  if ([1, 2, 3].includes(weatherCode)) {
    return '多云';
  }
  if ([45, 48].includes(weatherCode)) {
    return '雾';
  }
  if ((weatherCode >= 51 && weatherCode <= 67) || (weatherCode >= 80 && weatherCode <= 82)) {
    return '雨';
  }
  if ((weatherCode >= 71 && weatherCode <= 77) || (weatherCode >= 85 && weatherCode <= 86)) {
    return '雪';
  }
  if (weatherCode >= 95) {
    return '雷雨';
  }
  return '多云';
}

function buildHumidityAdvice(humidity) {
  if (humidity >= 75) {
    return {
      advice: '湿度偏高，今日宜健脾祛湿，饮食清淡，室内注意通风。',
      riskLevel: '湿热提醒'
    };
  }
  if (humidity <= 35) {
    return {
      advice: '空气偏干，今日宜适量饮水，少食辛辣，注意皮肤与咽喉保湿。',
      riskLevel: '干燥提醒'
    };
  }
  return {
    advice: '湿度适中，今日宜规律作息，清淡饮食，保持舒缓活动。',
    riskLevel: '天气平稳'
  };
}

function buildOpenMeteoUrl(latitude, longitude) {
  const params = new URLSearchParams({
    latitude: `${latitude}`,
    longitude: `${longitude}`,
    current: 'temperature_2m,relative_humidity_2m,weather_code',
    timezone: 'auto'
  });
  return `${OPEN_METEO_FORECAST_URL}?${params.toString()}`;
}

function buildWeatherFromOpenMeteoPayload(payload, coordinate = null, cityParam = '') {
  const current = payload && typeof payload === 'object' ? payload.current : null;
  const temperature = current ? Number(current.temperature_2m) : NaN;
  const humidity = current ? Number(current.relative_humidity_2m) : NaN;
  const weatherCode = current ? Number(current.weather_code) : NaN;
  if (!Number.isFinite(temperature) || !Number.isFinite(humidity)) {
    throw new Error('Open-Meteo response is missing current temperature or humidity');
  }
  const humidityAdvice = buildHumidityAdvice(humidity);
  const cityName = (cityParam && cityParam.length > 0) ? cityParam : inferNearestCityName(coordinate);
  return {
    city: cityName,
    condition: getWeatherCondition(weatherCode),
    temperature: `${Math.round(temperature)}℃`,
    humidity: `${Math.round(humidity)}%`,
    advice: humidityAdvice.advice,
    riskLevel: humidityAdvice.riskLevel,
    sourceLabel: 'Open-Meteo',
    isFallback: false
  };
}

async function buildCurrentWeather(query = {}, options = {}) {
  const coordinate = parseCoordinatePair(query);
  const cityParam = typeof query.city === 'string' ? query.city.trim() : '';
  if (coordinate === null) {
    return buildDefaultWeather(null, cityParam);
  }
  const weatherFetch = options.weatherFetch || fetch;
  try {
    const response = await weatherFetch(buildOpenMeteoUrl(coordinate.latitude, coordinate.longitude));
    if (!response.ok) {
      throw new Error(`Open-Meteo request failed: ${response.status}`);
    }
    return buildWeatherFromOpenMeteoPayload(await response.json(), coordinate, cityParam);
  } catch (error) {
    return buildDefaultWeather(coordinate, cityParam);
  }
}

function parseRequestUrl(requestUrl) {
  return new URL(requestUrl, 'http://127.0.0.1');
}

function buildHealthStatus() {
  return {
    status: 'ok',
    service: 'yangshengzhushou_db',
    version: '0.1.0'
  };
}

function getLanIPv4Addresses() {
  const interfaces = os.networkInterfaces();
  const addresses = [];
  Object.keys(interfaces).forEach((name) => {
    const values = interfaces[name] || [];
    values.forEach((item) => {
      if (item.family === 'IPv4' && !item.internal) {
        addresses.push(item.address);
      }
    });
  });
  return addresses;
}

async function buildAssistantReply(body, options = {}) {
  if (options.enableLlm === false) {
    return runHealthAssistantGraph(body, options);
  }
  try {
    return await runHealthAssistantGraph(body, options);
  } catch (error) {
    return buildRuleBasedAssistantReply(body);
  }
}

function parseHumidityValue(weather = {}) {
  const humidityText = typeof weather.humidity === 'string' ? weather.humidity.replace('%', '') : '';
  const humidity = Number(humidityText);
  return Number.isFinite(humidity) ? humidity : NaN;
}

function buildWeatherAwareSuggestions(body = {}) {
  const weather = body.weather || {};
  const scenario = typeof body.scenario === 'string' ? body.scenario : 'home';
  const humidity = parseHumidityValue(weather);
  const constitution = body.profile && body.profile.constitution && body.profile.constitution.name
    ? body.profile.constitution.name
    : '平和质';
  const humid = Number.isFinite(humidity) && humidity >= 75;
  const dry = Number.isFinite(humidity) && humidity <= 35;
  const summary = humid
    ? `当前${weather.city || '位置'}湿度偏高，建议${constitution}以健脾祛湿、清淡饮食和温和活动为主。`
    : dry
    ? `当前空气偏干，建议${constitution}注意补水润燥，减少辛辣和熬夜。`
    : `当前温湿度较平稳，建议${constitution}保持规律作息、温和活动和清淡饮食。`;
  const suggestions = humid
    ? ['清淡饮食', '室内通风', '温和活动']
    : dry
    ? ['少量多次饮水', '润燥饮食', '减少辛辣']
    : ['规律作息', '清淡饮食', '温和运动'];
  return {
    source: '规则兜底',
    riskLevel: 'normal',
    scenario,
    summary,
    suggestions,
    plans: [
      {
        timeOfDay: 'morning',
        title: suggestions[0],
        action: `结合${weather.temperature || '--℃'}、湿度${weather.humidity || '--'}，早餐清淡并安排 5-10 分钟舒缓活动。`,
        reason: '晨间计划随天气负担调整，避免过度消耗。'
      },
      {
        timeOfDay: 'afternoon',
        title: suggestions[1],
        action: humid ? '午后保持室内通风，减少冰饮和油腻。' : '午后短时散步或闭目休息，保持节律稳定。',
        reason: '午后容易受湿度和疲劳影响，轻量调整更稳妥。'
      },
      {
        timeOfDay: 'evening',
        title: suggestions[2],
        action: '睡前减少屏幕刺激，可做缓慢呼吸或温水泡脚。',
        reason: '稳定睡前节律，有助于恢复体力。'
      }
    ],
    disclaimer: '本建议不能替代医生诊断，若症状持续或加重，请及时就医。'
  };
}

function normalizeSuggestionReply(reply, body = {}) {
  const fallback = buildWeatherAwareSuggestions(body);
  if (!reply || typeof reply !== 'object') {
    return fallback;
  }
  return {
    source: typeof reply.source === 'string' && reply.source.length > 0 ? reply.source : fallback.source,
    riskLevel: reply.riskLevel === 'urgent' ? 'urgent' : 'normal',
    scenario: typeof reply.scenario === 'string' && reply.scenario.length > 0 ? reply.scenario : fallback.scenario,
    summary: typeof reply.summary === 'string' && reply.summary.length > 0
      ? reply.summary
      : (typeof reply.reply === 'string' && reply.reply.length > 0 ? reply.reply : fallback.summary),
    suggestions: Array.isArray(reply.suggestions) && reply.suggestions.length > 0 ? reply.suggestions : fallback.suggestions,
    plans: Array.isArray(reply.plans) && reply.plans.length > 0 ? reply.plans : fallback.plans,
    disclaimer: typeof reply.disclaimer === 'string' && reply.disclaimer.length > 0 ? reply.disclaimer : fallback.disclaimer
  };
}

async function buildSuggestionReply(body, options = {}) {
  if (options.enableLlm === false && typeof options.requestSuggestionReply !== 'function') {
    return buildWeatherAwareSuggestions(body);
  }
  const requestSuggestionReply = options && typeof options.requestSuggestionReply === 'function'
    ? options.requestSuggestionReply
    : requestDeepSeekAssistantReply;
  try {
    const reply = await requestSuggestionReply({
      ...body,
      message: body && typeof body.question === 'string' && body.question.length > 0
        ? body.question
        : `${body && body.scenario ? body.scenario : 'home'} 场景养生建议`
    });
    return normalizeSuggestionReply(reply, body);
  } catch (error) {
    return buildWeatherAwareSuggestions(body);
  }
}

function createAppServer(options = {}) {
  const authService = options.authService || new AuthService(options.userStore || new FileUserStore());
  return http.createServer(async (request, response) => {
    if (request.method === 'OPTIONS') {
      sendJson(response, 204, {});
      return;
    }

    const parsedUrl = parseRequestUrl(request.url);

    if (request.method === 'GET' && parsedUrl.pathname === '/api/weather/current') {
      sendJson(response, 200, await buildCurrentWeather(Object.fromEntries(parsedUrl.searchParams.entries()), options));
      return;
    }

    if (request.method === 'GET' && parsedUrl.pathname === '/api/health') {
      sendJson(response, 200, buildHealthStatus());
      return;
    }

    if (request.method === 'POST' && parsedUrl.pathname === '/api/auth/register') {
      const body = await readJsonBody(request);
      const result = authService.register(body);
      sendJson(response, result.statusCode, result.payload);
      return;
    }

    if (request.method === 'POST' && parsedUrl.pathname === '/api/auth/login') {
      const body = await readJsonBody(request);
      const result = authService.login(body);
      sendJson(response, result.statusCode, result.payload);
      return;
    }

    if (request.method === 'POST' && parsedUrl.pathname === '/api/ai/suggestions') {
      const body = await readJsonBody(request);
      sendJson(response, 200, await buildSuggestionReply(body, options));
      return;
    }

    if (request.method === 'POST' && parsedUrl.pathname === '/api/ai/chat') {
      const body = await readJsonBody(request);
      sendJson(response, 200, await buildAssistantReply(body, options));
      return;
    }

    sendJson(response, 404, {
      error: 'Not found'
    });
  });
}

if (require.main === module) {
  createAppServer().listen(DEFAULT_PORT, '0.0.0.0', () => {
    const lanAddresses = getLanIPv4Addresses();
    console.log(`Mock backend listening on http://0.0.0.0:${DEFAULT_PORT}`);
    console.log(`Local access: http://127.0.0.1:${DEFAULT_PORT}/api/health`);
    lanAddresses.forEach((address) => {
      console.log(`APP access: http://${address}:${DEFAULT_PORT}/api/health`);
    });
  });
}

module.exports = {
  buildAssistantReply,
  buildCurrentWeather,
  buildSuggestionReply,
  buildWeatherAwareSuggestions,
  createAppServer
};
