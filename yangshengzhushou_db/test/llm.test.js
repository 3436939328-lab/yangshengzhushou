const assert = require('assert');
const { buildLlmRequestHeaders, buildLlmPrompt, normalizeLlmReply, parseLlmJsonContent } = require('../src/llmClient');
const { getLlmConfig } = require('../src/llmConfig');
const { buildRuleBasedAssistantReply } = require('../src/ruleAssistant');

function run() {
  const config = getLlmConfig({});
  assert.strictEqual(config.enabled, false);
  assert.strictEqual(config.provider, 'deepseek');
  assert.strictEqual(config.model, 'deepseek-chat');

  const localConfig = getLlmConfig({
    LOCAL_LLM_BASE_URL: 'http://127.0.0.1:11434/v1/chat/completions',
    LOCAL_LLM_MODEL: 'qwen2.5:7b'
  });
  assert.strictEqual(localConfig.enabled, true);
  assert.strictEqual(localConfig.provider, 'local-openai-compatible');
  assert.strictEqual(localConfig.model, 'qwen2.5:7b');
  assert.strictEqual(localConfig.apiKey, '');
  assert.strictEqual(localConfig.baseUrl, 'http://127.0.0.1:11434/v1/chat/completions');
  assert.deepStrictEqual(buildLlmRequestHeaders(localConfig), {
    'Content-Type': 'application/json'
  });
  assert.deepStrictEqual(buildLlmRequestHeaders({ apiKey: '"sk-test"' }), {
    'Content-Type': 'application/json',
    Authorization: 'Bearer sk-test'
  });

  const reply = buildRuleBasedAssistantReply({
    message: '最近睡眠不好',
    profile: { constitution: { name: '平和质' } }
  });
  assert.strictEqual(reply.source, '规则兜底');
  assert.ok(reply.reply.includes('屏幕刺激'));
  assert.ok(reply.suggestions.includes('睡前放松'));

  const normalized = normalizeLlmReply({
    reply: '建议先休息观察。'
  }, {
    message: '最近睡眠不好',
    profile: { constitution: { name: '平和质' } }
  });
  assert.strictEqual(normalized.source, 'DeepSeek');
  assert.strictEqual(normalized.riskLevel, 'normal');
  assert.ok(normalized.suggestions.includes('睡前放松'));
  assert.ok(normalized.disclaimer.includes('不能替代医生诊断'));

  const urgent = normalizeLlmReply({
    reply: '可以先休息。'
  }, {
    message: '胸痛还有呼吸困难',
    profile: { constitution: { name: '平和质' } }
  });
  assert.strictEqual(urgent.riskLevel, 'urgent');
  assert.ok(urgent.suggestions.includes('及时就医'));

  const fenced = parseLlmJsonContent('```json\n{"reply":"睡前放松","suggestions":["睡前放松"]}\n```');
  assert.strictEqual(fenced.reply, '睡前放松');
  assert.strictEqual(fenced.suggestions[0], '睡前放松');

  const embedded = parseLlmJsonContent('以下是建议：{"reply":"清淡饮食","riskLevel":"normal","suggestions":["规律三餐"]}请参考。');
  assert.strictEqual(embedded.reply, '清淡饮食');
  assert.strictEqual(embedded.riskLevel, 'normal');

  const prompt = buildLlmPrompt({
    message: '那饮食呢',
    profile: {
      constitution: { name: '平和质' },
      tongueNotes: [
        { color: '淡红', coating: '薄白', dryness: '适中', note: '晨起观察', recordedAt: '2026-06-23T08:00:00.000Z' }
      ],
      healthIndicators: [
        { name: '血压', value: '128/82', unit: 'mmHg', recordedAt: '2026-06-23T09:00:00.000Z' }
      ],
      reminderPreferences: [
        { title: '饮水提醒', time: '10:00', enabled: true },
        { title: '久坐拉伸', time: '15:00', enabled: false }
      ]
    },
    history: [
      { role: 'user', content: '最近睡眠不好' },
      { role: 'assistant', content: '建议固定入睡时间' }
    ]
  });
  assert.ok(prompt.includes('最近对话'));
  assert.ok(prompt.includes('用户：最近睡眠不好'));
  assert.ok(prompt.includes('助手：建议固定入睡时间'));
  assert.ok(prompt.includes('最近舌象：淡红、薄白、适中'));
  assert.ok(prompt.includes('最近指标：血压 128/82mmHg'));
  assert.ok(prompt.includes('提醒开启：1/2'));

  const weatherPrompt = buildLlmPrompt({
    message: '今天怎么安排',
    profile: { constitution: { name: '气虚质' } },
    weather: {
      city: '当前位置',
      condition: '多云',
      temperature: '29℃',
      humidity: '78%',
      riskLevel: '湿热提醒',
      sourceLabel: 'Open-Meteo'
    }
  });
  assert.ok(weatherPrompt.includes('当前天气：当前位置，多云，29℃，湿度78%'));
  assert.ok(weatherPrompt.includes('天气风险：湿热提醒'));
  assert.ok(weatherPrompt.includes('请结合当前温度、湿度和天气风险调整饮食、运动、睡眠和提醒建议'));

  const memoryPrompt = buildLlmPrompt({
    message: '最近睡眠不好',
    memoryContext: {
      constitutionName: '气虚质',
      profileSummary: '体质倾向：气虚质\n最近舌象：淡红、薄白、适中',
      historySummary: '用户：最近总是晚睡\n助手：先固定入睡时间'
    }
  });
  assert.ok(memoryPrompt.includes('用户体质倾向：气虚质'));
  assert.ok(memoryPrompt.includes('最近舌象：淡红、薄白、适中'));
  assert.ok(memoryPrompt.includes('用户：最近总是晚睡'));
}

run();
console.log('llm tests passed');
