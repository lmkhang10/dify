# Từ điển nghiệp vụ → bảng LFMS

Tên bảng tiếng Anh. Câu hỏi tiếng Việt. Không đoán bảng ngoài mapping.

| Người hỏi                               | Bảng                   | Ghi chú                                              |
| --------------------------------------- | ---------------------- | ---------------------------------------------------- |
| tổ chức, văn phòng, tenant, firm        | organizations          | Chỉ khi hỏi danh sách tổ chức. Không JOIN trang trí. |
| nhân viên, luật sư, staff               | users                  | status: active / away / inactive. Cấm password.      |
| phòng ban                               | departments            | Catalog. Không JOIN chỉ để lấy tên.                  |
| loại vụ, lĩnh vực vụ                    | case_types             | Catalog. cases.case_type_id đủ.                      |
| khách hàng                              | clients                | `profile_kind = 'client'`                            |
| lead, tiềm năng                         | clients                | `profile_kind = 'lead'`                              |
| vụ, hồ sơ tố tụng                       | cases                  | `category = 'litigation'`                            |
| vụ dịch vụ pháp lý                      | cases                  | `category = 'legal_service'`                         |
| hợp đồng, giá trị HĐ, doanh thu HĐ      | contracts              | Cột tiền: **payment_amount**                         |
| đợt thu, lần thu, installment           | payments               | `payments.contract_id`                               |
| công việc                               | tasks                  | Người làm: **task_assignees**, không `assigned_to`   |
| tài liệu, file đính kèm                 | documents              | morph `documentable_type/_id`                        |
| công văn đi/đến                         | official_dispatches    | direction inbound/outbound                           |
| lịch, sự kiện lịch                      | custom_calendar_events |                                                      |
| nhật ký, audit                          | audit_logs             |                                                      |
| báo cáo tài chính / vụ / lead / nhân sự | report_daily_*         | Ưu tiên tổng hợp                                     |
| quy trình giai đoạn                     | workflow_definitions   | Không `workflow_versions`                            |
| sổ tay, bài viết nội bộ                 | handbook_articles      |                                                      |

## Câu mẫu (tối thiểu bảng)

- "Danh sách khách hàng" → `clients` WHERE profile_kind='client' AND deleted_at IS NULL
- "Doanh thu theo khách" → `contracts` JOIN `clients` (không JOIN organizations)
- "Tổng thu tháng này" → ưu tiên `report_daily_finance` SUM(collected_in); không SUM receivable_*
- "Đợt thu chưa thanh toán" → `payments` WHERE status không phải paid
- "Công việc quá hạn" → `tasks` WHERE due_date < CURDATE() AND progress < 100
