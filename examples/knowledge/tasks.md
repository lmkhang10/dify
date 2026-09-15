# Table: tasks

Công việc. Assignment nằm ở bảng task_assignees, không phải cột assigned_to.

Columns:
- id (bigint, PK)
- organization_id (bigint)
- title (varchar)
- description (text)
- case_id (bigint, FK cases.id)
- priority (varchar)
- progress (tinyint)
- due_date (date)
- created_at (timestamp)
- deleted_at (timestamp) — always `WHERE deleted_at IS NULL`

Sample questions:
- Overdue tasks
- Tasks of a case
- High priority incomplete tasks