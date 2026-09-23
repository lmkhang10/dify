# Table: cases

Hồ sơ / vụ việc. Shared: CasesLitigation → `category = 'litigation'`; CasesLegalService → `category = 'legal_service'`.

Chỉ SELECT cột dưới đây. Cột không có trong danh sách **không tồn tại** — cấm đoán.

Columns:

- id (bigint, PK)
- organization_id (bigint)
- code (varchar) — mã vụ, copy nguyên (vd. D2-VV-003)
- name (varchar)
- client_id (bigint, FK clients.id)
- case_type_id (bigint, FK case_types.id) — lọc theo tên loại: JOIN case_types + LIKE name
- category (varchar): **litigation** | **legal_service**
- status (varchar): **new** | **in_progress** | **on_hold** | **closed**
- priority (varchar): **high** | **medium** | **low** — không có `emergency` (emergency chỉ thuộc tasks)
- hold_reason (text, nullable)
- held_at (timestamp, nullable) — lúc tạm dừng khi status = on_hold
- held_by (bigint, nullable)
- open_date (date)
- deadline (date)
- closed_at (timestamp, nullable)
- reopen_count (int)
- description, notes (text)
- lead_lawyer_id (bigint, FK users.id) — "liên quan tôi" **không** JOIN users. Trả id.
- created_by (bigint)
- stage (varchar, nullable) — giai đoạn theo quy trình của vụ, không phải enum cố định. SELECT nguyên giá trị. Không bịa `filing` / `trial`.
- outcome (varchar, nullable) — kết quả khi đóng, theo quy trình. SELECT nguyên. Không bịa `won` / `lost`.
- outcome_note (text, nullable)
- workflow_definition_id (bigint, nullable) — không JOIN workflow_versions
- workflow_version_id (bigint, nullable) — không JOIN bảng phiên bản
- stage_due_at (date, nullable)
- client_notified_at (timestamp, nullable)
- created_at, updated_at
- deleted_at — luôn `deleted_at IS NULL`

## Cột đã xóa — cấm SELECT

`fee_estimate`, `billing_method`, `area`, `on_hold` (boolean), `legal_area_id`, `amount`, `total_amount`.

Phí / doanh thu của vụ **không nằm trên cases**. JOIN `contracts` ON `contracts.case_id = cases.id` và dùng `contracts.payment_amount`.

Lọc tạm dừng: `status = 'on_hold'`.

Sample:

- Vụ tố tụng đang xử lý: SELECT id, code, name, status, client_id, lead_lawyer_id FROM cases WHERE category = 'litigation' AND status = 'in_progress' AND deleted_at IS NULL LIMIT 100
- Đếm theo tên loại: SELECT COUNT(*) AS cnt FROM cases cs INNER JOIN case_types ct ON ct.id = cs.case_type_id WHERE cs.deleted_at IS NULL AND LOWER(ct.name) LIKE '%thu hồi nợ%'
- Quá hạn chưa đóng: SELECT id, code, name, deadline FROM cases WHERE deadline < CURDATE() AND status <> 'closed' AND deleted_at IS NULL LIMIT 100

Liệt kê: SELECT `code`, `name`, `status`. Trả lời copy nguyên `code`. Cột trạng thái in nhãn: `new` → Mới, `in_progress` → Đang xử lý, `on_hold` → Tạm dừng, `closed` → Hoàn thành. Ưu tiên: `high` → Cao, `medium` → Trung bình, `low` → Thấp.
