# Table: clients

Khách hàng và lead.

Columns:
- id (bigint, PK)
- organization_id (bigint)
- code (varchar)
- type (enum: individual, business)
- profile_kind (enum: client, lead)
- name (varchar)
- company (varchar)
- email (varchar)
- phone (varchar)
- status (enum: active, inactive, potential, archived)
- lead_stage (enum: new, consulting, proposal, negotiating, won, lost)
- assigned_to (bigint, FK users.id)
- created_at (timestamp)
- deleted_at (timestamp) — always `WHERE deleted_at IS NULL`

Sample questions:
- How many active clients?
- List leads in negotiating stage
- Clients assigned to a lawyer