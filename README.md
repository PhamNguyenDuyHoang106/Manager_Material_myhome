# Construction Materials Manager

Production-oriented mobile + backend system for a private construction materials business.

## Tech Stack

- Mobile: Flutter
- Backend: Node.js + Express
- Database: PostgreSQL
- Money strategy: Store monetary values as integer cents (`BIGINT`) for financial precision
- Offline mode: SQLite (`sqflite`) + sync queue

## Project Structure

```text
.
|-- backend
|   |-- migrations
|   |   `-- 001_init.sql
|   |-- src
|   |   |-- app.js
|   |   |-- server.js
|   |   |-- config/db.js
|   |   |-- middlewares/errorHandler.js
|   |   |-- routes/index.js
|   |   |-- utils
|   |   |   |-- money.js
|   |   |   `-- runMigration.js
|   |   `-- modules
|   |       |-- dashboard/dashboard.routes.js
|   |       |-- customers/customer.routes.js
|   |       |-- materials/material.routes.js
|   |       |-- imports/import.routes.js
|   |       |-- invoices/invoice.routes.js
|   |       |-- payments/payment.routes.js
|   |       |-- ops/ops.routes.js
|   |       `-- reports/report.routes.js
|   |-- scripts
|   |   |-- backup.js
|   |   `-- restore.js
|   `-- package.json
|-- mobile_app
|   |-- pubspec.yaml
|   `-- lib
|       |-- main.dart
|       |-- core/local/local_db.dart
|       |-- core/sync/sync_service.dart
|       |-- core/network/api_client.dart
|       `-- features
|           |-- dashboard/presentation/dashboard_screen.dart
|           |-- customers/presentation/customers_screen.dart
|           |-- invoices/presentation/invoices_screen.dart
|           |-- inventory/presentation/inventory_screen.dart
|           `-- settings/presentation/settings_screen.dart
`-- README.md
```

## Database Schema (Required Tables)

Implemented in:
- `backend/migrations/001_init.sql`
- `backend/migrations/002_reliability_upgrade.sql`
- `backend/migrations/003_offline_hardening.sql`
- `backend/migrations/004_enterprise_safety.sql`

- `customers(id, name, phone, address, created_at, updated_at)`
- `materials(id, name, unit, default_import_price_cents, default_selling_price_cents, current_stock, created_at, updated_at)`
- `imports(id, material_id, quantity, import_price_cents, imported_at, created_at)`
- `invoices(id, customer_id, invoice_date, total_amount_cents, status, immutable, created_at)`
- `invoice_items(id, invoice_id, material_id, quantity, selling_price_cents, line_total_cents)`
- `payments(id, invoice_id, amount_cents, payment_date, created_at)`
- `audit_logs(id, action, entity_type, entity_id, metadata, created_at)`
- `invoices.client_id (UUID UNIQUE), invoices.updated_at`
- `payments.client_id (UUID UNIQUE), payments.updated_at`
- `customers.is_deleted`
- `materials.is_deleted`
- `daily_snapshots(id, snapshot_date, total_revenue_cents, total_debt_cents, total_stock_value_cents, created_at)`
- `migrations_history(id, migration_name, status, started_at, finished_at, error_message)`
- `system_state(state_key, state_value, updated_at)`

### Relationships

- `imports.material_id -> materials.id`
- `invoices.customer_id -> customers.id`
- `invoice_items.invoice_id -> invoices.id`
- `invoice_items.material_id -> materials.id`
- `payments.invoice_id -> invoices.id`

### Indexes

- `idx_customers_name`
- `idx_invoices_customer_id`
- `idx_invoices_invoice_date`
- `idx_invoices_status`
- `idx_invoice_items_invoice_id`
- `idx_payments_invoice_id`
- `idx_imports_material_id`
- `idx_audit_logs_entity`
- `idx_audit_logs_created_at`
- `idx_invoices_customer_date`
- `idx_payments_payment_date`
- `idx_imports_imported_at`

## Core Business Rules Implemented

1. Invoice immutability:
   - No update/delete endpoint for invoices or invoice items.
   - `selling_price_cents` persisted on each invoice item at creation time.
2. Debt accuracy:
   - Partial payments supported.
   - Overpayment blocked at API layer.
   - Invoice status auto-updated (`unpaid` -> `partially_paid` -> `paid`).
3. Inventory consistency:
   - Imports add stock.
   - Invoice creation checks stock and deducts stock.
   - Operations are wrapped in DB transactions.
4. Merged unpaid invoices:
   - Virtual grouping endpoint; original invoices remain unchanged.
5. Audit logging:
   - Automatically records `CREATE_INVOICE`, `ADD_PAYMENT`, `IMPORT_MATERIAL`, `UPDATE_CUSTOMER`, `UPDATE_MATERIAL`.
6. Offline and sync:
   - Mobile writes pending invoice/payment actions to local queue.
   - Auto-sync retries when connectivity is available.
   - Server remains source of truth.

## REST API Design

Base URL: `/api`

### Customers
- `GET /customers`
- `POST /customers`
- `PUT /customers/:id`
- `DELETE /customers/:id`
- `GET /customers/:id/details` (invoices + payment history + total debt)

### Materials
- `GET /materials`
- `POST /materials`
- `PUT /materials/:id`
- `DELETE /materials/:id`

### Inventory (Imports)
- `GET /imports`
- `POST /imports`

### Invoices
- `GET /invoices?q=&from=&to=&status=&page=&page_size=` (search/filter + pagination)
- `GET /invoices/:id`
- `POST /invoices` (immutable creation only)
- `GET /invoices/:id/export.png` (invoice image export)
- `GET /invoices/:id/export.pdf` (printable PDF)

### Payments
- `POST /payments`
- `GET /payments?page=&page_size=`

### Debt and Merged Unpaid
- `GET /reports/customers/:customerId/debt`
- `GET /reports/customers/:customerId/merged-unpaid?page=&page_size=`

### Dashboard
- `GET /dashboard/summary` (total unpaid debt, unpaid invoices, revenue today, revenue month)

### Incremental Sync and Idempotency
- `GET /sync?updated_since=<ISO_TIMESTAMP>` returns changed rows only.
- `POST /invoices` now requires `client_id` UUID for idempotent create.
- `POST /payments` now requires `client_id` UUID for idempotent create.
- if duplicate `client_id` is retried, server returns existing record and does not insert duplicate.

### Enterprise Health & Safety
- `GET /health` returns database status, last sync, pending queue count, last backup time.
- `GET /health/data-consistency` returns last consistency job output.
- `GET /health/data-consistency?run_now=true` forces immediate validation run.

### Backup/Restore
- `POST /ops/backup`
- `npm run backup`
- `npm run restore -- <path-to-backup.sql>`

## Required Example Flows

### 1) Create Invoice

`POST /api/invoices`

```json
{
  "customer_id": 1,
  "date": "2026-04-26",
  "items": [
    {
      "material_id": 2,
      "quantity": 5.5,
      "selling_price_at_that_time": 42.75
    }
  ]
}
```

### 2) Add Payment (Partial Allowed)

`POST /api/payments`

```json
{
  "invoice_id": 10,
  "amount": 50.0,
  "payment_date": "2026-04-27"
}
```

### 3) Calculate Debt

- Invoice remaining debt:
  - `invoice.total_amount_cents - sum(payments.amount_cents)`
- Customer total debt:
  - `sum(customer invoices total_amount_cents) - sum(all payments for customer invoices)`

Use: `GET /api/reports/customers/:customerId/debt`

## Flutter UI/UX Coverage

Tabs implemented:
- Dashboard
- Customers
- Invoices
- Inventory
- Settings

Each main screen includes list view and add/detail interaction.

Additional enhancements:
- Customer autocomplete in invoice create form.
- Fast numeric keyboard for quantity/price/amount.
- Loading indicator, empty state, and safer offline fallback.
- Local caching of customers/materials/invoices/payments.
- Offline queue for `CREATE_INVOICE`, `ADD_PAYMENT` with retry sync.

## Run Instructions

## 1. Database

Create DB:

```sql
CREATE DATABASE material_manager;
```

## 2. Backend

```bash
cd backend
cp .env.example .env
npm install
npm run migrate
npm run dev
```

Backend default: `http://localhost:4000`

## 3. Flutter Mobile

```bash
cd mobile_app
flutter pub get
flutter run
```

If using Android emulator, API URL in `main.dart` is already set to `http://10.0.2.2:4000/api`.

## 4. Backup and Restore operations

```bash
cd backend
npm run backup
npm run restore -- backups/backup-YYYY-MM-DDTHH-mm-ss-sssZ.sql
```

For scheduled backups (recommended): run `npm run backup` daily using OS task scheduler/cron.

## 5. Audit log verification examples

- Create invoice -> one row in `audit_logs` with action `CREATE_INVOICE`
- Add payment -> one row with action `ADD_PAYMENT`
- Import material -> one row with action `IMPORT_MATERIAL`
- Update customer/material -> one row with corresponding update action

```sql
SELECT action, entity_type, entity_id, metadata, created_at
FROM audit_logs
ORDER BY created_at DESC
LIMIT 20;
```

## 6. Idempotency request example

```json
POST /api/invoices
{
  "client_id": "2efdb4e4-407e-4f43-9d36-d4eec8313c0d",
  "customer_id": 1,
  "date": "2026-04-26",
  "items": [
    { "material_id": 2, "quantity": 3.0, "selling_price_at_that_time": 10.5 }
  ]
}
```

On retry with same `client_id`, API returns the same invoice row instead of creating a duplicate.

## 7. Background jobs and schedule

Scheduled in `backend/src/jobs/scheduler.js`:
- `0 1 * * *`: daily PostgreSQL backup
- `10 1 * * *`: daily financial snapshot
- `*/30 * * * *`: data consistency validation
- startup: immediate consistency check

### Data consistency validation checks
- invoice total mismatch (`invoices.total_amount_cents` vs sum of `invoice_items.line_total_cents`)
- invoice status mismatch (`unpaid` / `partially_paid` / `paid` vs actual payments)
- stock mismatch (`materials.current_stock` vs imports minus sold quantities)
- negative customer debt anomalies

On mismatch, logs `DATA_INCONSISTENCY` into `audit_logs`.

## 8. Automatic backup retention policy

- Backups saved under `backend/backups/`
- Old backups automatically deleted; only latest 30 files kept
- Last backup metadata persisted in `system_state` (`state_key = 'last_backup'`)

## 9. Safe migration strategy

`backend/src/utils/runMigration.js` now:
- creates/uses `migrations_history`
- skips already successful migrations
- records `running/success/failed` per migration file
- stores failure message for diagnosis

## 10. Example structured logs

```json
{"timestamp":"2026-04-27T00:00:00.000Z","level":"INFO","message":"daily_backup started","metadata":{}}
{"timestamp":"2026-04-27T00:00:05.000Z","level":"WARNING","message":"Sync retry attempt received","metadata":{"retry":3}}
{"timestamp":"2026-04-27T00:01:00.000Z","level":"ERROR","message":"Data consistency check failed","metadata":{"error":"relation does not exist"}}
```

## 11. Integration steps for enterprise safety layer

1. Install new dependencies:
```bash
cd backend
npm install
```
2. Apply migrations:
```bash
npm run migrate
```
3. Start server (scheduler auto-starts):
```bash
npm run dev
```
4. Verify health:
```bash
curl http://localhost:4000/api/health
curl http://localhost:4000/api/health/data-consistency
```

## Production Hardening Checklist

- Add auth (JWT + role-based permissions).
- Move route logic into dedicated service/repository layers per module.
- Add migration versioning tool (e.g. Prisma Migrate/Flyway/Knex).
- Add automated tests (unit + integration + API contract).
- Add audit logs (financial operations trail).
- Set up backups and restore drills for long-term retention.
