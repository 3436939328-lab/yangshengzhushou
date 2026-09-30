# Unified APP + PC + Backend Convergence Design

## 2026-06-25 Implementation Status

This implementation starts the convergence in a narrow, reversible way:

1. Spring Boot now exposes APP-compatible AI endpoints:
   - `POST /api/ai/chat`
   - `POST /api/assistant/chat`
   - `POST /api/ai/suggestions`
   - `POST /api/suggestions/scene`
2. Spring Boot calls the existing Node.js orchestration service internally through `NODE_AI_BASE_URL`.
3. PC `HealthQuestionAiService` now delegates to the same assistant bridge, so APP and PC share one AI path.
4. HarmonyOS APP AI chat and scene suggestions now target Spring Boot `8181` with `Authorization: Bearer <token>`.
5. Weather remains on Node `8787` for this phase and should be migrated in the next phase.
6. Node's `LLM / Prompt / LangGraph` code remains a protected AI asset, not deleted or rewritten yet.

Rollout checklist:

1. Start Node orchestration on `8787`.
2. Start Spring Boot on `8181`.
3. Log in from APP to get a Spring Boot token.
4. Send one APP assistant chat message and confirm it reaches Spring Boot `/api/ai/chat`.
5. Confirm Spring Boot can call Node `/api/ai/chat`.
6. Open PC health question flow and confirm it still returns an answer.
7. After this is stable, plan the weather migration from Node to Spring Boot.

## Goal

本技术路线面向四个现有资产：

- HarmonyOS APP：`D:\yangshengzhushou`
- Node 原型后端：`D:\yangshengzhushou\yangshengzhushou_db`
- Spring Boot 主业务后端：`D:\SpringBoot\SpringBootDemo`
- Vue PC 端：`D:\SpringBoot\SpringBootVue\Sprintvue`

最终目标不是长期维护两个后端，而是把两个后端二合一，形成一个统一主后端，同时完整支撑：

1. HarmonyOS APP 的全部功能。
2. PC 端的全部功能。
3. 普通用户、医生、管理员三种角色。
4. 一对一问诊、养生助手问答、健康档案、人员管理等共享业务。

最终交付形态应为：

- 一个统一后端。
- 一个移动端 APP。
- 一个 PC Web 端。
- 三者共享同一套业务模型、权限模型、接口契约和主数据。

## Current Asset Inventory

## 1. HarmonyOS APP Current State

APP 前端主入口位于：

- `D:\yangshengzhushou\entry\src\main\ets\pages\Index.ets`

当前 APP 的特点：

- 已有登录、引导、首页、AI 助手、数据、我的等主要页面。
- 本地健康档案和聊天记录仍大量保存在 Preferences。
- 当前接口配置是“双后端并存”：
  - `baseUrl = http://172.20.10.10:8787`
  - `authBaseUrl = http://172.20.10.10:8181`
- 也就是说，APP 当前已经天然拆成：
  - Node 后端负责天气、AI 聊天、建议。
  - Spring Boot 后端负责注册、登录。

这说明 APP 现在虽然能跑，但后端边界是分裂的，不适合长期扩展。

## 2. Node Backend Current State

Node 后端路径：

- `D:\yangshengzhushou\yangshengzhushou_db`

当前 Node 后端已具备：

- `/api/weather/current`
- `/api/health`
- `/api/auth/register`
- `/api/auth/login`
- `/api/ai/chat`
- `/api/ai/suggestions`
- LLM 配置与调用封装
- Prompt 拼装
- LangGraph 工作流编排
- 规则兜底与风险识别

当前 Node 后端特点：

- 技术栈轻量，基于 Node.js `http`。
- 用户数据默认落在 JSON 文件。
- AI 能力包含规则兜底、天气感知建议、DeepSeek 调用。
- 已经沉淀了 `LLM + Prompt + LangGraph` 的 AI 编排逻辑。
- 更像“AI 编排原型服务 + 天气能力层”，不是完整业务中台。

它的优势：

- AI、天气、规则建议已能快速跑通。
- LangGraph 工作流已经把“记忆构建、风险检测、安全兜底、LLM 回复、计划生成”串起来了。
- Prompt 已经包含天气、档案、历史对话等上下文拼装逻辑。
- 代码轻，适合验证交互。

它的短板：

- 缺少完整的角色、关系型数据、后台治理能力。
- 不适合承接复杂的人员管理、问诊管理、共享档案管理。
- 如果直接丢弃，会损失已经验证过的 AI 编排资产。

## 3. Spring Boot Backend Current State

Spring Boot 后端路径：

- `D:\SpringBoot\SpringBootDemo`

当前 Spring Boot 后端已具备的业务域明显更完整：

- `AuthController`
- `UserController`
- `RoleController`
- `UserRoleController`
- `HealthArchiveController`
- `DoctorProfileController`
- `ConsultationController`
- `ConsultationMessageController`
- `HealthQuestionController`

同时还具备：

- MyBatis + MySQL
- `TokenStore`
- `AuthInterceptor`
- `PermissionService`
- `HealthQuestionAiService`

这意味着 Spring Boot 后端已经具备成为“统一主后端”的基础。

它的优势：

- 数据建模比 Node 端成熟。
- 已有用户、角色、医生资料、问诊、健康档案。
- 已有权限校验和拦截器体系。
- 已对 PC 端做了 CORS 放行，说明方向就是走统一业务后端。

它的短板：

- 当前 token 仍是内存 `TokenStore`，不适合正式多端会话。
- AI 问答模型仍偏简化。
- 还没吸收 Node 端的天气和场景建议能力。
- 还没有完全覆盖 APP 的提醒、计划、天气、数据总览等全部功能。

## 4. PC Frontend Current State

PC 端路径：

- `D:\SpringBoot\SpringBootVue\Sprintvue`

当前 PC 端技术栈：

- Vue 3
- Vite

当前 PC 端现状：

- `src\App.vue` 已经堆了很多业务原型。
- 已包含角色化导航、用户管理、健康档案、养生助手问答、一对一问诊、医生资料等模块雏形。
- `src\api.mjs` 已经直接指向 `http://localhost:8181/api`。
- 但页面仍混合了大量本地 mock 数据和部分真实接口联调逻辑。

结论很清楚：

- PC 端不是从零开始。
- 但它还不是一个结构化、可维护的正式前端。
- 它需要从“单文件原型控制台”演进成“标准 Vue 多页面系统”。

## Core Problem Statement

当前系统不是“一个平台”，而是“三段式拼接”：

1. APP 用双后端。
2. Node 后端偏 AI 原型。
3. Spring Boot 后端偏业务原型。
4. PC 端已朝 Spring Boot 对齐，但仍大量依赖 mock。

如果继续这样发展，会出现四类问题：

## 1. 接口分裂

- APP 既要连 8787，又要连 8181。
- PC 只连 8181。
- 后续每加一个功能，都要决定“放哪一个后端”，维护成本会越来越高。

## 2. 数据主源不统一

- APP 仍有大量本地数据。
- Node 端走 JSON 文件。
- Spring Boot 端走 MySQL。

这会导致：

- 管理员看不到 APP 本地数据。
- PC 与 APP 数据无法天然一致。
- 问诊、问答、档案无法形成统一审计链路。

## 3. 角色模型不统一

当前角色实际上存在两套叫法：

- APP 设计语义：`user / doctor / admin`
- Spring Boot 当前语义：`USER / ADVISER / ADMIN`

如果不统一，APP、PC、后端三处会长期出现映射分叉。

## 4. 平台边界不清晰

- Node 更像能力原型。
- Spring Boot 更像业务主干。
- PC 更像后台原型。
- APP 更像移动端产品原型。

这不是坏事，但必须尽快收敛，否则后面每次改动都要跨四处同步。

## Recommended Convergence Options

建议先明确三种可选路线。

## Option A: Spring Boot 作为统一主后端入口，吸收或托管 Node AI 能力

做法：

- 以 `SpringBootDemo` 为统一业务中台。
- 将 Node 后端里的天气、AI 聊天、场景建议能力统一纳入 Spring Boot 主架构。
- Node 中已经存在的 `LLM / Prompt / LangGraph` 编排逻辑，先保留其能力边界，再决定是“嵌入式托管”还是“完全迁移”。
- 迁移完成后，APP 和 PC 都只调用 Spring Boot。
- Node 保留为参考实现或内部实验仓，不再对客户端直接暴露。

优点：

- 最符合当前现状。
- Spring Boot 已经有用户、角色、问诊、档案、权限体系。
- PC 端本来就已经连到 Spring Boot。
- 统一成本最低，长期可维护性最好。
- 不会粗暴抛弃已经写好的 LangGraph、Prompt、LLM 能力。

缺点：

- 需要额外设计 AI 编排能力如何并入 Spring Boot 主架构。

## Option B: 长期保留双后端，前面加网关

做法：

- Spring Boot 承接业务域。
- Node 承接 AI/天气域。
- API Gateway 对 APP/PC 暴露统一入口。

优点：

- 短期迁移量相对较小。

缺点：

- 长期仍然是双后端，不符合“二合一”的最终目标。
- 运维、鉴权、日志、权限、监控都会变复杂。

## Option C: 以 Node 为主，重写 Spring Boot 业务域

做法：

- 用 Node 重写用户、角色、问诊、档案、管理后台接口。

优点：

- 与当前 APP 里 8787 部分接口方向一致。

缺点：

- 会丢掉 Spring Boot 已经成型的业务层积累。
- PC 端要重新适配。
- 总体成本最高。

## Final Recommendation

推荐采用 `Option A`，但分成两个子阶段：

1. `统一对外阶段`
   由 Spring Boot 作为 APP 和 PC 唯一后端入口；Node 中的 LangGraph/Prompt/LLM 能力暂时作为内部 AI 引擎存在，不再让客户端直连。
2. `统一运行时阶段`
   等 APP、PC、权限和数据模型稳定后，再决定是把 Node AI 编排完全迁入 Java，还是以内嵌 AI 子服务的形式继续保留。

这是最符合当前仓库现实、也最能保住现有 AI 资产的路线。

## Final Target Architecture

最终目标架构建议如下：

```text
HarmonyOS APP  ─────┐
                    ├── Unified Spring Boot Backend ─── MySQL
Vue PC Web     ─────┘                    │
                                         ├── AI Orchestrator (Node.js LLM / Prompt / LangGraph, transition stage)
                                         ├── AI Provider Adapter (DeepSeek/OpenAI-compatible)
                                         ├── Weather Provider Adapter (Open-Meteo/其他)
                                         ├── File/OCR Adapter
                                         └── Cache / Session Layer
```

关键原则：

- 客户端只面对一个后端入口。
- AI、天气、OCR 是后端内部能力，不再由客户端决定走哪套服务。
- APP 和 PC 使用同一套领域模型与权限模型。
- Node 里的 AI 编排逻辑属于“核心资产”，迁移时优先保留能力，而不是先重写再验证。

## Unified Backend Domain Design

统一后的 Spring Boot 后端建议分成以下业务域。

## 1. Identity Domain

负责：

- 注册
- 登录
- 退出
- 会话校验
- 角色识别
- 权限校验

建议模块：

- `auth`
- `user`
- `role`
- `user-role`
- `session`

当前 Spring Boot 已有基础，可继续增强。

## 2. Consultation Domain

负责：

- 一对一问诊主会话
- 问诊消息
- 医生待处理提醒
- 问诊状态流转

建议模块：

- `consultation`
- `consultation-message`
- `doctor-dashboard`

这部分当前 Spring Boot 已有雏形，应继续深化而不是另起炉灶。

## 3. Assistant Domain

负责：

- 养生助手多轮问答
- AI 历史记录
- 风险提示
- 后台审计查看

建议模块：

- `assistant-session`
- `assistant-message`
- `assistant-ai`
- `assistant-audit`

当前 Spring Boot 的 `health-question` 可以作为这一域的前身。  
当前 Node 的 `/api/ai/chat` 和 `/api/ai/suggestions` 能力则要被合并到这里。

其中 Node 侧已存在的关键能力包括：

- `buildLlmPrompt`
- `requestDeepSeekAssistantReply`
- `runHealthAssistantGraph`
- `buildRuleBasedAssistantReply`

这些不是普通接口壳，而是当前 AI 交互质量的重要来源。

## 4. Health Archive Domain

负责：

- 用户健康档案
- 体质、问卷、指标、舌象记录
- 后台总览查看

建议模块：

- `health-archive`
- `constitution`
- `questionnaire`
- `indicator`
- `tongue-note`

## 5. Weather And Suggestion Domain

负责：

- 当前天气
- 节气信息
- 场景化养生建议
- 天气感知计划

建议模块：

- `weather`
- `solar-term`
- `suggestion`
- `plan`

这部分主要来自 Node 后端能力，需要迁入 Spring Boot。

## 6. Admin Domain

负责：

- 人员管理
- 角色分配
- 问答总览
- 问诊总览
- 审计日志

建议模块：

- `admin-user`
- `admin-role`
- `admin-assistant`
- `admin-consultation`
- `audit-log`

## 7. Extended APP Parity Domain

为了最终“完全对应 APP 功能”，统一后端还需要补足以下域：

- `reminder`
- `health-metric`
- `medical-report`
- `device`
- `notification`

这些能力在当前 Spring BootDemo 中还不完整，但它们必须进入最终路线。

## Role Model Unification

统一角色编码建议如下：

| 最终角色 | Spring Boot 当前 | APP 语义 | PC 当前语义 |
|----------|------------------|----------|-------------|
| `USER` | `USER` | 普通用户 | `USER` |
| `DOCTOR` | `ADVISER` 或 `DOCTOR` | 医生 | `ADVISER` |
| `ADMIN` | `ADMIN` | 管理员 | `ADMIN` |

建议迁移策略：

1. 后端先支持 `ADVISER -> DOCTOR` 别名兼容。
2. 新增统一字段 `primaryRole`。
3. APP 与 PC 统一只认：
   - `USER`
   - `DOCTOR`
   - `ADMIN`
4. 数据层逐步将旧 `ADVISER` 清理为 `DOCTOR`。

这样可以避免前后端长期保存两套角色语义。

## API Unification Strategy

统一后，APP 和 PC 都应只使用一个 API Base：

- `http://<server>:8181/api`

不再保留：

- APP 连 8787 做天气/AI
- APP 连 8181 做认证

## Current To Target API Mapping

| 当前来源 | 当前接口 | 目标接口 | 目标归属 |
|----------|----------|----------|----------|
| Node | `/api/weather/current` | `/api/weather/current` | Spring Boot |
| Node | `/api/ai/chat` | `/api/assistant/chat` | Spring Boot |
| Node | `/api/ai/suggestions` | `/api/suggestions/scene` | Spring Boot |
| Node | `/api/auth/login` | `/api/auth/login` | Spring Boot |
| Spring Boot | `/api/auth/login` | `/api/auth/login` | Spring Boot |
| Spring Boot | `/api/health-question` | `/api/assistant/messages` 或保留兼容入口 | Spring Boot |
| Spring Boot | `/api/consultation` | `/api/consultations` | Spring Boot |
| Spring Boot | `/api/consultation-message` | `/api/consultations/{id}/messages` | Spring Boot |
| Spring Boot | `/api/health-archive` | `/api/health-archives` | Spring Boot |

建议原则：

- 第一阶段允许兼容旧接口。
- 第二阶段统一 REST 风格命名。
- 第三阶段由 APP 和 PC 全量切到统一新接口。

## APP And PC Shared Capability Matrix

## APP 必须对应到统一后端的功能

1. 登录/注册/会话。
2. 角色识别。
3. 养生助手对话。
4. 天气与场景化建议。
5. 健康档案。
6. 问卷、体质、舌象、指标。
7. 一对一问诊。
8. 提醒、计划、数据总览。
9. 管理员查看全部记录。

## PC 必须对应到统一后端的功能

1. 登录/注册/会话。
2. 用户管理。
3. 角色管理。
4. 健康档案管理。
5. 养生助手问答查看或交互。
6. 一对一问诊工作台。
7. 医生资料维护。
8. 管理员审计和总览。

## 共享规则

- APP 和 PC 的用户、档案、问诊、问答记录必须来自同一主数据源。
- 不允许 APP 有一套主数据、PC 再有一套单独主数据。
- 客户端允许有本地缓存，但不能成为最终事实来源。

## Data Source Unification

统一后要明确主数据归属。

## Final Source Of Truth

- 用户、角色、医生资料：MySQL
- 健康档案：MySQL
- 问诊会话、问诊消息：MySQL
- 养生助手问答记录：MySQL
- 会话/Token：Redis 或数据库持久会话
- 天气缓存：Redis 或 MySQL 缓存表
- 提醒、计划、设备、体检报告：MySQL

## What Must Stop Being Source Of Truth

- APP 本地 Preferences 不能继续作为共享业务主数据源。
- Node JSON 文件不能继续作为正式用户数据存储。
- PC 端本地 mock 数组不能继续作为正式业务数据。

## Migration Strategy

## Phase 0: Inventory Freeze

在正式合并前，先冻结三类资产清单：

1. APP 当前已上线或已存在页面功能。
2. Node 当前接口与 payload。
3. Spring Boot 当前接口、数据表、权限行为。
4. PC 当前已存在模块与 mock 行为。

产出：

- 统一接口对照表
- 统一角色对照表
- 统一数据模型表

## Phase 1: Make Spring Boot The Main Backend

目标：

- 明确 Spring Boot 是唯一主后端。
- 不再给 Node 增加新业务域。

动作：

1. 在 Spring Boot 中补 `auth/me`。
2. 将 token 机制从内存 `TokenStore` 升级为可持久化方案。
3. 统一角色编码。
4. 统一 APP 与 PC 登录响应格式。

## Phase 2: Migrate Node AI And Weather Capabilities

目标：

- 吸收 Node 的天气与建议能力。
- 明确保留 Node 里已经写好的 LLM、Prompt、LangGraph 编排资产。

动作：

1. 将 Node 天气能力迁为 Spring Boot `WeatherService`。
2. 将 Node 场景建议能力迁为 Spring Boot `SuggestionService`。
3. 将 Node AI 聊天逻辑整理为独立 AI orchestration contract。
4. 在 Spring Boot 中新增 `AssistantAiService`，先通过内部适配层调用 Node AI orchestration。
5. 保留 Node 代码作参考与迁移基线，但停止给客户端直接调用。

迁移完成标志：

- APP 不再请求 8787。
- PC 也不需要任何 Node 直连。
- AI 对话质量不因迁移而明显退化。

## Phase 3: Align HarmonyOS APP To Unified Backend

目标：

- APP 全面切到 Spring Boot。

动作：

1. 修改 `ApiConfig.ets`，移除双 baseUrl 结构。
2. 登录、天气、AI、问诊、档案全部走同一后端。
3. 将本地档案和聊天记录改成“后端主存储 + 本地缓存”。
4. 增加角色化壳层与问诊模块。

## Phase 4: Complete PC Frontend

目标：

- 将当前 `Sprintvue` 从单文件原型升级为正式 PC 端。

动作：

1. 将 `App.vue` 拆分为：
   - 登录
   - 仪表盘
   - 用户管理
   - 档案管理
   - 养生助手
   - 问诊工作台
   - 医生资料
   - 管理端总览
2. 将 mock 数据逐步替换为真实接口。
3. 使用统一角色控制导航和权限。

## Phase 5: Fill Missing APP Capability Domains In Spring Boot

目标：

- 让统一后端真正“完全对应 APP 功能”。

需要补足的后端能力：

1. 天气和节气建议。
2. 场景化健康建议。
3. 提醒与通知。
4. 健康指标与图表数据。
5. 体检报告与解读。
6. 个人计划。
7. 设备数据接口。

## Phase 6: Retire Direct Node Client Traffic

目标：

- 客户端彻底不依赖 Node。

可选处理方式：

1. 代码迁完后，将 Node 仓库保留为参考原型。
2. 或者将其缩减为内部 AI orchestration 样板仓。
3. 如果 Java 侧已完整接管 LangGraph 等价能力，再彻底停止 Node 运行时依赖。

但最终不应出现：

- APP 继续调 8787
- APP 和 PC 分别调不同业务后端
- 数据再分别写两边

## Detailed Technical Refactor Plan

## Spring BootDemo Refactor Plan

建议将当前后端从“控制器平铺式原型”升级为“按域组织的统一后端”。

建议包结构方向：

```text
org.example.springbootdemo
├── auth
├── user
├── role
├── archive
├── assistant
├── consultation
├── doctor
├── weather
├── suggestion
├── reminder
├── report
├── metric
├── device
├── admin
└── common
```

重点改造项：

1. `TokenStore`
   现状是内存 token，不适合正式多端会话。

2. `PermissionService`
   继续保留，但要与统一角色编码同步。

3. `HealthQuestionAiService`
   作为统一养生助手域的起点，吸收或托管 Node AI 逻辑。

4. `ConsultationController` / `ConsultationMessageController`
   继续演进为正式问诊域。

5. `HealthArchiveController`
   演进为 APP 与 PC 共用档案主服务。

## Node Backend Refactor Plan

Node 后端不建议继续承担正式业务后端角色。

建议定位调整为：

- 迁移期参考实现
- AI orchestration 样板仓
- 测试工具仓

迁移时保留的重点：

1. 天气请求逻辑。
2. 湿度感知建议逻辑。
3. `LLM` 调用封装。
4. `Prompt` 拼装逻辑。
5. `LangGraph` 工作流编排。
6. AI 聊天兜底逻辑。
7. 场景 suggestions 结构。

迁移后不再保留的客户端职责：

- 认证主入口。
- 用户主数据入口。
- 客户端正式 AI/天气入口。

## AI Orchestration Convergence Strategy

由于 Node 后端已经写了 `LLM / Prompt / LangGraph`，统一路线不能把这部分视作普通接口代码。

建议采用两步法：

### Step A: Preserve Ability First

- 保留 Node 中现有 AI 编排作为能力基线。
- Spring Boot 先通过内部适配层调用它。
- APP 与 PC 只感知 Spring Boot，不感知 Node。

这样做的好处是：

- 不丢掉现有 AI 效果。
- 不会在“业务统一”同时引入“AI 重写”双重风险。

### Step B: Decide Runtime Unification Later

等统一业务后端稳定后，再在这两个方向中二选一：

1. `完全迁入 Java`
   将 Prompt、风险路由、计划生成、记忆构建迁入 Spring Boot。
2. `保留 Node 作为内部 AI 运行时`
   但它只作为 Spring Boot 的内部能力层，不再算一个对外独立后端。

如果你的最终要求是“部署层面也只保留一个后端进程”，那长期就要走第 1 条。  
如果你的重点是“对 APP 和 PC 来说只有一个后端入口”，那第 2 条也能满足业务统一目标。

## HarmonyOS APP Refactor Plan

APP 需要从“本地优先 + 双后端”演进为“统一后端 + 本地缓存”。

重点改造文件方向：

- `entry/src/main/ets/services/ApiConfig.ets`
- `entry/src/main/ets/services/AuthService.ets`
- `entry/src/main/ets/services/ProfileRepository.ets`
- `entry/src/main/ets/services/ChatHistoryRepository.ets`
- `entry/src/main/ets/components/tabs/AssistantTab.ets`
- `entry/src/main/ets/pages/Index.ets`

需要完成：

1. 单后端 API 配置。
2. 统一角色识别。
3. 问诊模块正式化。
4. 本地数据迁移到后端。
5. 管理员视角数据来自后端而不是本地。

## Vue PC Refactor Plan

PC 当前最大的问题不是“没有功能”，而是“功能都堆在一个原型页面里”。

建议重构为：

- `views/login`
- `views/dashboard`
- `views/users`
- `views/archives`
- `views/assistant`
- `views/consultation`
- `views/doctor`
- `views/admin`

同时增加：

- `router`
- `stores`
- `api`
- `layouts`
- `role guards`

目标不是只做后台，而是做一个与 APP 共用业务内核的 PC 端。

## Contract Standardization

统一后的登录返回建议：

```json
{
  "success": true,
  "message": "login success",
  "data": {
    "token": "xxx",
    "user": {
      "id": 1,
      "phone": "13800000000",
      "realName": "张三",
      "roles": ["USER"],
      "primaryRole": "USER",
      "status": 1
    }
  }
}
```

统一后的问诊会话建议：

```json
{
  "id": 1001,
  "patientUserId": 3,
  "doctorUserId": 2,
  "symptom": "睡眠浅",
  "description": "最近一周夜醒明显",
  "status": "ACTIVE",
  "lastMessageAt": "2026-06-25T15:30:00+08:00"
}
```

统一后的养生助手消息建议：

```json
{
  "id": 501,
  "sessionId": 88,
  "userId": 3,
  "role": "USER",
  "content": "最近睡眠不好怎么调理？",
  "answer": "建议规律作息...",
  "riskLevel": "normal",
  "createdAt": "2026-06-25T15:40:00+08:00"
}
```

## Database Evolution Direction

当前 Spring Boot 已有部分核心表。  
统一后建议分三类看待：

## Already Existing Or Close To Existing

- `sys_user`
- `sys_role`
- `sys_user_role`
- `health_archive`
- `doctor_profile`
- `consultation`
- `consultation_message`
- `health_question`

## Need To Be Extended

- `health_archive`
  需要补更多 APP 档案字段。

- `health_question`
  需要决定是扩展为完整 assistant session/message，还是新建两张表承接多轮对话。

- `consultation`
  需要补状态、未读数、最后消息摘要等字段。

## Need To Be Added

- `assistant_session`
- `assistant_message`
- `weather_cache`
- `scene_suggestion`
- `user_reminder`
- `health_metric_record`
- `medical_report`
- `personal_plan`
- `audit_log`

## Testing Strategy

统一后测试必须分成三层。

## Backend Tests

- 登录注册。
- 角色鉴权。
- 用户和管理员权限边界。
- 医生问诊权限边界。
- AI 问答持久化。
- 天气建议正确返回。

## APP Integration Tests

- APP 只使用一个后端地址。
- 登录后角色正确分流。
- 本地数据可迁移到后端。
- 问诊、档案、AI 对话均能落库并回显。

## PC Integration Tests

- PC 登录态可持续。
- mock 数据全部替换后功能可用。
- 管理员、医生、用户三种角色视图正确切换。
- 问诊与问答记录可真实查询。

## Risks And Decisions

## Risk 1: TokenStore 目前是内存实现

这意味着：

- 服务重启后登录失效。
- 不适合正式多端共享。

结论：

- 必须尽早替换为 JWT 或 Redis / DB 会话。

## Risk 2: APP 仍有本地主数据

如果不迁移：

- 管理员永远看不到完整用户数据。
- PC 与 APP 会长期不一致。

结论：

- 必须建立本地到后端的数据迁移机制。

## Risk 3: PC 原型页面过大

`App.vue` 目前承担过多功能，后续很难维护。

结论：

- PC 端必须尽快拆页面、拆路由、拆状态管理。

## Risk 4: 双后端并存时间过长

如果双后端拖太久：

- 后续改一个业务要改两边。
- 权限和数据问题会持续放大。

结论：

- Node 只允许作为迁移期参考，不应长期作为客户端正式依赖。

## Final Decision Summary

本路线确认以下核心决策：

1. `SpringBootDemo` 作为最终统一主后端。
2. `yangshengzhushou_db` 中的天气、AI、建议能力统一纳入 Spring Boot 主架构。
3. HarmonyOS APP 与 Vue PC 最终都只连一个 Spring Boot 后端。
4. 统一角色编码为 `USER / DOCTOR / ADMIN`。
5. APP 本地数据改为“后端主存储 + 本地缓存”。
6. PC 从原型控制台演进为正式角色化前端。
7. Node 仓库中的 `LLM / Prompt / LangGraph` 属于核心 AI 资产，迁移时优先保留能力完整性。
8. Node 仓库迁移完成后不再承担正式客户端接口职责。

## Execution Order

建议后续按这个顺序推进：

1. 统一角色、登录返回、token 策略。
2. 统一 APP 与 PC 的接口契约。
3. 将 Node 天气/AI/建议迁入 Spring Boot。
4. APP 切换到单后端。
5. PC 去 mock、拆模块、补真实接口。
6. 补足 APP 尚未在 Spring Boot 中落地的功能域。
7. 完成管理员总览、医生工作台、用户问诊的全链路联调。
