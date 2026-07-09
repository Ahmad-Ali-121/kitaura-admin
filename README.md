<div align="center">

# KitAura Admin Panel

**Feature-complete admin dashboard for [KitAura](https://github.com/Winibex/KitAura) — Flutter Web.**

[![Live](https://img.shields.io/badge/live-admin--kitaura.winibex.com-0F172A)](https://admin-kitaura.winibex.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.9-0F172A)](https://flutter.dev)
[![Auth](https://img.shields.io/badge/auth-Firebase%20custom%20claim-CF4D6F)](https://firebase.google.com/docs/auth/admin/custom-claims)

</div>

---

## What is this?

A separate Flutter Web project (`kitaura_admin`) that connects to the same Firebase backend as the main KitAura app, gated behind the Firebase custom claim `admin: true`. Provides:

- User support & lookup
- Real-time AI spend monitoring (KitAura is free-tier — every Claude call costs money)
- Live config editing (plan limits, pricing, Pro templates, feature flags, announcements)
- Abuse detection (refusals + hourly burst + cost outliers)
- Read-only document inspector with canvas preview (~85% visual fidelity)
- Full audit log of every admin mutation

**Deployed separately** to give the main app a smaller bundle and stronger security separation.

**Live at** [admin-kitaura.winibex.com](https://admin-kitaura.winibex.com)

## Status

Feature-complete for current operational needs.

- ✅ **Phase A1 — Foundation** (custom claim, guard, shell, audit collection)
- ✅ **Phase A2 — Read-only dashboards** (KPI dashboard, users list, user detail, AI activity, AI failures, cost overview)
- ✅ **Phase A3 — Config editors** (plan limits, pricing, Pro templates, feature flags, announcements)
- ✅ **Phase A4 — Mutations + audit log** (6 user action buttons + full audit trail)
- ✅ **Phase A5 — Investigative tools** (Steps 16–23 — per-user AI activity, documents, transactions, refusals, cost by user/feature, abuse monitor, document inspector with read-only canvas renderer)
- ⏳ **Step 24 (Templates Manager)** — deferred until templates migrate from source-code data files to Firestore
- ⏳ **Phase A6 (Multi-admin)** — deferred until a second admin is needed

**23 of 25 screens live.**

## Features

**Dashboard** (`/admin`)
- 8 KPI cards: total users, active today, MTD spend, active trials, signups this week, AI failures 24h, AI refusals 24h, cache hit rate
- Top 5 spenders this month
- Recent AI failures

**Users** (`/admin/users`, `/admin/users/:uid`)
- Paginated search + plan filter + sort
- Guest filter chip (dustyMauve badge for anonymous users)
- User detail: profile, subscription, lifetime totals
- 6 mutation buttons: grant Pro, extend trial, reset counters, reset hourly burst, reset refusal soft-block, revoke Pro
- Tabs: AI Activity, Documents, Transactions

**AI monitoring** (`/admin/ai`, `/admin/ai/failures`, `/admin/ai/refusals`)
- Cross-user AI activity feed with tool/status/user/date filters
- AI Failures with error pattern grouping + spike detection
- AI Refusals with reason grouping

**Finance** (`/admin/finance`, `/admin/finance/by-user`, `/admin/finance/by-feature`)
- 30-day spend chart (fl_chart)
- Model + tool breakdown
- Cache savings
- Per-user rankings (sortable by spend / refusal rate / call count)
- Per-feature stacked bar chart

**Config editors** (`/admin/config/*`)
- Plan limits (4-tier: Guest / Free / Trial / Pro) with dirty-tracking + diff confirmation
- Model pricing
- Pro template IDs
- Feature flags (7 kill-switches — `guestModeEnabled` added Phase H)
- Announcements (auto-generates fresh hex `id` on every save so dismissed users get re-notified)

**Investigation** (`/admin/abuse`, `/admin/documents`, `/admin/documents/:type/:uid/:docId`)
- Composite abuse monitor: refusals ≥3 + hourly burst ≥10 + top 10% spenders
- Cross-user document list with type filter + cursor pagination
- Document inspector with read-only `AdminCanvasRenderer` (~85% visual fidelity, per-item collapsible JSON)

**Audit log** (`/admin/audit`)
- Every mutation written in the same batch as the action
- Filter by admin, action type, date range, target user
- Expandable rows show side-by-side BEFORE/AFTER JSON

## Tech Stack

Inherits the main app's stack:

- Flutter Web 3.41.9 / Dart 3.11.5
- Riverpod 2.x (StateNotifier + FutureProvider)
- go_router with admin guard
- Firebase Auth with custom claim `admin: true`
- Firestore (shared with main app — no schema divergence)
- fl_chart for spend visualizations
- Firebase Cloud Functions with `adminGuard` on every mutation

## Security Model

```
FIREBASE CUSTOM CLAIM: admin: true
  ├── Set via Admin SDK, one-off bootstrap script
  └── Token-level check — no per-request Firestore read

FRONTEND
  ├── GoRouter redirect: idTokenResult.claims['admin'] === true → allow
  └── Non-admins redirect to /dashboard on main app

CLOUD FUNCTIONS (all admin ops)
  ├── adminGuard() first line — throws if claim missing
  ├── Validate inputs strictly
  ├── Read before-snapshot
  ├── Batch write: mutation + adminActivity audit entry
  └── Return { success: true }

FIRESTORE RULES
  └── adminActivity: read for admins, write blocked (functions only)
```

Admin reads of user data go through Cloud Functions using the Admin SDK (which bypasses rules). Firestore rules don't try to express "admin can read any user" — that would weaken the primary rules.

## Project Structure

```
lib/
├── app.dart, main.dart, firebase_options.dart
├── core/
│   ├── router/       # app_router with adminGuard
│   ├── theme/
│   └── constants/    # brand colors, fonts
├── features/
│   ├── auth/         # admin login (email + Google)
│   ├── shell/        # AdminShell — sidebar + top bar
│   ├── dashboard/    # KPI dashboard
│   ├── users/        # list + detail (with tabs)
│   ├── ai/           # activity, failures, refusals
│   ├── finance/      # cost overview + by-user + by-feature
│   ├── config/       # limits, pricing, pro-templates, feature-flags, announcements
│   ├── audit/        # audit log
│   ├── abuse/        # abuse monitor
│   └── documents/    # list + inspector
└── shared/
    ├── models/       # admin_activity, feature_flag, announcement, admin_action
    ├── services/     # admin_firebase_service, admin_functions_service
    └── widgets/      # admin_confirm_dialog, admin_data_table, canvas_renderer
```

## Cloud Functions (in main app's `functions/` folder)

15 admin-only endpoints, all in `functions/admin_*.js`:

| File | Endpoints |
|---|---|
| `admin.js` | adminGuard helper, setAdminClaim |
| `admin_dashboard.js` | adminGetDashboardKpis |
| `admin_users.js` | adminListUsers, adminGetUserOverview |
| `admin_ai_activity.js` | adminListAiActivity (userId + statusFilter + cursor) |
| `admin_user_documents.js` | adminListUserDocuments |
| `admin_cost_overview.js` | adminGetCostOverview |
| `admin_cost_by_user.js` | adminGetCostByUser |
| `admin_cost_by_feature.js` | adminGetCostByFeature |
| `admin_abuse_monitor.js` | adminGetAbuseMonitor |
| `admin_documents.js` | adminListDocuments, adminGetDocument |
| `admin_actions.js` | adminSetPlan, adminResetCounters, adminResetHourlyBurst, adminResetRefusalCount, adminExtendTrial |
| `admin_config.js` | adminUpdateConfig |
| `admin_announcement.js` | adminUpdateAnnouncement |

Every audit-logged mutation writes `adminActivity/{id}` in the same batch as the mutation.

## Firestore Additions

Schema is additive — no changes to existing main-app collections:

```
adminActivity/{actionId}      # Audit log
config/featureFlags           # 8 kill-switches
config/announcement           # Active system banner (auto-generates fresh id per save)
```

Existing collections read via Cloud Functions with Admin SDK privileges.

## Running Locally

```bash
# 1. Clone
git clone https://github.com/Winibex/kitaura_admin.git
cd kitaura_admin

# 2. Install
flutter pub get

# 3. Firebase config
# Same firebase_options.dart as main app (shared backend)

# 4. Grant yourself the admin claim (one-off, via scripts/bootstrap-admin.js)
# See "Bootstrapping the first admin" below

# 5. Run
flutter run -d chrome
```

## Bootstrapping the First Admin

One-time setup via Node script (in the main app repo's `scripts/` folder):

```javascript
// scripts/bootstrap-admin.js
const admin = require('firebase-admin');
admin.initializeApp({
  credential: admin.credential.cert(require('./service-account.json')),
});

const targetUid = 'YOUR_UID_HERE'; // from Firebase Auth console
await admin.auth().setCustomUserClaims(targetUid, { admin: true });
console.log('Done. Sign out and sign back in for the token to refresh.');
```

After that, the `setAdminClaim` Cloud Function can grant admin to additional UIDs (callable only by existing admins).

## Firestore Indexes

Managed via `firestore.indexes.json` (deployed with `firebase deploy --only firestore:indexes`).

**Composite:**
- `aiActivity` collection group: `status` ASC + `createdAt` DESC

**Single-field collection-group exemptions:**
- `aiActivity.createdAt` (ASC + DESC)
- `cvs.updatedAt` (DESC)
- `coverLetters.updatedAt` (DESC)
- `proposals.updatedAt` (DESC)

## UI Conventions

- **Sidebar:** Prussian Blue (dark) — visually distinct from main app's white sidebar
- **Admin badge:** Magenta Bloom chip in top bar
- **Destructive actions:** `Colors.red.shade700` — the one place we break the "brand colors only" rule, because admin mutations are dangerous and need urgent visual weight
- **Confirmation modals:** Mandatory for every mutation, always show audit preview ("This will be logged as: adminSetPlan by you")

## Deferred Work

- **Templates Manager** (Step 24) — waits on templates migrating from `*_template_data.dart` files to Firestore
- **Multi-admin support** (Phase A6) — waits on the need to grant admin to a second person
- **Scheduled aggregate cache** — Cost Overview currently recomputes on every load. Deploy `scheduledAggregateRefresh` when AI call volume crosses ~50k/month.

## Related

- **[KitAura](https://github.com/Winibex/KitAura)** — main user-facing app (Flutter Web)
- Shared Firebase project: `kitaura-app` (us-central1)

## License

Proprietary. All rights reserved © 2026 Winibex.