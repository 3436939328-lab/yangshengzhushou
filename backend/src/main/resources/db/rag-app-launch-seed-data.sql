-- APP launch seed knowledge for the private RAG database.
-- This is the first production-oriented seed batch, not the final knowledge scale.
-- Re-run safe: documents/chunks/quality/embedding tasks are idempotent.

INSERT INTO medical_knowledge_category (code, name, parent_code, description, sort_order) VALUES
('TCM_DIGESTION', '中医脾胃调理', 'TCM', '食欲、腹胀、便溏、胃部不适等脾胃养生知识', 13),
('TCM_EMOTION', '中医情志调养', 'TCM', '焦虑、郁闷、压力、睡眠相关情志养生知识', 14),
('WESTERN_DIABETES', '糖尿病管理', 'WESTERN_CHRONIC', '血糖监测、低血糖预警、生活方式和就医边界', 23),
('WESTERN_CARDIO', '心脑血管风险', 'WESTERN', '胸痛、卒中、高血压、心血管危险信号识别', 24),
('WESTERN_RESPIRATORY', '呼吸与发热', 'WESTERN_SYMPTOM', '发热、咳嗽、呼吸困难等常见症状识别', 25),
('WESTERN_DIGESTION', '消化系统症状', 'WESTERN_SYMPTOM', '腹痛、腹泻、呕吐、便血等风险识别', 26),
('MENTAL_HEALTH', '心理健康风险', 'WESTERN', '焦虑、抑郁、睡眠和心理危机识别', 27),
('CONSULTATION_TEMPLATE', '问诊追问模板', 'APP_AGENT', '症状追问、科室建议和医生审核模板', 61)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  parent_code = VALUES(parent_code),
  description = VALUES(description),
  sort_order = VALUES(sort_order),
  enabled = 1;

INSERT INTO medical_knowledge_document
(category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
SELECT id, '中医九种体质养生知识', 'TCM', 'PLATFORM', '平台中医养生内部知识', NULL, 'system',
       '九种体质的健康管理建议，用于APP个性化养生提示，不作为疾病诊断。',
       '中医,体质,养生,九种体质'
FROM medical_knowledge_category WHERE code = 'TCM_CONSTITUTION'
ON DUPLICATE KEY UPDATE summary = VALUES(summary), tags = VALUES(tags), status = 'ACTIVE';

INSERT INTO medical_knowledge_document
(category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
SELECT id, '中医睡眠与疲劳调理知识', 'TCM', 'PLATFORM', '平台中医养生内部知识', NULL, 'system',
       '失眠、多梦、疲劳、心烦等场景的中医养生建议和安全边界。',
       '中医,睡眠,失眠,疲劳'
FROM medical_knowledge_category WHERE code = 'TCM_SLEEP'
ON DUPLICATE KEY UPDATE summary = VALUES(summary), tags = VALUES(tags), status = 'ACTIVE';

INSERT INTO medical_knowledge_document
(category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
SELECT id, '中医脾胃与饮食调养知识', 'TCM', 'PLATFORM', '平台中医养生内部知识', NULL, 'system',
       '腹胀、食欲差、便溏、胃部不适相关的饮食和起居调养。',
       '中医,脾胃,饮食,腹胀'
FROM medical_knowledge_category WHERE code = 'TCM_DIGESTION'
ON DUPLICATE KEY UPDATE summary = VALUES(summary), tags = VALUES(tags), status = 'ACTIVE';

INSERT INTO medical_knowledge_document
(category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
SELECT id, '中医情志与压力调养知识', 'TCM', 'PLATFORM', '平台中医养生内部知识', NULL, 'system',
       '压力、焦虑、情绪低落、胸闷叹气等情志调养建议和转诊边界。',
       '中医,情志,压力,焦虑'
FROM medical_knowledge_category WHERE code = 'TCM_EMOTION'
ON DUPLICATE KEY UPDATE summary = VALUES(summary), tags = VALUES(tags), status = 'ACTIVE';

INSERT INTO medical_knowledge_document
(category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
SELECT id, '高血压健康管理知识', 'WESTERN', 'PUBLIC_AUTHORITY', 'CDC/AHA公开健康资料', 'https://www.heart.org/', 'system',
       '血压监测、生活方式、危险信号和医生评估边界。',
       '高血压,血压,心血管,慢病'
FROM medical_knowledge_category WHERE code = 'WESTERN_CHRONIC'
ON DUPLICATE KEY UPDATE summary = VALUES(summary), tags = VALUES(tags), status = 'ACTIVE';

INSERT INTO medical_knowledge_document
(category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
SELECT id, '糖尿病与低血糖风险知识', 'WESTERN', 'PUBLIC_AUTHORITY', 'CDC/NIDDK公开健康资料', 'https://www.cdc.gov/diabetes/', 'system',
       '血糖监测、低血糖风险、饮食运动和就医边界。',
       '糖尿病,低血糖,血糖,慢病'
FROM medical_knowledge_category WHERE code = 'WESTERN_DIABETES'
ON DUPLICATE KEY UPDATE summary = VALUES(summary), tags = VALUES(tags), status = 'ACTIVE';

INSERT INTO medical_knowledge_document
(category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
SELECT id, '心脑血管急症预警知识', 'WESTERN', 'PUBLIC_AUTHORITY', 'CDC/AHA公开健康资料', 'https://www.cdc.gov/stroke/signs-symptoms/index.html', 'system',
       '胸痛、卒中、呼吸困难、意识异常等急症信号识别。',
       '胸痛,卒中,中风,急症,心脑血管'
FROM medical_knowledge_category WHERE code = 'WESTERN_CARDIO'
ON DUPLICATE KEY UPDATE summary = VALUES(summary), tags = VALUES(tags), status = 'ACTIVE';

INSERT INTO medical_knowledge_document
(category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
SELECT id, '发热咳嗽与呼吸症状识别知识', 'WESTERN', 'PUBLIC_AUTHORITY', 'CDC公开健康资料', 'https://www.cdc.gov/', 'system',
       '发热、咳嗽、呼吸困难等症状的风险分层和就医建议。',
       '发热,咳嗽,呼吸困难,感染'
FROM medical_knowledge_category WHERE code = 'WESTERN_RESPIRATORY'
ON DUPLICATE KEY UPDATE summary = VALUES(summary), tags = VALUES(tags), status = 'ACTIVE';

INSERT INTO medical_knowledge_document
(category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
SELECT id, '消化系统常见症状识别知识', 'WESTERN', 'PLATFORM', '平台医生审核知识', NULL, 'system',
       '腹痛、腹泻、呕吐、便血等消化系统症状的风险识别。',
       '腹痛,腹泻,呕吐,便血,消化'
FROM medical_knowledge_category WHERE code = 'WESTERN_DIGESTION'
ON DUPLICATE KEY UPDATE summary = VALUES(summary), tags = VALUES(tags), status = 'ACTIVE';

INSERT INTO medical_knowledge_document
(category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
SELECT id, '心理健康与危机预警知识', 'WESTERN', 'PLATFORM', '平台医生审核知识', NULL, 'system',
       '焦虑、抑郁、睡眠问题和自伤风险识别。',
       '心理健康,焦虑,抑郁,自伤,危机'
FROM medical_knowledge_category WHERE code = 'MENTAL_HEALTH'
ON DUPLICATE KEY UPDATE summary = VALUES(summary), tags = VALUES(tags), status = 'ACTIVE';

INSERT INTO medical_knowledge_document
(category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
SELECT id, '中西医结合失眠问诊知识', 'INTEGRATED', 'INTERNAL_RULE', '系统预问诊规则', NULL, 'system',
       '失眠场景下的西医风险识别、中医调养方向和医生追问模板。',
       '中西医结合,失眠,问诊,睡眠'
FROM medical_knowledge_category WHERE code = 'INTEGRATED'
ON DUPLICATE KEY UPDATE summary = VALUES(summary), tags = VALUES(tags), status = 'ACTIVE';

INSERT INTO medical_knowledge_document
(category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
SELECT id, '中西医结合疲劳问诊知识', 'INTEGRATED', 'INTERNAL_RULE', '系统预问诊规则', NULL, 'system',
       '疲劳场景下的危险信号、生活方式、体质调理和医生追问模板。',
       '中西医结合,疲劳,问诊,气虚'
FROM medical_knowledge_category WHERE code = 'INTEGRATED'
ON DUPLICATE KEY UPDATE summary = VALUES(summary), tags = VALUES(tags), status = 'ACTIVE';

INSERT INTO medical_knowledge_document
(category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
SELECT id, 'APP预问诊追问模板知识', 'GENERAL', 'INTERNAL_RULE', '系统预问诊规则', NULL, 'system',
       '用户提交症状后，Agent和医生需要补充追问的信息模板。',
       'APP,Agent,问诊,追问模板,医生审核'
FROM medical_knowledge_category WHERE code = 'CONSULTATION_TEMPLATE'
ON DUPLICATE KEY UPDATE summary = VALUES(summary), tags = VALUES(tags), status = 'ACTIVE';

-- TCM constitution chunks
INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 1, '平和质养生建议',
       '平和质通常表现为精力较稳定、睡眠和食欲较好、情绪相对平稳。APP可以建议保持规律作息、均衡饮食、适度运动和定期健康监测。此类建议只用于健康管理，不作为疾病诊断。',
       '平和质,体质,规律作息,均衡饮食,运动', 'tcm_constitution,wellness', 'LOW', 1
FROM medical_knowledge_document WHERE title = '中医九种体质养生知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 2, '气虚质养生建议',
       '气虚质用户常描述容易疲劳、气短、出汗、运动耐受差。建议避免过度劳累，选择散步、八段锦等温和活动，保证睡眠和规律进餐。如果疲劳突然加重，或伴随胸痛、呼吸困难、黑便、明显消瘦，应优先就医。',
       '气虚质,疲劳,气短,出汗,八段锦,就医', 'tcm_constitution,fatigue,warning', 'MEDIUM', 2
FROM medical_knowledge_document WHERE title = '中医九种体质养生知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 3, '阳虚质养生建议',
       '阳虚质用户可能描述怕冷、手脚凉、精神不足。健康管理上可提示注意保暖、避免长期熬夜和过度贪凉，运动宜循序渐进。若出现持续腹泻、明显水肿、胸闷气短等情况，应交由医生评估。',
       '阳虚质,怕冷,手脚凉,保暖,水肿,医生评估', 'tcm_constitution,cold_intolerance', 'MEDIUM', 3
FROM medical_knowledge_document WHERE title = '中医九种体质养生知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 4, '阴虚质养生建议',
       '阴虚质用户可能描述口干、心烦、睡眠浅、夜间出汗。APP可建议规律睡眠、减少辛辣刺激和夜间过度用脑，避免把调养建议当作治疗方案。若伴随长期低热、体重下降或严重失眠，应建议就医。',
       '阴虚质,口干,心烦,盗汗,失眠,低热', 'tcm_constitution,sleep', 'MEDIUM', 4
FROM medical_knowledge_document WHERE title = '中医九种体质养生知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

-- Sleep and fatigue chunks
INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 1, '失眠基础追问',
       '用户描述失眠时，应追问入睡困难还是早醒、持续多久、每晚睡眠时长、是否打鼾憋醒、是否饮用咖啡酒精、是否使用药物、是否伴随焦虑抑郁或疼痛。信息不足时不应直接给出确定原因。',
       '失眠,早醒,打鼾,咖啡,酒精,药物,焦虑,疼痛', 'sleep,follow_up', 'LOW', 1
FROM medical_knowledge_document WHERE title = '中医睡眠与疲劳调理知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 2, '失眠生活方式建议',
       '一般睡眠管理可建议固定起床时间、白天适度活动、睡前减少电子屏幕和刺激性饮品、保持卧室安静舒适。若失眠持续影响工作生活，或伴随明显焦虑抑郁、自伤想法，应转人工或医生处理。',
       '失眠,生活方式,电子屏幕,咖啡,焦虑,抑郁,自伤', 'sleep,wellness,mental_health', 'MEDIUM', 2
FROM medical_knowledge_document WHERE title = '中医睡眠与疲劳调理知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 3, '疲劳基础追问',
       '用户描述疲劳时，应追问持续时间、是否休息后缓解、睡眠质量、体重变化、发热、胸闷气短、食欲、情绪、月经或出血情况、既往慢病和近期用药。疲劳只是症状，不能直接等同于气虚或亚健康。',
       '疲劳,睡眠质量,体重下降,发热,胸闷,食欲,用药', 'fatigue,follow_up', 'LOW', 3
FROM medical_knowledge_document WHERE title = '中医睡眠与疲劳调理知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 4, '疲劳危险信号',
       '疲劳若伴随胸痛、呼吸困难、晕厥、黑便、持续发热、明显消瘦、意识改变或单侧肢体无力，应按高风险情况处理，建议尽快就医或急诊评估，不能只给养生建议。',
       '疲劳,胸痛,呼吸困难,晕厥,黑便,发热,消瘦,单侧无力', 'fatigue,emergency,warning', 'HIGH', 4
FROM medical_knowledge_document WHERE title = '中医睡眠与疲劳调理知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

-- Digestion chunks
INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 1, '脾胃不适饮食调养',
       '腹胀、食欲差、饭后不适等轻度脾胃问题，可建议规律进餐、避免暴饮暴食、减少油腻辛辣和冰冷刺激，记录诱发食物。若症状反复或加重，应建议医生评估。',
       '脾胃,腹胀,食欲差,饮食,油腻,辛辣,医生评估', 'tcm_digestion,diet', 'LOW', 1
FROM medical_knowledge_document WHERE title = '中医脾胃与饮食调养知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 2, '便溏与生活方式',
       '便溏或大便不成形时，可先了解持续时间、次数、是否腹痛发热、是否近期饮食不洁或用药。轻度情况可建议清淡饮食和补充水分；若有脱水、血便、高热或持续腹泻，应及时就医。',
       '便溏,腹泻,腹痛,发热,脱水,血便,清淡饮食', 'tcm_digestion,diarrhea,warning', 'MEDIUM', 2
FROM medical_knowledge_document WHERE title = '中医脾胃与饮食调养知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 3, '反酸烧心边界',
       '反酸、烧心可提示规律饮食、避免睡前过饱、减少酒精和刺激性食物，并记录诱因。若出现吞咽困难、呕血、黑便、体重下降或胸痛，应优先排除危险情况。',
       '反酸,烧心,胃食管反流,吞咽困难,呕血,黑便,胸痛', 'digestion,reflux,warning', 'HIGH', 3
FROM medical_knowledge_document WHERE title = '中医脾胃与饮食调养知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 4, '食欲下降追问',
       '食欲下降需要追问持续时间、体重变化、恶心呕吐、腹痛、发热、情绪变化、近期压力和用药。短期轻度可先观察饮食规律，长期明显食欲下降或伴随消瘦时应医生评估。',
       '食欲下降,体重变化,恶心,呕吐,腹痛,消瘦,压力', 'digestion,follow_up', 'MEDIUM', 4
FROM medical_knowledge_document WHERE title = '中医脾胃与饮食调养知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

-- Emotion chunks
INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 1, '情志压力基础调养',
       '压力大、胸闷叹气、情绪波动时，可建议规律作息、适度运动、呼吸放松、减少连续高压工作，并鼓励与家人或医生沟通。若情绪问题持续影响生活，应转专业心理或精神卫生服务。',
       '压力,情志,胸闷,叹气,呼吸放松,心理,精神卫生', 'emotion,mental_health', 'MEDIUM', 1
FROM medical_knowledge_document WHERE title = '中医情志与压力调养知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 2, '焦虑睡眠关联',
       '焦虑常与入睡困难、早醒、心悸、胃口变化相互影响。APP可建议记录触发事件和睡眠情况，但不应自行判断心理疾病。若出现惊恐发作、持续失眠或明显功能受损，应建议专业评估。',
       '焦虑,失眠,早醒,心悸,惊恐发作,专业评估', 'emotion,sleep,anxiety', 'MEDIUM', 2
FROM medical_knowledge_document WHERE title = '中医情志与压力调养知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 3, '心理危机红线',
       '如果用户表达想死、自杀、自伤、活不下去、伤害自己或他人的想法，应触发最高级别预警，建议立即联系家属、医生、当地急救或危机干预服务，不能只返回普通安慰性内容。',
       '想死,自杀,自伤,活不下去,伤害自己,心理危机,急救', 'mental_health,emergency', 'EMERGENCY', 3
FROM medical_knowledge_document WHERE title = '中医情志与压力调养知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 4, '情绪低落追问',
       '情绪低落需要追问持续时间、睡眠、食欲、兴趣下降、工作学习影响、是否有自伤想法、是否有既往心理疾病和近期重大压力事件。涉及自伤风险时必须人工介入。',
       '情绪低落,兴趣下降,食欲,睡眠,自伤,压力事件', 'mental_health,follow_up', 'HIGH', 4
FROM medical_knowledge_document WHERE title = '中医情志与压力调养知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

-- Hypertension chunks
INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 1, '血压记录建议',
       '血压管理应鼓励用户在安静休息后按规范测量，记录日期、时间、收缩压、舒张压、心率和当时症状。单次偏高不等于确诊，但反复偏高需要医生评估。',
       '血压,收缩压,舒张压,心率,测量,医生评估', 'blood_pressure,chronic', 'LOW', 1
FROM medical_knowledge_document WHERE title = '高血压健康管理知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 2, '高血压生活方式',
       '高血压健康管理可包括减少高盐饮食、控制体重、规律运动、限制饮酒、戒烟、保持睡眠和按医嘱用药。APP不能建议用户自行停药或调整处方药剂量。',
       '高血压,少盐,体重,运动,饮酒,戒烟,用药,停药', 'blood_pressure,lifestyle,medication_safety', 'MEDIUM', 2
FROM medical_knowledge_document WHERE title = '高血压健康管理知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 3, '血压急症预警',
       '如果血压明显升高并伴随胸痛、呼吸困难、剧烈头痛、视物模糊、意识改变、肢体无力或说话不清，应按高危情况处理，建议立即急诊或急救。',
       '血压很高,胸痛,呼吸困难,剧烈头痛,视物模糊,意识改变,肢体无力', 'blood_pressure,emergency', 'EMERGENCY', 3
FROM medical_knowledge_document WHERE title = '高血压健康管理知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 4, '血压问诊补充信息',
       '血压相关问诊需补充最近测量值、测量方式、是否规律服药、是否漏服、是否有胸痛头痛、既往高血压病史、糖尿病或肾病史。缺少这些信息时不应直接判断严重程度。',
       '血压,服药,漏服,胸痛,头痛,糖尿病,肾病', 'blood_pressure,follow_up', 'LOW', 4
FROM medical_knowledge_document WHERE title = '高血压健康管理知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

-- Diabetes chunks
INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 1, '血糖记录建议',
       '糖尿病用户应记录空腹血糖、餐后血糖、用药情况、饮食运动和低血糖症状。APP可帮助整理记录，但治疗目标和药物调整应由医生决定。',
       '糖尿病,空腹血糖,餐后血糖,用药,饮食,运动', 'diabetes,chronic', 'LOW', 1
FROM medical_knowledge_document WHERE title = '糖尿病与低血糖风险知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 2, '低血糖常见表现',
       '低血糖可能出现出汗、心慌、手抖、饥饿、头晕、乏力、意识模糊等表现。糖尿病用药用户出现相关症状时，应优先测血糖并按医生预先指导处理，严重或意识异常时需急救。',
       '低血糖,出汗,心慌,手抖,饥饿,意识模糊,急救', 'diabetes,hypoglycemia,warning', 'HIGH', 2
FROM medical_knowledge_document WHERE title = '糖尿病与低血糖风险知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 3, '糖尿病运动安全',
       '糖尿病用户运动前后应关注血糖变化，避免空腹剧烈运动。若运动中出现心慌、出汗、头晕、胸痛或明显乏力，应停止运动并评估血糖和心血管风险。',
       '糖尿病,运动,空腹,心慌,头晕,胸痛,血糖', 'diabetes,exercise,warning', 'MEDIUM', 3
FROM medical_knowledge_document WHERE title = '糖尿病与低血糖风险知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 4, '糖尿病足部风险提示',
       '糖尿病用户若出现足部破溃、感染、麻木、颜色改变或伤口久不愈合，应建议尽快就医。APP可提醒日常足部检查，但不能替代医生处理伤口。',
       '糖尿病足,足部破溃,感染,麻木,伤口,就医', 'diabetes,foot,warning', 'HIGH', 4
FROM medical_knowledge_document WHERE title = '糖尿病与低血糖风险知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

-- Cardio emergency chunks
INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 1, '胸痛急症识别',
       '胸部压榨样疼痛、胸闷，或疼痛放射到左臂、背部、颈部、下颌、上腹，并伴随冷汗、气短、恶心、头晕，应按心血管急症风险处理，建议立即急救或急诊。',
       '胸痛,胸闷,压榨感,左臂痛,冷汗,气短,恶心,急诊', 'chest_pain,emergency', 'EMERGENCY', 1
FROM medical_knowledge_document WHERE title = '心脑血管急症预警知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 2, '卒中FAST识别',
       '突然出现口角歪斜、单侧手臂或腿无力、说话不清或理解困难，应考虑卒中风险，重点是立即急救并记录发作时间。即使症状缓解，也不建议自行等待。',
       '卒中,中风,口角歪斜,单侧无力,说话不清,发作时间,急救', 'stroke,emergency,fast', 'EMERGENCY', 2
FROM medical_knowledge_document WHERE title = '心脑血管急症预警知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 3, '心悸追问与边界',
       '心悸需要追问持续时间、诱因、心率、是否胸痛气短、晕厥、甲状腺疾病、咖啡酒精摄入和用药。若伴随胸痛、晕厥、明显呼吸困难，应优先急诊评估。',
       '心悸,心率,胸痛,气短,晕厥,咖啡,甲状腺', 'palpitation,follow_up,warning', 'HIGH', 3
FROM medical_knowledge_document WHERE title = '心脑血管急症预警知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 4, '头晕风险分层',
       '头晕需要区分眩晕、眼前发黑、站立不稳和晕厥感。若突然头晕伴随说话不清、单侧无力、视物异常、剧烈头痛或胸痛，应按高风险处理。',
       '头晕,眩晕,晕厥,说话不清,单侧无力,视物异常,剧烈头痛', 'dizziness,stroke,warning', 'HIGH', 4
FROM medical_knowledge_document WHERE title = '心脑血管急症预警知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

-- Respiratory chunks
INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 1, '发热基础追问',
       '发热需要追问最高体温、持续时间、测量方式、是否寒战、咳嗽、咽痛、腹泻、皮疹、基础疾病和近期接触史。持续高热、意识异常、抽搐或呼吸困难时需要及时就医。',
       '发热,高热,寒战,咳嗽,咽痛,腹泻,皮疹,抽搐,呼吸困难', 'fever,follow_up,warning', 'HIGH', 1
FROM medical_knowledge_document WHERE title = '发热咳嗽与呼吸症状识别知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 2, '咳嗽基础管理',
       '咳嗽应了解持续时间、是否发热、痰色、胸痛、喘息、过敏史和吸烟史。轻度短期咳嗽可注意休息和补水；若咳血、呼吸困难、胸痛或持续加重，应就医。',
       '咳嗽,痰,发热,喘息,吸烟,咳血,胸痛,呼吸困难', 'cough,respiratory,warning', 'MEDIUM', 2
FROM medical_knowledge_document WHERE title = '发热咳嗽与呼吸症状识别知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 3, '呼吸困难急症识别',
       '喘不上气、嘴唇发紫、说话困难、胸痛、意识异常、氧饱和度明显降低等属于高危信号。APP应触发急症提示，建议立即急救或急诊。',
       '呼吸困难,喘不上气,嘴唇发紫,胸痛,意识异常,氧饱和度,急诊', 'breathing,emergency', 'EMERGENCY', 3
FROM medical_knowledge_document WHERE title = '发热咳嗽与呼吸症状识别知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 4, '咽痛就医边界',
       '咽痛若伴随高热、吞咽困难、呼吸困难、皮疹、颈部明显肿胀或症状持续加重，应建议医生评估。普通咽部不适可先注意饮水、休息和避免刺激。',
       '咽痛,高热,吞咽困难,呼吸困难,皮疹,颈部肿胀', 'throat,warning', 'MEDIUM', 4
FROM medical_knowledge_document WHERE title = '发热咳嗽与呼吸症状识别知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

-- Western digestion chunks
INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 1, '腹痛危险信号',
       '腹痛若突发剧烈、持续加重，或伴随发热、呕血、黑便、便血、持续呕吐、腹部硬痛、孕期腹痛，应建议尽快就医或急诊评估。',
       '腹痛,剧烈腹痛,发热,呕血,黑便,便血,呕吐,孕期', 'abdominal_pain,emergency', 'HIGH', 1
FROM medical_knowledge_document WHERE title = '消化系统常见症状识别知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 2, '腹泻脱水风险',
       '腹泻需要关注次数、持续时间、是否发热、血便、呕吐、尿量减少、口干乏力。儿童、老人、孕妇或慢病患者出现脱水表现时应优先医生评估。',
       '腹泻,脱水,血便,呕吐,尿少,口干,老人,儿童', 'diarrhea,dehydration,warning', 'HIGH', 2
FROM medical_knowledge_document WHERE title = '消化系统常见症状识别知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 3, '呕吐风险识别',
       '呕吐若频繁且无法进水、伴随剧烈头痛、意识异常、胸痛、腹部剧痛、呕血或黑便，应建议急诊评估。轻度短期呕吐可先补液观察，但需关注加重。',
       '呕吐,无法进水,剧烈头痛,意识异常,胸痛,呕血,黑便', 'vomiting,warning', 'HIGH', 3
FROM medical_knowledge_document WHERE title = '消化系统常见症状识别知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 4, '便血和黑便边界',
       '便血或黑便不应被简单归为上火或痔疮。需要询问颜色、量、是否腹痛头晕、是否服用抗凝药或止痛药。明显出血、头晕乏力或黑便应尽快就医。',
       '便血,黑便,痔疮,腹痛,头晕,抗凝药,止痛药,出血', 'blood_stool,warning', 'HIGH', 4
FROM medical_knowledge_document WHERE title = '消化系统常见症状识别知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

-- Mental health chunks
INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 1, '焦虑症状追问',
       '用户描述焦虑时，应追问持续时间、是否突然发作、是否心慌胸闷、是否影响工作学习、是否伴随失眠、是否使用咖啡酒精或药物。不能仅凭一次描述诊断焦虑障碍。',
       '焦虑,心慌,胸闷,失眠,咖啡,酒精,药物', 'anxiety,follow_up', 'MEDIUM', 1
FROM medical_knowledge_document WHERE title = '心理健康与危机预警知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 2, '抑郁风险追问',
       '情绪低落、兴趣下降、疲劳、睡眠食欲改变持续存在时，应询问持续时间、功能影响、是否有无价值感和自伤想法。涉及自伤或自杀表达时必须触发人工和紧急支持。',
       '抑郁,情绪低落,兴趣下降,无价值感,自伤,自杀', 'depression,mental_health,warning', 'HIGH', 2
FROM medical_knowledge_document WHERE title = '心理健康与危机预警知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 3, '心理危机处理',
       '当用户表达自杀、自伤或伤害他人想法时，APP应立即提示联系可信任的人、医生、当地急救或危机干预服务，并在系统内触发紧急审核和联系人通知流程。',
       '自杀,自伤,伤害他人,危机干预,急救,紧急联系人', 'mental_health,crisis,emergency', 'EMERGENCY', 3
FROM medical_knowledge_document WHERE title = '心理健康与危机预警知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 4, '压力管理建议',
       '一般压力管理可建议规律作息、分解任务、适度运动、呼吸放松、减少酒精和过量咖啡因，并寻求社会支持。若持续明显影响生活，应转专业服务。',
       '压力,作息,运动,呼吸放松,酒精,咖啡因,社会支持', 'stress,wellness', 'LOW', 4
FROM medical_knowledge_document WHERE title = '心理健康与危机预警知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

-- Integrated insomnia chunks
INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 1, '失眠中西医结合分析框架',
       '失眠问诊应先识别西医风险因素，如疼痛、呼吸暂停、焦虑抑郁、药物和咖啡因；再结合中医养生角度整理作息、情志、饮食和体质线索。最终建议必须经医生审核。',
       '失眠,中西医结合,呼吸暂停,焦虑,药物,咖啡因,体质', 'integrated,sleep,agent_triage', 'LOW', 1
FROM medical_knowledge_document WHERE title = '中西医结合失眠问诊知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 2, '失眠科室建议',
       '短期轻度失眠可先健康管理；长期严重失眠、伴明显焦虑抑郁、打鼾憋醒、慢病或药物相关问题时，可建议睡眠医学、心理精神科、呼吸科或相关专科评估。',
       '失眠,睡眠医学,心理精神科,呼吸科,打鼾,慢病', 'department,sleep', 'MEDIUM', 2
FROM medical_knowledge_document WHERE title = '中西医结合失眠问诊知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 3, '失眠医生审核要点',
       '医生审核失眠Agent结果时，应重点查看持续时间、严重程度、心理风险、用药史、是否存在打鼾憋醒和日间嗜睡，以及是否需要转专科或线下面诊。',
       '失眠,医生审核,心理风险,用药史,打鼾,日间嗜睡', 'doctor_review,sleep', 'LOW', 3
FROM medical_knowledge_document WHERE title = '中西医结合失眠问诊知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 4, '失眠回答安全边界',
       '失眠相关回答不得承诺治愈，不得推荐处方药或停药换药。可以提供睡眠卫生、记录症状、就医建议和医生审核后的个性化建议。',
       '失眠,安全边界,处方药,停药,睡眠卫生,医生审核', 'safety,sleep', 'MEDIUM', 4
FROM medical_knowledge_document WHERE title = '中西医结合失眠问诊知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

-- Integrated fatigue chunks
INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 1, '疲劳中西医结合分析框架',
       '疲劳问诊应先排查西医危险信号和常见原因，如感染、贫血、甲状腺问题、睡眠不足、慢病、药物影响；再从中医角度整理气虚、脾胃、情志和作息因素。',
       '疲劳,感染,贫血,甲状腺,慢病,气虚,脾胃', 'integrated,fatigue,agent_triage', 'MEDIUM', 1
FROM medical_knowledge_document WHERE title = '中西医结合疲劳问诊知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 2, '疲劳科室建议',
       '疲劳伴胸痛气短或晕厥应急诊；伴持续发热或明显消瘦可建议内科评估；伴情绪低落和失眠可建议心理精神或睡眠相关专科；普通慢性疲劳可先全科或中医科评估。',
       '疲劳,急诊,内科,心理精神科,睡眠,中医科', 'department,fatigue', 'HIGH', 2
FROM medical_knowledge_document WHERE title = '中西医结合疲劳问诊知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 3, '疲劳调养建议边界',
       '疲劳调养可以建议规律睡眠、循序渐进运动、均衡饮食和减少过劳。若疲劳原因不明、持续加重或伴随危险信号，不应只给补气养生建议，应提示医生评估。',
       '疲劳,规律睡眠,运动,均衡饮食,补气,医生评估', 'fatigue,safety', 'MEDIUM', 3
FROM medical_knowledge_document WHERE title = '中西医结合疲劳问诊知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 4, '疲劳医生审核要点',
       '医生审核疲劳Agent结果时，应确认是否收集了持续时间、睡眠、发热、体重、胸闷气短、出血迹象、慢病、用药和心理状态，并决定是否需要进一步检查或会诊。',
       '疲劳,医生审核,睡眠,发热,体重,胸闷,出血,会诊', 'doctor_review,fatigue', 'LOW', 4
FROM medical_knowledge_document WHERE title = '中西医结合疲劳问诊知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

-- Consultation template chunks
INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 1, '通用症状追问模板',
       '通用追问包括开始时间、持续时间、严重程度、诱因、缓解因素、伴随症状、既往病史、用药史、过敏史、是否线下就医和是否影响日常生活。',
       '追问模板,开始时间,持续时间,严重程度,诱因,伴随症状,用药史,过敏史', 'consultation_template,follow_up', 'LOW', 1
FROM medical_knowledge_document WHERE title = 'APP预问诊追问模板知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 2, '医生审核动作模板',
       '医生收到Agent预问诊结果后，可以选择通过、修改、否定、要求补充信息或发起会诊。系统应保存医生操作、最终意见、引用知识和发送给患者的内容。',
       '医生审核,通过,修改,否定,补充信息,会诊,最终意见', 'doctor_review,workflow', 'LOW', 2
FROM medical_knowledge_document WHERE title = 'APP预问诊追问模板知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 3, 'Agent输出结构模板',
       'Agent预问诊输出应包含症状摘要、已知信息、缺失信息、风险等级、可能方向、建议追问、建议科室和免责声明。不能直接输出最终诊断或处方。',
       'Agent,症状摘要,缺失信息,风险等级,建议科室,免责声明,诊断,处方', 'agent_triage,output_template', 'LOW', 3
FROM medical_knowledge_document WHERE title = 'APP预问诊追问模板知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT id, 4, '高风险优先级模板',
       '当用户症状命中胸痛、卒中、呼吸困难、心理危机、高热抽搐、严重低血糖等规则时，系统应优先返回安全提示，通知医生优先审核，并避免生成普通养生建议掩盖风险。',
       '高风险,胸痛,卒中,呼吸困难,心理危机,高热,低血糖,优先审核', 'risk_priority,emergency', 'EMERGENCY', 4
FROM medical_knowledge_document WHERE title = 'APP预问诊追问模板知识'
ON DUPLICATE KEY UPDATE content = VALUES(content), keywords = VALUES(keywords), enabled = 1;

-- Doctor review records for this seed batch.
INSERT INTO knowledge_review
(document_id, chunk_id, reviewer_id, reviewer_role, review_status, review_comment, safety_level, clinical_boundary)
SELECT d.id, c.id, 1, 'DOCTOR', 'APPROVED',
       '系统首批上线种子知识，作为健康管理和预问诊辅助材料使用。',
       CASE c.risk_level
         WHEN 'EMERGENCY' THEN 'EMERGENCY_ONLY'
         WHEN 'HIGH' THEN 'HIGH_RISK'
         WHEN 'MEDIUM' THEN 'CAUTION'
         ELSE 'NORMAL'
       END,
       '仅用于健康管理、风险识别和医生审核前的信息整理，不能替代医生诊断、检查或处方。'
FROM medical_knowledge_chunk c
JOIN medical_knowledge_document d ON c.document_id = d.id
WHERE d.title IN (
  '中医九种体质养生知识',
  '中医睡眠与疲劳调理知识',
  '中医脾胃与饮食调养知识',
  '中医情志与压力调养知识',
  '高血压健康管理知识',
  '糖尿病与低血糖风险知识',
  '心脑血管急症预警知识',
  '发热咳嗽与呼吸症状识别知识',
  '消化系统常见症状识别知识',
  '心理健康与危机预警知识',
  '中西医结合失眠问诊知识',
  '中西医结合疲劳问诊知识',
  'APP预问诊追问模板知识'
)
AND NOT EXISTS (
  SELECT 1 FROM knowledge_review r
  WHERE r.chunk_id = c.id
    AND r.review_status = 'APPROVED'
);

-- Quality score records.
INSERT INTO knowledge_quality_score
(chunk_id, accuracy_score, safety_score, freshness_score, usage_count, positive_feedback_count, negative_feedback_count, last_review_time)
SELECT c.id,
       CASE c.risk_level WHEN 'EMERGENCY' THEN 92.00 WHEN 'HIGH' THEN 90.00 ELSE 88.00 END,
       CASE c.risk_level WHEN 'EMERGENCY' THEN 98.00 WHEN 'HIGH' THEN 95.00 ELSE 90.00 END,
       85.00,
       0,
       0,
       0,
       CURRENT_TIMESTAMP
FROM medical_knowledge_chunk c
JOIN medical_knowledge_document d ON c.document_id = d.id
WHERE d.title IN (
  '中医九种体质养生知识',
  '中医睡眠与疲劳调理知识',
  '中医脾胃与饮食调养知识',
  '中医情志与压力调养知识',
  '高血压健康管理知识',
  '糖尿病与低血糖风险知识',
  '心脑血管急症预警知识',
  '发热咳嗽与呼吸症状识别知识',
  '消化系统常见症状识别知识',
  '心理健康与危机预警知识',
  '中西医结合失眠问诊知识',
  '中西医结合疲劳问诊知识',
  'APP预问诊追问模板知识'
)
ON DUPLICATE KEY UPDATE
  accuracy_score = VALUES(accuracy_score),
  safety_score = VALUES(safety_score),
  freshness_score = VALUES(freshness_score),
  last_review_time = VALUES(last_review_time);

-- Embedding tasks. These tasks are pending until Milvus and the local embedding service are connected.
INSERT INTO knowledge_embedding_task
(task_no, chunk_id, embedding_provider, embedding_model, vector_database, collection_name, vector_dimension, task_status)
SELECT CONCAT('seed-embedding-', c.id), c.id, 'LOCAL', 'bge-base-zh-v1.5', 'MILVUS', 'medical_knowledge_chunk_vector', 768, 'PENDING'
FROM medical_knowledge_chunk c
JOIN medical_knowledge_document d ON c.document_id = d.id
WHERE d.title IN (
  '中医九种体质养生知识',
  '中医睡眠与疲劳调理知识',
  '中医脾胃与饮食调养知识',
  '中医情志与压力调养知识',
  '高血压健康管理知识',
  '糖尿病与低血糖风险知识',
  '心脑血管急症预警知识',
  '发热咳嗽与呼吸症状识别知识',
  '消化系统常见症状识别知识',
  '心理健康与危机预警知识',
  '中西医结合失眠问诊知识',
  '中西医结合疲劳问诊知识',
  'APP预问诊追问模板知识'
)
ON DUPLICATE KEY UPDATE
  embedding_model = VALUES(embedding_model),
  vector_database = VALUES(vector_database),
  collection_name = VALUES(collection_name),
  vector_dimension = VALUES(vector_dimension);

-- Add seed chunks to the initial knowledge version.
INSERT INTO knowledge_version_item
(version_id, document_id, chunk_id, item_action, change_summary)
SELECT v.id, d.id, c.id, 'ADD', 'APP launch seed knowledge chunk'
FROM knowledge_version v
JOIN medical_knowledge_document d
JOIN medical_knowledge_chunk c ON c.document_id = d.id
WHERE v.version_no = 'kb-v1.0.0'
  AND d.title IN (
    '中医九种体质养生知识',
    '中医睡眠与疲劳调理知识',
    '中医脾胃与饮食调养知识',
    '中医情志与压力调养知识',
    '高血压健康管理知识',
    '糖尿病与低血糖风险知识',
    '心脑血管急症预警知识',
    '发热咳嗽与呼吸症状识别知识',
    '消化系统常见症状识别知识',
    '心理健康与危机预警知识',
    '中西医结合失眠问诊知识',
    '中西医结合疲劳问诊知识',
    'APP预问诊追问模板知识'
  )
  AND NOT EXISTS (
    SELECT 1 FROM knowledge_version_item vi
    WHERE vi.version_id = v.id
      AND vi.chunk_id = c.id
  );
