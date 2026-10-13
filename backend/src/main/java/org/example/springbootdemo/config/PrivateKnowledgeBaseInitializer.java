package org.example.springbootdemo.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

@Component
public class PrivateKnowledgeBaseInitializer implements CommandLineRunner {

    private final JdbcTemplate jdbcTemplate;

    public PrivateKnowledgeBaseInitializer(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) {
        createTables();
        createProductionGovernanceTables();
        seedProductionDefaults();
        if (!hasSeedData()) {
            seedCategories();
            seedDocuments();
            seedChunks();
            seedRiskRules();
        }
        seedAppKnowledge();
    }

    private void createTables() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS medical_knowledge_category (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  code VARCHAR(50) NOT NULL,
                  name VARCHAR(100) NOT NULL,
                  parent_code VARCHAR(50) NULL,
                  description VARCHAR(500) NULL,
                  sort_order INT NOT NULL DEFAULT 0,
                  enabled TINYINT NOT NULL DEFAULT 1,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  update_time TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_medical_knowledge_category_code (code),
                  INDEX idx_medical_knowledge_category_parent (parent_code),
                  INDEX idx_medical_knowledge_category_enabled (enabled)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='medical private knowledge categories'
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS medical_knowledge_document (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  category_id BIGINT NOT NULL,
                  title VARCHAR(200) NOT NULL,
                  medicine_system VARCHAR(30) NOT NULL COMMENT 'TCM, WESTERN, INTEGRATED, GENERAL',
                  source_type VARCHAR(50) NOT NULL COMMENT 'PUBLIC_GUIDELINE, PLATFORM, DOCTOR_REVIEW, INTERNAL_RULE',
                  source_name VARCHAR(200) NULL,
                  source_url VARCHAR(500) NULL,
                  author VARCHAR(100) NULL,
                  summary VARCHAR(1000) NULL,
                  tags VARCHAR(500) NULL,
                  status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  update_time TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_medical_knowledge_document_title (title),
                  INDEX idx_medical_knowledge_document_category (category_id),
                  INDEX idx_medical_knowledge_document_system (medicine_system),
                  INDEX idx_medical_knowledge_document_status (status),
                  CONSTRAINT fk_medical_knowledge_document_category
                    FOREIGN KEY (category_id) REFERENCES medical_knowledge_category(id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='medical private knowledge documents'
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS medical_knowledge_chunk (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  document_id BIGINT NOT NULL,
                  chunk_no INT NOT NULL,
                  title VARCHAR(200) NOT NULL,
                  content VARCHAR(4000) NOT NULL,
                  keywords VARCHAR(800) NULL,
                  intent_tags VARCHAR(500) NULL,
                  risk_level VARCHAR(20) NOT NULL DEFAULT 'LOW',
                  embedding_status VARCHAR(30) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING, EMBEDDED, DISABLED',
                  vector_id VARCHAR(100) NULL COMMENT 'Reserved for future vector database id',
                  sort_order INT NOT NULL DEFAULT 0,
                  enabled TINYINT NOT NULL DEFAULT 1,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  update_time TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_medical_knowledge_chunk_doc_no (document_id, chunk_no),
                  INDEX idx_medical_knowledge_chunk_enabled (enabled),
                  INDEX idx_medical_knowledge_chunk_risk (risk_level),
                  INDEX idx_medical_knowledge_chunk_vector (vector_id),
                  FULLTEXT KEY ft_medical_knowledge_chunk_text (title, content, keywords),
                  CONSTRAINT fk_medical_knowledge_chunk_document
                    FOREIGN KEY (document_id) REFERENCES medical_knowledge_document(id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='searchable medical knowledge chunks'
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS medical_risk_rule (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  rule_code VARCHAR(50) NOT NULL,
                  name VARCHAR(100) NOT NULL,
                  trigger_keywords VARCHAR(1000) NOT NULL,
                  severity VARCHAR(20) NOT NULL COMMENT 'LOW, MEDIUM, HIGH, EMERGENCY',
                  action VARCHAR(100) NOT NULL,
                  suggestion VARCHAR(1000) NOT NULL,
                  require_doctor_review TINYINT NOT NULL DEFAULT 1,
                  enabled TINYINT NOT NULL DEFAULT 1,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  update_time TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_medical_risk_rule_code (rule_code),
                  INDEX idx_medical_risk_rule_severity (severity),
                  INDEX idx_medical_risk_rule_enabled (enabled)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='medical risk warning rules'
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS medical_knowledge_search_log (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  user_id BIGINT NULL,
                  query_text VARCHAR(1000) NOT NULL,
                  matched_chunk_ids VARCHAR(1000) NULL,
                  matched_rule_codes VARCHAR(500) NULL,
                  scene VARCHAR(50) NOT NULL COMMENT 'AI_CHAT, AGENT_TRIAGE, DOCTOR_REVIEW, APP_SEARCH',
                  requester_role VARCHAR(30) NULL,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_medical_knowledge_search_user (user_id),
                  INDEX idx_medical_knowledge_search_scene (scene),
                  INDEX idx_medical_knowledge_search_time (create_time)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='knowledge retrieval logs'
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS agent_knowledge_reference (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  consultation_id BIGINT NULL,
                  health_question_id BIGINT NULL,
                  chunk_id BIGINT NOT NULL,
                  reference_scene VARCHAR(50) NOT NULL COMMENT 'AGENT_TRIAGE, AI_CHAT, DOCTOR_REVIEW',
                  relevance_score DECIMAL(6,4) NULL,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_agent_knowledge_reference_consultation (consultation_id),
                  INDEX idx_agent_knowledge_reference_question (health_question_id),
                  INDEX idx_agent_knowledge_reference_chunk (chunk_id),
                  CONSTRAINT fk_agent_knowledge_reference_chunk
                    FOREIGN KEY (chunk_id) REFERENCES medical_knowledge_chunk(id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='knowledge references used by AI or Agent'
                """);
    }

    private void createProductionGovernanceTables() {
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS knowledge_source (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  source_code VARCHAR(80) NOT NULL,
                  source_name VARCHAR(200) NOT NULL,
                  source_type VARCHAR(50) NOT NULL COMMENT 'PUBLIC_AUTHORITY, HOSPITAL_RULE, DOCTOR_REVIEW, PLATFORM_OPERATION, USER_CONSULTATION',
                  authority_level VARCHAR(30) NOT NULL DEFAULT 'MEDIUM' COMMENT 'HIGH, MEDIUM, LOW',
                  organization VARCHAR(200) NULL,
                  source_url VARCHAR(500) NULL,
                  license_note VARCHAR(500) NULL,
                  contact_person VARCHAR(100) NULL,
                  review_required TINYINT NOT NULL DEFAULT 1,
                  enabled TINYINT NOT NULL DEFAULT 1,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  update_time TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_knowledge_source_code (source_code),
                  INDEX idx_knowledge_source_type (source_type),
                  INDEX idx_knowledge_source_enabled (enabled)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='RAG knowledge source governance'
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS knowledge_review (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  document_id BIGINT NULL,
                  chunk_id BIGINT NULL,
                  reviewer_id BIGINT NOT NULL,
                  reviewer_role VARCHAR(30) NOT NULL DEFAULT 'DOCTOR',
                  review_status VARCHAR(30) NOT NULL COMMENT 'PENDING, APPROVED, REJECTED, NEED_MODIFICATION, RETIRED',
                  review_comment VARCHAR(1000) NULL,
                  safety_level VARCHAR(30) NOT NULL DEFAULT 'NORMAL' COMMENT 'NORMAL, CAUTION, HIGH_RISK, EMERGENCY_ONLY',
                  clinical_boundary VARCHAR(1000) NULL COMMENT 'Usage boundary and medical disclaimer',
                  review_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_knowledge_review_document (document_id),
                  INDEX idx_knowledge_review_chunk (chunk_id),
                  INDEX idx_knowledge_review_status (review_status),
                  INDEX idx_knowledge_review_reviewer (reviewer_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Doctor or expert review records for RAG knowledge'
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS knowledge_version (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  version_no VARCHAR(50) NOT NULL,
                  version_name VARCHAR(100) NOT NULL,
                  description VARCHAR(1000) NULL,
                  release_status VARCHAR(30) NOT NULL DEFAULT 'DRAFT' COMMENT 'DRAFT, REVIEWING, RELEASED, ROLLED_BACK, RETIRED',
                  release_time TIMESTAMP NULL,
                  rollback_from_version VARCHAR(50) NULL,
                  created_by BIGINT NULL,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_knowledge_version_no (version_no),
                  INDEX idx_knowledge_version_status (release_status)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='RAG knowledge base release versions'
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS knowledge_version_item (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  version_id BIGINT NOT NULL,
                  document_id BIGINT NULL,
                  chunk_id BIGINT NULL,
                  item_action VARCHAR(30) NOT NULL COMMENT 'ADD, UPDATE, DELETE, RETAIN',
                  change_summary VARCHAR(1000) NULL,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_knowledge_version_item_version (version_id),
                  INDEX idx_knowledge_version_item_document (document_id),
                  INDEX idx_knowledge_version_item_chunk (chunk_id),
                  CONSTRAINT fk_knowledge_version_item_version
                    FOREIGN KEY (version_id) REFERENCES knowledge_version(id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Knowledge items included in a release version'
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS knowledge_import_task (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  task_no VARCHAR(80) NOT NULL,
                  source_id BIGINT NULL,
                  import_type VARCHAR(50) NOT NULL COMMENT 'MARKDOWN, PDF, DOCX, EXCEL, WEB_PAGE, MANUAL',
                  file_name VARCHAR(255) NULL,
                  file_path VARCHAR(500) NULL,
                  original_url VARCHAR(500) NULL,
                  task_status VARCHAR(30) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING, PARSING, CHUNKING, REVIEWING, COMPLETED, FAILED',
                  total_document_count INT NOT NULL DEFAULT 0,
                  total_chunk_count INT NOT NULL DEFAULT 0,
                  success_count INT NOT NULL DEFAULT 0,
                  fail_count INT NOT NULL DEFAULT 0,
                  error_message VARCHAR(1000) NULL,
                  created_by BIGINT NULL,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  update_time TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_knowledge_import_task_no (task_no),
                  INDEX idx_knowledge_import_task_source (source_id),
                  INDEX idx_knowledge_import_task_status (task_status),
                  CONSTRAINT fk_knowledge_import_task_source
                    FOREIGN KEY (source_id) REFERENCES knowledge_source(id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='RAG knowledge import and cleaning tasks'
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS knowledge_embedding_task (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  task_no VARCHAR(80) NOT NULL,
                  chunk_id BIGINT NOT NULL,
                  embedding_provider VARCHAR(50) NOT NULL DEFAULT 'LOCAL',
                  embedding_model VARCHAR(100) NOT NULL,
                  vector_database VARCHAR(50) NOT NULL DEFAULT 'MILVUS',
                  collection_name VARCHAR(100) NOT NULL,
                  vector_id VARCHAR(100) NULL,
                  vector_dimension INT NOT NULL,
                  task_status VARCHAR(30) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING, RUNNING, SUCCESS, FAILED, RETRYING',
                  retry_count INT NOT NULL DEFAULT 0,
                  error_message VARCHAR(1000) NULL,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  update_time TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_knowledge_embedding_task_no (task_no),
                  INDEX idx_knowledge_embedding_task_chunk (chunk_id),
                  INDEX idx_knowledge_embedding_task_status (task_status),
                  INDEX idx_knowledge_embedding_task_vector (vector_database, collection_name, vector_id),
                  CONSTRAINT fk_knowledge_embedding_task_chunk
                    FOREIGN KEY (chunk_id) REFERENCES medical_knowledge_chunk(id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Embedding generation tasks for Milvus or other vector databases'
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS knowledge_feedback (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  chunk_id BIGINT NULL,
                  retrieval_log_id BIGINT NULL,
                  user_id BIGINT NULL,
                  doctor_id BIGINT NULL,
                  feedback_type VARCHAR(50) NOT NULL COMMENT 'HELPFUL, NOT_HELPFUL, UNSAFE, OUTDATED, WRONG, NEED_MORE_DETAIL',
                  feedback_content VARCHAR(1000) NULL,
                  process_status VARCHAR(30) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING, ACCEPTED, REJECTED, FIXED',
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  update_time TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                  INDEX idx_knowledge_feedback_chunk (chunk_id),
                  INDEX idx_knowledge_feedback_log (retrieval_log_id),
                  INDEX idx_knowledge_feedback_status (process_status)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='User and doctor feedback for knowledge quality improvement'
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS knowledge_quality_score (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  chunk_id BIGINT NOT NULL,
                  accuracy_score DECIMAL(5,2) NOT NULL DEFAULT 0,
                  safety_score DECIMAL(5,2) NOT NULL DEFAULT 0,
                  freshness_score DECIMAL(5,2) NOT NULL DEFAULT 0,
                  usage_count INT NOT NULL DEFAULT 0,
                  positive_feedback_count INT NOT NULL DEFAULT 0,
                  negative_feedback_count INT NOT NULL DEFAULT 0,
                  last_review_time TIMESTAMP NULL,
                  last_used_time TIMESTAMP NULL,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  update_time TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
                  UNIQUE KEY uk_knowledge_quality_score_chunk (chunk_id),
                  CONSTRAINT fk_knowledge_quality_score_chunk
                    FOREIGN KEY (chunk_id) REFERENCES medical_knowledge_chunk(id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Knowledge chunk quality score and usage metrics'
                """);
        jdbcTemplate.execute("""
                CREATE TABLE IF NOT EXISTS rag_retrieval_result (
                  id BIGINT PRIMARY KEY AUTO_INCREMENT,
                  search_log_id BIGINT NOT NULL,
                  chunk_id BIGINT NOT NULL,
                  retrieval_type VARCHAR(30) NOT NULL COMMENT 'KEYWORD, VECTOR, HYBRID, RISK_RULE, RERANK',
                  keyword_score DECIMAL(8,4) NULL,
                  vector_score DECIMAL(8,4) NULL,
                  rerank_score DECIMAL(8,4) NULL,
                  final_score DECIMAL(8,4) NULL,
                  rank_no INT NOT NULL,
                  used_in_answer TINYINT NOT NULL DEFAULT 0,
                  create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  INDEX idx_rag_retrieval_result_log (search_log_id),
                  INDEX idx_rag_retrieval_result_chunk (chunk_id),
                  INDEX idx_rag_retrieval_result_rank (search_log_id, rank_no),
                  CONSTRAINT fk_rag_retrieval_result_chunk
                    FOREIGN KEY (chunk_id) REFERENCES medical_knowledge_chunk(id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Detailed retrieval hit records for RAG explainability'
                """);
    }

    private void seedProductionDefaults() {
        for (Object[] source : SeedData.SOURCES) {
            jdbcTemplate.update(
                    """
                            INSERT INTO knowledge_source
                            (source_code, source_name, source_type, authority_level, organization, source_url, license_note, review_required)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                            ON DUPLICATE KEY UPDATE
                              source_name = VALUES(source_name),
                              source_type = VALUES(source_type),
                              authority_level = VALUES(authority_level),
                              organization = VALUES(organization),
                              source_url = VALUES(source_url),
                              license_note = VALUES(license_note),
                              review_required = VALUES(review_required),
                              enabled = 1
                            """,
                    source
            );
        }
        jdbcTemplate.update(
                """
                        INSERT INTO knowledge_version
                        (version_no, version_name, description, release_status)
                        VALUES (?, ?, ?, ?)
                        ON DUPLICATE KEY UPDATE
                          version_name = VALUES(version_name),
                          description = VALUES(description)
                        """,
                "kb-v1.0.0",
                "APP上线知识库初始版本",
                "生产级RAG知识库的初始版本，包含知识治理表、风险规则、审核流程和向量库预留字段。",
                "DRAFT"
        );
    }

    private void seedAppKnowledge() {
        executeSqlResource("db/rag-app-launch-seed-data.sql");
        executeSqlResource("db/rag-app-large-seed-data.sql");
    }

    private void executeSqlResource(String resourcePath) {
        ClassPathResource resource = new ClassPathResource(resourcePath);
        try {
            String sql = new String(resource.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
            for (String statement : sql.split(";")) {
                String trimmed = removeSqlComments(statement).trim();
                if (!trimmed.isEmpty()) {
                    jdbcTemplate.execute(trimmed);
                }
            }
        } catch (IOException exception) {
            throw new IllegalStateException("failed to load RAG seed data: " + resourcePath, exception);
        }
    }

    private String removeSqlComments(String statement) {
        StringBuilder builder = new StringBuilder();
        for (String line : statement.split("\\R")) {
            String trimmed = line.trim();
            if (!trimmed.startsWith("--")) {
                builder.append(line).append(System.lineSeparator());
            }
        }
        return builder.toString();
    }

    private boolean hasSeedData() {
        Integer count = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM medical_knowledge_category", Integer.class);
        return count != null && count > 0;
    }

    private void seedCategories() {
        for (Object[] category : SeedData.CATEGORIES) {
            jdbcTemplate.update(
                    """
                            INSERT INTO medical_knowledge_category
                            (code, name, parent_code, description, sort_order)
                            VALUES (?, ?, ?, ?, ?)
                            ON DUPLICATE KEY UPDATE
                              name = VALUES(name),
                              parent_code = VALUES(parent_code),
                              description = VALUES(description),
                              sort_order = VALUES(sort_order),
                              enabled = 1
                            """,
                    category
            );
        }
    }

    private void seedDocuments() {
        insertDocument(
                "TCM_CONSTITUTION",
                "中医体质与日常养生基础",
                "TCM",
                "PLATFORM",
                "平台私域整理",
                null,
                "system",
                "用于解释体质辨识、饮食起居和情志调养，不作为疾病诊断结论。",
                "中医,体质,养生,饮食,起居"
        );
        insertDocument(
                "WESTERN_SYMPTOM",
                "常见症状西医风险识别",
                "WESTERN",
                "PUBLIC_GUIDELINE",
                "CDC/AHA/NHLBI公开健康资料",
                "https://www.cdc.gov/stroke/signs-symptoms/index.html",
                "system",
                "用于识别胸痛、卒中、呼吸困难、高热等需要及时就医的危险信号。",
                "症状,风险,急症,卒中,胸痛"
        );
        insertDocument(
                "INTEGRATED",
                "中西医结合健康问诊规则",
                "INTEGRATED",
                "INTERNAL_RULE",
                "系统预问诊规则",
                null,
                "system",
                "用于把用户症状整理为中医调理方向、西医风险判断和医生审核要点。",
                "中西医结合,预问诊,Agent,医生审核"
        );
        insertDocument(
                "WELLNESS",
                "生活方式健康管理基础",
                "GENERAL",
                "PUBLIC_GUIDELINE",
                "WHO健康饮食资料",
                "https://www.who.int/news-room/fact-sheets/detail/healthy-diet",
                "system",
                "用于提供饮食、运动、睡眠等基础健康管理建议。",
                "饮食,运动,睡眠,生活方式"
        );
    }

    private void seedChunks() {
        insertChunk("中医体质与日常养生基础", 1, "中医体质辨识的使用边界",
                "中医体质辨识适合用于健康管理和生活方式建议，例如饮食偏好、作息规律、运动强度和情志调养。系统在使用体质结果时，应提示用户这不是疾病诊断，不能替代医生面诊、检查和处方。",
                "中医体质,体质辨识,健康管理,不是诊断,医生面诊", "constitution,wellness,disclaimer", "LOW", 1);
        insertChunk("中医体质与日常养生基础", 2, "气虚与疲劳的养生提示",
                "如果用户长期疲劳、气短、容易出汗，可以从作息、饮食和运动方面进行温和调理，例如保证睡眠、避免过度劳累、选择散步或八段锦等低强度活动。若疲劳突然加重，或伴随胸痛、呼吸困难、黑便、明显消瘦等情况，应优先建议就医。",
                "疲劳,气虚,气短,出汗,八段锦,就医", "fatigue,tcm,warning", "MEDIUM", 2);
        insertChunk("中医体质与日常养生基础", 3, "阴虚与睡眠问题的养生提示",
                "如果用户描述入睡困难、心烦、口干、夜间出汗等情况，可以提示保持规律作息，减少睡前刺激性饮品，避免熬夜，并记录睡眠持续时间和伴随症状。若出现明显焦虑抑郁、自伤想法、持续严重失眠，应建议寻求专业帮助。",
                "失眠,阴虚,心烦,口干,盗汗,睡眠,焦虑", "sleep,tcm,mental_health", "MEDIUM", 3);
        insertChunk("常见症状西医风险识别", 1, "胸痛和心梗危险信号",
                "如果用户出现胸部压榨样疼痛、胸闷，或疼痛放射到手臂、背部、颈部、下颌、上腹，并伴随气短、冷汗、恶心、头晕、明显乏力等表现，应按高危情况处理，建议立即拨打急救电话或前往急诊。系统不能把此类问题只当作普通养生咨询。",
                "胸痛,胸闷,心梗,气短,冷汗,恶心,头晕,急诊,急救", "chest_pain,emergency,western", "EMERGENCY", 1);
        insertChunk("常见症状西医风险识别", 2, "卒中危险信号",
                "如果用户突然出现一侧面部、手臂或腿无力或麻木，突然说话不清、理解困难，突然视物异常，突然行走不稳、眩晕、失去平衡，或突发原因不明的剧烈头痛，应按卒中危险信号处理，建议立即急救，不要自行开车等待。",
                "卒中,中风,口角歪斜,一侧无力,说话不清,视物异常,眩晕,剧烈头痛,急救", "stroke,emergency,western", "EMERGENCY", 2);
        insertChunk("常见症状西医风险识别", 3, "血压异常的处理边界",
                "血压管理需要结合多次测量、既往病史和医生建议。若用户血压明显升高并伴随胸痛、呼吸困难、神经功能异常、意识改变、剧烈头痛等症状，应按紧急情况处理。普通血压偏高可以建议记录血压、减少高盐饮食、规律运动并咨询医生。",
                "高血压,血压异常,胸痛,呼吸困难,剧烈头痛,限盐,运动", "blood_pressure,chronic,warning", "HIGH", 3);
        insertChunk("中西医结合健康问诊规则", 1, "中西医结合问诊输出原则",
                "Agent可以把用户症状整理为三个层次：第一是症状摘要和持续时间；第二是西医风险识别，例如是否存在急症信号；第三是中医养生角度，例如体质、作息、饮食和情志因素。Agent输出只能作为预问诊材料，必须交给医生审核后才能发送给患者。",
                "Agent,预问诊,中西医结合,医生审核,风险识别,症状摘要", "agent_triage,doctor_review,integrated", "LOW", 1);
        insertChunk("中西医结合健康问诊规则", 2, "问诊需要补充的信息",
                "当用户只描述一个笼统症状时，系统应补充询问开始时间、持续时间、严重程度、诱因、缓解因素、伴随症状、既往病史、用药史、过敏史和是否已经线下就医。缺少关键信息时，不应直接给出确定结论。",
                "问诊,补充信息,持续时间,严重程度,诱因,伴随症状,用药史,过敏史", "agent_question,symptom_extract", "LOW", 2);
        insertChunk("生活方式健康管理基础", 1, "健康饮食的基本原则",
                "健康饮食应强调充足、均衡、适度和多样化。日常建议以未深加工或少加工食物为主，控制过多盐、糖和不健康脂肪摄入，注意饮食安全。对慢病用户，饮食建议应结合医生或营养师意见。",
                "健康饮食,均衡,多样化,少盐,少糖,慢病,营养", "diet,wellness,chronic", "LOW", 1);
        insertChunk("生活方式健康管理基础", 2, "运动建议的安全边界",
                "一般健康管理可建议循序渐进地增加身体活动，例如散步、拉伸、太极、八段锦或轻中等强度有氧运动。若运动时出现胸痛、明显气短、晕厥、心悸或异常乏力，应停止运动并及时就医。",
                "运动,散步,太极,八段锦,有氧运动,胸痛,心悸,晕厥", "exercise,wellness,warning", "MEDIUM", 2);
    }

    private void seedRiskRules() {
        for (Object[] rule : SeedData.RISK_RULES) {
            jdbcTemplate.update(
                    """
                            INSERT INTO medical_risk_rule
                            (rule_code, name, trigger_keywords, severity, action, suggestion, require_doctor_review)
                            VALUES (?, ?, ?, ?, ?, ?, ?)
                            ON DUPLICATE KEY UPDATE
                              name = VALUES(name),
                              trigger_keywords = VALUES(trigger_keywords),
                              severity = VALUES(severity),
                              action = VALUES(action),
                              suggestion = VALUES(suggestion),
                              require_doctor_review = VALUES(require_doctor_review),
                              enabled = 1
                            """,
                    rule
            );
        }
    }

    private void insertDocument(
            String categoryCode,
            String title,
            String medicineSystem,
            String sourceType,
            String sourceName,
            String sourceUrl,
            String author,
            String summary,
            String tags
    ) {
        jdbcTemplate.update(
                """
                        INSERT INTO medical_knowledge_document
                        (category_id, title, medicine_system, source_type, source_name, source_url, author, summary, tags)
                        SELECT id, ?, ?, ?, ?, ?, ?, ?, ?
                        FROM medical_knowledge_category
                        WHERE code = ?
                        ON DUPLICATE KEY UPDATE
                          medicine_system = VALUES(medicine_system),
                          source_type = VALUES(source_type),
                          source_name = VALUES(source_name),
                          source_url = VALUES(source_url),
                          author = VALUES(author),
                          summary = VALUES(summary),
                          tags = VALUES(tags),
                          status = 'ACTIVE'
                        """,
                title, medicineSystem, sourceType, sourceName, sourceUrl, author, summary, tags, categoryCode
        );
    }

    private void insertChunk(
            String documentTitle,
            int chunkNo,
            String title,
            String content,
            String keywords,
            String intentTags,
            String riskLevel,
            int sortOrder
    ) {
        jdbcTemplate.update(
                """
                        INSERT INTO medical_knowledge_chunk
                        (document_id, chunk_no, title, content, keywords, intent_tags, risk_level, sort_order)
                        SELECT id, ?, ?, ?, ?, ?, ?, ?
                        FROM medical_knowledge_document
                        WHERE title = ?
                        ON DUPLICATE KEY UPDATE
                          title = VALUES(title),
                          content = VALUES(content),
                          keywords = VALUES(keywords),
                          intent_tags = VALUES(intent_tags),
                          risk_level = VALUES(risk_level),
                          sort_order = VALUES(sort_order),
                          enabled = 1
                        """,
                chunkNo, title, content, keywords, intentTags, riskLevel, sortOrder, documentTitle
        );
    }

    private static final class SeedData {
        private static final Object[][] SOURCES = {
                {"PLATFORM_TCM_INTERNAL", "平台中医养生内部知识", "PLATFORM_OPERATION", "MEDIUM", "Yangsheng APP", null, "平台整理，医生审核后上线", 1},
                {"PUBLIC_WHO_HEALTH", "WHO公开健康资料", "PUBLIC_AUTHORITY", "HIGH", "World Health Organization", "https://www.who.int/", "公开资料，仅保存摘要和来源链接", 1},
                {"PUBLIC_CDC_HEALTH", "CDC公开健康资料", "PUBLIC_AUTHORITY", "HIGH", "Centers for Disease Control and Prevention", "https://www.cdc.gov/", "公开资料，仅保存摘要和来源链接", 1},
                {"DOCTOR_REVIEWED_QA", "医生审核后的问答沉淀", "DOCTOR_REVIEW", "HIGH", "Yangsheng APP Doctor Team", null, "平台业务沉淀，需脱敏和医生审核", 1}
        };

        private static final Object[][] CATEGORIES = {
                {"TCM", "中医知识", null, "体质、脏腑、饮食、起居、情志、节气养生等中医知识", 10},
                {"WESTERN", "西医知识", null, "常见症状、慢病管理、用药提醒、急症识别等现代医学知识", 20},
                {"INTEGRATED", "中西医结合", null, "同一健康问题下的中医调理思路和西医风险识别", 30},
                {"WELLNESS", "健康管理", null, "饮食、运动、睡眠、心理、生活方式管理", 40},
                {"RISK_WARNING", "风险预警", null, "胸痛、卒中、高热、血压异常等需要优先处理的风险规则", 50},
                {"APP_AGENT", "APP Agent问诊", null, "预问诊、医生审核、会诊和可追溯引用相关知识", 60},
                {"TCM_CONSTITUTION", "中医体质", "TCM", "平和质、气虚质、阳虚质、阴虚质、痰湿质等体质知识", 11},
                {"TCM_SLEEP", "中医睡眠调理", "TCM", "失眠、多梦、疲劳相关的中医养生知识", 12},
                {"WESTERN_SYMPTOM", "西医症状识别", "WESTERN", "症状危险信号和就医建议", 21},
                {"WESTERN_CHRONIC", "慢病管理", "WESTERN", "高血压、糖尿病、血脂异常、肥胖等慢病管理", 22}
        };

        private static final Object[][] RISK_RULES = {
                {"CHEST_PAIN_EMERGENCY", "胸痛急症预警", "胸痛,胸闷,压榨感,冷汗,气短,左臂痛,下颌痛,恶心,头晕", "EMERGENCY", "CALL_EMERGENCY", "提示用户可能存在心血管急症风险，应立即拨打急救电话或前往急诊，并将该记录置为医生优先审核。", 1},
                {"STROKE_EMERGENCY", "卒中急症预警", "口角歪斜,一侧无力,说话不清,突然头痛,突然眩晕,视物异常,走路不稳,中风,卒中", "EMERGENCY", "CALL_EMERGENCY", "提示用户可能存在卒中风险，应立即急救，不要自行等待症状消失。", 1},
                {"BREATHING_EMERGENCY", "呼吸困难预警", "呼吸困难,喘不上气,憋气,嘴唇发紫,胸闷气短,氧饱和度低", "EMERGENCY", "CALL_EMERGENCY", "提示用户呼吸异常属于高危信号，应及时急诊处理。", 1},
                {"HIGH_FEVER_WARNING", "高热预警", "高烧,高热,体温39,体温40,持续发热,抽搐,意识模糊", "HIGH", "DOCTOR_PRIORITY", "提示用户持续高热或伴随抽搐、意识异常时需要及时就医，并建议医生优先审核。", 1},
                {"BLOOD_PRESSURE_WARNING", "血压异常预警", "血压很高,高血压,收缩压180,舒张压120,剧烈头痛,胸痛,视物模糊", "HIGH", "DOCTOR_PRIORITY", "提示用户血压明显异常且伴随症状时需要急诊或医生尽快评估。", 1},
                {"MENTAL_HEALTH_WARNING", "心理风险预警", "想死,自杀,自伤,活不下去,伤害自己,严重焦虑,严重抑郁", "EMERGENCY", "CRISIS_SUPPORT", "提示用户心理危机需要立即联系家属、医生或当地危机干预服务，系统应触发人工审核。", 1}
        };
    }
}
