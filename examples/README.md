# Text-to-SQL examples (LFMS)

Plugin + Knowledge + workflow DSL.

| File                             | Loại                         | Ghi chú                                                                                             |
| -------------------------------- | ---------------------------- | --------------------------------------------------------------------------------------------------- |
| `text_to_sql_knowledge.yml`      | Workflow thuần               | Form chạy 1 lần; LLM + guardrail + `sql_execute`                                                    |
| `text_to_sql_agent.yml`          | Agent app                    | Chat Agent trực tiếp (`/agent/...`) — hiện tool debug                                               |
| `text_to_sql_workflow_agent.yml` | **Chatflow** (advanced-chat) | KB → LLM SQL → **LFMS SQL Gateway** (`/sql/execute`) → tóm tắt; spec: `docs/lfms-sql-policy-api.md` |

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

Upload thêm `knowledge/glossary.md` và `knowledge/organizations.md` vào dataset đã tạo (Add file), rồi **Index**. Không cần tạo dataset mới.

Câu tiếng Việt cần **từ điển** (tổ chức → `organizations`, nhân viên → `users`), không chỉ DESCRIBE cột.

## Host DB

`host.docker.internal:3306`. User/pass/db default trên form Start.
