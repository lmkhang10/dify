# Table: clients

Khách hàng **và** lead (cùng bảng). LFMS lọc theo module: Clients → `profile_kind = 'client'`; Leads → `profile_kind = 'lead'`.

Columns:

- id (bigint, PK)
- organization_id (bigint) — LFMS tự lọc; không JOIN organizations
- code (varchar)
- type (enum: individual, business)
- profile_kind (enum: client, lead) — bắt buộc ghi trong SQL khi phân biệt
- name (varchar)
- company (varchar, nullable)
- gender (enum: male, female, other)
- city, district, ward
- source (enum: referral, website, walk_in, social_media, advertisement, other)
- status (enum: active, inactive, potential, archived)
- lead_stage (enum: new, consulting, proposal, negotiating, won, lost)
- lost_reason_code (varchar, nullable)
- assigned_to (bigint, FK users.id) — trả id; JOIN users chỉ khi cần tên và Users được phép
- created_by (bigint, FK users.id)
- created_at, updated_at
- deleted_at — luôn `deleted_at IS NULL`

PII (cần SeePii): email, phone, phone_secondary, address, id_number, id_issued_date, id_issued_place, date_of_birth, tax_code, business_registration_number, representative_name, representative_id_number.

Sample:

- Khách active: SELECT id, code, name, type, status FROM clients WHERE profile_kind = 'client' AND status = 'active' AND deleted_at IS NULL LIMIT 100
- Lead negotiating: SELECT id, name, lead_stage FROM clients WHERE profile_kind = 'lead' AND lead_stage = 'negotiating' AND deleted_at IS NULL LIMIT 100
