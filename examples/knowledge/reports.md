# Tables: report_daily_* (Reports)

Snapshot theo ngày. Ưu tiên cho câu tổng hợp. LFMS không whitelist `report_daily_finance_by_dim` — không query bảng đó.

Tiền tệ: số nguyên VND. `is_partial = 1` = tạm tính trong ngày.

## FLOW vs STOCK (bắt buộc)

- FLOW (SUM theo kỳ): phát sinh trong ngày.
- STOCK (lấy **một** dòng ngày cuối kỳ, **không SUM**): trạng thái cuối ngày. SUM 30 ngày stock ≈ sai ×30.

Không JOIN organizations. Không JOIN users trên report_daily_staff trừ khi cần (đã có user_name cache).

## report_daily_finance

- organization_id, date, currency
- FLOW: collected_in, collected_out, payment_count, contracts_signed_count, contracts_signed_value (SeeMoney trên các cột tiền)
- STOCK: receivable_total, receivable_not_due, receivable_0_30, receivable_31_60, receivable_61_90, receivable_90_plus, overdue_contract_count
- dso_sum_days, dso_n — DSO = SUM(dso_sum_days)/SUM(dso_n), không AVG của AVG
- is_partial, computed_at

Thu tháng: SUM(collected_in) WHERE date trong tháng. Công nợ hiện tại: receivable_total của MAX(date), không SUM.

## report_daily_cases

FLOW: opened_count, closed_count (không có reopened_count — số mở lại nằm ở cases.reopen_count)
STOCK: backlog_count, overdue_count, due_soon_count, on_hold_count, on_hold_over_30_count
cycle_sum_days, cycle_n

## report_daily_leads

FLOW: new_count, won_count, lost_count
STOCK: pipeline_count, stale_count

## report_daily_staff

user_id, user_name (cache — GROUP BY user_id không user_name)
FLOW: hours_logged, cases_closed_count, tasks_due_count, tasks_done_on_time_count, collected_attributed (SeeMoney)
STOCK: cases_open_count

Lawyer/staff thường **reports=off** — đừng dùng report_* nếu câu hỏi chi tiết từng vụ/HĐ; dùng bảng gốc.

```sql
SELECT SUM(collected_in) AS collected_in
FROM report_daily_finance
WHERE date >= DATE_FORMAT(CURDATE(), '%Y-%m-01') AND date <= CURDATE() AND currency = 'VND'
```
