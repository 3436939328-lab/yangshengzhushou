# Role-Based Consultation Platform Design

## Goal

将当前“单用户本地养生助手”升级为“多角色协同养生平台”，支持三种身份：

- `user`：普通用户，保留当前已选 APP 的全部已有功能，并新增一对一问诊。
- `doctor`：医生，查看并回复用户发起的问诊，登录后优先收到待处理提醒。
- `admin`：管理员，查看所有人员信息、所有养生助手问答记录，并对人员信息执行增删改查。

本次设计目标不是一次性重写应用，而是在现有 HarmonyOS 前端和 Node.js 后端基础上，演进为可持续扩展的角色化系统。

## Current State

当前项目已经具备以下基础：

- HarmonyOS 前端已有登录页、引导页、四个主 Tab 和本地健康档案。
- 前端主页入口集中在 `entry/src/main/ets/pages/Index.ets`。
- 用户登录已打通手机号注册/登录，但登录返回中没有角色信息。
- AI 助手对话、本地健康档案、聊天记录仍主要保存在本地 Preferences 中。
- Node.js 后端已提供天气、AI 聊天、注册、登录接口，但尚无角色、问诊、后台管理、共享数据能力。

当前限制也很明显：

- 管理员无法看到其他用户本地保存的数据。
- 医生没有独立工作台，也没有待处理提醒。
- 普通用户无法选择医生发起一对一问诊。
- 现有登录体系只有身份认证，没有权限分层。

## Product Scope

本阶段覆盖以下能力：

- 新增三种角色并完成登录后分流。
- 普通用户新增一对一问诊功能。
- 医生新增问诊工作台与待处理提醒。
- 管理员新增人员管理、养生助手问答总览、问诊记录查看能力。
- 将关键共享数据从“本地独占”升级为“后端主存储 + 前端缓存”。

本阶段暂不覆盖以下内容：

- 音视频问诊。
- 医生排班、挂号、付费。
- 多机构、多院区、多租户。
- 云端推送通知服务。
- 复杂 BI 报表。

## Recommended Approach

推荐采用“单应用 + 角色化壳层 + 统一后端”的路线。

核心思路如下：

1. 保留现有单个 HarmonyOS App，不拆成三个独立应用。
2. 登录成功后，根据角色动态切换首页结构、Tab 配置和可访问页面。
3. 后端新增统一认证、角色鉴权、问诊、后台管理接口。
4. 当前本地健康档案和 AI 对话记录逐步迁移到后端作为主数据源。
5. 前端继续保留本地缓存，用于首屏加载、离线兜底和旧数据迁移。

选择该路线的原因：

- 与当前 `Index.ets + Tab` 架构最兼容。
- 能复用现有视觉风格、聊天组件和档案组件。
- 可分阶段上线，不要求一次性改完全部页面。
- 后续增加新角色或新工作台时，边界更清晰。

## Target Architecture

系统拆分为四层：

1. `Identity Layer`
   负责注册、登录、会话校验、角色识别、权限判断。
2. `Business Layer`
   负责问诊会话、问诊消息、健康档案、AI 问答记录、用户管理。
3. `Presentation Layer`
   负责普通用户、医生、管理员三套角色化页面。
4. `Persistence Layer`
   负责本地缓存、后端文件存储或数据库存储、数据迁移。

前端建议从“单一主页状态”升级为“角色壳层 + 角色业务页面”：

- `AppShell`
- `UserShell`
- `DoctorShell`
- `AdminShell`

后端建议从“扁平接口集合”升级为“按业务域拆分的服务”：

- `auth`
- `users`
- `profiles`
- `consultations`
- `assistant-records`
- `admin`

## Role Definitions

### User

普通用户可使用：

- 当前 APP 已有全部功能。
- 养生助手对话。
- 本人健康档案维护。
- 一对一问诊医生选择、发起、持续聊天、查看历史问诊。

普通用户不可执行：

- 查看其他用户信息。
- 查看其他人的 AI 问答和问诊记录。
- 管理医生或管理员账号。

### Doctor

医生可使用：

- 登录后查看待处理问诊提醒。
- 查看发给自己的问诊会话列表。
- 进入某个问诊会话后查看完整消息并回复。
- 查看问诊对象的必要档案摘要，便于回复。

医生端行为要求：

- 如果没有用户向该医生提问，则问诊列表为空。
- 如果有待处理问诊，医生登录后优先弹出提醒或进入提醒卡片区域。
- 医生不能查看不属于自己的问诊记录。

### Admin

管理员可使用：

- 查看所有人员信息。
- 对所有人员信息执行增删改查。
- 查看所有养生助手问答记录的聚合总览。
- 查看所有问诊会话及详情。
- 筛选、检索、打开某个用户的完整问答或问诊详情弹窗。

管理员端查看规则：

- 总览默认使用列表或表格，不直接把所有完整消息展开。
- 当管理员点击某一个用户记录后，再打开问答详情弹窗或抽屉。
- 管理员具有全局只读查看能力和人员维护能力。

## Data Model Design

### 1. User

用于统一账号基础信息。

```json
{
  "id": "user_xxx",
  "phone": "13800000000",
  "passwordHash": "...",
  "role": "user",
  "displayName": "张三",
  "status": "active",
  "createdAt": "2026-06-25T08:00:00.000Z",
  "updatedAt": "2026-06-25T08:00:00.000Z"
}
```

字段说明：

- `role`：`user | doctor | admin`
- `status`：`active | disabled`

### 2. UserProfile

用于保存用户健康档案主数据。

```json
{
  "userId": "user_xxx",
  "constitution": {},
  "questionnaireRecords": [],
  "healthIndicators": [],
  "tongueNotes": [],
  "reminderPreferences": [],
  "updatedAt": "2026-06-25T08:00:00.000Z"
}
```

该模型与当前 `HealthProfile` 高度接近，适合从 [ProfileRepository.ets](<D:\yangshengzhushou\entry\src\main\ets\services\ProfileRepository.ets>) 演进。

### 3. DoctorProfile

用于保存医生业务信息。

```json
{
  "doctorId": "doctor_xxx",
  "displayName": "李医生",
  "department": "中医内科",
  "specialties": ["失眠调理", "体质调理"],
  "introduction": "10年临床经验",
  "isAvailable": true,
  "createdAt": "2026-06-25T08:00:00.000Z",
  "updatedAt": "2026-06-25T08:00:00.000Z"
}
```

### 4. ConsultationThread

表示一次一对一问诊主会话。

```json
{
  "id": "consult_xxx",
  "patientUserId": "user_xxx",
  "doctorUserId": "doctor_xxx",
  "status": "active",
  "subject": "近期睡眠浅",
  "lastMessagePreview": "晚上总是容易醒",
  "lastMessageAt": "2026-06-25T08:30:00.000Z",
  "patientUnreadCount": 0,
  "doctorUnreadCount": 2,
  "createdAt": "2026-06-25T08:20:00.000Z",
  "updatedAt": "2026-06-25T08:30:00.000Z"
}
```

建议状态：

- `active`
- `closed`
- `archived`

### 5. ConsultationMessage

表示问诊会话中的单条消息。

```json
{
  "id": "msg_xxx",
  "threadId": "consult_xxx",
  "senderUserId": "user_xxx",
  "senderRole": "user",
  "content": "最近晚上总醒，白天也乏力",
  "messageType": "text",
  "createdAt": "2026-06-25T08:30:00.000Z",
  "readBy": ["user_xxx"]
}
```

首版只支持：

- `messageType = text`

### 6. AssistantConversationRecord

用于保存养生助手问答记录，供管理员查看。

```json
{
  "id": "assistant_record_xxx",
  "userId": "user_xxx",
  "sessionId": "assistant_session_xxx",
  "messages": [],
  "lastMessageAt": "2026-06-25T09:00:00.000Z",
  "createdAt": "2026-06-25T08:50:00.000Z",
  "updatedAt": "2026-06-25T09:00:00.000Z"
}
```

该模型用于替代当前仅本地持久化的聊天记录 [ChatHistoryRepository.ets](<D:\yangshengzhushou\entry\src\main\ets\services\ChatHistoryRepository.ets>)。

### 7. AuditLog

用于记录管理员和核心流程操作。

```json
{
  "id": "audit_xxx",
  "operatorUserId": "admin_xxx",
  "operatorRole": "admin",
  "action": "USER_UPDATED",
  "targetType": "user",
  "targetId": "user_xxx",
  "createdAt": "2026-06-25T10:00:00.000Z"
}
```

## Backend Design

### Auth And Session

现有认证逻辑位于 [authService.js](<D:\yangshengzhushou\yangshengzhushou_db\src\authService.js>)，需要从“只校验手机号密码”升级为“角色化会话认证”。

后端改造点：

- 注册时支持指定默认角色。
- 登录成功后返回角色、昵称、基础角色资料。
- 服务端保存 token 与用户的映射关系。
- 新增通用鉴权中间层。
- 新增角色校验中间层。

登录返回示例：

```json
{
  "token": "token_xxx",
  "user": {
    "id": "user_xxx",
    "phone": "13800000000",
    "role": "doctor",
    "displayName": "李医生",
    "createdAt": "2026-06-25T08:00:00.000Z"
  }
}
```

### API Domains

建议将后端接口按以下域拆分。

#### Auth

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`

#### Doctors

- `GET /api/doctors`
- `GET /api/doctors/:doctorId`

#### Profiles

- `GET /api/profile/me`
- `PUT /api/profile/me`
- `GET /api/admin/profiles`
- `GET /api/admin/profiles/:userId`

#### Consultations

- `POST /api/consultations`
- `GET /api/consultations/me`
- `GET /api/consultations/:threadId`
- `GET /api/consultations/:threadId/messages`
- `POST /api/consultations/:threadId/messages`
- `POST /api/consultations/:threadId/read`

#### Doctor Dashboard

- `GET /api/doctor/dashboard/summary`

#### Assistant Records

- `GET /api/assistant/records/me`
- `POST /api/assistant/records/sync`
- `GET /api/admin/assistant-records`
- `GET /api/admin/assistant-records/:userId`

#### Admin Users

- `GET /api/admin/users`
- `POST /api/admin/users`
- `PUT /api/admin/users/:userId`
- `DELETE /api/admin/users/:userId`

### Permission Rules

后端必须在接口层严格控制访问范围。

- `user` 只能访问自己的 profile、自己的 assistant 记录、自己的 consultations。
- `doctor` 只能访问分配给自己的 consultation threads 和 messages。
- `admin` 可以访问所有用户、所有资料、所有问诊、所有 AI 问答记录。

建议每个业务域统一经过：

1. `authenticateRequest`
2. `authorizeRole`
3. `authorizeResourceOwnership`

### Storage Strategy

当前后端以文件存储为主，短期可继续使用 repository 抽象承接。

推荐策略：

1. 第一阶段：
   保持 `JSON file store`，快速打通全链路。
2. 第二阶段：
   将 `users / consultations / messages / assistant records` 切换到 `SQLite`。

推荐从一开始就设计 repository 接口，避免后续替换存储层时牵动 controller。

建议后端目录演进为：

- `src/auth`
- `src/users`
- `src/profiles`
- `src/consultations`
- `src/assistantRecords`
- `src/admin`
- `src/shared`

## Frontend Design

### App Shell Refactor

当前前端入口集中在 [Index.ets](<D:\yangshengzhushou\entry\src\main\ets\pages\Index.ets>)，登录后直接进入固定四 Tab 结构。  
本次建议将其升级为“登录成功后按角色挂载不同壳层”。

目标结构：

- `Index.ets`
- `UserShell.ets`
- `DoctorShell.ets`
- `AdminShell.ets`

`Index.ets` 负责：

- 检查本地会话。
- 拉取当前登录用户信息。
- 根据角色分发到对应壳层。

### Auth Session Evolution

现有会话结构位于 [AuthService.ets](<D:\yangshengzhushou\entry\src\main\ets\services\AuthService.ets>)，需要新增：

- `role`
- `displayName`
- 可选 `doctorProfile`
- 可选 `adminPermissions`

建议前端 `AuthSession` 变更为：

```ts
interface AuthSession {
  token: string;
  user: {
    id: string;
    phone: string;
    role: 'user' | 'doctor' | 'admin';
    displayName: string;
    createdAt: string;
  };
}
```

### User UI

普通用户保留已有四 Tab 能力，并新增问诊模块。

推荐两种接入方式：

1. 将 `AssistantTab` 拆分为 `养生助手` 与 `问诊` 两个子页面。
2. 保留四 Tab 数量不变，在 `AssistantTab` 内增加 segmented control。

推荐方案是第 2 种，原因是对现有底部 Tab 改动更小。

普通用户问诊页建议结构：

- 顶部：医生选择入口与当前会话状态。
- 中部：消息流列表。
- 底部：输入框、发送按钮、固定工具栏。

问诊页需要支持：

- 选择已有注册医生。
- 新建会话。
- 查看自己的历史会话。
- 切换当前会话。
- 发送文本消息。

UI 风格建议：

- 延续当前 `AssistantTab` 的气泡对话基础风格。
- 增加医生头像区、消息时间、未读标记、状态标签。
- 保持页面干净，避免做成客服样式或 IM 大杂烩。

### Doctor UI

医生端建议使用“双区结构”：

- 左侧或上方：待处理问诊列表。
- 右侧或下方：当前会话消息流。

若受移动端布局限制，可采用“列表页 -> 详情页”的两段式导航。

医生登录后第一屏要展示：

- 今日待处理数。
- 未读问诊数。
- 最新患者提问摘要。

若存在未处理问诊，则登录后立即提醒：

- 弹窗提醒。
- 顶部提示条。
- 首页高优先级卡片。

首版推荐用“首页高优先级卡片 + 自动跳转按钮”，实现成本低，交互也稳定。

### Admin UI

管理员端建议使用工作台结构，不沿用普通用户四 Tab 语义。

推荐模块：

- `人员管理`
- `健康档案总览`
- `养生助手问答总览`
- `问诊记录总览`

管理员问答总览交互：

- 默认按用户聚合。
- 每行展示用户、最近更新时间、消息数。
- 点击某个用户后，打开弹窗或抽屉显示完整问答记录。

管理员人员管理交互：

- 列表 + 搜索 + 角色筛选。
- 新增用户。
- 编辑人员角色、姓名、状态。
- 删除或禁用人员。

管理员查看问诊记录交互：

- 支持按医生、患者、状态筛选。
- 支持打开某个问诊会话详情。
- 首版只读即可，不要求管理员直接回复消息。

## Data Synchronization Strategy

这是本项目最关键的演进点。

### Why Migration Is Required

当前本地数据结构决定了：

- 用户的档案仅在自己手机上。
- 用户的养生助手聊天记录仅在自己手机上。

如果不迁移，管理员无法看到这些共享业务数据。

### Migration Plan

前端首次升级后执行迁移流程：

1. 用户登录。
2. 读取本地 `HealthProfile`。
3. 读取本地 `ChatHistory`。
4. 上传至后端对应接口。
5. 后端落库并返回同步结果。
6. 前端记录“已迁移”标记。

建议迁移标记保存在本地会话或独立 Preferences key 中。

### Sync Rules

- 健康档案：以后端为主，前端本地做缓存。
- AI 问答记录：每次本地对话完成后同步后端。
- 问诊会话：以后端为唯一真源，不在本地独立持久化完整主数据。

## Detailed User Flows

### User Consultation Flow

1. 普通用户登录。
2. 进入问诊区域。
3. 从医生列表中选择一名医生。
4. 创建一条问诊线程。
5. 输入问题并发送。
6. 前端保存本地显示状态，同时调用后端发送消息。
7. 医生回复后，用户再次进入时看到新消息和未读提醒。

### Doctor Consultation Flow

1. 医生登录。
2. 拉取待处理问诊汇总。
3. 如果有未读会话，则显示高优先级提醒。
4. 医生进入某个会话。
5. 查看患者问题和必要档案摘要。
6. 回复文本消息。
7. 后端更新最后消息与未读计数。

### Admin Assistant Audit Flow

1. 管理员登录。
2. 进入养生助手问答总览。
3. 看到按用户聚合的问答记录列表。
4. 点击某个用户。
5. 打开弹窗或抽屉，展示该用户完整问答记录。

### Admin User Management Flow

1. 管理员进入人员管理。
2. 搜索、筛选人员。
3. 新增、编辑、删除或禁用人员。
4. 后端校验当前管理员权限。
5. 操作成功后刷新列表，并写入审计日志。

## API Contract Suggestions

### Create Consultation

`POST /api/consultations`

```json
{
  "doctorUserId": "doctor_xxx",
  "subject": "最近睡眠浅"
}
```

response:

```json
{
  "thread": {
    "id": "consult_xxx",
    "patientUserId": "user_xxx",
    "doctorUserId": "doctor_xxx",
    "status": "active"
  }
}
```

### Send Consultation Message

`POST /api/consultations/:threadId/messages`

```json
{
  "content": "最近晚上总醒，白天也乏力"
}
```

response:

```json
{
  "message": {
    "id": "msg_xxx",
    "threadId": "consult_xxx",
    "senderRole": "user",
    "content": "最近晚上总醒，白天也乏力",
    "createdAt": "2026-06-25T08:30:00.000Z"
  }
}
```

### Admin List Assistant Records

`GET /api/admin/assistant-records`

response:

```json
{
  "items": [
    {
      "userId": "user_xxx",
      "phone": "13800000000",
      "displayName": "张三",
      "messageCount": 12,
      "lastMessageAt": "2026-06-25T09:00:00.000Z"
    }
  ]
}
```

## File-Level Refactor Plan

### Frontend

建议新增或改造以下模块：

- `entry/src/main/ets/pages/Index.ets`
- `entry/src/main/ets/components/shells/UserShell.ets`
- `entry/src/main/ets/components/shells/DoctorShell.ets`
- `entry/src/main/ets/components/shells/AdminShell.ets`
- `entry/src/main/ets/components/consultation/UserConsultationView.ets`
- `entry/src/main/ets/components/consultation/DoctorConsultationView.ets`
- `entry/src/main/ets/components/admin/AdminUserManagementView.ets`
- `entry/src/main/ets/components/admin/AdminAssistantAuditView.ets`
- `entry/src/main/ets/components/admin/AdminConsultationAuditView.ets`
- `entry/src/main/ets/services/ConsultationService.ets`
- `entry/src/main/ets/services/AdminService.ets`
- `entry/src/main/ets/services/DoctorDirectoryService.ets`
- `entry/src/main/ets/services/ProfileSyncService.ets`

现有模块重点改造：

- [AuthService.ets](<D:\yangshengzhushou\entry\src\main\ets\services\AuthService.ets>)
- [AssistantTab.ets](<D:\yangshengzhushou\entry\src\main\ets\components\tabs\AssistantTab.ets>)
- [ProfileRepository.ets](<D:\yangshengzhushou\entry\src\main\ets\services\ProfileRepository.ets>)
- [ChatHistoryRepository.ets](<D:\yangshengzhushou\entry\src\main\ets\services\ChatHistoryRepository.ets>)

### Backend

建议新增或改造以下模块：

- `yangshengzhushou_db/src/server.js`
- `yangshengzhushou_db/src/authService.js`
- `yangshengzhushou_db/src/sessionStore.js`
- `yangshengzhushou_db/src/userService.js`
- `yangshengzhushou_db/src/profileService.js`
- `yangshengzhushou_db/src/consultationService.js`
- `yangshengzhushou_db/src/assistantRecordService.js`
- `yangshengzhushou_db/src/adminService.js`
- `yangshengzhushou_db/src/doctorDirectoryService.js`

## Implementation Phases

### Phase 1: Identity Upgrade

- 扩展注册/登录，支持角色字段。
- 会话中保存角色信息。
- 前端登录成功后按角色路由到不同壳层。

### Phase 2: Shared Data Foundation

- 健康档案后端化。
- AI 问答记录后端化。
- 本地数据迁移与缓存策略落地。

### Phase 3: User Consultation

- 医生列表接口。
- 用户发起问诊。
- 用户问诊对话 UI。

### Phase 4: Doctor Workbench

- 医生问诊列表。
- 医生登录提醒。
- 医生回复能力。

### Phase 5: Admin Console

- 人员管理 CRUD。
- 养生助手问答总览。
- 问诊总览与详情弹窗。

### Phase 6: Hardening

- 权限补强。
- 审计日志。
- 数据筛选、状态流转、未读逻辑。
- 完整测试。

## Error Handling

必须覆盖以下异常场景：

- token 失效或缺失。
- 角色与接口不匹配。
- 普通用户访问不存在的医生。
- 医生访问不属于自己的会话。
- 管理员查看空记录。
- 本地迁移失败但不能阻塞登录。
- 后端同步失败时前端仍需保留必要本地显示。

前端原则：

- 不因共享接口失败而让页面白屏。
- 对问诊和管理页提供明确空状态。
- 对关键提交行为显示成功/失败反馈。

## Testing Strategy

### Backend Tests

- 注册/登录返回角色正确。
- 未授权请求被拒绝。
- 用户只能访问自己的资料和会话。
- 医生只能访问分配给自己的问诊。
- 管理员可以查看所有问答与问诊。
- 人员 CRUD 正常工作。

### Frontend Tests

- `Index.ets` 能根据角色正确挂载壳层。
- 普通用户能创建并发送问诊消息。
- 医生能看到待处理提醒和问诊详情。
- 管理员能查看问答聚合列表并打开详情弹窗。

### Manual Verification

- HarmonyOS 模拟器或真机登录三种角色。
- 用户发起问诊后，医生端重新登录可见提醒。
- 管理员登录可查看用户问答记录和人员列表。

## Risks And Tradeoffs

### Risk 1: Local Data Migration Complexity

如果旧数据只存在本地，迁移失败会导致管理员无法看到历史数据。  
解决方式是做“幂等同步 + 可重试迁移标记”。

### Risk 2: JSON Store Growth

问诊消息和问答记录快速增长后，JSON 文件会变重。  
因此文档建议尽早抽象 repository，并规划切换到 SQLite。

### Risk 3: Frontend Shell Complexity

一个 App 同时容纳三种身份后，`Index.ets` 容易再次膨胀。  
解决方式是尽早拆分 `UserShell / DoctorShell / AdminShell`。

## Out Of Scope

- 多终端消息实时推送。
- 视频问诊。
- 医疗收费。
- OCR、图片问诊、处方流转。
- 复杂运营后台图表。

## Decision Summary

本设计确认以下结论：

1. 继续沿用单个 HarmonyOS App，不拆三个应用。
2. 登录后按角色挂载不同业务壳层。
3. 问诊与管理员可见数据必须以后端为主存储。
4. 普通用户保留现有全部功能，并新增一对一问诊。
5. 医生端以待处理问诊工作台为核心。
6. 管理员端以人员管理和记录审计为核心。

## Next Step

在该设计确认后，下一份文档应当是实现计划，建议按以下顺序展开：

1. 数据模型与后端接口清单。
2. 角色化前端壳层改造计划。
3. 问诊模块实现计划。
4. 管理员后台实现计划。
