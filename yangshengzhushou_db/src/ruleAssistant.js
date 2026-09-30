function includesAny(text, keywords) {
  return keywords.some((keyword) => text.includes(keyword));
}

function hasUrgentRisk(message) {
  return includesAny(message, ['胸痛', '呼吸困难', '晕倒', '昏厥', '剧烈头痛', '血压很高', '半身麻木', '说话不清']);
}

function buildSuggestions(message) {
  if (hasUrgentRisk(message)) {
    return ['及时就医', '停止自行调理', '联系家属', '记录症状'];
  }
  if (includesAny(message, ['睡眠', '失眠', '睡不着', '入睡', '熬夜'])) {
    return ['睡前放松', '减少咖啡因', '固定入睡时间', '睡前泡脚'];
  }
  if (includesAny(message, ['饮食', '吃', '胃口', '清淡', '脾胃', '消化'])) {
    return ['规律三餐', '少冰冷', '清淡饮食', '细嚼慢咽'];
  }
  if (includesAny(message, ['乏累', '疲劳', '困', '没精神', '气虚'])) {
    return ['循序运动', '午间小憩', '补充蛋白', '持续记录'];
  }
  if (includesAny(message, ['运动', '锻炼', '久坐', '步数'])) {
    return ['温和运动', '久坐拉伸', '饭后散步', '量力而行'];
  }
  return ['规律作息', '清淡饮食', '温和运动', '持续记录'];
}

function buildReplyText(message, constitution, suggestions, disclaimer) {
  if (hasUrgentRisk(message)) {
    return `你提到“${message}”，其中可能包含需要尽快就医评估的风险信号。请先停止自行调理，尽快就医或联系当地急救/家属协助，并记录症状出现时间、持续多久、是否伴随出汗、胸闷、麻木或意识异常。${disclaimer}`;
  }
  if (includesAny(message, ['睡眠', '失眠', '睡不着', '入睡', '熬夜'])) {
    return `针对“${message}”，当前体质倾向为${constitution}。睡眠调理可先减少睡前屏幕刺激，固定入睡时间，睡前用温水泡脚或做缓慢呼吸放松，并持续记录入睡和醒来时间。${disclaimer}`;
  }
  if (includesAny(message, ['饮食', '吃', '胃口', '清淡', '脾胃', '消化'])) {
    return `针对“${message}”，当前体质倾向为${constitution}。饮食调理可先保持规律三餐，减少冰冷、辛辣和油腻，选择温和清淡的食物，并观察胃口和消化变化。${disclaimer}`;
  }
  if (includesAny(message, ['乏累', '疲劳', '困', '没精神', '气虚'])) {
    return `针对“${message}”，当前体质倾向为${constitution}。乏累时可先从循序运动入手，安排短时午间小憩，三餐保证基础蛋白和主食，并记录精神状态变化。${disclaimer}`;
  }
  if (includesAny(message, ['运动', '锻炼', '久坐', '步数'])) {
    return `针对“${message}”，当前体质倾向为${constitution}。运动安排宜温和渐进，可从饭后散步、久坐拉伸开始，避免突然增加强度，并按体感调整。${disclaimer}`;
  }
  return `针对“${message}”，当前体质倾向为${constitution}。建议先从${suggestions[0]}入手，并配合${suggestions[1]}、${suggestions[2]}，持续记录变化。${disclaimer}`;
}

function buildRuleBasedAssistantReply(body) {
  const message = typeof body.message === 'string' && body.message.trim().length > 0
    ? body.message.trim()
    : '日常调理';
  const profile = body.profile || {};
  const constitution = profile.constitution && typeof profile.constitution.name === 'string'
    ? profile.constitution.name
    : '平和质';
  const suggestions = buildSuggestions(message);
  const disclaimer = '本建议不能替代医生诊断，若症状持续或加重，请及时就医。';
  const riskLevel = hasUrgentRisk(message) ? 'urgent' : 'normal';

  return {
    reply: buildReplyText(message, constitution, suggestions, disclaimer),
    source: '规则兜底',
    riskLevel,
    suggestions,
    disclaimer
  };
}

module.exports = {
  buildRuleBasedAssistantReply,
  buildSuggestions,
  hasUrgentRisk
};
