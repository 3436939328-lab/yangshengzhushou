const { normalizeLlmReply, requestDeepSeekAssistantReply } = require('../llmClient');
const { buildRuleBasedAssistantReply, hasUrgentRisk } = require('../ruleAssistant');

async function createGraph() {
  const { Annotation, END, START, StateGraph } = await import('@langchain/langgraph');

  const GraphState = Annotation.Root({
    input: Annotation(),
    options: Annotation(),
    memoryContext: Annotation(),
    riskLevel: Annotation(),
    draftReply: Annotation(),
    finalReply: Annotation(),
    plan: Annotation()
  });

  return new StateGraph(GraphState)
    .addNode('buildMemoryContext', async (state) => ({
      memoryContext: buildMemoryContext(state.input)
    }))
    .addNode('detectRisk', async (state) => {
      const message = state.input && typeof state.input.message === 'string' ? state.input.message : '';
      return {
        riskLevel: hasUrgentRisk(message) ? 'urgent' : 'normal'
      };
    })
    .addNode('buildSafetyReply', async (state) => ({
      draftReply: buildRuleBasedAssistantReply(state.input)
    }))
    .addNode('generateReply', async (state) => {
      if (state.options && state.options.enableLlm === false) {
        return {
          draftReply: buildRuleBasedAssistantReply(state.input)
        };
      }
      const requestLlmReply = state.options && typeof state.options.requestLlmReply === 'function'
        ? state.options.requestLlmReply
        : requestDeepSeekAssistantReply;
      const llmInput = {
        ...state.input,
        memoryContext: state.memoryContext
      };
      const llmReply = await requestLlmReply(llmInput);
      return {
        draftReply: llmReply || buildRuleBasedAssistantReply(state.input)
      };
    })
    .addNode('normalizeReply', async (state) => {
      const withGraphMetadata = (reply) => ({
        ...reply,
        workflow: 'langgraph'
      });
      if (state.draftReply && state.draftReply.source === 'DeepSeek') {
        return {
          finalReply: withGraphMetadata(normalizeLlmReply(state.draftReply, state.input))
        };
      }
      return {
        finalReply: withGraphMetadata(state.draftReply || buildRuleBasedAssistantReply(state.input))
      };
    })
    .addNode('buildPlan', async (state) => ({
      plan: buildWellnessPlan(state.finalReply, state.memoryContext)
    }))
    .addNode('attachPlan', async (state) => ({
      finalReply: {
        ...state.finalReply,
        plan: state.plan
      }
    }))
    .addEdge(START, 'buildMemoryContext')
    .addEdge('buildMemoryContext', 'detectRisk')
    .addConditionalEdges('detectRisk', (state) => (
      state.riskLevel === 'urgent' ? 'buildSafetyReply' : 'generateReply'
    ))
    .addEdge('buildSafetyReply', 'normalizeReply')
    .addEdge('generateReply', 'normalizeReply')
    .addEdge('normalizeReply', 'buildPlan')
    .addEdge('buildPlan', 'attachPlan')
    .addEdge('attachPlan', END)
    .compile();
}

async function runHealthAssistantGraph(input, options = {}) {
  const graph = await createGraph();
  const result = await graph.invoke({
    input,
    options,
    memoryContext: undefined,
    riskLevel: 'normal',
    draftReply: undefined,
    finalReply: undefined,
    plan: undefined
  });
  return result.finalReply;
}

function buildMemoryContext(input) {
  const profile = input && input.profile ? input.profile : {};
  const constitutionName = profile.constitution && typeof profile.constitution.name === 'string'
    ? profile.constitution.name
    : '平和质';
  const profileSummary = buildProfileMemorySummary(profile);
  const historySummary = buildHistoryMemorySummary(input && Array.isArray(input.history) ? input.history : []);

  return {
    constitutionName,
    profileSummary,
    historySummary
  };
}

function buildProfileMemorySummary(profile) {
  const lines = [`体质倾向：${profile.constitution && profile.constitution.name ? profile.constitution.name : '平和质'}`];
  if (Array.isArray(profile.tongueNotes) && profile.tongueNotes.length > 0) {
    const note = profile.tongueNotes[0];
    lines.push(`最近舌象：${note.color || '未记录'}、${note.coating || '未记录'}、${note.dryness || '未记录'}`);
  } else {
    lines.push('最近舌象：未记录');
  }
  if (Array.isArray(profile.healthIndicators) && profile.healthIndicators.length > 0) {
    const indicator = profile.healthIndicators[0];
    lines.push(`最近指标：${indicator.name || '指标'} ${indicator.value || ''}${indicator.unit || ''}`);
  } else {
    lines.push('最近指标：未记录');
  }
  if (Array.isArray(profile.reminderPreferences) && profile.reminderPreferences.length > 0) {
    const enabledCount = profile.reminderPreferences.filter((item) => item.enabled).length;
    lines.push(`提醒开启：${enabledCount}/${profile.reminderPreferences.length}`);
  } else {
    lines.push('提醒开启：未记录');
  }
  return lines.join('\n');
}

function buildHistoryMemorySummary(history) {
  const lines = history.slice(-6).map((item) => {
    const role = item.role === 'assistant' ? '助手' : '用户';
    const content = typeof item.content === 'string' ? item.content : '';
    return `${role}：${content}`;
  }).filter((line) => line.trim().length > 3);
  return lines.length > 0 ? lines.join('\n') : '最近对话：无';
}

function buildWellnessPlan(reply, memoryContext) {
  if (reply && reply.riskLevel === 'urgent') {
    return [
      {
        timeOfDay: 'urgent',
        title: '先处理风险信号',
        action: '停止自行调理，尽快就医或联系当地急救/家属协助。',
        reason: '当前描述包含需要专业评估的风险信号，安全优先。'
      }
    ];
  }

  const suggestions = reply && Array.isArray(reply.suggestions) ? reply.suggestions : [];
  const constitutionName = memoryContext && memoryContext.constitutionName ? memoryContext.constitutionName : '平和质';
  return [
    {
      timeOfDay: 'morning',
      title: suggestions[0] || '晨间轻启动',
      action: `结合${constitutionName}，起床后先喝温水，做 5-10 分钟温和拉伸。`,
      reason: '晨间用轻量活动唤醒身体，避免一开始就过度消耗。'
    },
    {
      timeOfDay: 'afternoon',
      title: suggestions[1] || '午后稳节律',
      action: '午后安排短时散步或闭目休息，避免久坐连续超过 60 分钟。',
      reason: '稳定白天节律，有助于改善疲劳、睡眠和消化状态。'
    },
    {
      timeOfDay: 'evening',
      title: suggestions[2] || '睡前慢收尾',
      action: '睡前减少屏幕刺激，可泡脚或做缓慢呼吸 5 分钟。',
      reason: '降低睡前兴奋度，让身体更容易进入休息状态。'
    }
  ];
}

module.exports = {
  createGraph,
  buildMemoryContext,
  buildWellnessPlan,
  runHealthAssistantGraph
};
