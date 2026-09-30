# 后端启动与 AI 引擎状态检查

当前架构不是把两个后端物理合并到同一个文件夹，而是：

- APP / PC 只访问 Spring Boot：`http://<电脑IP>:8181`
- Spring Boot 内部访问 Node AI 引擎：`http://127.0.0.1:8787`
- Node 保留 `LLM / Prompt / LangGraph` 编排能力

## 启动顺序

1. 启动 Node AI 引擎

```powershell
cd D:\yangshengzhushou\yangshengzhushou_db
npm start
```

2. 启动 Spring Boot 主后端

```powershell
cd D:\SpringBoot\SpringBootDemo
mvn spring-boot:run
```

3. APP / PC 只配置 Spring Boot 地址

```text
http://<电脑IP>:8181
```

## AI 状态检查

Spring Boot 提供统一检查接口：

```http
GET http://127.0.0.1:8181/api/ai/status
Authorization: Bearer <登录token>
```

Node AI 在线时返回：

```json
{
  "nodeAvailable": true,
  "mode": "node-ai",
  "nodeStatus": "ok",
  "nodeBaseUrl": "http://127.0.0.1:8787",
  "message": "Node AI engine is available."
}
```

Node AI 未启动或不可达时返回：

```json
{
  "nodeAvailable": false,
  "mode": "springboot-fallback",
  "nodeStatus": "unavailable",
  "nodeBaseUrl": "http://127.0.0.1:8787",
  "message": "Node AI engine is unavailable. Spring Boot fallback is active."
}
```

## 部署配置

Spring Boot 的 Node AI 地址通过环境变量配置：

```text
NODE_AI_BASE_URL=http://127.0.0.1:8787
NODE_AI_TIMEOUT_MS=6000
```

上线时 APP / PC 不应直接访问 Node `8787`。Node 只作为 Spring Boot 内部 AI 子服务存在。
