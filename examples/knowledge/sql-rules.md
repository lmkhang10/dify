# Luật SQL tối-thiểu-bảng (bắt buộc)

LFMS từ chối **cả câu** nếu một bảng trong FROM/JOIN không thuộc quyền (`TABLE_DENIED`). Luật sư / kế toán / nhân viên thường **không** có module Organizations. JOIN `organizations` lấy tên văn phòng → fail cả query doanh thu.

## Tối thiểu bảng

1. Chỉ FROM/JOIN bảng cần cột. Tên văn phòng: ghi trong tóm tắt "thuộc văn phòng bạn" — **không** JOIN `organizations`.
2. Không JOIN `departments` chỉ để lấy tên. Trả `department_id`. Lọc **theo tên loại vụ** thì JOIN `case_types` (`cases.case_type_id`) + `LOWER(case_types.name) LIKE …` — không đếm hết `category = 'litigation'`.
3. **Cấm JOIN `users` cho "tôi / liên quan tôi / LS phụ trách / tôi phụ trách".** LFMS đã lọc Của tôi, **gồm `cases.lead_lawyer_id`**. Nhân viên thường không có module Users — JOIN `users` → `TABLE_DENIED`, mất cả vụ bạn phụ trách. Trả `lead_lawyer_id`. JOIN users chỉ khi hỏi **tên** nhân sự khác và module Users được phép.
4. Tenant filter và Của tôi do LFMS tự chèn. Không viết `WHERE organization_id = …`. **Cấm** `:current_user_id` / mọi placeholder PDO — PDO sẽ vỡ (`HY093`) và trả "Không chạy được truy vấn."
5. Ưu tiên `report_daily_*` cho câu tổng hợp (doanh thu kỳ, backlog vụ, pipeline lead, giờ nhân sự). Không SUM stock.
6. Subquery `IN` / `EXISTS` / derived table được LFMS rewrite tenant từng SELECT. Cấm UNION, WITH, SELECT *, INSERT/UPDATE/DELETE. JOIN phẳng vẫn ưu tiên.
7. Soft-delete: `deleted_at IS NULL` trên clients, cases, contracts, tasks, official_dispatches, documents, handbook_articles, organizations (nếu được phép).
8. LIMIT 100 trừ COUNT/SUM/AVG.

## Của tôi / liên quan tôi

Không viết `WHERE lead_lawyer_id = …` hay JOIN `users`/`case_team`. LFMS Mine = luật sư phụ trách OR người tạo OR đội OR khách (assigned_to/created_by). SELECT `code, name, status` (+ loại nếu JOIN case_types).

## Tên khách / công ty

Không `clients.name = 'TM AN Khang'`. Tên trên UI thường rút; DB là tên đầy đủ (vd. Công ty TNHH TM An Khang). Dùng:

`LOWER(clients.name) LIKE CONCAT('%', LOWER('an khang'), '%')`

Lấy 1–3 token đặc trưng (bỏ Công ty, TNHH, TM nếu còn nhiều kết quả thì giữ TM).

Công nợ **một khách**: `SUM(p.amount)` đợt `pending` + `in` (JOIN clients + contracts + payments). **Cấm** `status = 'paid'` / `'unpaid'`. **Cấm** `SUM(ct.payment_amount) - SUM(p.amount)` trên cùng JOIN (fan-out nhân giá trị HĐ). Tổng văn phòng: `report_daily_finance.receivable_total` ngày cuối kỳ, không SUM stock.

## Mapping tiền

- Giá trị / doanh thu hợp đồng → `contracts.payment_amount` (+ `payment_currency`). Không `amount` trừ khi hỏi cột legacy.
- Đợt thu thực tế → `payments.amount` qua `contract_id`.
- Tổng hợp tài chính theo ngày → `report_daily_finance` (FLOW: `collected_in`/`out`, `contracts_signed_*`; STOCK: `receivable_*` lấy ngày cuối kỳ, không SUM).

## Domain filters (LFMS cũng chèn; LLM nên ghi rõ)

- Khách: `clients.profile_kind = 'client'`
- Lead: `clients.profile_kind = 'lead'`
- Tố tụng: `cases.category = 'litigation'`
- Dịch vụ PL: `cases.category = 'legal_service'`

## Bảng không whitelist — không dạy, không query

service_plans, organization_subscriptions, case_checklist_items, workflow_versions, workflow_keys, `vanna_*`, password_reset_tokens, sessions, roles, role_user, `zl_*`, official_dispatch_histories, handbook_keywords, report_daily_finance_by_dim.

## Cột luôn cấm

users.password, users.remember_token. Không SELECT smtp_password, is_super_admin, api_token.

## Cột PII / tiền (thiếu cờ → COLUMN_DENIED)

PII: `clients` email/phone/address/id_number/tax_code; `users` email/phone/note; `contracts.referrer_name`; `official_dispatches` counterparty__; `audit_logs` ip_address/user_agent.
Tiền: `payments.amount`/`currency`; `contracts.payment_*`; `report_daily_finance` collected__/receivable_*/contracts_signed_value; `report_daily_staff.collected_attributed`.

Khi thiếu cờ: bỏ cột đó, vẫn trả các cột khác.

## Ví dụ đúng: doanh thu theo khách

```sql
SELECT c.id, c.name, SUM(ct.payment_amount) AS revenue
FROM contracts ct
INNER JOIN clients c ON c.id = ct.client_id AND c.deleted_at IS NULL AND c.profile_kind = 'client'
WHERE ct.deleted_at IS NULL AND ct.is_canceled = 0
GROUP BY c.id, c.name
ORDER BY revenue DESC
LIMIT 100
```

Không JOIN organizations. Không JOIN users.

## Ví dụ đúng: còn nợ khách (đợt chưa thu)

```sql
SELECT c.id, c.name, SUM(p.amount) AS con_no
FROM clients c
INNER JOIN contracts ct ON ct.client_id = c.id AND ct.deleted_at IS NULL AND ct.is_canceled = 0
INNER JOIN payments p ON p.contract_id = ct.id
WHERE c.deleted_at IS NULL AND c.profile_kind = 'client'
  AND p.status = 'pending' AND p.direction = 'in'
  AND LOWER(c.name) LIKE CONCAT('%', LOWER('an khang'), '%')
GROUP BY c.id, c.name
LIMIT 100
```

Sai: `p.status = 'paid'` hoặc `'unpaid'`. Sai: trừ `SUM(ct.payment_amount)` sau LEFT JOIN payments.

## Follow-up (cùng khách)

Sau "doanh thu An Khang", câu "còn nợ?" phải LIKE `'%an khang%'` và `payments.status = 'pending' AND direction = 'in'`. Không bỏ tên khách. Xem `followups.md`.
