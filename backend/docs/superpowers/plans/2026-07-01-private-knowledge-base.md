# Private Knowledge Base Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first local private medical knowledge database for the health assistant system without depending on an external LLM or vector database.

**Architecture:** Store medical knowledge categories, documents, searchable chunks, risk rules, and search logs in MySQL. Seed a first set of TCM, western medicine, integrated medicine, chronic disease, emergency warning, and wellness knowledge at Spring Boot startup, while also providing a standalone SQL script for manual import.

**Tech Stack:** Spring Boot 3.3.6, Java 17, MySQL, JdbcTemplate, Markdown documentation.

---

### Task 1: Database Schema Script

**Files:**
- Create: `D:\SpringBoot\SpringBootDemo\src\main\resources\db\rag-private-knowledge-base.sql`

- [x] **Step 1: Create tables**

Create SQL for:
- `medical_knowledge_category`
- `medical_knowledge_document`
- `medical_knowledge_chunk`
- `medical_risk_rule`
- `medical_knowledge_search_log`

- [x] **Step 2: Add seed knowledge**

Insert first-version knowledge covering TCM, western medicine, integrated medicine, symptoms, chronic disease, emergency warnings, diet, sleep, exercise, and APP consultation.

### Task 2: Runtime Initializer

**Files:**
- Create: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\config\PrivateKnowledgeBaseInitializer.java`

- [x] **Step 1: Create tables on startup**

Use `JdbcTemplate.execute(...)` to create all private knowledge tables if they do not exist.

- [x] **Step 2: Seed only when empty**

Use `select count(*)` on `medical_knowledge_category` and skip inserts when data already exists.

### Task 3: Documentation

**Files:**
- Create: `D:\SpringBoot\SpringBootDemo\docs\rag-private-knowledge-base.md`

- [x] **Step 1: Explain implementation**

Document what was built, where files are located, which tables were created, how first-version retrieval works, and how to answer defense questions.

### Task 4: Verification

**Files:**
- Run: `mvn test`

- [ ] **Step 1: Run backend tests**

Run `mvn test` from `D:\SpringBoot\SpringBootDemo`.

- [ ] **Step 2: Report result**

Tell the user whether tests passed and list created files.
