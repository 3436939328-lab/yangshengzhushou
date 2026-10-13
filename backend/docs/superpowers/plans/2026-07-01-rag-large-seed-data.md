# RAG Large Seed Data Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a much larger APP-oriented private medical knowledge seed dataset so RAG tables are useful after Spring Boot startup.

**Architecture:** Add a separate idempotent SQL seed file and call it from `PrivateKnowledgeBaseInitializer`. The SQL writes categories, sources, documents, chunks, doctor review records, quality scores, embedding tasks, and version items.

**Tech Stack:** Spring Boot, Java 17, MySQL, JdbcTemplate, SQL seed scripts.

---

### Task 1: Add Large Seed SQL

**Files:**
- Create: `D:\SpringBoot\SpringBootDemo\src\main\resources\db\rag-app-large-seed-data.sql`

- [x] **Step 1: Add more sources and categories**

Add APP launch categories for pediatrics, elderly health, women's health, medication safety, exercise injury, nutrition, TCM seasons, headache, dizziness, cough, obesity, and follow-up care.

- [x] **Step 2: Add many documents and chunks**

Add 30+ documents and 120+ chunks, using safe health-management wording and risk boundaries.

- [x] **Step 3: Add review, quality, embedding, and version records**

For all new chunks, insert approved review records, quality scores, pending embedding tasks, and version items.

### Task 2: Wire Startup Import

**Files:**
- Modify: `D:\SpringBoot\SpringBootDemo\src\main\java\org\example\springbootdemo\config\PrivateKnowledgeBaseInitializer.java`
- Modify: `D:\SpringBoot\SpringBootDemo\src\test\java\org\example\springbootdemo\config\PrivateKnowledgeBaseInitializerTest.java`

- [x] **Step 1: Execute the new SQL file**

Call the large seed file after the existing launch seed file.

- [x] **Step 2: Update tests**

Verify the initializer executes the new large seed file.

### Task 3: Verify

**Files:**
- Run: `mvn test`

- [x] **Step 1: Run backend tests**

Run all tests and confirm build success.
