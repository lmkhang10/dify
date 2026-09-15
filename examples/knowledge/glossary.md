# Từ điển nghiệp vụ → bảng LFMS

Tên bảng tiếng Anh. Câu hỏi tiếng Việt. Không đoán bảng khác nếu đã có mapping.

| Người hỏi | Bảng | Ý nghĩa |
|---|---|---|
| tổ chức, công ty luật, tenant, văn phòng, firm, org | organizations | Một đơn vị/tenant. Tên: organizations.name |
| nhân viên, nhân sự, luật sư, staff, lawyer, user, người dùng | users | Nhân sự thuộc tổ chức. users.organization_id |
| phòng ban, bộ phận | departments | users.department_id |
| khách hàng, khách, lead, client | clients | Không phải tổ chức. profile_kind client/lead |
| vụ, hồ sơ, case | cases | Vụ việc của client |
| hợp đồng | contracts | Hợp đồng |
| công việc, task | tasks | Task, thường gắn case |

## Câu mẫu

- "Tổ chức nào có nhiều nhân viên nhất" → COUNT users GROUP BY organizations
- "Bao nhiêu luật sư active" → users WHERE status = 'active'
- "Danh sách khách hàng" → clients, không phải organizations

## SQL đếm nhân viên theo tổ chức

```sql
SELECT o.id, o.name, COUNT(u.id) AS staff_count
FROM organizations o
INNER JOIN users u ON u.organization_id = o.id
WHERE o.deleted_at IS NULL
GROUP BY o.id, o.name
ORDER BY staff_count DESC
LIMIT 1
```

Không đếm clients.organization_id — đó là khách thuộc tenant, không phải nhân viên.
