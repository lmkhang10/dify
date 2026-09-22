# Table: cases

Hồ sơ / vụ việc. Shared: CasesLitigation → `category = 'litigation'`; CasesLegalService → `category = 'legal_service'`.

Columns:

- id (bigint, PK)
- organization_id (bigint)
- code (varchar)
- name (varchar)
- client_id (bigint, FK clients.id)
- case_type_id (bigint, FK case_types.id) — lọc theo tên loại: JOIN case_types + LIKE name; không JOIN chỉ để hiện tên trên list
- category (varchar): **litigation** | **legal_service**
- area (varchar)
- status (varchar): **new** | **in_progress** | **on_hold** | **closed** — không còn cột boolean `on_hold`
- held_at (timestamp, nullable) — thời điểm tạm dừng khi status = on_hold
- hold_reason (text, nullable)
- priority (varchar)
- open_date (date)
- deadline (date)
- closed_at (timestamp, nullable)
- fee_estimate (bigint, nullable)
- billing_method (varchar, nullable)
- description, notes (text)
- lead_lawyer_id (bigint, FK users.id) — "liên quan tôi" **không** JOIN users; LFMS đã gồm cột này trong Của tôi. Trả id.
- created_by (bigint)
- workflow_definition_id (bigint, nullable) — chỉ tên cột; không query workflow_versions / case_checklist_items
- workflow_version_id (bigint, nullable) — không JOIN bảng phiên bản
- created_at, updated_at
- deleted_at — luôn `deleted_at IS NULL`

Cấm: cột `on_hold` boolean (đã drop). Lọc tạm dừng: `status = 'on_hold'`.

Sample:

- Vụ tố tụng đang xử lý: SELECT id, code, name, status, client_id, lead_lawyer_id FROM cases WHERE category = 'litigation' AND status = 'in_progress' AND deleted_at IS NULL LIMIT 100
- Đếm theo tên loại: SELECT COUNT(*) AS cnt FROM cases cs INNER JOIN case_types ct ON ct.id = cs.case_type_id WHERE cs.deleted_at IS NULL AND LOWER(ct.name) LIKE '%thu hồi nợ%'
- Quá hạn chưa đóng: SELECT id, code, name, deadline FROM cases WHERE deadline < CURDATE() AND status <> 'closed' AND deleted_at IS NULL LIMIT 100

Liệt kê: SELECT `code`, `name`, `status`. Trả lời copy nguyên `code` từ JSON. Không bịa / không rút mã (cấm VV001 nếu JSON không có đúng chuỗi đó).
