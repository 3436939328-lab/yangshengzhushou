const assert = require('assert');
const { createAppServer } = require('../src/server');
const { MemoryUserStore } = require('../src/authService');

async function requestJson(server, method, path, body) {
  const address = server.address();
  const response = await fetch(`http://127.0.0.1:${address.port}${path}`, {
    method,
    headers: { 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body)
  });
  const data = await response.json();
  return { status: response.status, data };
}

async function run() {
  const weatherRequests = [];
  const weatherFetch = async (url) => {
    weatherRequests.push(url);
    return {
      ok: true,
      json: async () => ({
        current: {
          temperature_2m: 22.4,
          relative_humidity_2m: 56,
          weather_code: 3
        }
      })
    };
  };
  const server = createAppServer({ enableLlm: false, weatherFetch, userStore: new MemoryUserStore() });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));

  try {
    const health = await requestJson(server, 'GET', '/api/health');
    assert.strictEqual(health.status, 200);
    assert.strictEqual(health.data.status, 'ok');
    assert.strictEqual(health.data.service, 'yangshengzhushou_db');

    const register = await requestJson(server, 'POST', '/api/auth/register', {
      phone: '13800138000',
      password: 'abc12345'
    });
    assert.strictEqual(register.status, 200);
    assert.strictEqual(register.data.user.phone, '13800138000');
    assert.ok(register.data.token.length > 20);

    const duplicateRegister = await requestJson(server, 'POST', '/api/auth/register', {
      phone: '13800138000',
      password: 'abc12345'
    });
    assert.strictEqual(duplicateRegister.status, 409);
    assert.strictEqual(duplicateRegister.data.error, 'PHONE_ALREADY_REGISTERED');

    const login = await requestJson(server, 'POST', '/api/auth/login', {
      phone: '13800138000',
      password: 'abc12345'
    });
    assert.strictEqual(login.status, 200);
    assert.strictEqual(login.data.user.phone, '13800138000');
    assert.ok(login.data.token.length > 20);

    const wrongPassword = await requestJson(server, 'POST', '/api/auth/login', {
      phone: '13800138000',
      password: 'wrong-password'
    });
    assert.strictEqual(wrongPassword.status, 401);
    assert.strictEqual(wrongPassword.data.error, 'INVALID_CREDENTIALS');

    const weather = await requestJson(server, 'GET', '/api/weather/current');
    assert.strictEqual(weather.status, 200);
    assert.strictEqual(weather.data.city, '杭州');
    assert.strictEqual(weather.data.sourceLabel, '后端兜底');
    assert.strictEqual(weather.data.isFallback, true);

    const locatedWeather = await requestJson(server, 'GET', '/api/weather/current?latitude=31.2304&longitude=121.4737');
    assert.strictEqual(locatedWeather.status, 200);
    assert.strictEqual(locatedWeather.data.city, '上海');
    assert.strictEqual(locatedWeather.data.sourceLabel, 'Open-Meteo');
    assert.strictEqual(locatedWeather.data.isFallback, false);
    assert.strictEqual(locatedWeather.data.temperature, '22℃');
    assert.strictEqual(locatedWeather.data.humidity, '56%');
    assert.strictEqual(locatedWeather.data.condition, '多云');
    assert.ok(locatedWeather.data.advice.includes('湿度适中'));
    assert.strictEqual(weatherRequests.length, 1);
    assert.ok(weatherRequests[0].includes('latitude=31.2304'));
    assert.ok(weatherRequests[0].includes('longitude=121.4737'));

    const fallbackWeatherServer = createAppServer({
      enableLlm: false,
      weatherFetch: async () => ({ ok: false, status: 503 }),
      userStore: new MemoryUserStore()
    });
    await new Promise((resolve) => fallbackWeatherServer.listen(0, '127.0.0.1', resolve));
    try {
      const fallbackWeather = await requestJson(fallbackWeatherServer, 'GET', '/api/weather/current?latitude=31.2304&longitude=121.4737');
      assert.strictEqual(fallbackWeather.status, 200);
      assert.strictEqual(fallbackWeather.data.city, '上海');
      assert.strictEqual(fallbackWeather.data.sourceLabel, '后端兜底');
      assert.strictEqual(fallbackWeather.data.isFallback, true);
    } finally {
      await new Promise((resolve) => fallbackWeatherServer.close(resolve));
    }

    const suggestions = await requestJson(server, 'POST', '/api/ai/suggestions', {
      scenario: 'home',
      weather: {
        city: '当前位置',
        condition: '多云',
        temperature: '29℃',
        humidity: '78%',
        riskLevel: '湿热提醒',
        sourceLabel: 'Open-Meteo'
      },
      profile: { constitution: { name: '气虚质' } }
    });
    assert.strictEqual(suggestions.status, 200);
    assert.strictEqual(suggestions.data.source, '规则兜底');
    assert.strictEqual(suggestions.data.riskLevel, 'normal');
    assert.ok(suggestions.data.summary.includes('湿度偏高'));
    assert.ok(suggestions.data.suggestions.includes('室内通风'));
    assert.ok(Array.isArray(suggestions.data.plans));
    assert.ok(suggestions.data.plans[0].action.includes('湿度'));

    let suggestionLlmCallCount = 0;
    const aiSuggestionServer = createAppServer({
      enableLlm: false,
      requestSuggestionReply: async (body) => {
        suggestionLlmCallCount += 1;
        assert.strictEqual(body.weather.humidity, '78%');
        return {
          source: 'DeepSeek',
          riskLevel: 'normal',
          scenario: body.scenario,
          summary: 'AI 已结合湿度78%生成首页建议。',
          suggestions: ['AI祛湿饮食'],
          plans: [
            {
              timeOfDay: 'morning',
              title: 'AI祛湿饮食',
              action: '早餐清淡，减少油腻。',
              reason: '湿度偏高。'
            }
          ],
          disclaimer: '本建议不能替代医生诊断'
        };
      }
    });
    await new Promise((resolve) => aiSuggestionServer.listen(0, '127.0.0.1', resolve));
    try {
      const aiSuggestions = await requestJson(aiSuggestionServer, 'POST', '/api/ai/suggestions', {
        scenario: 'home',
        weather: {
          city: '当前位置',
          condition: '多云',
          temperature: '29℃',
          humidity: '78%',
          riskLevel: '湿热提醒',
          sourceLabel: 'Open-Meteo'
        }
      });
      assert.strictEqual(aiSuggestions.status, 200);
      assert.strictEqual(aiSuggestions.data.source, 'DeepSeek');
      assert.strictEqual(aiSuggestions.data.summary, 'AI 已结合湿度78%生成首页建议。');
      assert.strictEqual(suggestionLlmCallCount, 1);
    } finally {
      await new Promise((resolve) => aiSuggestionServer.close(resolve));
    }

    const chat = await requestJson(server, 'POST', '/api/ai/chat', {
      message: '最近有点困',
      profile: { constitution: { name: '气虚质' } }
    });
    assert.strictEqual(chat.status, 200);
    assert.strictEqual(chat.data.workflow, 'langgraph');
    assert.strictEqual(chat.data.source, '规则兜底');
    assert.strictEqual(chat.data.riskLevel, 'normal');
    assert.ok(Array.isArray(chat.data.suggestions));
    assert.ok(chat.data.suggestions.includes('循序运动'));
    assert.ok(chat.data.suggestions.includes('午间小憩'));
    assert.ok(chat.data.disclaimer.includes('不能替代医生诊断'));
    assert.ok(chat.data.reply.includes('最近有点困'));
    assert.ok(chat.data.reply.includes('不能替代医生诊断'));

    const sleepChat = await requestJson(server, 'POST', '/api/ai/chat', {
      message: '最近睡眠不好',
      profile: { constitution: { name: '平和质' } }
    });
    assert.ok(sleepChat.data.suggestions.includes('睡前放松'));
    assert.ok(sleepChat.data.suggestions.includes('减少咖啡因'));
    assert.ok(sleepChat.data.reply.includes('屏幕刺激'));
    assert.ok(sleepChat.data.reply.includes('固定入睡时间'));

    const dietChat = await requestJson(server, 'POST', '/api/ai/chat', {
      message: '饮食怎么调整',
      profile: { constitution: { name: '平和质' } }
    });
    assert.ok(dietChat.data.suggestions.includes('规律三餐'));
    assert.ok(dietChat.data.suggestions.includes('少冰冷'));
    assert.ok(dietChat.data.reply.includes('规律三餐'));
    assert.ok(dietChat.data.reply.includes('少冰冷'));

    const urgentChat = await requestJson(server, 'POST', '/api/ai/chat', {
      message: '胸痛还有呼吸困难',
      profile: { constitution: { name: '平和质' } }
    });
    assert.strictEqual(urgentChat.data.riskLevel, 'urgent');
    assert.ok(urgentChat.data.suggestions.includes('及时就医'));
    assert.ok(urgentChat.data.reply.includes('尽快就医'));
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

run().then(() => {
  console.log('server tests passed');
}).catch((error) => {
  console.error(error);
  process.exit(1);
});
