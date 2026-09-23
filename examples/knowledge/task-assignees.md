# Table: task_assignees

N-N task ↔ user. LFMS whitelist `task_assignees` (tenant qua `tasks`, Mine qua `task_id IN` việc visibleTo).

**Của tôi / việc tôi làm:** chỉ `FROM tasks` — không JOIN bảng này, không `user_id = <số>`. Gateway đã gồm người được gán.

JOIN khi hỏi người làm của **một việc cụ thể** (có mã việc). Nếu `users` không có trên thẻ quyền: trả `ta.user_id`, không JOIN `users`.

Columns:

- id (bigint, PK)
- task_id (bigint, FK tasks.id)
- user_id (bigint, FK users.id)
- created_at, updated_at
- unique (task_id, user_id)

Không có organization_id.

```sql
SELECT t.id, t.title, ta.user_id
FROM tasks t
INNER JOIN task_assignees ta ON ta.task_id = t.id
WHERE t.deleted_at IS NULL AND t.id = 123
LIMIT 100
```

Không dùng `tasks.assigned_to` (đã drop).
