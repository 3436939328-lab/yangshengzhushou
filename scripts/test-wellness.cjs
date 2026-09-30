const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const Module = require('node:module');
const crypto = require('node:crypto');
const ts = require(process.env.TYPESCRIPT_PATH || 'D:/DevEcoStudio/DevEcoStudio/tools/ohpm/node_modules/typescript');
require.extensions['.ets'] = (module, filename) => {
  const source = fs.readFileSync(filename, 'utf8');
  module._compile(ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 } }).outputText, filename);
};
const originalLoad = Module._load;
const capturedRequests = [];
const preferenceStores = new Map();
Module._load = function (name, parent, main) {
  if (name === '@kit.NetworkKit') return { http: { RequestMethod: { GET: 'GET', POST: 'POST' }, createHttp: () => ({
    request: (url, options) => { capturedRequests.push({ url, options }); return Promise.resolve({ responseCode: 200, result: '{"reply":"test response","source":"deepseek"}' }); }, destroy: () => {}
  }) } };
  if (name === '@kit.ArkTS') return { util: { generateRandomUUID: crypto.randomUUID } };
  if (name === '@kit.ArkData') return { preferences: { getPreferences: async (_context, options) => {
    if (!preferenceStores.has(options.name)) preferenceStores.set(options.name, new Map());
    const data = preferenceStores.get(options.name);
    return { getSync: (key, fallback) => data.get(key) ?? fallback, put: async (key, value) => data.set(key, value),
      putSync: (key, value) => data.set(key, value), delete: async key => data.delete(key), deleteSync: key => data.delete(key), flush: async () => {} };
  } } };
  if (name.startsWith('@kit.')) return {};
  return originalLoad.call(this, name, parent, main);
};
const root = path.resolve(__dirname, '../entry/src/main/ets');
const api = require(path.join(root, 'services/ApiConfig.ets'));
const solar = require(path.join(root, 'utils/SolarTermUtil.ets'));
const status = require(path.join(root, 'services/BackendStatusService.ets'));
const weather = require(path.join(root, 'services/WeatherService.ets'));
const suggestions = require(path.join(root, 'services/SuggestionService.ets'));
const assistant = require(path.join(root, 'services/AssistantReplyService.ets'));
const auth = require(path.join(root, 'services/AuthService.ets'));
const history = require(path.join(root, 'services/ChatHistoryRepository.ets'));
const { PendingOrderRepository } = require(path.join(root, 'services/PendingOrderRepository.ets'));
let failures = 0;
function test(name, run) {
  try { run(); console.log('PASS', name); }
  catch (error) { failures++; console.error('FAIL', name, error.message); }
}
test('business, auth and model endpoints stay on the same server', () => {
  api.setRuntimeBaseUrl('http://192.168.1.99:8181/');
  assert.equal(api.getApiConfig().aiBaseUrl, api.getApiConfig().baseUrl);
  assert.equal(api.getApiConfig().suggestionsBaseUrl, api.getApiConfig().baseUrl);
});
test('model timeout covers backend generation budget', () => {
  assert.ok(api.getApiConfig().aiTimeoutMs >= 60000);
});
test('formatted health JSON is accepted', () => {
  assert.equal(status.buildBackendStatusFromHealthPayload('{ "success": true, "data": "ok" }').available, true);
});
test('actual Spring Boot code envelope is accepted', () => {
  assert.equal(status.buildBackendStatusFromHealthPayload('{"code":200,"message":"success","data":"ok"}').available, true);
});
test('September 2026 is White Dew, not Minor Heat', () => {
  assert.equal(solar.getCurrentSolarTerm(new Date('2026-09-08T12:00:00+08:00')).name, '白露');
});
test('January starts in previous winter solstice', () => {
  assert.equal(solar.getCurrentSolarTerm(new Date('2027-01-01T12:00:00+08:00')).name, '冬至');
});
test('every solar term can be selected in a full year', () => {
  const names = new Set();
  for (let day = 0; day < 366; day++) names.add(solar.getCurrentSolarTerm(new Date(Date.UTC(2028, 0, 1 + day, 4))).name);
  assert.equal(names.size, 24);
});
test('solar term changes at the exact calculated instant', () => {
  const data = require(path.join(root, 'utils/SolarTermData.ets'));
  const instant = data.SOLAR_TERM_TIMES[2026 - data.SOLAR_TERM_START_YEAR][16] * 1000;
  assert.equal(solar.getCurrentSolarTerm(new Date(instant - 1)).name, '处暑');
  assert.equal(solar.getCurrentSolarTerm(new Date(instant)).name, '白露');
});
test('stale, invalid and excessively imprecise locations are rejected', () => {
  const coordinate = { latitude: 36.6512, longitude: 117.1201, accuracy: 30, timestamp: 1700000000000 };
  assert.equal(weather.isFreshCoordinate(coordinate, coordinate.timestamp), true);
  assert.equal(weather.isFreshCoordinate(coordinate, coordinate.timestamp + 300001), false);
  assert.equal(weather.isFreshCoordinate({ ...coordinate, latitude: NaN }, coordinate.timestamp), false);
  assert.equal(weather.isFreshCoordinate({ ...coordinate, accuracy: 6000 }, coordinate.timestamp), false);
});
test('missing location or malformed weather never invents real conditions', () => {
  assert.equal(weather.getCurrentWeatherWellness().condition, '天气未获取');
  assert.equal(weather.buildWeatherFromBackendPayload('{}').isFallback, true);
  assert.equal(weather.buildWeatherFromBackendPayload('{}').temperature, '--℃');
});
test('suggestions retain actual coordinates and district', () => {
  const location = suggestions.buildSuggestionLocation({ city: '济南市', district: '历下区', latitude: 36.65, longitude: 117.12, address: '济南市历下区' });
  assert.equal(location.district, '历下区'); assert.equal(location.latitude, 36.65);
});
test('empty chat has no saved welcome message', () => {
  assert.deepEqual(history.deserializeChatHistory(''), []);
  assert.deepEqual(history.deserializeChatHistory(JSON.stringify([{ role: 'assistant', content: '你好，我会把你的问题、当前位置天气和健康档案发送给后端大模型生成建议。' }])), []);
});
async function asyncChecks() {
  auth.setRuntimeAuthToken('account-A');
  const operation = assistant.requestAssistantReplyRemoteFirst('test', {}, [], undefined, 'owned-request');
  auth.setRuntimeAuthToken('account-B');
  await operation;
  const sent = capturedRequests[capturedRequests.length - 1];
  assert.equal(sent.options.header.Authorization, 'Bearer account-A');
  assert.equal(JSON.parse(sent.options.extraData).requestId, 'owned-request');
  console.log('PASS chat captures initiating authorization before asynchronous work');
  const repository = new PendingOrderRepository({}, 'account-A');
  const order = { order: { requestId: 'original-order', productId: 1, recipient: 'test', phone: '0000000', address: 'test address', addressConfirmed: true }, productName: 'test', points: 10 };
  await repository.save(order);
  assert.deepEqual(await new PendingOrderRepository({}, 'account-A').load(), order);
  assert.equal(await new PendingOrderRepository({}, 'account-B').load(), null);
  await repository.clear(); assert.equal(await repository.load(), null);
  console.log('PASS uncertain order survives component recreation and remains account-scoped');
  const chat = new history.ChatHistoryRepository(new history.MemoryChatHistoryStorageAdapter());
  await chat.savePending({ id: 'request-1', question: 'test' });
  assert.equal((await chat.loadPending()).id, 'request-1');
  await chat.clearPending(); assert.equal(await chat.loadPending(), null);
  console.log('PASS pending chat has a durable recovery lifecycle');
}
asyncChecks().catch(error => { failures++; console.error('FAIL asynchronous regression', error); }).finally(() => { process.exitCode = failures ? 1 : 0; });
