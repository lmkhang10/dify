# Table: organizations

Tổ chức / công ty luật / tenant. Tiếng Việt: tổ chức, văn phòng, firm, org. KHÔNG nhầm với clients.

Columns:
- id (bigint, PK)
- name (varchar) — tên hiển thị
- legal_name (varchar)
- tax_code (varchar)
- slug (varchar)
- is_active (tinyint, 1 = đang hoạt động)
- created_at (timestamp)
- deleted_at (timestamp) — always `WHERE deleted_at IS NULL`

Không SELECT smtp_password.

Nhân viên: JOIN users ON users.organization_id = organizations.id
Nhiều-nhiều (hiếm): organization_user (organization_id, user_id)

Sample questions:
- Tổ chức nào có nhiều nhân viên nhất
- Danh sách tổ chức đang active
- Tổ chức theo mã số thuế
