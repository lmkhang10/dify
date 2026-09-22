# Table: payments

Đợt thu / sổ cái theo lần (installment). Header tiền HĐ nằm trên `contracts.payment_*`. Tenant: LFMS lọc qua EXISTS contracts (LLM không cần viết EXISTS tenant).

Columns:

- id (bigint, PK)
- contract_id (bigint, FK contracts.id) — bắt buộc JOIN contracts nếu cần khách/vụ
- installment_no (int, nullable)
- description (varchar)
- amount (bigint) — SeeMoney
- currency (char 3, default VND) — SeeMoney
- due_date (date, nullable) — hạn từng đợt
- paid_at (timestamp, nullable)
- status (varchar, enum `PaymentHistoryStatus`): pending | succeeded | cancelled — **không có** `paid`/`unpaid`
- direction (varchar, enum `PaymentDirection`): in | out — **không có** `inbound`/`outbound`
- reference (varchar)
- collected_by_user_id (bigint, nullable) — trả id. "của tôi" không JOIN users; LFMS = người thu OR HĐ visibleTo
- created_at, updated_at

Không có organization_id / deleted_at trên bảng này.

**Cấm literal:** `'paid'`, `'unpaid'`, `'inbound'`, `'outbound'`. Đã thu = `'succeeded'`. Còn nợ = `'pending'` + `'in'`.

Sample — đợt chưa thu (không JOIN organizations):

```sql
SELECT p.id, p.contract_id, p.amount, p.currency, p.due_date, p.status
FROM payments p
INNER JOIN contracts ct ON ct.id = p.contract_id AND ct.deleted_at IS NULL
WHERE p.status = 'pending'
LIMIT 100
```

Sample — công nợ khách còn thu (thu = `direction='in'` + `status='succeeded'`; chưa thu = `status='pending'`):

```sql
SELECT cl.id, cl.name, SUM(p.amount) AS outstanding
FROM clients cl
INNER JOIN contracts ct ON ct.client_id = cl.id AND ct.deleted_at IS NULL
INNER JOIN payments p ON p.contract_id = ct.id
WHERE cl.deleted_at IS NULL AND cl.profile_kind = 'client'
    AND p.direction = 'in' AND p.status = 'pending'
    AND LOWER(cl.name) LIKE CONCAT('%', LOWER('an khang'), '%')
GROUP BY cl.id, cl.name
LIMIT 100
```
