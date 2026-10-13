# 茹安阁 (RuAnGe)

> 一款基于 HarmonyOS + Spring Boot 的智能健康养生管理应用，融合 AI 对话、舌象分析、健康档案、在线问诊、亲人关怀等功能。

![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-green)
![HarmonyOS](https://img.shields.io/badge/HarmonyOS-5.0-red)
![MySQL](https://img.shields.io/badge/MySQL-8.0-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

## ✨ 功能特色

### 👤 用户端
- **AI 养生助手** — 智能对话问答，场景化健康建议，基于 RAG 知识库
- **健康档案** — 血压、血糖、心率、睡眠、体重、BMI 等 10+ 种健康指标记录与趋势分析
- **舌象分析** — 舌象照片上传、AI 智能分析、历史记录对比
- **在线问诊** — 图文问诊、医生推荐、健康快照一键发送
- **亲人关怀** — 邀请家人、健康数据共享、授权管理、实时关注
- **每日建议** — 基于个人健康数据的个性化养生建议生成
- **积分奖励** — 健康打卡、任务完成、积分兑换

### 👨‍⚕️ 医生端
- **工作台** — 待处理问诊、今日预约、数据概览
- **问诊管理** — 图文接诊、消息收发、健康快照查看
- **患者管理** — 患者列表、健康档案查看、随访记录
- **投诉申诉** — 投诉处理、申诉提交、处罚记录

### 🔧 管理员端
- **用户管理** — 用户列表、角色分配、状态管理
- **医生审核** — 资质审核、医生列表、状态管理
- **问诊管理** — 全部问诊、投诉处理、申诉裁决
- **知识库管理** — RAG 私有知识库、词条管理
- **AI 对话日志** — 助手对话记录、问题统计

---

## 🏗️ 技术架构

```
┌─────────────────────────────────────────────────────┐
│                    HarmonyOS App                     │
│         ArkTS / ArkUI / HarmonyOS 5.0               │
└──────────────────────┬──────────────────────────────┘
                       │ HTTPS / RESTful API
┌──────────────────────▼──────────────────────────────┐
│                 Spring Boot 后端                     │
│  Spring Boot 3.x + MyBatis + MySQL + Redis(可选)     │
├─────────────────────────────────────────────────────┤
│  用户认证  │  健康档案  │  AI 助手  │  问诊系统     │
│  舌象分析  │  亲人关怀  │  积分系统  │  投诉申诉     │
└───────────┬───────────────────────────┬─────────────┘
            │                           │
   ┌────────▼────────┐        ┌─────────▼─────────┐
   │   MySQL 数据库   │        │  Node.js AI 引擎   │
   │  ruange_db      │        │  LLM / RAG / 舌象  │
   └─────────────────┘        └───────────────────┘
```

---

## 📁 项目结构

```
ruange/
├── entry/                      # HarmonyOS 前端 App
│   └── src/main/ets/
│       ├── components/         # 组件
│       │   ├── tabs/           # 底部导航 Tab（首页/健康/问诊/亲人/我的）
│       │   ├── profile/        # 健康档案相关组件
│       │   ├── family/         # 亲人关怀组件
│       │   ├── consultation/   # 问诊相关组件
│       │   ├── doctor/         # 医生端组件
│       │   └── admin/          # 管理员端组件
│       ├── pages/              # 页面
│       ├── services/           # 网络服务 & 业务逻辑
│       └── theme/              # 主题样式
│
├── backend/                    # Spring Boot 后端
│   └── src/main/
│       ├── java/org/example/springbootdemo/
│       │   ├── controller/     # 控制层（REST API）
│       │   ├── service/        # 业务层
│       │   ├── dao/            # 数据访问层
│       │   ├── bean/           # 实体类
│       │   ├── auth/           # 认证与权限
│       │   ├── rag/            # RAG 知识库
│       │   ├── rewards/        # 积分奖励
│       │   ├── ai/             # AI 相关（舌象/对话）
│       │   └── config/         # 配置与数据库初始化
│       └── resources/
│           ├── db/             # SQL 脚本
│           └── org.example.springbootdemo/  # MyBatis Mapper XML
│
├── docs/                       # 项目文档
│   ├── 茹安阁三端完整说明文档.md
│   ├── 技术实现.md
│   └── ...
│
├── 上架材料/                    # 应用商店上架材料
│   ├── 截图/                   # App 截图
│   ├── 用户协议.html
│   ├── 隐私政策.html
│   └── 应用商店文案.md
│
└── scripts/                    # 工具脚本
```

---

## 🚀 快速开始

### 环境要求

| 组件 | 版本要求 |
|------|----------|
| JDK | 17+ |
| Maven | 3.8+ |
| MySQL | 8.0+ |
| Node.js | 18+（AI 引擎可选） |
| DevEco Studio | 5.0+（前端开发） |
| HarmonyOS | 5.0+（运行环境） |

### 1. 启动后端

```bash
# 进入后端目录
cd backend

# 配置数据库
# 修改 src/main/resources/application.yml 中的数据库连接信息

# 启动
./mvnw spring-boot:run
# Windows: mvnw.cmd spring-boot:run
```

后端默认端口：`8181`

### 2. 配置 AI（可选）

如需启用 AI 对话和建议生成功能，配置环境变量：

```powershell
# DeepSeek API（Java 原生 AI 回退）
$env:DEEPSEEK_API_KEY = "sk-xxx"

# Node.js AI 引擎地址（推荐，支持 RAG 和更复杂的编排）
$env:NODE_AI_BASE_URL = "http://127.0.0.1:8787"
```

### 3. 启动前端

使用 **DevEco Studio** 打开项目根目录，选择 `entry` 模块，连接设备或模拟器后点击运行。

---

## 📡 API 概览

### 认证模块
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/send-code` | 发送验证码 |
| POST | `/api/auth/login` | 验证码登录 |
| POST | `/api/auth/logout` | 退出登录 |

### 用户模块
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/user/me` | 获取当前用户信息 |
| PUT | `/api/user/profile` | 更新用户资料 |
| POST | `/api/user/avatar-credential` | 获取头像上传凭证 |

### 健康档案
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/health-card` | 健康卡摘要 |
| GET | `/api/health-measurements` | 测量记录列表 |
| POST | `/api/health-measurements` | 新增测量记录 |
| GET | `/api/health-archives` | 健康档案列表 |

### 舌象照片
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/tongue-images` | 照片列表 |
| POST | `/api/tongue-images` | 创建照片记录 |
| POST | `/api/tongue-images/{id}/analyze` | 请求 AI 分析 |
| POST | `/api/tongue-images/upload-credential` | 获取上传凭证 |

### AI 助手
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/ai/chat` | 对话聊天 |
| POST | `/api/ai/suggestions` | 场景化建议 |
| GET | `/api/health-questions` | 健康问答 |

### 问诊系统
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/consultations` | 问诊列表 |
| POST | `/api/consultations` | 创建问诊 |
| GET | `/api/consultations/{id}/health-snapshot` | 健康快照 |
| POST | `/api/consultations/{id}/rating` | 提交评价 |

### 亲人关怀
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/family/invite` | 邀请亲人 |
| GET | `/api/family/members` | 亲人列表 |
| GET | `/api/family/members/{id}/health-card` | 亲人健康卡 |
| PUT | `/api/family/members/{id}/share-settings` | 更新共享授权 |

> 完整 API 文档请参考后端源码及 `docs/` 目录。

---

## 🧪 运行测试

```bash
cd backend
./mvnw test
```

后端包含约 **50+** 个单元测试类，覆盖 Controller、Service、配置初始化等核心模块。

---

## 📚 相关文档

- [茹安阁三端完整说明文档](docs/养生助手三端完整说明文档.md) — 产品功能完整说明
- [技术实现](docs/技术实现.md) — 技术架构与实现细节
- [用户端健康与亲人关怀实现文档](docs/用户端健康与亲人关怀实现文档.md) — 健康 & 亲人模块详情
- [管理员端实现文档](docs/管理员端实现文档.md) — 管理后台功能说明
- [后端启动与 AI 状态](docs/backend-startup-and-ai-status.md) — 后端部署与 AI 配置
- [发布检查清单](docs/release-checklist.md) — 版本发布检查项

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📄 许可证

本项目采用 MIT 许可证 — 详见 [LICENSE](LICENSE) 文件。

---

## 📮 联系方式

如有问题或建议，欢迎通过 GitHub Issues 联系我们。
