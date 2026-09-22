# Table: official_dispatches

Công văn đi/đến.

Columns:

- id (bigint, PK)
- organization_id (bigint)
- direction (varchar, enum `DispatchDirection`): **incoming** | **outgoing** — **không có** `inbound`/`outbound`/`in`/`out`
- code (varchar, nullable)
- title (varchar)
- summary (text)
- counterparty_name, counterparty_address — PII
- issued_date, received_date, deadline (date)
- legal_case_id (bigint, FK cases, nullable) — trả id
- reply_to_id (bigint, nullable)
- status (varchar, enum `DispatchStatus` — tập giá trị khác nhau theo `direction`):
  - `direction = 'incoming'`: received | processing | replied | completed | canceled
  - `direction = 'outgoing'`: draft | pending_sign | signed | sent | acknowledged
- assignee_id, created_by, signer_id, signed_by, sent_by (bigint, nullable) — "của tôi" không JOIN users; LFMS = assignee OR signer OR created_by OR vụ visibleTo
- signed_at, sent_at, completed_at (timestamp)
- sent_via (varchar)
- rejection_reason, completion_reason (text)
- created_at, updated_at
- deleted_at — luôn `deleted_at IS NULL`

Không query official_dispatch_histories / official_dispatch_task (không whitelist).

Sample:
SELECT id, direction, code, title, status, deadline, legal_case_id FROM official_dispatches WHERE deleted_at IS NULL LIMIT 100

Sample — công văn đến chưa xử lý:
SELECT id, code, title, status, deadline FROM official_dispatches WHERE deleted_at IS NULL AND direction = 'incoming' AND status IN ('received', 'processing') LIMIT 100
