# Table: workflow_definitions

Định nghĩa quy trình (mẫu Super hoặc bản văn phòng). **Không** query `workflow_versions`, `workflow_keys`, `case_checklist_items`.

Columns:

- id (bigint, PK)
- organization_id (bigint, nullable) — NULL = mẫu nền tảng Super
- key (varchar) — bất biến: criminal_litigation | civil_litigation | legal_service | …
- name (varchar)
- category (varchar): litigation | legal_service
- is_locked (tinyint)
- source_definition_id (bigint, nullable)
- current_version_id (bigint, nullable) — trả id, không JOIN versions
- created_by (bigint, nullable)
- created_at, updated_at

Hồ sơ ghim quy trình qua `cases.workflow_definition_id` / `workflow_version_id`.

Sample:
SELECT id, `key`, name, category, is_locked FROM workflow_definitions LIMIT 100
