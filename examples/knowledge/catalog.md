# Tables: departments, case_types (Catalog)

Chỉ query khi người dùng hỏi danh mục phòng ban / loại vụ. Không JOIN vào cases/users chỉ để lấy tên.

## departments

- id, organization_id, name, description, created_at, updated_at

## case_types

- id, organization_id (nếu có)
- name, slug, description, area
- category: litigation | legal_service
- workflow (varchar khóa, legacy)
- workflow_definition_id (bigint, nullable) — không JOIN workflow_definitions trừ khi hỏi quy trình
- created_at, updated_at

Sample:
SELECT id, name, category, area FROM case_types LIMIT 100
SELECT id, name FROM departments LIMIT 100
