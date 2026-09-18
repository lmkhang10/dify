# Table: audit_logs

Nhật ký thao tác. Không soft-delete.

Columns:

- id (bigint, PK)
- organization_id (bigint, nullable)
- event (varchar)
- description (text)
- subject_type, subject_id
- actor_guard (varchar)
- actor_id (bigint)
- real_actor_guard, real_actor_id
- impersonated_user_id (bigint)
- is_super_action (tinyint)
- via_impersonation (tinyint)
- ip_address, user_agent — PII
- request_id (varchar)
- source (varchar, default web)
- created_at, updated_at

Không SELECT properties (JSON nặng). Không JOIN users/organizations trang trí.

Sample:
SELECT id, event, description, actor_id, subject_type, subject_id, created_at FROM audit_logs ORDER BY created_at DESC LIMIT 100
