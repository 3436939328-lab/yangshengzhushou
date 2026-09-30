const fs = require('node:fs');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const base = process.env.WELLNESS_SMOKE_URL || 'http://127.0.0.1:8181';
let token = '';
const results = {};
async function request(path, body) {
  const response = await fetch(base + path, { method: body === undefined ? 'GET' : 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: 'Bearer ' + token } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body), signal: AbortSignal.timeout(95000) });
  const data = await response.json();
  if (!response.ok) throw new Error(`${path}: HTTP ${response.status}: ${data.message || data.error || 'request failed'}`);
  return data;
}
async function main() {
  assert.ok(process.env.WELLNESS_SMOKE_PHONE && process.env.WELLNESS_SMOKE_PASSWORD, 'Provide a demo account via environment');
  const login = await request('/api/auth/login', { phone: process.env.WELLNESS_SMOKE_PHONE, password: process.env.WELLNESS_SMOKE_PASSWORD });
  assert.equal(login.success, true, login.message);
  token = login.data.token;
  results.health = (await request('/api/health')).code === 200;
  const weather = await request('/api/weather/current?latitude=36.6512&longitude=117.1201&city=' + encodeURIComponent('济南市'));
  results.weather = { city: weather.city, source: weather.sourceLabel, isFallback: weather.isFallback };
  assert.equal(weather.city, '济南市');
  const first = (await request('/api/rewards/check-in', {})).data;
  const second = (await request('/api/rewards/check-in', {})).data;
  assert.equal(first.balance, second.balance);
  results.checkInIdempotent = true;
  const question = { requestId: randomUUID(), message: '请用一句话给出成年人日常作息建议，不需要医疗诊断。', profile: {}, weather, history: [] };
  const chat = await request('/api/ai/chat', question);
  assert.ok(chat.reply && chat.reply.trim().length > 0);
  const balance = (await request('/api/rewards/account')).data;
  assert.equal(balance.balance, first.balance - 1);
  const repeated = await request('/api/ai/chat', question);
  assert.equal(repeated.reply, chat.reply);
  const recovered = (await request('/api/ai/chat/' + question.requestId)).data;
  assert.equal(recovered.status, 'SUCCEEDED');
  assert.equal(recovered.reply.reply, chat.reply);
  assert.equal((await request('/api/rewards/account')).data.balance, balance.balance);
  results.chat = { source: chat.source, characters: chat.reply.length, chargedOnce: true, recovery: true };
  const suggestions = await request('/api/ai/suggestions', { scenario: 'home', profile: {}, weather,
    location: { city: '济南市', district: '', address: '济南市', latitude: 36.6512, longitude: 117.1201 } });
  assert.ok(suggestions.summary && suggestions.suggestions.length > 0);
  results.suggestions = { source: suggestions.source, count: suggestions.suggestions.length, plans: suggestions.plans.length };
  results.model = await request('/api/ai/status');
  assert.equal(results.model.status, 'available');
  assert.equal((await request('/api/rewards/account')).data.balance, balance.balance);
  results.suggestionsFree = true;
  results.passed = true;
}
main().catch(error => { results.passed = false; results.error = error.message; process.exitCode = 1; }).finally(() => {
  fs.writeFileSync('.work/run/live-report.json', JSON.stringify(results, null, 2));
  console.log(JSON.stringify(results, null, 2));
});
