# APP 后续功能与数据库扩展规划

## 1. 当前系统已有数据库表

当前系统核心数据库表共 11 张，已经可以支撑 PC 端的基础功能，包括登录权限、健康档案、AI 问答、医生资料和在线问诊。

| 表名 | 当前用途 | 是否建议保留 |
| --- | --- | --- |
| `sys_user` | 用户账号、手机号、密码、个人资料 | 保留 |
| `sys_role` | 角色信息，例如管理员、医生、普通用户 | 保留 |
| `sys_user_role` | 用户和角色的关联关系 | 保留 |
| `health_archive` | 用户健康档案 | 保留 |
| `health_question` | AI 问答和人工问答记录 | 保留 |
| `health_questionnaire_record` | 体质问卷记录 | 保留 |
| `health_indicator_record` | 健康指标记录，例如体重、血压、血糖 | 保留 |
| `tongue_observation_record` | 舌象观察记录 | 保留 |
| `doctor_profile` | 医生资料、职称、擅长方向 | 保留 |
| `consultation` | 用户和医生的一次问诊主记录 | 保留 |
| `consultation_message` | 问诊过程中的聊天消息 | 保留 |

结论：当前这 11 张表都在系统功能中有实际用途，也适合未来 PC 端和 APP 端继续复用，不建议删除。

## 2. 后续 APP 功能是否需要增加表

需要。当前 11 张表适合支撑毕业设计阶段的核心功能，但如果后续 APP 页面要做得更完整、更像正式产品，就需要新增一些业务表。

原因是：APP 后续功能包括短信验证码、紧急联系人、异常预警、中医养生游戏、积分兑换、排行榜、人脸识别登录、手表接入、双定位、Agent 预问诊、医生审核和会诊等。这些功能的数据结构和当前基础问诊表不同，如果全部混在旧表里，会导致字段混乱、后期维护困难。

## 3. 忘记密码与短信验证码

### 功能说明

忘记密码流程建议设计为：

1. 用户输入账号或手机号。
2. 后端判断账号是否存在。
3. 如果存在，进入身份验证步骤。
4. 后端向绑定手机号发送短信验证码。
5. 用户输入验证码。
6. 验证码正确后，允许修改密码。

### 建议新增表

| 表名 | 作用 |
| --- | --- |
| `sms_verification_code` | 保存短信验证码、用途、过期时间、是否已使用 |

### 主要字段

| 字段 | 说明 |
| --- | --- |
| `id` | 主键 |
| `phone` | 手机号 |
| `code` | 验证码 |
| `purpose` | 用途，例如 `LOGIN`、`REGISTER`、`RESET_PASSWORD` |
| `expire_time` | 过期时间 |
| `used` | 是否已使用 |
| `send_count` | 发送次数 |
| `create_time` | 创建时间 |

## 4. 紧急联系人与异常预警

### 功能说明

APP 中如果出现异常情况，例如健康指标异常、位置异常、长时间无响应等，可以通知紧急联系人。

### 建议新增表

| 表名 | 作用 |
| --- | --- |
| `emergency_contact` | 保存用户紧急联系人 |
| `health_warning` | 保存异常预警记录 |
| `warning_notification` | 保存预警通知发送记录 |

### 说明

`emergency_contact` 用来记录联系人姓名、手机号、关系等信息。

`health_warning` 用来记录异常类型、异常等级、异常来源，例如手机、手表或 AI 判断。

`warning_notification` 用来记录是否已经通知联系人、通知方式和通知状态。

## 5. 中医养生游戏

### 功能说明

用户可以通过玩游戏学习中医养生知识，例如答题、闯关、知识卡片、小游戏任务等。

### 建议新增表

| 表名 | 作用 |
| --- | --- |
| `health_game` | 游戏信息 |
| `game_question` | 游戏题库和中医养生知识题 |
| `game_play_record` | 用户游戏记录、分数和用时 |

### 说明

游戏模块不建议直接写死在前端，因为后续题库、分值、关卡都可能调整。用数据库表保存后，后台可以维护题目和游戏内容。

## 6. 积分、兑换与排行榜

### 功能说明

用户可以通过玩游戏获得积分，再用积分兑换一对一问答次数、专业 AI 请求次数或其他服务。同时可以根据积分形成排行榜。

### 建议新增表

| 表名 | 作用 |
| --- | --- |
| `user_point` | 用户当前积分余额 |
| `point_record` | 积分流水，记录积分来源和消费 |
| `point_exchange_rule` | 积分兑换规则 |
| `point_exchange_order` | 积分兑换记录 |
| `leaderboard_record` | 排行榜记录 |

### 说明

积分不能只保存在 `sys_user` 表里，因为需要追踪每一次积分增加和减少的来源。使用积分流水表后，可以清楚知道用户通过什么方式获得积分、什么时候消费积分。

## 7. 人脸识别登录

### 功能说明

APP 后续可以支持人脸识别登录，用来提高登录便利性。

### 建议新增表

| 表名 | 作用 |
| --- | --- |
| `face_auth` | 保存用户人脸识别绑定状态和特征标识 |
| `login_record` | 保存登录记录和异常登录信息 |

### 说明

人脸数据属于敏感信息，正式上线时不建议直接保存原始人脸图片。更合适的方式是保存加密后的特征标识，或者保存第三方人脸识别服务返回的用户标识。

## 8. 手机和手表双定位

### 功能说明

如果用户发生异常情况，系统可以通过手机和手表双定位获取当前位置，辅助紧急联系人或医生判断。

### 建议新增表

| 表名 | 作用 |
| --- | --- |
| `user_device` | 保存用户手机设备、推送 token 等 |
| `watch_bind` | 保存用户和手表设备的绑定关系 |
| `location_record` | 保存手机和手表上传的位置记录 |

### 主要字段

`location_record` 可以包含：

| 字段 | 说明 |
| --- | --- |
| `user_id` | 用户 id |
| `device_type` | 设备类型，例如 `PHONE`、`WATCH` |
| `latitude` | 纬度 |
| `longitude` | 经度 |
| `address` | 解析后的地址 |
| `record_time` | 定位时间 |

## 9. 手表数据接入

### 功能说明

后续 APP 可以预留手表接口，接收心率、血氧、步数、睡眠等数据。

### 建议新增表

| 表名 | 作用 |
| --- | --- |
| `watch_bind` | 用户和手表设备绑定关系 |
| `watch_health_data` | 手表上传的健康数据 |

### 说明

`watch_health_data` 可以保存心率、血氧、步数、睡眠时间、设备编号、上传时间等信息。未来如果做健康预警，也可以和 `health_warning` 表关联。

## 10. Agent 预问诊

### 功能说明

APP 病人问诊时，可以先由 Agent 根据用户描述进行初步判断，整理可能原因、风险等级和建议问题，然后发送给医生。

推荐流程：

```text
用户提交症状
↓
Agent 初步分析
↓
生成可能原因、风险等级、建议问题
↓
发送给医生
↓
医生复查审核
↓
医生确认、修改、否定或发起会诊
↓
结果返回给病人
```

### 建议新增表

| 表名 | 作用 |
| --- | --- |
| `agent_triage_record` | Agent 对一次问诊的初步分析记录 |
| `agent_triage_item` | Agent 分析出的可能原因、风险等级和建议 |

### 说明

Agent 的判断不能直接作为最终诊断，需要医生审核。这样既能提高医生处理效率，也能保证医疗建议更加谨慎。

## 11. 医生审核与会诊

### 功能说明

医生收到 Agent 初步判断后，可以进行审核。医生可以选择通过、修改、否定，或者发起会诊。

### 建议新增表

| 表名 | 作用 |
| --- | --- |
| `doctor_review` | 医生对 Agent 建议的审核结果 |
| `consultation_consult` | 会诊记录，支持多个医生参与 |
| `consultation_review_log` | 医生操作日志 |

### 审核状态示例

| 状态 | 说明 |
| --- | --- |
| `APPROVED` | 医生通过 Agent 建议 |
| `REJECTED` | 医生否定 Agent 建议 |
| `MODIFIED` | 医生修改后通过 |
| `CONSULTATION` | 医生发起会诊 |

## 12. APP 消息通知

### 功能说明

APP 后续需要通知用户医生回复、系统消息、预警信息、积分到账、兑换成功等。

### 建议新增表

| 表名 | 作用 |
| --- | --- |
| `notification` | 系统通知、医生回复、预警通知 |
| `notification_read` | 用户通知已读状态 |

## 13. 后续建议新增表汇总

如果完整实现上述 APP 功能，建议新增以下表：

| 序号 | 表名 | 所属功能 |
| --- | --- | --- |
| 1 | `sms_verification_code` | 短信验证码 |
| 2 | `emergency_contact` | 紧急联系人 |
| 3 | `health_warning` | 异常预警 |
| 4 | `warning_notification` | 预警通知 |
| 5 | `health_game` | 养生游戏 |
| 6 | `game_question` | 游戏题库 |
| 7 | `game_play_record` | 游戏记录 |
| 8 | `user_point` | 用户积分 |
| 9 | `point_record` | 积分流水 |
| 10 | `point_exchange_rule` | 积分兑换规则 |
| 11 | `point_exchange_order` | 积分兑换订单 |
| 12 | `leaderboard_record` | 排行榜 |
| 13 | `face_auth` | 人脸识别 |
| 14 | `login_record` | 登录记录 |
| 15 | `user_device` | 用户设备 |
| 16 | `location_record` | 定位记录 |
| 17 | `watch_bind` | 手表绑定 |
| 18 | `watch_health_data` | 手表健康数据 |
| 19 | `agent_triage_record` | Agent 预问诊 |
| 20 | `agent_triage_item` | Agent 分析明细 |
| 21 | `doctor_review` | 医生审核 |
| 22 | `consultation_consult` | 会诊 |
| 23 | `consultation_review_log` | 审核操作日志 |
| 24 | `notification` | 通知 |
| 25 | `notification_read` | 通知已读状态 |

## 14. 是否需要现在就建这些表

不建议现在全部建表。

当前毕业设计阶段只需要保留现有 11 张核心表，保证系统功能清晰、稳定、容易答辩。后续 APP 真正开发时，可以根据功能优先级逐步建表。

推荐优先级：

| 优先级 | 建议先做的表 |
| --- | --- |
| 第一阶段 | `sms_verification_code`、`notification`、`notification_read` |
| 第二阶段 | `emergency_contact`、`health_warning`、`warning_notification` |
| 第三阶段 | `user_device`、`watch_bind`、`location_record`、`watch_health_data` |
| 第四阶段 | `health_game`、`game_question`、`game_play_record`、`user_point`、`point_record` |
| 第五阶段 | `agent_triage_record`、`agent_triage_item`、`doctor_review`、`consultation_consult` |

## 15. 答辩说法

可以这样回答：

> 当前系统核心数据库表共 11 张，主要支撑登录权限、健康档案、AI 问答、健康指标、舌象记录、医生资料和在线问诊。对于后续 APP 端扩展功能，例如短信验证码、紧急联系人、异常预警、中医养生游戏、积分排行榜、人脸识别、手表接入、双定位、Agent 预问诊、医生审核和会诊等，需要继续增加对应的数据表。这样可以保证每个业务模块的数据结构独立，方便后续维护、扩展和上线。

如果老师问为什么不现在全部建表，可以这样回答：

> 当前阶段以毕业设计核心功能为主，所以数据库只保留已经使用的核心表。未来 APP 功能属于扩展规划，如果提前全部建表，会增加系统复杂度。后续可以按照功能迭代逐步增加表结构。
