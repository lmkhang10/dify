# LFMS schema overview

Law-firm MySQL `lfms_db`. Soft-delete: business tables có `deleted_at` thì luôn `deleted_at IS NULL`.

## Glossary (tiếng Việt → bảng)

- tổ chức / công ty luật / tenant / văn phòng → **organizations** (name)
- nhân viên / nhân sự / luật sư / staff → **users** (users.organization_id)
- phòng ban → **departments**
- khách hàng / lead → **clients** (không phải organizations)
- vụ / hồ sơ → **cases**
- hợp đồng → **contracts**
- công việc → **tasks**

## Tables

- organizations: tenant
- users: staff (không có deleted_at; không SELECT password)
- clients, cases, contracts, tasks: nghiệp vụ + deleted_at

## Joins

- users.organization_id = organizations.id
- cases.client_id = clients.id
- contracts.client_id = clients.id
- contracts.case_id = cases.id
- tasks.case_id = cases.id
- cases.lead_lawyer_id = users.id
- clients.assigned_to = users.id

LIMIT 100 trừ COUNT/SUM/AVG. Không bịa bảng ngoài docs đã retrieve.
