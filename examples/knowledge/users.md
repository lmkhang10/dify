# Table: users

Nhân viên trong văn phòng. Không có `deleted_at`. Chỉ FROM/JOIN khi `users` có trên thẻ quyền của câu hỏi. Không JOIN chỉ để lấy tên cho "của tôi".

Columns:

- id (bigint, PK)
- organization_id (bigint)
- name (varchar)
- email (varchar) — PII (cờ SeePii)
- phone (varchar) — PII
- avatar (varchar) — đường dẫn file, không phải URL công khai
- note (text) — PII, cấm khi thiếu SeePii
- position (varchar)
- department_id (bigint) — trả id, không JOIN departments trừ khi hỏi catalog
- status (varchar): **active**, **away**, **inactive** (không còn cột is_active)
- created_at, updated_at

Luôn cấm: **password**, **remember_token**. Không SELECT is_super_admin / api_token.

Sample:

- Luật sư đang làm việc → SELECT id, name, position, status FROM users WHERE status = 'active' LIMIT 100
- Không: JOIN organizations để lấy tên văn phòng
