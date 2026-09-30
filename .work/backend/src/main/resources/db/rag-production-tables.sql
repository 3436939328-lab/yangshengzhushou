-- Production-grade RAG governance tables for APP launch.
-- Run after rag-private-knowledge-base.sql.
-- These tables do not replace the first-version knowledge tables.
-- They add source governance, medical review, versioning, import tasks,
-- embedding tasks, quality feedback, and detailed retrieval trace records.

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='RAG knowledge source governance';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Doctor or expert review records for RAG knowledge';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='RAG knowledge base release versions';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Knowledge items included in a release version';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='RAG knowledge import and cleaning tasks';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Embedding generation tasks for Milvus or other vector databases';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='User and doctor feedback for knowledge quality improvement';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Knowledge chunk quality score and usage metrics';

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Detailed retrieval hit records for RAG explainability';

INSERT INTO knowledge_source
(source_code, source_name, source_type, authority_level, organization, source_url, license_note, review_required)
VALUES
('PLATFORM_TCM_INTERNAL', '平台中医养生内部知识', 'PLATFORM_OPERATION', 'MEDIUM', 'Yangsheng APP', NULL, '平台整理，医生审核后上线', 1),
('PUBLIC_WHO_HEALTH', 'WHO公开健康资料', 'PUBLIC_AUTHORITY', 'HIGH', 'World Health Organization', 'https://www.who.int/', '公开资料，仅保存摘要和来源链接', 1),
('PUBLIC_CDC_HEALTH', 'CDC公开健康资料', 'PUBLIC_AUTHORITY', 'HIGH', 'Centers for Disease Control and Prevention', 'https://www.cdc.gov/', '公开资料，仅保存摘要和来源链接', 1),
('DOCTOR_REVIEWED_QA', '医生审核后的问答沉淀', 'DOCTOR_REVIEW', 'HIGH', 'Yangsheng APP Doctor Team', NULL, '平台业务沉淀，需脱敏和医生审核', 1)
ON DUPLICATE KEY UPDATE
  source_name = VALUES(source_name),
  source_type = VALUES(source_type),
  authority_level = VALUES(authority_level),
  organization = VALUES(organization),
  source_url = VALUES(source_url),
  license_note = VALUES(license_note),
  review_required = VALUES(review_required),
  enabled = 1;

INSERT INTO knowledge_version
(version_no, version_name, description, release_status)
VALUES
('kb-v1.0.0', 'APP上线知识库初始版本', '生产级RAG知识库的初始版本，包含知识治理表、风险规则、审核流程和向量库预留字段。', 'DRAFT')
ON DUPLICATE KEY UPDATE
  version_name = VALUES(version_name),
  description = VALUES(description);
