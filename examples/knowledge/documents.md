# Table: documents

Tài liệu đính kèm (morph). Soft-delete.

Columns:

- id (bigint, PK)
- organization_id (bigint)
- documentable_type (varchar) — class name cha (Case, Client, Task, Contract, Dispatch…)
- documentable_id (bigint)
- uploaded_by (bigint, FK users)
- sender_id (bigint) — trùng nghĩa uploaded_by; ưu tiên uploaded_by
- name (varchar)
- disk (varchar)
- path (varchar) — không trả path đầy đủ nếu không cần
- size (bigint)
- mime_type (varchar)
- purpose (varchar, nullable)
- uploaded_at (timestamp)
- created_at, updated_at
- deleted_at — luôn `deleted_at IS NULL`

Không JOIN bảng cha qua subquery. Lọc theo type/id morph nếu user nêu rõ.

Sample:
SELECT id, name, mime_type, size, documentable_type, uploaded_at FROM documents WHERE deleted_at IS NULL LIMIT 100
