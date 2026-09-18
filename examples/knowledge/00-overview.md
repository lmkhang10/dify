# LFMS schema overview

Law-firm MySQL `lfms_db`. Soft-delete: bảng có `deleted_at` thì luôn `deleted_at IS NULL`.

LFMS tự chèn lọc tenant (`organization_id`) — SQL sinh ra **không** JOIN `organizations` chỉ để biết văn phòng.

## Glossary (tiếng Việt → bảng)

- tổ chức / văn phòng / tenant → **organizations** (chỉ khi hỏi danh sách tổ chức; luật sư/kế toán thường **không** được JOIN bảng này)
- nhân viên / luật sư / staff → **users**
- phòng ban → **departments** (Catalog)
- loại vụ → **case_types** (Catalog)
- khách hàng → **clients** WHERE `profile_kind = 'client'`
- lead / tiềm năng → **clients** WHERE `profile_kind = 'lead'`
- vụ tố tụng → **cases** WHERE `category = 'litigation'`
- vụ dịch vụ pháp lý → **cases** WHERE `category = 'legal_service'`
- hợp đồng / giá trị HĐ / doanh thu HĐ → **contracts.payment_amount** (không `total_amount`)
- đợt thu / lần thu tiền / còn nợ → **payments** (`status`: pending/succeeded/cancelled — **cấm paid/unpaid**; `direction`: in/out)
- công việc → **tasks**; người làm → **task_assignees**
- tài liệu → **documents**
- công văn → **official_dispatches** (`direction`: incoming/outgoing)
- lịch nội bộ → **custom_calendar_events**
- nhật ký hệ thống → **audit_logs**
- báo cáo tổng hợp → **report_daily_finance / cases / leads / staff** (ưu tiên hơn SUM bảng gốc)
- quy trình → **workflow_definitions** (không query `workflow_versions`)
- sổ tay → **handbook_articles**, **handbook_categories**

## Bảng cấm (không query)

`service_plans`, `organization_subscriptions`, `case_checklist_items`, `workflow_versions`, `workflow_keys`, `vanna_*`, `password_reset_tokens`, `sessions`, `roles`, `role_user`, mọi bảng `zl_*`.

## Joins tối thiểu (chỉ khi cần cột từ bảng đó)

- cases.client_id = clients.id
- contracts.client_id = clients.id
- contracts.case_id = cases.id
- payments.contract_id = contracts.id
- tasks.case_id = cases.id
- task_assignees.task_id = tasks.id
- cases.lead_lawyer_id = users.id (chỉ khi cần tên luật sư và module Users được phép)
- clients.assigned_to = users.id
- handbook_articles.category_id = handbook_categories.id

Không JOIN organizations / departments / case_types chỉ để lấy tên — trả id.

LIMIT 100 trừ COUNT/SUM/AVG. Không subquery, UNION, WITH, SELECT *.

Follow-up ("khách đó", "còn nợ thì sao") giữ cùng tên/mã lượt trước — xem `followups.md`. Không JOIN organizations.
