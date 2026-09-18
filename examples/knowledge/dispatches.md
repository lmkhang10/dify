# Table: official_dispatches

Công văn đi/đến.

Columns:

- id (bigint, PK)
- organization_id (bigint)
- direction (varchar): inbound | outbound (kiểm tra giá trị thực tế inbound/outbound hoặc in/out trong dữ liệu)
- code (varchar, nullable)
- title (varchar)
- summary (text)
- counterparty_name, counterparty_address — PII
- issued_date, received_date, deadline (date)
- legal_case_id (bigint, FK cases, nullable) — trả id
- reply_to_id (bigint, nullable)
- status (varchar)
- assignee_id, created_by, signer_id, signed_by, sent_by (bigint, nullable)
- signed_at, sent_at, completed_at (timestamp)
- sent_via (varchar)
- rejection_reason, completion_reason (text)
- created_at, updated_at
- deleted_at — luôn `deleted_at IS NULL`

Không query official_dispatch_histories / official_dispatch_task (không whitelist).

Sample:
SELECT id, direction, code, title, status, deadline, legal_case_id FROM official_dispatches WHERE deleted_at IS NULL LIMIT 100
