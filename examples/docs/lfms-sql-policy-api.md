# LFMS SQL Gateway API — Yêu cầu triển khai (Dify Embed)

Tài liệu cho team LFMS implement API phía server.

Dify chỉ: LLM sinh SQL → gọi LFMS → nhận `data[]` → tóm tắt tiếng Việt.

**LFMS giữ toàn bộ:** policy theo user, rewrite SQL, execute DB, audit.

**Dify không** cần credential MySQL / plugin `sql_execute`.

---

## 1. Tổng quan luồng

### 1.1 Embed (khuyến nghị — ít code LFMS UI)

```
[User đã login LFMS]
  → LFMS cấp embed_token (JWT ngắn hạn)
  → Trang LFMS nhúng iframe Dify + truyền lfms_token (hidden input / query)
  → User chat trong iframe
  → Dify workflow: LLM sinh SQL
  → POST LFMS /sql/execute (HMAC + embed_token)
  → LFMS: verify → policy → chạy SQL → trả data[]
  → Dify LLM tóm tắt → hiển thị trong iframe
```

### 1.2 Hai lớp xác thực

| Lớp                    | Mục đích                                               | Ai cấp                   |
| ---------------------- | ------------------------------------------------------ | ------------------------ |
| **HMAC (service)**     | Chứng request từ Dify server (chống gọi API trái phép) | Secret chung LFMS ↔ Dify |
| **embed_token (user)** | Chứng user LFMS nào (org, role, user_id)               | LFMS khi render iframe   |

**Không tin** `user_id` / `organization_id` / `role` gửi plain trong body nếu client có thể sửa.

Chỉ tin sau khi **verify embed_token** (hoặc session server-side khi cấp token).

---

## 2. Endpoint cấp token embed (LFMS — bắt buộc cho embed)

### `POST /api/embed/dify-token`

Gọi từ **trang LFMS đã login** (session cookie / Sanctum). Không public anonymous.

**Response `200`**

```json
{
  "embed_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_in": 900,
  "token_type": "Bearer"
}
```

**JWT payload gợi ý (claims)**

```json
{
  "sub": "12345",
  "org_id": 1,
  "role": "lawyer",
  "iat": 1690000000,
  "exp": 1690000900,
  "jti": "uuid"
}
```

| Claim    | Mô tả                                                   |
| -------- | ------------------------------------------------------- |
| `sub`    | `users.id` LFMS (string hoặc int)                       |
| `org_id` | `organization_id`                                       |
| `role`   | Slug quyền: `lawyer`, `org_admin`, `webapp_readonly`, … |
| `exp`    | TTL ngắn (5–15 phút); refresh khi reload trang embed    |

**Trang LFMS** đưa `embed_token` vào URL embed Dify (hidden start variable `lfms_token`).

---

## 3. Endpoint thực thi SQL (LFMS — bắt buộc)

### `POST /api/internal/dify/sql/execute`

Dify workflow gọi sau khi LLM sinh SQL. LFMS evaluate policy **và** execute **trong một request**.

### 3.1 Headers

| Header             | Bắt buộc    | Mô tả                                |
| ------------------ | ----------- | ------------------------------------ |
| `Content-Type`     | Có          | `application/json`                   |
| `X-Dify-Timestamp` | Có          | Unix epoch (giây), chống replay      |
| `X-Dify-Nonce`     | Có          | UUID, dùng một lần (cache 5–10 phút) |
| `X-Dify-Signature` | Có          | HMAC-SHA256 hex (xem §3.2)           |
| `X-Request-Id`     | Khuyến nghị | UUID audit                           |

### 3.2 HMAC — cách ký (Dify Code node hoặc proxy)

```
signing_string = timestamp + "\n" + nonce + "\n" + method + "\n" + path + "\n" + sha256_hex(raw_body)
signature = HMAC_SHA256(signing_string, DIFY_LFMS_HMAC_SECRET)
```

- `path` = `/api/internal/dify/sql/execute` (không domain).
- `raw_body` = JSON string **đúng bytes** gửi đi (không pretty-print lệch).
- Server reject nếu `|now - timestamp| > 300` giây hoặc nonce trùng.

Env LFMS: `DIFY_LFMS_HMAC_SECRET`

Env Dify (workflow env var): cùng secret.

### 3.3 Request body

```json
{
  "embed_token": "eyJhbGciOiJIUzI1NiIs...",
  "sql": "SELECT c.name, c.email FROM clients c WHERE c.deleted_at IS NULL LIMIT 100",
  "natural_language_query": "Danh sách khách hàng đang hoạt động",
  "request_id": "550e8400-e29b-41d4-a716-446655440000",
  "context": {
    "source": "dify",
    "app": "text_to_sql_chatflow",
    "dify_conversation_id": "550e8400-e29b-41d4-a716-446655440000",
    "dify_user_id": "lfms-12345-1~3",
    "conversation_title": "Danh sách khách hàng đang hoạt động"
  }
}
```

| Field                          | Type   | Bắt buộc    | Mô tả                                                                                           |
| ------------------------------ | ------ | ----------- | ----------------------------------------------------------------------------------------------- |
| `embed_token`                  | string | Có*         | JWT từ §2. *Bỏ qua chỉ khi role cố định public readonly có flag nội bộ                          |
| `sql`                          | string | Có          | SQL từ LLM (đã tách khối `sql`). Rỗng → `ok: false`                                             |
| `natural_language_query`       | string | Không       | Câu hỏi gốc — audit + chặn intent (“super admin”, …)                                            |
| `request_id`                   | string | Khuyến nghị | Idempotency / audit                                                                             |
| `context`                      | object | Không       | Metadata. LFMS ghi clock khi có `dify_conversation_id` (UUID) và `dify_user_id` (`sys.user_id`) |
| `context.dify_conversation_id` | string | Không       | `sys.conversation_id`. Thiếu hoặc không phải UUID → execute vẫn chạy, không ghi lịch sử         |
| `context.dify_user_id`         | string | Không       | `sys.user_id` (có thể hậu tố `~n`). Bắt buộc để mở lại đúng thread                              |
| `context.conversation_title`   | string | Không       | `sys.query` lần đầu. Các lượt sau không ghi đè tiêu đề đã có                                    |

**`sql_encrypted` (tùy chọn phase 2):** AES-GCM blob thay `sql` nếu cần; phase 1 có thể chỉ `sql` qua TLS.

### 3.4 Xử lý server (thứ tự)

1. Verify HMAC + timestamp + nonce.
2. Verify `embed_token` → `sub`, `org_id`, `role`.
3. Parse SQL; chỉ `SELECT`; deny stacked queries.
4. Policy theo `role` + `org_id` + `user_id` (bảng/cột/intent).
5. Rewrite SQL (inject `organization_id`, `deleted_at IS NULL`, lọc super admin…).
6. Execute trên DB user readonly / connection pool LFMS.
7. `LIMIT` cứng server-side (vd. max 100 rows).
8. Audit log.

### 3.5 Response — thành công (`HTTP 200`)

```json
{
  "ok": true,
  "data": [
    { "name": "Công ty A", "email": "a@example.com" },
    { "name": "Công ty B", "email": "b@example.com" }
  ],
  "columns": ["name", "email"],
  "row_count": 2,
  "message": null,
  "violations": [],
  "policy_version": "2026-09-15"
}
```

- `data`: **array** — có thể `[]` (không có bản ghi) vẫn `ok: true`.
- `columns`: tên cột (giúp Dify tóm tắt).
- `row_count`: số hàng trả về.

### 3.6 Response — từ chối policy (`HTTP 200` hoặc `403` — chọn một convention)

```json
{
  "ok": false,
  "data": [],
  "columns": [],
  "row_count": 0,
  "message": "Không có quyền truy vấn bảng users",
  "violations": [
    {
      "type": "table",
      "name": "users",
      "code": "TABLE_DENIED"
    }
  ],
  "policy_version": "2026-09-15"
}
```

| Field               | Mô tả                                                                                   |
| ------------------- | --------------------------------------------------------------------------------------- |
| `ok`                | `true` = có kết quả hợp lệ; `false` = không chạy / không trả data                       |
| `data`              | Luôn array khi parse JSON thành công                                                    |
| `message`           | Tiếng Việt — Dify hiển thị cho user                                                     |
| `violations[].type` | `table` \| `column` \| `statement` \| `intent` \| `limit`                               |
| `violations[].code` | `TABLE_DENIED`, `COLUMN_DENIED`, `NOT_SELECT`, `TOKEN_EXPIRED`, `SUPER_ADMIN_DENIED`, … |

### 3.7 Lỗi HTTP

| Status | Khi                             |
| ------ | ------------------------------- |
| `401`  | HMAC sai / thiếu                |
| `401`  | `embed_token` invalid / expired |
| `422`  | Body không hợp lệ               |
| `429`  | Rate limit                      |
| `503`  | DB / policy service down        |

Body lỗi: `{"message": "...", "code": "HMAC_INVALID"}`.

**Fail closed:** token lỗi, parse SQL lỗi, role không map policy → `ok: false`, không execute.

---

## 4. Policy theo role (LFMS nội bộ)

| `role` (từ JWT)   | Gợi ý                          |
| ----------------- | ------------------------------ |
| `webapp_readonly` | Hẹp nhất; embed public nếu cần |
| `lawyer`          | Data trong `org_id` của user   |
| `org_admin`       | Rộng hơn trong org             |
| `system`          | Không qua embed WebApp         |

Mapping `role → allowed_tables / denied_columns / row_filters` — DB hoặc config LFMS, **không** hardcode Dify.

---

## 5. Tích hợp Dify (tham chiếu)

Workflow (`text_to_sql_workflow_agent.yml`):

```
Kiểm Tra Embed LFMS → Cổng Embed (token + api_base hợp lệ?)
  ├─ false → Từ Chối Embed (Answer text cứng từ Code)
  └─ true  → Knowledge → Sinh SQL
  → Chuẩn Bị Execute Request (sql + lfms_token + HMAC)
  → Gọi LFMS Execute (HTTP POST)
  → Parse Execute Response
  → Phân Luồng → Tóm Tắt / Từ Chối
```

**Start variable (User Input / Bắt đầu):**

| Thuộc tính      | Giá trị                                                                                                                             |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Biến            | Mô tả                                                                                                                               |
| ------          | --------                                                                                                                            |
| `lfms_token`    | JWT embed (Paragraph, Hidden, không Required)                                                                                       |
| `lfms_api_base` | Base URL LFMS **không** slash cuối (Paragraph, Hidden). VD `https://lfms-dev.truyenfox.net` hoặc `http://host.docker.internal:8010` |

Cả hai do LFMS truyền qua query embed (xem §6). Label = tên biến, không dùng nhãn hiển thị riêng.

Node **Gọi LFMS Execute** URL: `{{#validate_embed.api_base#}}/api/internal/dify/sql/execute`.

Node **Chuẩn Bị Execute Request** map `validate_embed.embed_token` → `embed_token` trong body HTTP.

WebApp `/chat/...` **không** giải nén query (khác `/chatbot` + `embed.js`). LFMS hay gửi gzip+base64 (`H4sI…`). Node **Kiểm Tra Embed** tự `gzip.decompress` rồi mới check JWT / `http(s)`.

**Workflow env (secret):** `DIFY_LFMS_HMAC_SECRET` — cùng giá trị LFMS.

### 5.1 Agent app (`/agent/...`) — không tự có user

Agent Studio **không** gắn `lfms_token`. Execute vẫn cần JWT + HMAC. Test: User Input `lfms_token` + `lfms_api_base`, env HMAC, CLI `examples/agent/lfms_sql_execute.py`. Không dùng URL `/agent/` cho khách; bubble LFMS chỉ `/chatbot/` Chatflow.

**Preview Studio:** không truyền `lfms_token` / `lfms_api_base` thì nhánh **Từ Chối Embed** chạy ngay (đúng). Mở **User Input** trên panel Preview nếu muốn điền tay để test happy path.

**Không dùng:** plugin `sql_execute`, credential MySQL trên Dify.

**Cấu hình sau import**

- **Không hardcode domain** — dùng Start `lfms_api_base` (LFMS truyền khi embed)
- Docker Dify → LFMS local: `lfms_api_base=http://host.docker.internal:8010` (port = host map `lfms-web`, vd. `8010:80`)
- SSRF: allowlist domain host trong `SSRF_PROXY_ALLOW_PRIVATE_DOMAINS` (vd. `host.docker.internal,lfms-dev.truyenfox.net`) + `docker compose -p dify up -d --force-recreate ssrf_proxy`
- Lỗi **HTTP 503** từ node HTTP thường = **sai port** hoặc không có service lắng nghe trên `host.docker.internal:<port>`

---

## 6. Trang embed LFMS (pseudo)

```javascript
// Sau khi user login LFMS
const { embed_token } = await fetch('/api/embed/dify-token', {
  credentials: 'include',
}).then((r) => r.json())

// Query param = tên biến Start (lfms_token).
// Có thể gửi JWT/URL thô HOẶC gzip+base64 (H4sI…, kiểu embed.js) — workflow tự giải nén.
const lfmsApiBase = window.location.origin
const iframeUrl =
  `https://dify.example.com/chat/${DIFY_APP_CODE}` +
  `?lfms_token=${encodeURIComponent(embed_token)}` +
  `&lfms_api_base=${encodeURIComponent(lfmsApiBase)}`
```

**Quy tắc**

- Tên query / hidden input **phải khớp** `variable` trên Start node (`lfms_token`), không phải label hiển thị.
- User **không nhập** token — LFMS cấp sau login; Dify chỉ chuyển tiếp sang LFMS Execute.
- **Nhận dạng user** do LFMS khi verify `embed_token` (claims `sub`, `org_id`, `role`), không tin giá trị client tự gõ trên Dify.

---

## 7. Ví dụ curl (LFMS test)

### Cấp token (user đã login)

```bash
curl -sS -X POST 'http://localhost:8000/api/embed/dify-token' \
  -H 'Cookie: laravel_session=...'
```

### Execute (giả lập Dify)

```bash
BODY='{"embed_token":"...","sql":"SELECT COUNT(*) AS cnt FROM clients WHERE deleted_at IS NULL","natural_language_query":"bao nhiêu khách","request_id":"test-1","context":{"source":"dify"}}'
TS=$(date +%s)
NONCE=$(uuidgen)
PATH='/api/internal/dify/sql/execute'
# Ký HMAC theo §3.2 → SIG

curl -sS -X POST "http://localhost:8000${PATH}" \
  -H 'Content-Type: application/json' \
  -H "X-Dify-Timestamp: $TS" \
  -H "X-Dify-Nonce: $NONCE" \
  -H "X-Dify-Signature: $SIG" \
  -d "$BODY"
```

---

## 8. Checklist implement LFMS

- [ ] `POST /api/embed/dify-token` (session auth)
- [ ] JWT sign/verify (`LFMS_EMBED_JWT_SECRET`)
- [ ] `POST /api/internal/dify/sql/execute`
- [ ] Middleware HMAC (`DIFY_LFMS_HMAC_SECRET`)
- [ ] Nonce store + timestamp window
- [ ] SQL parser + policy engine + rewrite
- [ ] Execute DB (user readonly / view)
- [ ] Rate limit theo `sub` / IP
- [ ] Audit: `request_id`, `sub`, `org_id`, `role`, sql hash, `ok`, `row_count`
- [ ] Tests: deny table/column/super admin; allow scoped org; empty `data[]`; expired token; bad HMAC

---

## 9. Deprecation

`POST /api/internal/dify/sql-policy/evaluate` (chỉ evaluate, trả `sanitized_sql`) — **không dùng** trong kiến trúc mới.

Gộp evaluate + execute vào `/sql/execute`.

---

## 10. Env vars

| Biến                    | Nơi         | Mô tả                       |
| ----------------------- | ----------- | --------------------------- |
| `LFMS_EMBED_JWT_SECRET` | LFMS        | Ký `embed_token`            |
| `DIFY_LFMS_HMAC_SECRET` | LFMS + Dify | HMAC request Dify → LFMS    |
| `DIFY_SQL_MAX_ROWS`     | LFMS        | Giới hạn hàng (default 100) |
