# Table: documents

Tài liệu đính kèm (morph). Soft-delete.

Columns:

- id (bigint, PK)
- organization_id (bigint)
- documentable_type (varchar) — nơi gắn. Viết nhãn tiếng Việt (Vụ việc, Khách hàng, Công việc, Hợp đồng, Công văn). Không có cột `case_id`.
- documentable_id (bigint) — id cha (vụ: `cases.id`)
- uploaded_by (bigint, FK users) — "của tôi" không JOIN users; LFMS = uploaded_by OR cha morph visibleTo
- sender_id (bigint) — trùng nghĩa uploaded_by; ưu tiên uploaded_by
- name (varchar)
- disk (varchar)
- path (varchar) — cấm SELECT (không có cột `file_path`)
- size (bigint)
- mime_type (varchar)
- purpose (varchar, nullable)
- uploaded_at (timestamp)
- created_at, updated_at
- deleted_at — luôn `deleted_at IS NULL`

Nơi gắn (`documentable_type`) — viết nhãn tiếng Việt, LFMS đổi thành class:

- Vụ việc → `cases`
- Khách hàng → `clients`
- Công việc → `tasks`
- Hợp đồng → `contracts`
- Công văn → `official_dispatches`

`purpose`: Tệp đính kèm | Nội dung nhúng. Chỉ lọc khi user hỏi mục đích.
`size` là byte. `mime_type` đọc thành PDF / Word / Excel / Ảnh.
"File tôi đã upload": SELECT `documents`, không WHERE `uploaded_by` (LFMS lọc).
JOIN cha: `documents.documentable_id = <bảng>.id` AND `documents.documentable_type = 'Vụ việc'` (nhãn, không class).

Sample:
SELECT documents.name, documents.mime_type, documents.size, documents.uploaded_at FROM documents WHERE documents.deleted_at IS NULL LIMIT 100
SELECT cases.code, cases.name FROM cases JOIN documents ON documents.documentable_id = cases.id AND documents.documentable_type = 'Vụ việc' AND documents.deleted_at IS NULL WHERE cases.deleted_at IS NULL LIMIT 100
