# Table: contracts

Hợp đồng. Tiền trên HĐ: **payment_amount** (không `total_amount` / `contract_value`).

Columns:

- id (bigint, PK)
- organization_id (bigint)
- code (varchar)
- name (varchar)
- client_id (bigint, FK clients.id)
- case_id (bigint, FK cases.id, nullable) — phí của một vụ: JOIN đây, không có cột phí trên cases
- payment_description (varchar) — SeeMoney
- payment_amount (bigint) — doanh thu / giá trị HĐ; SeeMoney
- payment_currency (char 3) — SeeMoney
- payment_due_date (date) — SeeMoney
- referral_source (varchar, nullable)
- referrer_name (varchar) — PII
- effective_from, expires_at (date)
- is_canceled (tinyint)
- canceled_reason, canceled_at
- is_completed (tinyint)
- completed_at (timestamp)
- created_by (bigint) — "của tôi": LFMS lọc; không JOIN users, không WHERE created_by = số
- created_at, updated_at
- deleted_at — luôn `deleted_at IS NULL`

Không có cột `type`, `status`, `template_id`, `amount`, `signed_at`, `total_amount`. Hủy/xong = `is_canceled` / `is_completed`, không lọc `status = 'draft'`. Không SELECT `party_a_snapshot` / `party_b_snapshot`.

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
