# Table: users

Nhân viên / nhân sự / luật sư / staff. Không có deleted_at.

"Tổ chức nào nhiều nhân viên" = COUNT users theo organizations, không đếm clients.

Columns:
- id (bigint, PK)
- organization_id (bigint, FK organizations.id) — thuộc tổ chức nào
- name (varchar)
- email (varchar)
- phone (varchar)
- position (varchar)
- department_id (bigint, FK departments.id)
- status (varchar, default active)
- created_at (timestamp)

Do not SELECT password or remember_token.

Sample questions:
- Tổ chức nào có nhiều nhân viên nhất
- Luật sư đang active
- Nhân viên theo phòng ban
