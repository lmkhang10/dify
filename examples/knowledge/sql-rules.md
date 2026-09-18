# Luật SQL tối-thiểu-bảng (bắt buộc)

LFMS từ chối **cả câu** nếu một bảng trong FROM/JOIN không thuộc quyền (`TABLE_DENIED`). Luật sư / kế toán / nhân viên thường **không** có module Organizations. JOIN `organizations` lấy tên văn phòng → fail cả query doanh thu.

## Tối thiểu bảng

1. Chỉ FROM/JOIN bảng cần cột. Tên văn phòng: ghi trong tóm tắt "thuộc văn phòng bạn" — **không** JOIN `organizations`.
2. Không JOIN `departments` / `case_types` chỉ để lấy tên. Trả `department_id` / `case_type_id`.
3. Không JOIN `users` nếu chỉ cần `lead_lawyer_id` / `assigned_to` / `created_by` (trả id). JOIN users chỉ khi hỏi tên nhân sự **và** câu hỏi về nhân sự.
4. Tenant filter do LFMS tự chèn. Không viết `WHERE organization_id = …`. Không JOIN organizations để lọc tenant.
5. Ưu tiên `report_daily_*` cho câu tổng hợp (doanh thu kỳ, backlog vụ, pipeline lead, giờ nhân sự). Không SUM stock.
6. Cấm subquery, UNION, WITH, EXISTS do LLM viết, SELECT *, INSERT/UPDATE/DELETE.
7. Soft-delete: `deleted_at IS NULL` trên clients, cases, contracts, tasks, official_dispatches, documents, handbook_articles, organizations (nếu được phép).
8. LIMIT 100 trừ COUNT/SUM/AVG.

## Mapping tiền

- Giá trị / doanh thu hợp đồng → `contracts.payment_amount` (+ `payment_currency`). Không `amount` trừ khi hỏi cột legacy.
- Đợt thu thực tế → `payments.amount` qua `contract_id`.
- Tổng hợp tài chính theo ngày → `report_daily_finance` (FLOW: collected_in/out, contracts_signed__; STOCK: receivable__ lấy ngày cuối kỳ, không SUM).

## Domain filters (LFMS cũng chèn; LLM nên ghi rõ)

- Khách: `clients.profile_kind = 'client'`
- Lead: `clients.profile_kind = 'lead'`
- Tố tụng: `cases.category = 'litigation'`
- Dịch vụ PL: `cases.category = 'legal_service'`

## Bảng không whitelist — không dạy, không query

service_plans, organization_subscriptions, case_checklist_items, workflow_versions, workflow_keys, vanna__, password_reset_tokens, sessions, roles, role_user, zl__, official_dispatch_histories, handbook_keywords, report_daily_finance_by_dim.

## Cột luôn cấm

users.password, users.remember_token. Không SELECT smtp_password, is_super_admin, api_token.

## Cột PII / tiền (thiếu cờ → COLUMN_DENIED)

PII: clients.email/phone/address/id_number/tax_code/…; users.email/phone/note; contracts.referrer_name; official_dispatches.counterparty__; audit_logs.ip_address/user_agent.
Tiền: payments.amount/currency; contracts.payment_amount/currency/due_date/description; report_daily_finance collected__/receivable_total/not_due/contracts_signed_value; report_daily_staff.collected_attributed.

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
