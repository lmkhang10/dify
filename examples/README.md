# Text-to-SQL examples (LFMS)

Plugin + Knowledge + workflow DSL.

| File                             | Loại                         | Ghi chú                                                                                             |
| -------------------------------- | ---------------------------- | --------------------------------------------------------------------------------------------------- |
| `text_to_sql_knowledge.yml`      | Workflow thuần               | Form chạy 1 lần; LLM + guardrail + `sql_execute`                                                    |
| `text_to_sql_agent.yml`          | Agent app                    | Debug Studio `/agent/...` — không có session LFMS; User Input JWT + HMAC CLI                        |
| `text_to_sql_workflow_agent.yml` | **Chatflow** (advanced-chat) | KB → LLM SQL → **LFMS SQL Gateway** (`/sql/execute`) → tóm tắt; spec: `docs/lfms-sql-policy-api.md` |

Khách không mở `/agent/...`. Bubble LFMS chỉ nhúng **Chatflow** `/chatbot/...`.

### Ngữ cảnh nhiều lượt (Chatflow)

`text_to_sql_workflow_agent.yml` có node **Rewrite câu hỏi** (memory, `query` template phải chứa `{{#sys.query#}}`) → Knowledge query = câu đã rewrite → Sinh SQL.

Import DSL **không** giữ model/dataset của app cũ. Checklist(12) sau import: chọn lại model trên mọi LLM (kể cả Rewrite), gắn lại Knowledge, cài/authorize plugin ECharts, xóa node **Lưu câu độc lập** nếu còn trôi (unconnected). Không import đè nếu app đã chạy — chỉ thêm Rewrite rồi nối `embed_guard true → rewrite → knowledge`.

### Agent Studio không qua được API — đúng thiết kế

`POST /api/internal/dify/sql/execute` cần **hai** lớp:

1. HMAC (`DIFY_LFMS_HMAC_SECRET`) — chứng request từ Dify
2. `embed_token` JWT — chứng **user/org** LFMS

URL `http://localhost/agent/<id>` không nhận query gzip `lfms_token` như `/chatbot/`. Không có JWT → LFMS không biết user nào.

**Test trên `/agent/`:**

1. Login LFMS (cùng org cần hỏi dữ liệu).
2. `POST /api/embed/dify-token` (cookie session) → copy `embed_token`.
3. Agent Studio → User Input: `lfms_token` = JWT thô (không gzip), `lfms_api_base` = origin LFMS mà container Dify gọi được (`http://host.docker.internal:8010` hoặc URL public).
4. Environment: `DIFY_LFMS_HMAC_SECRET` trùng `apps/.env`.
5. CLI `lfms_sql_execute` (`examples/agent/lfms_sql_execute.py`): map env `LFMS_EMBED_TOKEN` / `LFMS_API_BASE` từ hai input trên; sửa `command` nếu sandbox không mount `/app/examples/...`.

Không dán JWT một user vào env toàn cục (mọi cuộc chat sẽ mượn quyền người đó).

**Production:** Chatflow `text_to_sql_workflow_agent.yml` + bubble Admin.

## Bảo mật — không lộ SQL cho khách (không sửa source Dify)

Skill chỉ điều khiển **chữ** agent trả lời. Khối `sql_execute` → REQUEST / RESPONSE trên màn hình Agent là **UI debug của Dify** — không có setting tắt, skill cũng không chặn được.

| Màn hình                                         | SQL có hiện không?                   |
| ------------------------------------------------ | ------------------------------------ |
| `http://localhost/agent/...` (Studio Agent)      | Có — luôn hiện tool REQUEST/RESPONSE |
| WebApp của **Agent**                             | Vẫn hiện tool (cùng component)       |
| **Workflow** + WebApp, tắt “Show workflow steps” | Không — khách chỉ thấy output cuối   |

**Cách dùng đúng cho khách (không fork Dify):**

1. Import **`text_to_sql_workflow_agent.yml`** (ưu tiên) hoặc `text_to_sql_knowledge.yml`. Không đưa URL `/agent/...` cho khách.
2. **Overview → Settings** → tắt **Show workflow steps** (chỉ có trên Workflow / Chatflow).
3. **Publish** → đưa link **WebApp / Access Point** cho khách.
4. Studio Agent (`/agent/...`) chỉ để builder debug — chấp nhận thấy SQL ở đó.

Nếu bắt buộc dùng Agent: chỉ gọi qua **API** và tự render `answer` trên UI riêng (bỏ qua `agent_thought` / tool payload). Không có cách config thuần trên Agent Studio.

## Thứ tự

1. Cài plugin: Plugins → **Install plugin** → **Install from local file** → `plugins/dify-plugin-database-0.0.5.difypkg`
2. **Knowledge** (menu trái) → Create → upload hết file trong `knowledge/`
3. Skills → upload `skills/lfms-sql-guarded.skill` (policy trong Skill). Gỡ `lfms-sql-readonly` nếu đang gắn — **một** skill SQL thôi.
4. **Authorize plugin** — xem mục dưới
5. Chọn một app:
   - **Chatflow có chat (khuyến nghị):** Import `text_to_sql_workflow_agent.yml` → LFMS implement `docs/lfms-sql-policy-api.md` (embed_token + `/sql/execute` + HMAC) → cấu hình HTTP node Dify → gắn Knowledge, chọn model → Overview tắt Show workflow steps → Publish WebApp + embed từ LFMS
   - **Workflow thuần (form, không chat):** Import `text_to_sql_knowledge.yml` → gắn Knowledge (bước dưới)
   - **Agent app (debug):** Import `text_to_sql_agent.yml` → gắn Knowledge + Skill, chọn model

## Authorize DB (khách không cần biết URI)

Plugin `hjlarry/database` lấy URI từ **credential workspace**, không từ chat.

1. **Plugins** → tìm **Database** (`hjlarry/database`) → **Authorize** / **API Key** / **Credentials**
2. Dán URI (đúng dialect `pymysql`, không phải `mysql://`):

   ```
   mysql+pymysql://lfms_user:secret@host.docker.internal:3306/lfms_db
   ```

   - Docker Desktop (API trong container → MySQL trên máy host): `host.docker.internal`
   - MySQL cùng Docker network: tên service (vd. `mysql`) thay vì `localhost`

3. Save / Verify (plugin chạy `SELECT 1`)
4. Mở Agent app → Tools `sql_execute` / `table_schema` phải hiện **Authorized** (không còn `unauthorized`)
5. Publish lại app

Sau bước này khách chỉ hỏi nghiệp vụ; agent **không** xin `db_uri`.

## Bước 4 — gắn Knowledge (trong Studio, không phải file YAML)

`dataset_ids` **không hiện trên UI**. Đó là ID trong YAML. Gắn bằng click:

1. Studio → mở app **Text-to-SQL Knowledge (LFMS)** (phải vào **canvas workflow**, không phải màn hình chat/preview).
2. Trên canvas, node thứ 2 (sau **Yêu Cầu Từ Người Dùng**) tên **Knowledge Retrieval**. Click vào node đó.
3. Panel phải → mục **Knowledge** / **Kiến thức** (có dấu bắt buộc).
4. Click nút **+** cạnh tiêu đề đó.
5. Tick dataset vừa tạo ở bước 2 → Add / Confirm.
6. **Save** (góc phải trên).

Nếu canvas không có node **Knowledge Retrieval**, đang mở nhầm app khác (app schema cứng / Chatbot). Import lại đúng `text_to_sql_knowledge.yml`.

Publish sẽ fail với “Knowledge is required” nếu chưa chọn dataset.

## Knowledge mới / đổi file

Sửa file trên đĩa **không** đổi câu SQL Dify đang sinh. Studio → Knowledge → dataset LFMS → **Add file** (gồm `knowledge/enums.md`) → **Save & Process / Index** lại toàn bộ chunk. Chunk cũ còn `'paid'`/`inbound` thì model vẫn copy.

Câu tiếng Việt cần **từ điển** (tổ chức → `organizations`, nhân viên → `users`), không chỉ DESCRIBE cột.

## Host DB

`host.docker.internal:3306`. User/pass/db default trên form Start.
