# Hội thoại nhiều lượt (coreference)

Câu follow-up không đủ chủ thể. SQL phải giữ **cùng khách / vụ / HĐ** như lượt trước. Không đổi sang danh sách toàn văn phòng.

Đại từ: khách đó, vụ này, HĐ đó, của họ, còn nợ thì sao, thế còn, còn lại, chi tiết hơn.

## Lượt 1 → lượt 2 (cùng khách)

Lượt 1: "Doanh thu hợp đồng khách An Khang"

```sql
SELECT c.id, c.name, SUM(ct.payment_amount) AS revenue
FROM contracts ct
INNER JOIN clients c ON c.id = ct.client_id AND c.deleted_at IS NULL AND c.profile_kind = 'client'
WHERE ct.deleted_at IS NULL AND ct.is_canceled = 0
  AND LOWER(c.name) LIKE CONCAT('%', LOWER('an khang'), '%')
GROUP BY c.id, c.name
LIMIT 100
```

Lượt 2: "còn nợ thì sao?" / "khách đó còn nợ bao nhiêu?"

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

Cấm lượt 2: bỏ LIKE tên khách; cấm `status = 'unpaid'` / `'paid'`.

## Lượt 1 → lượt 2 (cùng vụ)

Lượt 1: "Vụ tố tụng mã CASE-12 đang thế nào?"

```sql
SELECT cs.id, cs.code, cs.name, cs.status, cs.category
FROM cases cs
WHERE cs.deleted_at IS NULL AND cs.category = 'litigation'
  AND LOWER(cs.code) LIKE CONCAT('%', LOWER('CASE-12'), '%')
LIMIT 100
```

Lượt 2: "công việc của vụ này"

```sql
SELECT t.id, t.title, t.priority, t.progress, t.due_date
FROM tasks t
INNER JOIN cases cs ON cs.id = t.case_id AND cs.deleted_at IS NULL
WHERE t.deleted_at IS NULL
  AND LOWER(cs.code) LIKE CONCAT('%', LOWER('CASE-12'), '%')
LIMIT 100
```

## Lượt 1 → lượt 2 (cùng HĐ)

Lượt 1: "Hợp đồng của khách An Khang"

Lượt 2: "các đợt thu của HĐ đó" → `payments` JOIN `contracts` JOIN `clients` với cùng `LIKE '%an khang%'`. `payments.status` chỉ `pending|succeeded|cancelled`.
