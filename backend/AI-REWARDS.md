# AI and Rewards Operations

The application serves the app API on port 8181. Conversation and daily suggestions both use `app.health-ai`; no Node or local-model fallback is attempted. The default provider/model is `deepseek` / `deepseek-chat`. Set `DEEPSEEK_API_KEY` in the backend process environment. `DEEPSEEK_BASE_URL` and `DEEPSEEK_MODEL` are optional overrides. Do not put credentials in source control or browser storage.

An explicitly chosen local OpenAI-compatible service uses `HEALTH_AI_PROVIDER=local`, `HEALTH_AI_BASE_URL`, and `HEALTH_AI_MODEL`. Remove any `DEEPSEEK_*` overrides when choosing that option. The base URL excludes `/chat/completions`. `HEALTH_AI_TIMEOUT` defaults to 45 seconds; request timeouts are capped at 120 seconds. Missing keys, provider errors, invalid JSON, and empty model content fail the request. MySQL keyword knowledge retrieval remains active; Milvus stays optional.

`GET /api/ai/status` reports the configured provider/model and the last completed model request status. `not_checked` means no model call has completed in this process; it is not a health guarantee. No synthetic answer is used as evidence of availability.

## Points and Recovery

New accounts have zero points. `POST /api/rewards/check-in` grants 10 points once per calendar day in `Asia/Shanghai`. Daily suggestions are free. A successful chat costs one point; reserve/settle/release operations and the ledger are persisted in MySQL.

Chat requests require a stable `requestId` (maximum 100 characters). Persist the ID before sending. Retrying the same ID and content returns a stored completed reply without a second charge. A pending ID returns HTTP 409, insufficient points returns 402, and a failed model returns 503. After a disconnect, use `GET /api/ai/chat/{requestId}`. The response envelope contains `data.status` (`PENDING`, `SUCCEEDED`, or `FAILED`), `data.reply`, and `data.error`. A failed ID is terminal; an intentional new attempt needs a new ID. Abandoned reservations expire after three minutes and are released when the user next accesses their account, check-in, chat, recovery, or order endpoint. A result arriving after expiry is not charged.

Legacy AI generation through `POST /health-question` or `POST /api/health-question` is retired with HTTP 410. Clients must use `/api/ai/chat` with a request ID so requests cannot bypass the point ledger or rate limiter. Existing history and administrator manual-answer endpoints remain available. Chat accepts both `role`/`content` history entries and legacy `question`/`answer` pairs.

`GET /api/rewards/account` returns `balance`, `reserved`, `available`, `checkedInToday`, `dailyCheckInPoints`, and `chatCost`. `GET /api/rewards/ledger` returns the latest 200 entries, with `delta`, `type`, `reference`, and `createdAt`. Rewards and recovery use the existing `{code,message,data}` envelope.

## Catalog and Orders

The startup initializer creates five reward tables with no seed products. The configured database must allow table creation and use transactional InnoDB tables. Administrators add actual inventory through `POST /api/rewards/admin/products`; update an item with `PUT /api/rewards/admin/products/{id}`. The payload is `{name,description,imageUrl,points,stock,active}`. All administrative routes require the existing `ADMIN` role.

`GET /api/rewards/products` lists active products. `POST /api/rewards/orders` accepts `{requestId,productId,recipient,phone,address,addressConfirmed:true}`. Each order is one item; stock decrement, point debit, order insertion, and ledger insertion commit together. Repeating the same order request is idempotent. The delivery address is stored as a confirmed snapshot. The user can only list their own orders through `GET /api/rewards/orders`.

Administrators list orders with `GET /api/rewards/admin/orders` and mark a pending order shipped through `POST /api/rewards/admin/orders/{id}/fulfill`, with `{carrier,trackingNumber}`. Carrier booking, shipping payment, returns, cancellations, and refunds for physical goods are outside this implementation; operators must arrange shipment before entering tracking details.

Verification uses local HTTP model stubs and H2 in MySQL compatibility mode, including concurrent reservations and last-item redemption. A live DeepSeek response and a production MySQL integration run require the deployment environment and are not represented by these tests.
