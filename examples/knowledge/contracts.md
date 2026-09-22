# Table: contracts

Hợp đồng. Tiền trên HĐ: **payment_amount** (không `total_amount` / `contract_value`).

Columns:

- id (bigint, PK)
- organization_id (bigint)
- code (varchar)
- name (varchar)
- type (varchar)
- template_id (bigint, nullable) — không JOIN contract_templates (không whitelist)
- client_id (bigint, FK clients.id)
- case_id (bigint, FK cases.id, nullable)
- amount (bigint, nullable) — legacy; ưu tiên payment_amount
- payment_description (varchar) — SeeMoney
- payment_amount (bigint) — doanh thu / giá trị HĐ; SeeMoney
- payment_currency (char 3, default VND) — SeeMoney
- payment_due_date (date) — SeeMoney
- signed_at (timestamp)
- effective_from, expires_at (date)
- status (varchar, default draft)
- is_canceled (tinyint)
- canceled_reason, canceled_at
- is_completed (tinyint)
- completed_at (timestamp)
- referrer_name (varchar) — PII
- created_by (bigint) — "của tôi": LFMS = created_by OR vụ visibleTo; không JOIN users, không WHERE created_by = số
- created_at, updated_at
- deleted_at — luôn `deleted_at IS NULL`

Không SELECT content / variables_snapshot (nặng, không cần cho thống kê).

Sample — doanh thu theo khách (không JOIN organizations):

```sql
SELECT cl.id, cl.name, SUM(ct.payment_amount) AS revenue
FROM contracts ct
INNER JOIN clients cl ON cl.id = ct.client_id AND cl.deleted_at IS NULL AND cl.profile_kind = 'client'
WHERE ct.deleted_at IS NULL AND ct.is_canceled = 0
GROUP BY cl.id, cl.name
ORDER BY revenue DESC
LIMIT 100
```
