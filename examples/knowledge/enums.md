# ENUM SQL — chỉ literal này, không bịa gần nghĩa

Khi viết WHERE/JOIN, copy **đúng chuỗi** dưới đây. Cấm `paid`, `unpaid`, `inbound`, `outbound`.

## payments (đợt thu)

| Cột         | Chỉ các giá trị này                                                | Cấm (LLM hay bịa)                                |
| ----------- | ------------------------------------------------------------------ | ------------------------------------------------ |
| `status`    | `pending` (chưa thu / còn nợ) · `succeeded` (đã thu) · `cancelled` | `paid` · `unpaid` · `done` · `complete`          |
| `direction` | `in` (thu khách) · `out` (chi)                                     | `inbound` · `outbound` · `incoming` · `outgoing` |

Công nợ khách = `SUM(payments.amount)` WHERE `status = 'pending' AND direction = 'in'`.
Không: `SUM(contracts.payment_amount) - SUM(payments…)` trên cùng JOIN (nhân giá trị HĐ theo số đợt).

## official_dispatches (công văn)

| Cột               | Chỉ các giá trị này                                              | Cấm                                   |
| ----------------- | ---------------------------------------------------------------- | ------------------------------------- |
| `direction`       | `incoming` · `outgoing`                                          | `inbound` · `outbound` · `in` · `out` |
| `status` incoming | `received` · `processing` · `replied` · `completed` · `canceled` |                                       |
| `status` outgoing | `draft` · `pending_sign` · `signed` · `sent` · `acknowledged`    |                                       |

## clients

- `profile_kind`: `client` · `lead`
- `type`: `individual` · `business`
- `status`: `active` · `inactive` · `potential` · `archived`
- `source`: `referral` · `website` · `walk_in` · `social_media` · `advertisement` · `other`
- `lead_stage`: `new` · `consulting` · `proposal` · `negotiating` · `won` · `lost`

## cases

- `category`: `litigation` · `legal_service`
- `status`: `new` · `in_progress` · `on_hold` · `closed` — không cột boolean `on_hold`

## tasks

Không cột `status`. Tiến độ: `progress` 0–100. Ưu tiên: `emergency` · `high` · `medium` · `low`.

## users.status

`active` · `away` · `inactive`
