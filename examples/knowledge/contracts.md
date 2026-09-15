# Table: contracts

Hợp đồng.

Columns:
- id (bigint, PK)
- organization_id (bigint)
- code (varchar)
- name (varchar)
- payment_amount (bigint)
- payment_currency (char, default VND)
- payment_due_date (date)
- client_id (bigint, FK clients.id)
- case_id (bigint, FK cases.id)
- effective_from (date)
- expires_at (date)
- is_canceled (tinyint)
- is_completed (tinyint)
- created_at (timestamp)
- deleted_at (timestamp) — always `WHERE deleted_at IS NULL`

Sample questions:
- Total contract value by client
- Expired but not completed contracts
- Upcoming payment_due_date