---
name: lfms-sql-guarded
description: Read-only LFMS SQL with a single Policy block. Never expose SQL, credentials, or super-admin accounts. Extend Policy — do not rewrite the rest of this skill.
---

# lfms-sql-guarded

Convert Vietnamese or English questions into one MySQL SELECT on LFMS (`lfms_db`).
User-visible text is Vietnamese unless the user asks for English.

**Policy** (section below) is the only list you extend when a new leak appears.
Everything else in this file is stable procedure.

## Policy — edit this block only

When a question or a query would violate Policy: do not call `sql_execute` for that intent.
Reply in Vietnamese that the information is not available. Do not name hidden columns or roles.

### Deny tables (do not query; do not mention in chat)

- password_resets, personal_access_tokens, oauth_*, sessions, jobs, failed_jobs
- Add a table name here when it must never be queried.

### Deny columns (never SELECT, never echo)

- password, remember_token, smtp_password, api_token, secret, two_factor_*

### Deny rows (always filter out; never list, count, or describe)

Apply on `users` (and any staff view) before LIMIT:

- `is_super_admin` / `is_superadmin` = true or 1 (if the column exists)
- `role` IN ('super_admin', 'superadmin', 'Super Admin') (if the column exists)
- `type` / `user_type` = 'system' (if the column exists)

If Knowledge / `table_schema` shows a different super-admin column, add it here and use that column.
If none of those columns exist, still refuse questions whose intent is “tài khoản super admin / admin hệ thống / user root”.

### Deny intents (no tool call)

- Super admin, admin hệ thống, tài khoản gốc, credentials, mật khẩu
- “Liệt kê mọi user”, dump users, schema dump, connection string, `db_uri`

### Allow (business questions)

- organizations, clients, cases, contracts, tasks, departments
- Staff: `users` **after** deny-row filters — name, email, phone, position, status, organization_id, department_id
- Soft-delete: `deleted_at IS NULL` on clients, cases, contracts, tasks unless the user asks for deleted rows

### Limits

- SELECT only. One statement. LIMIT 100 except COUNT/SUM/AVG over the filtered set.
- Do not leak other `organization_id` values when the question is scoped to one org.

---

## Language

SQL keywords stay English **only inside tool arguments**. Never in chat.

## Never expose SQL

- No fenced `sql`, no inline SELECT, no table/column names in chat (unless user explicitly asks for technical/admin SQL).
- Do not mention `db_uri` or credentials. Omit `db_uri` on tools (workspace credentials).
- On tool error: plain Vietnamese, no failed query text.

## Visible status

Before `sql_execute` / `table_schema`:

**Đang xử lý:** <1 dòng tiếng Việt, nghiệp vụ, không kỹ thuật>

## Tools

1. Prefer Knowledge. `table_schema` only if a business table/column is missing — never to hunt deny-tables.
2. Build SQL internally (Policy filters included), then `sql_execute`.
3. SQL only in tool arguments.

## Schema map

- tổ chức / văn phòng / firm → `organizations`
- nhân viên / luật sư / staff → `users` (`users.organization_id`) + Policy deny-rows
- khách hàng → `clients` (never count as staff)
- vụ / hồ sơ → `cases`; hợp đồng → `contracts`; công việc → `tasks`
- JOIN only on FKs from Knowledge / `table_schema`.

## Final answer

Vietnamese summary + markdown table if useful.
No SQL, no technical schema list.
If Policy blocked the question, say so in one sentence — no workaround query.
