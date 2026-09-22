# Table: tasks

Công việc. **Không còn cột status** (đã drop). Tiến độ: `progress` 0–100. Người làm: bảng **task_assignees**, không cột `assigned_to` / `assignee_id`.

Columns:

- id (bigint, PK)
- organization_id (bigint)
- title (varchar)
- description (text)
- internal_notes (text)
- case_id (bigint, FK cases.id, nullable)
- created_by (bigint, nullable) — "của tôi" không lọc cột này tay; LFMS Mine = assignee (task_assignees) OR created_by OR vụ attachedTo
- task_group_id (bigint, nullable)
- is_confirm (tinyint)
- priority (varchar): emergency | high | medium | low
- progress (tinyint 0–100)
- order (int)
- due_date (date)
- created_at, updated_at
- deleted_at — luôn `deleted_at IS NULL`

Hoàn thành: `progress = 100` hoặc `is_confirm = 1`. Quá hạn: `due_date < CURDATE() AND progress < 100`.

Sample:

- Việc quá hạn: SELECT id, title, case_id, due_date, progress, priority FROM tasks WHERE deleted_at IS NULL AND due_date < CURDATE() AND progress < 100 LIMIT 100

Của tôi / việc tôi làm: `SELECT id, title, due_date, progress FROM tasks WHERE deleted_at IS NULL`. Không JOIN users. Không `user_id = 12`. JOIN `task_assignees` chỉ khi hỏi người làm của một việc (không phải "của tôi").
