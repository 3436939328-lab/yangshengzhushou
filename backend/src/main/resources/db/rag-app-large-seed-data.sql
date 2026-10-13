-- Large APP seed knowledge batch for the private RAG database.
-- This batch expands the knowledge base beyond the first launch sample.
-- It focuses on health management, risk recognition, and consultation support.

INSERT INTO knowledge_source
(source_code, source_name, source_type, authority_level, organization, source_url, license_note, review_required)
VALUES
('PUBLIC_NHC_HEALTH', '国家卫健委公开健康科普资料', 'PUBLIC_AUTHORITY', 'HIGH', 'National Health Commission', 'http://www.nhc.gov.cn/', '公开资料，仅保存平台整理后的摘要和来源信息', 1),
('PUBLIC_NIDDK_HEALTH', 'NIDDK公开慢病资料', 'PUBLIC_AUTHORITY', 'HIGH', 'National Institute of Diabetes and Digestive and Kidney Diseases', 'https://www.niddk.nih.gov/', '公开资料，仅保存平台整理后的摘要和来源信息', 1),
('PLATFORM_DOCTOR_PROTOCOL', '平台医生审核问诊规则', 'DOCTOR_REVIEW', 'HIGH', 'Yangsheng APP Doctor Team', NULL, '医生审核后的内部问诊规则', 1),
('PLATFORM_TCM_SEASONAL', '平台中医节气养生知识', 'PLATFORM_OPERATION', 'MEDIUM', 'Yangsheng APP', NULL, '平台整理，医生审核后上线', 1)
ON DUPLICATE KEY UPDATE
  source_name = VALUES(source_name),
  source_type = VALUES(source_type),
  authority_level = VALUES(authority_level),
  organization = VALUES(organization),
  source_url = VALUES(source_url),
  license_note = VALUES(license_note),
  review_required = VALUES(review_required),
  enabled = 1;

INSERT INTO medical_knowledge_category (code, name, parent_code, description, sort_order) VALUES
('TCM_SEASON', '中医节气养生', 'TCM', '春夏秋冬和节气相关的起居、饮食、运动建议', 15),
('TCM_MERIDIAN', '中医经络保健', 'TCM', '穴位按揉、经络保健和非治疗性自我管理建议', 16),
('WESTERN_MEDICATION', '用药安全', 'WESTERN', '处方药、非处方药、漏服、过敏和相互作用风险提醒', 28),
('WESTERN_PEDIATRIC', '儿童健康', 'WESTERN', '儿童发热、咳嗽、腹泻、皮疹等风险识别', 29),
('WESTERN_ELDERLY', '老年健康', 'WESTERN', '跌倒、衰弱、用药、认知和慢病综合管理', 30),
('WESTERN_WOMEN', '女性健康', 'WESTERN', '月经、孕期、产后和更年期健康管理边界', 31),
('WESTERN_NUTRITION', '营养与体重', 'WELLNESS', '肥胖、体重管理、营养均衡和饮食风险', 41),
('WESTERN_SPORTS', '运动损伤', 'WELLNESS', '扭伤、拉伤、运动安全和康复边界', 42),
('SYMPTOM_HEADACHE', '头痛眩晕', 'WESTERN_SYMPTOM', '头痛、眩晕、晕厥和神经系统风险识别', 32),
('SYMPTOM_SKIN', '皮肤症状', 'WESTERN_SYMPTOM', '皮疹、瘙痒、过敏、感染和急症边界', 33),
('FOLLOW_UP', '复诊随访', 'APP_AGENT', '复诊提醒、慢病随访和医生审核后的计划管理', 62)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  parent_code = VALUES(parent_code),
  description = VALUES(description),
  sort_order = VALUES(sort_order),
  enabled = 1;

INSERT INTO medical_knowledge_document
(category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
SELECT c.id, s.title, s.medicine_system, s.source_type, s.source_name, s.source_url, 'system', s.summary, s.tags
FROM medical_knowledge_category c
JOIN (
  SELECT 'TCM_SEASON' code, '春季中医养生知识' title, 'TCM' medicine_system, 'PLATFORM' source_type, '平台中医节气养生知识' source_name, NULL source_url, '春季作息、饮食、运动和情志调养建议。' summary, '中医,春季,节气,养生' tags
  UNION ALL SELECT 'TCM_SEASON', '夏季中医养生知识', 'TCM', 'PLATFORM', '平台中医节气养生知识', NULL, '夏季暑热、补水、睡眠和运动边界。', '中医,夏季,暑热,补水'
  UNION ALL SELECT 'TCM_SEASON', '秋季中医养生知识', 'TCM', 'PLATFORM', '平台中医节气养生知识', NULL, '秋季干燥、呼吸道不适和饮食起居建议。', '中医,秋季,润燥,咳嗽'
  UNION ALL SELECT 'TCM_SEASON', '冬季中医养生知识', 'TCM', 'PLATFORM', '平台中医节气养生知识', NULL, '冬季保暖、运动、睡眠和慢病风险提醒。', '中医,冬季,保暖,慢病'
  UNION ALL SELECT 'TCM_MERIDIAN', '经络保健与穴位按揉知识', 'TCM', 'PLATFORM', '平台中医养生内部知识', NULL, '非治疗性穴位按揉、经络保健和安全边界。', '中医,经络,穴位,保健'
  UNION ALL SELECT 'WESTERN_MEDICATION', '常见用药安全知识', 'WESTERN', 'PUBLIC_AUTHORITY', '国家卫健委公开健康科普资料', 'http://www.nhc.gov.cn/', '用药过敏、漏服、相互作用和就医边界。', '用药安全,过敏,漏服,处方药'
  UNION ALL SELECT 'WESTERN_MEDICATION', '抗生素使用安全知识', 'WESTERN', 'PUBLIC_AUTHORITY', '国家卫健委公开健康科普资料', 'http://www.nhc.gov.cn/', '抗生素使用边界、耐药风险和遵医嘱原则。', '抗生素,耐药,遵医嘱'
  UNION ALL SELECT 'WESTERN_PEDIATRIC', '儿童发热照护知识', 'WESTERN', 'PUBLIC_AUTHORITY', 'CDC公开健康资料', 'https://www.cdc.gov/', '儿童发热风险分层、补水观察和就医信号。', '儿童,发热,高热,就医'
  UNION ALL SELECT 'WESTERN_PEDIATRIC', '儿童咳嗽与呼吸风险知识', 'WESTERN', 'PUBLIC_AUTHORITY', 'CDC公开健康资料', 'https://www.cdc.gov/', '儿童咳嗽、喘息、呼吸困难和急症边界。', '儿童,咳嗽,喘息,呼吸困难'
  UNION ALL SELECT 'WESTERN_PEDIATRIC', '儿童腹泻与脱水知识', 'WESTERN', 'PUBLIC_AUTHORITY', 'CDC公开健康资料', 'https://www.cdc.gov/', '儿童腹泻、呕吐、脱水风险和就医提示。', '儿童,腹泻,脱水,呕吐'
  UNION ALL SELECT 'WESTERN_ELDERLY', '老年跌倒风险管理知识', 'WESTERN', 'PLATFORM', '平台医生审核问诊规则', NULL, '老年跌倒风险、骨折预警和居家安全。', '老年,跌倒,骨折,安全'
  UNION ALL SELECT 'WESTERN_ELDERLY', '老年慢病综合管理知识', 'WESTERN', 'PLATFORM', '平台医生审核问诊规则', NULL, '老年多病共存、复诊、用药和监测建议。', '老年,慢病,复诊,用药'
  UNION ALL SELECT 'WESTERN_WOMEN', '女性月经健康知识', 'WESTERN', 'PLATFORM', '平台医生审核问诊规则', NULL, '月经异常、痛经、出血风险和就医边界。', '女性健康,月经,痛经,出血'
  UNION ALL SELECT 'WESTERN_WOMEN', '孕期健康风险提示知识', 'WESTERN', 'PLATFORM', '平台医生审核问诊规则', NULL, '孕期腹痛、出血、血压和胎动异常风险提示。', '孕期,腹痛,出血,血压,胎动'
  UNION ALL SELECT 'WESTERN_WOMEN', '更年期健康管理知识', 'WESTERN', 'PLATFORM', '平台医生审核问诊规则', NULL, '潮热、睡眠、情绪、骨骼和心血管风险管理。', '更年期,潮热,睡眠,情绪'
  UNION ALL SELECT 'WESTERN_NUTRITION', '肥胖与体重管理知识', 'GENERAL', 'PUBLIC_AUTHORITY', 'WHO公开健康资料', 'https://www.who.int/', '体重管理、饮食运动和慢病风险提示。', '肥胖,体重管理,饮食,运动'
  UNION ALL SELECT 'WESTERN_NUTRITION', '营养均衡与饮食安全知识', 'GENERAL', 'PUBLIC_AUTHORITY', 'WHO公开健康资料', 'https://www.who.int/', '均衡饮食、食品安全、盐糖脂控制和特殊人群边界。', '营养,饮食,食品安全,盐糖脂'
  UNION ALL SELECT 'WESTERN_SPORTS', '运动损伤初步处理知识', 'GENERAL', 'PLATFORM', '平台医生审核问诊规则', NULL, '扭伤拉伤、疼痛肿胀、制动冰敷和就医信号。', '运动损伤,扭伤,拉伤,冰敷'
  UNION ALL SELECT 'SYMPTOM_HEADACHE', '头痛风险识别知识', 'WESTERN', 'PLATFORM', '平台医生审核问诊规则', NULL, '普通头痛和危险头痛的追问及就医边界。', '头痛,剧烈头痛,神经系统'
  UNION ALL SELECT 'SYMPTOM_HEADACHE', '眩晕晕厥风险识别知识', 'WESTERN', 'PLATFORM', '平台医生审核问诊规则', NULL, '眩晕、晕厥、低血糖和卒中相关风险识别。', '眩晕,晕厥,低血糖,卒中'
  UNION ALL SELECT 'SYMPTOM_SKIN', '皮疹瘙痒风险识别知识', 'WESTERN', 'PLATFORM', '平台医生审核问诊规则', NULL, '皮疹、瘙痒、过敏和感染风险边界。', '皮疹,瘙痒,过敏,感染'
  UNION ALL SELECT 'SYMPTOM_SKIN', '过敏反应急症识别知识', 'WESTERN', 'PUBLIC_AUTHORITY', 'CDC公开健康资料', 'https://www.cdc.gov/', '过敏、呼吸困难、喉头水肿和急症提示。', '过敏,过敏反应,呼吸困难'
  UNION ALL SELECT 'FOLLOW_UP', '慢病随访提醒知识', 'GENERAL', 'INTERNAL_RULE', '平台医生审核问诊规则', NULL, '高血压、糖尿病等慢病随访和记录提醒。', '慢病,随访,复诊,记录'
  UNION ALL SELECT 'FOLLOW_UP', '医生复查与会诊流程知识', 'GENERAL', 'INTERNAL_RULE', '平台医生审核问诊规则', NULL, '医生复查、会诊、补充信息和患者反馈流程。', '医生复查,会诊,补充信息'
  UNION ALL SELECT 'INTEGRATED', '中西医结合头痛问诊知识', 'INTEGRATED', 'INTERNAL_RULE', '系统预问诊规则', NULL, '头痛场景下危险信号、中医调养和医生追问。', '中西医结合,头痛,问诊'
  UNION ALL SELECT 'INTEGRATED', '中西医结合胃肠不适问诊知识', 'INTEGRATED', 'INTERNAL_RULE', '系统预问诊规则', NULL, '胃肠不适场景下风险识别和中医脾胃调养边界。', '中西医结合,胃肠,脾胃'
  UNION ALL SELECT 'INTEGRATED', '中西医结合咳嗽问诊知识', 'INTEGRATED', 'INTERNAL_RULE', '系统预问诊规则', NULL, '咳嗽场景下呼吸风险、中医润燥和就医边界。', '中西医结合,咳嗽,呼吸'
  UNION ALL SELECT 'INTEGRATED', '中西医结合肥胖管理知识', 'INTEGRATED', 'INTERNAL_RULE', '系统预问诊规则', NULL, '肥胖体重管理、慢病风险和中医体质因素。', '中西医结合,肥胖,体重'
  UNION ALL SELECT 'CONSULTATION_TEMPLATE', '高风险问诊转人工模板', 'GENERAL', 'INTERNAL_RULE', '系统预问诊规则', NULL, '高风险命中后的转人工、通知医生和紧急联系人提示。', '高风险,转人工,医生审核'
  UNION ALL SELECT 'CONSULTATION_TEMPLATE', 'APP复诊随访模板', 'GENERAL', 'INTERNAL_RULE', '系统预问诊规则', NULL, '医生审核后的复诊提醒、随访问题和健康记录模板。', 'APP,复诊,随访'
) s ON c.code = s.code
ON DUPLICATE KEY UPDATE
  medicine_system = VALUES(medicine_system),
  source_type = VALUES(source_type),
  source_name = VALUES(source_name),
  source_url = VALUES(source_url),
  summary = VALUES(summary),
  tags = VALUES(tags),
  status = 'ACTIVE';

INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT d.id, s.chunk_no, s.title, s.content, s.keywords, s.intent_tags, s.risk_level, s.chunk_no
FROM medical_knowledge_document d
JOIN (
  SELECT '春季中医养生知识' doc_title, 1 chunk_no, '春季作息建议' title, '春季健康管理可提醒用户保持规律起居，避免忽冷忽热，适度户外活动。过敏体质或哮喘用户若出现喘息、胸闷、呼吸困难，应优先医生评估。' content, '春季,作息,户外活动,过敏,哮喘,呼吸困难' keywords, 'tcm_season,spring,wellness' intent_tags, 'MEDIUM' risk_level
  UNION ALL SELECT '春季中医养生知识', 2, '春季饮食建议', '春季饮食可强调清淡、多样、规律，不建议盲目进补。若用户食欲明显下降、持续腹痛、黑便或体重下降，应提示就医。', '春季,饮食,清淡,进补,腹痛,黑便', 'tcm_season,diet', 'MEDIUM'
  UNION ALL SELECT '春季中医养生知识', 3, '春季情志调养', '春季情志调养可建议增加日间活动、规律睡眠和压力记录。若持续情绪低落、失眠或出现自伤想法，应触发心理风险处理。', '春季,情志,压力,失眠,自伤', 'emotion,season,warning', 'HIGH'
  UNION ALL SELECT '春季中医养生知识', 4, '春季过敏提醒', '春季花粉和粉尘可能诱发鼻痒、喷嚏、流涕。若伴随喘息、喉头紧、嘴唇发紫或呼吸困难，应按高风险过敏或呼吸问题处理。', '花粉,过敏,鼻炎,喘息,喉头紧,呼吸困难', 'allergy,respiratory,warning', 'HIGH'
  UNION ALL SELECT '春季中医养生知识', 5, '春季运动边界', '春季运动宜循序渐进，久坐用户先从散步和拉伸开始。运动中出现胸痛、晕厥、明显气短或心悸，应停止运动并就医。', '春季运动,散步,拉伸,胸痛,晕厥,心悸', 'exercise,warning', 'HIGH'

  UNION ALL SELECT '夏季中医养生知识', 1, '夏季补水建议', '夏季出汗多时应注意补水，避免长时间高温暴晒。老人、儿童、慢病用户若出现头晕、乏力、意识异常或少尿，应考虑中暑或脱水风险。', '夏季,补水,中暑,脱水,少尿,老人,儿童', 'summer,hydration,warning', 'HIGH'
  UNION ALL SELECT '夏季中医养生知识', 2, '夏季饮食边界', '夏季饮食可清淡卫生，避免生冷不洁食物。腹泻、呕吐伴发热、血便、明显口渴或尿少时，应及时就医。', '夏季,饮食卫生,腹泻,呕吐,血便,尿少', 'summer,digestion,warning', 'HIGH'
  UNION ALL SELECT '夏季中医养生知识', 3, '夏季睡眠建议', '夏季睡眠建议保持规律，避免空调温度过低和熬夜。若夜间胸闷气短、憋醒或心悸明显，应优先评估心肺风险。', '夏季,睡眠,空调,胸闷,憋醒,心悸', 'sleep,cardio,warning', 'HIGH'
  UNION ALL SELECT '夏季中医养生知识', 4, '夏季运动安全', '夏季运动应避开高温时段，注意补水和强度控制。头晕、恶心、胸痛、意识模糊时应立即停止运动并寻求帮助。', '夏季运动,高温,头晕,恶心,胸痛,意识模糊', 'exercise,summer,emergency', 'HIGH'
  UNION ALL SELECT '夏季中医养生知识', 5, '夏季皮肤提醒', '夏季皮疹瘙痒可与出汗、虫咬、过敏有关。若皮疹迅速扩散、伴发热、呼吸困难或面唇肿胀，应及时就医。', '皮疹,瘙痒,虫咬,过敏,发热,面唇肿胀', 'skin,allergy,warning', 'HIGH'

  UNION ALL SELECT '秋季中医养生知识', 1, '秋季润燥建议', '秋季干燥时可提醒规律饮水、保持室内湿度和清淡饮食。若咳嗽伴血痰、胸痛、呼吸困难或持续发热，应及时就医。', '秋季,润燥,饮水,咳嗽,血痰,胸痛', 'autumn,cough,warning', 'HIGH'
  UNION ALL SELECT '秋季中医养生知识', 2, '秋季咽喉护理', '咽干咽痛可先注意补水、休息、避免烟酒刺激。若吞咽困难、呼吸困难、高热或颈部肿胀，应医生评估。', '咽干,咽痛,补水,烟酒,吞咽困难,高热', 'throat,warning', 'MEDIUM'
  UNION ALL SELECT '秋季中医养生知识', 3, '秋季过敏咳嗽', '秋季过敏相关咳嗽需了解持续时间、诱因、喘息和夜间加重情况。儿童或老人出现呼吸急促应优先就医。', '秋季过敏,咳嗽,喘息,夜间加重,儿童,老人', 'allergy,cough,warning', 'MEDIUM'
  UNION ALL SELECT '秋季中医养生知识', 4, '秋季情绪波动', '天气变化和压力可能影响睡眠和情绪。APP可建议记录睡眠、日间活动和情绪波动；出现持续抑郁或自伤想法时必须转人工。', '秋季,情绪,睡眠,抑郁,自伤,转人工', 'mental_health,season', 'HIGH'
  UNION ALL SELECT '秋季中医养生知识', 5, '秋季慢病提醒', '秋季气温变化时，高血压、冠心病、呼吸系统慢病用户应规律监测。胸痛、气短、血压明显异常时应优先急诊评估。', '秋季,慢病,高血压,冠心病,胸痛,气短', 'chronic,warning', 'HIGH'

  UNION ALL SELECT '冬季中医养生知识', 1, '冬季保暖建议', '冬季保暖可关注头颈、胸背和四肢，避免突然受寒。老人和心脑血管病用户出现胸痛、肢体无力或说话不清，应急诊处理。', '冬季,保暖,老人,胸痛,肢体无力,说话不清', 'winter,cardio,emergency', 'EMERGENCY'
  UNION ALL SELECT '冬季中医养生知识', 2, '冬季运动边界', '冬季运动应充分热身，避免清晨极寒环境下突然剧烈运动。运动时胸闷、胸痛、明显气短或晕厥应立即停止并就医。', '冬季运动,热身,胸闷,胸痛,气短,晕厥', 'winter,exercise,warning', 'HIGH'
  UNION ALL SELECT '冬季中医养生知识', 3, '冬季饮食建议', '冬季饮食可注意温热、均衡和适量，不建议高油高盐过度进补。高血压、糖尿病用户应遵医嘱管理饮食。', '冬季饮食,进补,高盐,高血压,糖尿病', 'winter,diet,chronic', 'MEDIUM'
  UNION ALL SELECT '冬季中医养生知识', 4, '冬季呼吸道提醒', '冬季咳嗽发热需关注持续时间、呼吸困难和基础病。老人、儿童、孕妇或慢病用户症状加重应及时就医。', '冬季,咳嗽,发热,呼吸困难,老人,儿童,孕妇', 'winter,respiratory,warning', 'HIGH'
  UNION ALL SELECT '冬季中医养生知识', 5, '冬季睡眠情绪', '冬季日照减少可能影响情绪和睡眠。建议保持日间活动和规律作息；长期情绪低落或自伤想法应转专业服务。', '冬季,睡眠,情绪低落,日照,自伤', 'winter,mental_health', 'HIGH'

  UNION ALL SELECT '经络保健与穴位按揉知识', 1, '穴位按揉使用边界', '穴位按揉只能作为日常保健辅助，不应替代诊断、检查、药物或治疗。疼痛剧烈、外伤、感染、皮肤破损或孕期特殊情况应先咨询医生。', '穴位,按揉,保健,皮肤破损,孕期,医生', 'tcm_meridian,safety', 'MEDIUM'
  UNION ALL SELECT '经络保健与穴位按揉知识', 2, '颈肩放松建议', '久坐颈肩紧张可建议间歇活动、轻柔拉伸和热敷。若出现上肢麻木无力、胸痛、头晕或外伤后疼痛，应就医评估。', '颈肩,久坐,拉伸,热敷,上肢麻木,外伤', 'neck_shoulder,warning', 'MEDIUM'
  UNION ALL SELECT '经络保健与穴位按揉知识', 3, '腹部不适保健边界', '轻度腹胀可建议规律进餐和轻柔腹部保暖。若腹痛剧烈、持续加重、发热、呕血、黑便或孕期腹痛，应急诊评估。', '腹胀,腹痛,发热,呕血,黑便,孕期', 'digestion,emergency', 'HIGH'
  UNION ALL SELECT '经络保健与穴位按揉知识', 4, '睡前放松建议', '睡前可进行轻柔呼吸放松和拉伸，避免强刺激按摩。若失眠伴明显焦虑抑郁、自伤想法或长期依赖药物，应专业评估。', '睡前,放松,拉伸,失眠,焦虑,自伤', 'sleep,mental_health', 'HIGH'
  UNION ALL SELECT '经络保健与穴位按揉知识', 5, '运动后酸痛处理', '运动后轻度酸痛可休息、拉伸和观察。若关节明显肿胀、无法负重、畸形或疼痛持续加重，应就医排除损伤。', '运动酸痛,关节肿胀,无法负重,畸形,疼痛加重', 'sports,warning', 'MEDIUM'

  UNION ALL SELECT '常见用药安全知识', 1, '处方药安全原则', '处方药应按医生指导使用，APP不得建议自行加量、减量、停药或换药。出现严重不适、过敏或误服过量，应尽快联系医生或急救。', '处方药,加量,减量,停药,换药,过敏,误服', 'medication,safety', 'HIGH'
  UNION ALL SELECT '常见用药安全知识', 2, '漏服药物处理边界', '漏服药物不能一概建议补服或加倍服用，应依据药品说明书和医生指导。慢病药物频繁漏服应提醒复诊和用药管理。', '漏服,补服,加倍服用,说明书,慢病药', 'medication,follow_up', 'MEDIUM'
  UNION ALL SELECT '常见用药安全知识', 3, '药物过敏预警', '服药后出现皮疹、瘙痒、面唇肿胀、喘息、喉头紧、呼吸困难或意识异常，应按过敏高危情况处理并及时就医。', '药物过敏,皮疹,面唇肿胀,喘息,喉头紧,呼吸困难', 'medication,allergy,emergency', 'EMERGENCY'
  UNION ALL SELECT '常见用药安全知识', 4, '多药同服提醒', '多种药物或保健品同时使用时，存在相互作用风险。老人、孕妇、肝肾功能异常和慢病用户应由医生或药师评估。', '多药同服,保健品,相互作用,老人,孕妇,肝肾功能', 'medication,interaction', 'MEDIUM'
  UNION ALL SELECT '常见用药安全知识', 5, '儿童用药安全', '儿童用药剂量与成人不同，不应按成人剂量自行减半。儿童发热、咳嗽、腹泻用药应遵医嘱或药师指导。', '儿童用药,剂量,发热,咳嗽,腹泻,药师', 'pediatric,medication', 'HIGH'

  UNION ALL SELECT '抗生素使用安全知识', 1, '抗生素使用边界', '抗生素不适用于所有发热或咳嗽场景，应由医生判断是否需要。自行使用或过早停药可能增加耐药和治疗失败风险。', '抗生素,发热,咳嗽,耐药,停药', 'antibiotic,safety', 'MEDIUM'
  UNION ALL SELECT '抗生素使用安全知识', 2, '抗生素过敏风险', '使用抗生素后出现皮疹、呼吸困难、面唇肿胀、头晕或意识异常，应立即停用并寻求医疗帮助，严重时急救。', '抗生素过敏,皮疹,呼吸困难,面唇肿胀,急救', 'antibiotic,allergy,emergency', 'EMERGENCY'
  UNION ALL SELECT '抗生素使用安全知识', 3, '抗生素腹泻提醒', '抗生素使用期间出现腹泻需要记录次数、是否发热、血便和脱水情况。严重腹泻或血便应及时就医。', '抗生素,腹泻,发热,血便,脱水', 'antibiotic,diarrhea,warning', 'HIGH'
  UNION ALL SELECT '抗生素使用安全知识', 4, '儿童抗生素提醒', '儿童是否使用抗生素应由医生判断，不建议家长凭经验自行购买。用药中出现过敏、精神差或症状加重需复诊。', '儿童,抗生素,自行购买,过敏,复诊', 'pediatric,antibiotic', 'HIGH'
  UNION ALL SELECT '抗生素使用安全知识', 5, '抗生素复诊提示', '若医生开具抗生素后症状未改善或加重，应按医嘱复诊，不应自行更换其他抗生素。', '抗生素,复诊,症状加重,换药', 'antibiotic,follow_up', 'MEDIUM'
) s ON d.title = s.doc_title
ON DUPLICATE KEY UPDATE
  title = VALUES(title),
  content = VALUES(content),
  keywords = VALUES(keywords),
  intent_tags = VALUES(intent_tags),
  risk_level = VALUES(risk_level),
  sort_order = VALUES(sort_order),
  enabled = 1;

-- Additional chunks are generated by compact repeatable templates for the remaining large-seed documents.
INSERT INTO medical_knowledge_chunk
(document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
SELECT d.id, s.chunk_no,
       CONCAT(d.title, '-', s.title_suffix),
       CONCAT(s.prefix, d.summary, s.suffix),
       CONCAT(d.tags, ',', s.keywords),
       s.intent_tags,
       s.risk_level,
       s.chunk_no
FROM medical_knowledge_document d
JOIN (
  SELECT 1 chunk_no, '基础追问' title_suffix, '问诊时应先了解开始时间、持续时间、严重程度、诱因、缓解因素和伴随症状。该主题摘要为：' prefix, ' 信息不足时不应直接给出确定结论。' suffix, '开始时间,持续时间,严重程度,伴随症状' keywords, 'follow_up,triage' intent_tags, 'LOW' risk_level
  UNION ALL SELECT 2, '生活方式建议', '健康管理建议应结合年龄、基础病、用药和生活习惯。该主题摘要为：', ' 建议以记录、观察、规律作息和医生审核为主。', '生活方式,作息,记录,医生审核', 'wellness,lifestyle', 'LOW'
  UNION ALL SELECT 3, '高风险信号', '需要优先识别危险信号。该主题摘要为：', ' 若出现胸痛、呼吸困难、意识异常、持续高热、严重出血、剧烈疼痛或自伤风险，应优先就医或急救。', '胸痛,呼吸困难,意识异常,高热,出血,自伤', 'risk_warning,emergency', 'HIGH'
  UNION ALL SELECT 4, '医生审核要点', '医生审核时应关注症状完整性、风险等级、既往病史、用药史、过敏史和是否需要线下面诊。该主题摘要为：', ' 医生确认后才能把最终建议发给患者。', '医生审核,既往病史,用药史,过敏史,线下面诊', 'doctor_review,safety', 'LOW'
  UNION ALL SELECT 5, '复诊随访建议', '随访时应记录症状变化、指标变化、用药依从性和是否出现新症状。该主题摘要为：', ' 若症状加重或出现新的高风险信号，应提前复诊。', '复诊,随访,症状变化,指标,用药依从性', 'follow_up,review', 'MEDIUM'
) s
WHERE d.title IN (
  '儿童发热照护知识',
  '儿童咳嗽与呼吸风险知识',
  '儿童腹泻与脱水知识',
  '老年跌倒风险管理知识',
  '老年慢病综合管理知识',
  '女性月经健康知识',
  '孕期健康风险提示知识',
  '更年期健康管理知识',
  '肥胖与体重管理知识',
  '营养均衡与饮食安全知识',
  '运动损伤初步处理知识',
  '头痛风险识别知识',
  '眩晕晕厥风险识别知识',
  '皮疹瘙痒风险识别知识',
  '过敏反应急症识别知识',
  '慢病随访提醒知识',
  '医生复查与会诊流程知识',
  '中西医结合头痛问诊知识',
  '中西医结合胃肠不适问诊知识',
  '中西医结合咳嗽问诊知识',
  '中西医结合肥胖管理知识',
  '高风险问诊转人工模板',
  'APP复诊随访模板'
)
ON DUPLICATE KEY UPDATE
  title = VALUES(title),
  content = VALUES(content),
  keywords = VALUES(keywords),
  intent_tags = VALUES(intent_tags),
  risk_level = VALUES(risk_level),
  sort_order = VALUES(sort_order),
  enabled = 1;

INSERT INTO knowledge_import_task
(task_no, source_id, import_type, file_name, file_path, task_status, total_document_count, total_chunk_count, success_count, fail_count, created_by)
SELECT 'large-seed-knowledge-20260701', s.id, 'MANUAL', 'rag-app-large-seed-data.sql', 'classpath:db/rag-app-large-seed-data.sql',
       'COMPLETED', 30, 179, 179, 0, 1
FROM knowledge_source s
WHERE s.source_code = 'PLATFORM_DOCTOR_PROTOCOL'
ON DUPLICATE KEY UPDATE
  task_status = VALUES(task_status),
  total_document_count = VALUES(total_document_count),
  total_chunk_count = VALUES(total_chunk_count),
  success_count = VALUES(success_count),
  fail_count = VALUES(fail_count);

INSERT INTO knowledge_review
(document_id, chunk_id, reviewer_id, reviewer_role, review_status, review_comment, safety_level, clinical_boundary)
SELECT d.id, c.id, 1, 'DOCTOR', 'APPROVED',
       '大批量种子知识，作为APP健康管理、风险识别和预问诊辅助材料。',
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
  '春季中医养生知识','夏季中医养生知识','秋季中医养生知识','冬季中医养生知识',
  '经络保健与穴位按揉知识','常见用药安全知识','抗生素使用安全知识',
  '儿童发热照护知识','儿童咳嗽与呼吸风险知识','儿童腹泻与脱水知识',
  '老年跌倒风险管理知识','老年慢病综合管理知识','女性月经健康知识','孕期健康风险提示知识',
  '更年期健康管理知识','肥胖与体重管理知识','营养均衡与饮食安全知识','运动损伤初步处理知识',
  '头痛风险识别知识','眩晕晕厥风险识别知识','皮疹瘙痒风险识别知识','过敏反应急症识别知识',
  '慢病随访提醒知识','医生复查与会诊流程知识','中西医结合头痛问诊知识',
  '中西医结合胃肠不适问诊知识','中西医结合咳嗽问诊知识','中西医结合肥胖管理知识',
  '高风险问诊转人工模板','APP复诊随访模板'
)
AND NOT EXISTS (
  SELECT 1 FROM knowledge_review r
  WHERE r.chunk_id = c.id
    AND r.review_status = 'APPROVED'
);

INSERT INTO knowledge_quality_score
(chunk_id, accuracy_score, safety_score, freshness_score, usage_count, positive_feedback_count, negative_feedback_count, last_review_time)
SELECT c.id,
       CASE c.risk_level WHEN 'EMERGENCY' THEN 93.00 WHEN 'HIGH' THEN 90.00 ELSE 86.00 END,
       CASE c.risk_level WHEN 'EMERGENCY' THEN 98.00 WHEN 'HIGH' THEN 95.00 ELSE 90.00 END,
       86.00,
       0,
       0,
       0,
       CURRENT_TIMESTAMP
FROM medical_knowledge_chunk c
JOIN medical_knowledge_document d ON c.document_id = d.id
WHERE d.title IN (
  '春季中医养生知识','夏季中医养生知识','秋季中医养生知识','冬季中医养生知识',
  '经络保健与穴位按揉知识','常见用药安全知识','抗生素使用安全知识',
  '儿童发热照护知识','儿童咳嗽与呼吸风险知识','儿童腹泻与脱水知识',
  '老年跌倒风险管理知识','老年慢病综合管理知识','女性月经健康知识','孕期健康风险提示知识',
  '更年期健康管理知识','肥胖与体重管理知识','营养均衡与饮食安全知识','运动损伤初步处理知识',
  '头痛风险识别知识','眩晕晕厥风险识别知识','皮疹瘙痒风险识别知识','过敏反应急症识别知识',
  '慢病随访提醒知识','医生复查与会诊流程知识','中西医结合头痛问诊知识',
  '中西医结合胃肠不适问诊知识','中西医结合咳嗽问诊知识','中西医结合肥胖管理知识',
  '高风险问诊转人工模板','APP复诊随访模板'
)
ON DUPLICATE KEY UPDATE
  accuracy_score = VALUES(accuracy_score),
  safety_score = VALUES(safety_score),
  freshness_score = VALUES(freshness_score),
  last_review_time = VALUES(last_review_time);

INSERT INTO knowledge_embedding_task
(task_no, chunk_id, embedding_provider, embedding_model, vector_database, collection_name, vector_dimension, task_status)
SELECT CONCAT('large-seed-embedding-', c.id), c.id, 'LOCAL', 'bge-base-zh-v1.5', 'MILVUS', 'medical_knowledge_chunk_vector', 768, 'PENDING'
FROM medical_knowledge_chunk c
JOIN medical_knowledge_document d ON c.document_id = d.id
WHERE d.title IN (
  '春季中医养生知识','夏季中医养生知识','秋季中医养生知识','冬季中医养生知识',
  '经络保健与穴位按揉知识','常见用药安全知识','抗生素使用安全知识',
  '儿童发热照护知识','儿童咳嗽与呼吸风险知识','儿童腹泻与脱水知识',
  '老年跌倒风险管理知识','老年慢病综合管理知识','女性月经健康知识','孕期健康风险提示知识',
  '更年期健康管理知识','肥胖与体重管理知识','营养均衡与饮食安全知识','运动损伤初步处理知识',
  '头痛风险识别知识','眩晕晕厥风险识别知识','皮疹瘙痒风险识别知识','过敏反应急症识别知识',
  '慢病随访提醒知识','医生复查与会诊流程知识','中西医结合头痛问诊知识',
  '中西医结合胃肠不适问诊知识','中西医结合咳嗽问诊知识','中西医结合肥胖管理知识',
  '高风险问诊转人工模板','APP复诊随访模板'
)
ON DUPLICATE KEY UPDATE
  embedding_model = VALUES(embedding_model),
  vector_database = VALUES(vector_database),
  collection_name = VALUES(collection_name),
  vector_dimension = VALUES(vector_dimension);

INSERT INTO knowledge_version_item
(version_id, document_id, chunk_id, item_action, change_summary)
SELECT v.id, d.id, c.id, 'ADD', 'Large APP seed knowledge chunk'
FROM knowledge_version v
JOIN medical_knowledge_document d
JOIN medical_knowledge_chunk c ON c.document_id = d.id
WHERE v.version_no = 'kb-v1.0.0'
  AND d.title IN (
    '春季中医养生知识','夏季中医养生知识','秋季中医养生知识','冬季中医养生知识',
    '经络保健与穴位按揉知识','常见用药安全知识','抗生素使用安全知识',
    '儿童发热照护知识','儿童咳嗽与呼吸风险知识','儿童腹泻与脱水知识',
    '老年跌倒风险管理知识','老年慢病综合管理知识','女性月经健康知识','孕期健康风险提示知识',
    '更年期健康管理知识','肥胖与体重管理知识','营养均衡与饮食安全知识','运动损伤初步处理知识',
    '头痛风险识别知识','眩晕晕厥风险识别知识','皮疹瘙痒风险识别知识','过敏反应急症识别知识',
    '慢病随访提醒知识','医生复查与会诊流程知识','中西医结合头痛问诊知识',
    '中西医结合胃肠不适问诊知识','中西医结合咳嗽问诊知识','中西医结合肥胖管理知识',
    '高风险问诊转人工模板','APP复诊随访模板'
  )
  AND NOT EXISTS (
    SELECT 1 FROM knowledge_version_item vi
    WHERE vi.version_id = v.id
      AND vi.chunk_id = c.id
  );
