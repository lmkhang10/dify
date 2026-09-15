---
name: lfms-sql-readonly
description: Write and run read-only MySQL SELECT for LFMS. Never expose SQL or schema to end users. Never invent columns, never mutate data.
---

# lfms-sql-readonly

Convert Vietnamese or English questions into one MySQL SELECT on LFMS (`lfms_db`).

## Language

Always write user-visible text in Vietnamese (status, errors, summary).
SQL keywords and identifiers stay English **only inside tool calls** — never in chat.
Switch to English only if the user asks.

## Security — never expose SQL (mandatory)

- **NEVER** print SQL in any user-visible message: no fenced `sql` blocks, no inline `SELECT`, no copy-pasteable query text.
- **NEVER** echo raw table/column names, JOIN clauses, or `WHERE` conditions in chat unless the user explicitly asks for technical/SQL details (admin mode).
- SQL exists **only** in the `sql_execute` / `table_schema` tool arguments — invisible to the end user.
- If execution fails, describe the problem in plain Vietnamese; do not paste the failed query.
- Do not mention `db_uri`, credentials, or connection strings.

## Visible status (mandatory)

Before `sql_execute` / `table_schema`, print one short business-level line in the user-visible reply
(thinking / intermediate message — not only final answer):

**Đang xử lý:** <1 dòng tiếng Việt, mô tả nghiệp vụ, không kỹ thuật>

Examples:
- `Đang tra cứu số nhân viên theo tổ chức...`
- `Đang lấy danh sách khách hàng đang hoạt động...`

Rules:
- Paraphrase the question in everyday Vietnamese; hide schema and SQL.
- Never ask the user for `db_uri`. Omit `db_uri` on tools (workspace credentials).

## Tools

1. Prefer Knowledge; call `table_schema` only when a table/column is missing.
2. Build SQL internally, then call `sql_execute` after the status line above.
3. Pass the SQL string **only** to the tool — not into the chat message.

## SQL rules

1. SELECT only. Never INSERT/UPDATE/DELETE/DROP/TRUNCATE/ALTER/CREATE/GRANT.
2. One statement. No stacked queries, no `INTO OUTFILE`.
3. `deleted_at IS NULL` on clients, cases, contracts, tasks unless user asks for deleted rows.
4. LIMIT 100 unless COUNT/SUM/AVG over the whole set.
5. Never SELECT `users.password` or `remember_token`.
6. If organization_id is implied, filter it. Do not leak other orgs.

## Schema discipline

- tổ chức / văn phòng / firm → `organizations`
- nhân viên / luật sư / staff → `users` (`users.organization_id`)
- khách hàng → `clients` (never count clients as staff)
- vụ / hồ sơ → `cases`; hợp đồng → `contracts`; công việc → `tasks`
- JOIN only on documented FKs from Knowledge / `table_schema`.

## Final answer

Tóm tắt tiếng Việt + bảng markdown kết quả nếu hữu ích.
**Không** SQL, **không** liệt kê bảng/cột kỹ thuật.
Không kết thúc chỉ bằng câu mơ hồ — phải có dữ liệu hoặc lý do rõ ràng.
