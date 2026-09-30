const assert = require('assert');
const { runHealthAssistantGraph } = require('../src/agent/healthAssistantGraph');

async function run() {
  const normal = await runHealthAssistantGraph({
    message: '最近睡眠不好',
    profile: { constitution: { name: '平和质' } }
  }, { enableLlm: false });

  assert.strictEqual(normal.source, '规则兜底');
  assert.strictEqual(normal.riskLevel, 'normal');
  assert.ok(normal.suggestions.includes('睡前放松'));

  const urgent = await runHealthAssistantGraph({
    message: '胸痛还有呼吸困难',
    profile: { constitution: { name: '平和质' } }
  }, { enableLlm: false });

  assert.strictEqual(urgent.riskLevel, 'urgent');
  assert.ok(urgent.suggestions.includes('及时就医'));
  let normalLlmCallCount = 0;
  const normalWithInjectedLlm = await runHealthAssistantGraph({
    message: 'diet advice',
    profile: { constitution: { name: 'normal' } }
  }, {
    requestLlmReply: async () => {
      normalLlmCallCount += 1;
      return {
        reply: 'llm reply',
        source: 'DeepSeek',
        riskLevel: 'normal',
        suggestions: ['llm suggestion'],
        disclaimer: 'llm disclaimer'
      };
    }
  });

  assert.strictEqual(normalLlmCallCount, 1);
  assert.strictEqual(normalWithInjectedLlm.source, 'DeepSeek');

  let urgentLlmCallCount = 0;
  const urgentWithInjectedLlm = await runHealthAssistantGraph({
    message: '胸痛还有呼吸困难',
    profile: { constitution: { name: 'normal' } }
  }, {
    requestLlmReply: async () => {
      urgentLlmCallCount += 1;
      return {
        reply: 'should not be used',
        source: 'DeepSeek',
        riskLevel: 'normal',
        suggestions: ['unsafe'],
        disclaimer: 'unsafe'
      };
    }
  });

  assert.strictEqual(urgentLlmCallCount, 0);
  assert.strictEqual(urgentWithInjectedLlm.source, '规则兜底');
  assert.strictEqual(urgentWithInjectedLlm.riskLevel, 'urgent');

  let capturedInput;
  await runHealthAssistantGraph({
    message: '最近睡眠不好',
    profile: {
      constitution: { name: '气虚质' },
      tongueNotes: [
        { color: '淡红', coating: '薄白', dryness: '适中' }
      ],
      healthIndicators: [
        { name: '血压', value: '128/82', unit: 'mmHg' }
      ],
      reminderPreferences: [
        { title: '饮水提醒', enabled: true },
        { title: '拉伸提醒', enabled: false }
      ]
    },
    weather: {
      city: '当前位置',
      condition: '多云',
      temperature: '29℃',
      humidity: '78%',
      riskLevel: '湿热提醒',
      sourceLabel: 'Open-Meteo'
    },
    history: [
      { role: 'user', content: '最近总是晚睡' },
      { role: 'assistant', content: '先固定入睡时间' }
    ]
  }, {
    requestLlmReply: async (input) => {
      capturedInput = input;
      return {
        reply: 'memory reply',
        source: 'DeepSeek',
        riskLevel: 'normal',
        suggestions: ['睡前放松'],
        disclaimer: '本建议不能替代医生诊断'
      };
    }
  });

  assert.strictEqual(capturedInput.memoryContext.constitutionName, '气虚质');
  assert.strictEqual(capturedInput.weather.temperature, '29℃');
  assert.strictEqual(capturedInput.weather.humidity, '78%');
  assert.ok(capturedInput.memoryContext.profileSummary.includes('淡红'));
  assert.ok(capturedInput.memoryContext.profileSummary.includes('血压 128/82mmHg'));
  assert.ok(capturedInput.memoryContext.historySummary.includes('用户：最近总是晚睡'));

  assert.ok(Array.isArray(normal.plan));
  assert.strictEqual(normal.plan.length, 3);
  assert.strictEqual(normal.plan[0].timeOfDay, 'morning');
  assert.ok(normal.plan[0].title.length > 0);
  assert.ok(normal.plan[0].action.length > 0);
  assert.ok(normal.plan[0].reason.length > 0);
  assert.strictEqual(urgent.plan.length, 1);
  assert.strictEqual(urgent.plan[0].timeOfDay, 'urgent');
}

run().then(() => {
  console.log('graph tests passed');
}).catch((error) => {
  console.error(error);
  process.exit(1);
});
