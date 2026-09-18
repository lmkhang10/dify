# Table: task_assignees

N-N task ↔ user. Catalog LFMS whitelist `tasks`; nếu execute trả TABLE_DENIED cho task_assignees thì bỏ JOIN, lọc tasks theo case_id / created_by. JOIN khi hỏi “việc của nhân viên X”. Nếu Users off, lọc `user_id` số, không JOIN users.

Columns:

- id (bigint, PK)
- task_id (bigint, FK tasks.id)
- user_id (bigint, FK users.id)
- created_at, updated_at
- unique (task_id, user_id)

Không có organization_id. Lọc tenant qua tasks.

```sql
SELECT t.id, t.title, t.due_date, t.progress, ta.user_id
FROM tasks t
INNER JOIN task_assignees ta ON ta.task_id = t.id
WHERE t.deleted_at IS NULL AND ta.user_id = 12 AND t.progress < 100
LIMIT 100
```

Không dùng tasks.assigned_to (đã drop).
