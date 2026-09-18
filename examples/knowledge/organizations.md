# Table: organizations

Tổ chức / tenant. Chỉ query khi người dùng hỏi danh sách / thông tin tổ chức. **Không** JOIN bảng này để lấy tên văn phòng trên câu hỏi nghiệp vụ (khách, hợp đồng, vụ) — dễ `TABLE_DENIED` với luật sư/kế toán/nhân viên.

Columns (được phép):

- id (bigint, PK) — LFMS lọc tenant bằng `id = current org` khi module Organizations bật
- name (varchar)
- legal_name (varchar)
- tax_code (varchar)
- slug (varchar)
- is_active (tinyint)
- created_at, updated_at
- deleted_at — luôn `deleted_at IS NULL`

Cấm SELECT: smtp_password, smtp_username, và mọi cột SMTP/branding bí mật.

Không có cột nhân viên trên bảng này. Đếm nhân sự: bảng `users` (module Users), không JOIN organizations nếu Users-only.

Sample:

- Danh sách tổ chức đang hoạt động → SELECT id, name, tax_code, is_active FROM organizations WHERE deleted_at IS NULL AND is_active = 1 LIMIT 100
