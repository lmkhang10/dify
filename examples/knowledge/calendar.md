# Table: custom_calendar_events

Lịch nội bộ văn phòng. Không query `custom_calendar_event_types` (không whitelist) — trả `type_id`.

Columns:

- id (bigint, PK)
- organization_id (bigint)
- type_id (bigint)
- title (varchar)
- starts_at (datetime)
- ends_at (datetime, nullable)
- all_day (tinyint)
- notes (text)
- created_by (bigint, nullable)
- created_at, updated_at

Không có deleted_at.

Sample:
SELECT id, title, starts_at, ends_at, all_day, type_id FROM custom_calendar_events WHERE starts_at >= CURDATE() ORDER BY starts_at LIMIT 100
