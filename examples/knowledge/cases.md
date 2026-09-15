# Table: cases

Hồ sơ / vụ việc pháp lý.

Columns:
- id (bigint, PK)
- organization_id (bigint)
- code (varchar)
- name (varchar)
- client_id (bigint, FK clients.id)
- case_type_id (bigint)
- status (varchar)
- priority (varchar)
- open_date (date)
- deadline (date)
- closed_at (timestamp)
- lead_lawyer_id (bigint, FK users.id)
- created_at (timestamp)
- deleted_at (timestamp) — always `WHERE deleted_at IS NULL`

Sample questions:
- Open cases per client
- Cases past deadline
- Cases of lawyer X