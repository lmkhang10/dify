# Table: payments

Đợt thu / sổ cái theo lần (installment). Header tiền HĐ nằm trên `contracts.payment_*`. Tenant: LFMS lọc qua EXISTS contracts (không viết subquery).

Columns:

- id (bigint, PK)
- contract_id (bigint, FK contracts.id) — bắt buộc JOIN contracts nếu cần khách/vụ
- installment_no (int, nullable)
- description (varchar)
- amount (bigint) — SeeMoney
- currency (char 3, default VND) — SeeMoney
- due_date (date, nullable) — hạn từng đợt
- paid_at (timestamp, nullable)
- status (varchar): pending | paid | cancelled (và giá trị ledger hiện hành)
- direction (varchar): in | out
- reference (varchar)
- collected_by_user_id (bigint, nullable) — trả id, không JOIN users trừ khi cần tên thu ngân
- created_at, updated_at

Không có organization_id / deleted_at trên bảng này.

Sample — đợt chưa thu (không JOIN organizations):

```sql
SELECT p.id, p.contract_id, p.amount, p.currency, p.due_date, p.status
FROM payments p
INNER JOIN contracts ct ON ct.id = p.contract_id AND ct.deleted_at IS NULL
WHERE p.status = 'pending'
LIMIT 100
```
