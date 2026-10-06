# eCuisine Mess Module — Documentation Index

RFID tap-to-bill mess / canteen entitlement system. Members tap a card at the counter, the system validates the entitlement, issues a token at **0.00** and prints a slip.

This folder holds the **common docs shared by the whole project**. Layer-specific docs live next to the code:

| Scope | Location | Audience |
|---|---|---|
| **Common (this folder)** | `docs/` | Everyone |
| **Front-end (Flutter)** | [`ecuisine_mess/docs/`](../ecuisine_mess/docs/README.md) | Flutter developers |
| **Back-end (FastAPI)** | [`backend_api/docs/`](../backend_api/docs/README.md) | Python developers |

## Common docs

| # | Doc | What it answers |
|---|---|---|
| 00 | [Product Overview](00-product-overview.md) | What are we building, for whom, what is in/out of scope, glossary |
| 01 | [Business Rules](01-business-rules.md) | Every rule the system must enforce (billing, validity, menus, cancel, override) |
| 02 | [System Architecture](02-system-architecture.md) | Components, runtime topology on Windows, data flow, tech stack |
| 03 | [Database Design](03-database-design.md) | MariaDB schema, UUID strategy, ERD, indexes, migrations |
| 04 | [API Contract](04-api-contract.md) | Single source of truth for every endpoint, payload, error code, and its implementation status |
| 05 | [Screens & UX Spec](05-screens-ux-spec.md) | All screens, mock-ui → Flutter route mapping, roles, keyboard map |
| 06 | [Engineering Standards](06-engineering-standards.md) | Naming, IDs, dates, errors, git, review checklist |
| 07 | [Windows Setup](07-windows-setup.md) | Install and run MariaDB + API + Flutter on Windows |
| 08 | [Gap Analysis & Roadmap](08-gap-analysis-roadmap.md) | What exists vs. what the mock needs; phased plan; open questions |

## Source-of-truth precedence

When documents disagree, resolve in this order:

1. **`database/schema.sql`** — the DB schema is declared accurate.
2. **`mock-ui/`** — screen behaviour, layout, flows (with the two overrides below).
3. **`Mess_Screens_Specification.md`** / **`Mess_Modules.md`** — original requirements.
4. These docs.
5. Existing code.

### The two overrides to the mock-ui / original spec

1. **No `CODE` fields anywhere.** `item_code`, `member_code`, `cuisine_code`, `category_code` do not exist. Where the spec or mock shows `Code – Name`, show `Name` only. (`bill_number` and `token_number` are *operational slip numbers*, not master codes, and stay.)
2. **All IDs are UUIDs** (`CHAR(36)`, string in Dart/JSON). Never integers, never user-visible.

## Legacy / planning docs at repo root

These pre-date `docs/` and remain for history. `docs/` supersedes them where they conflict.

| File | Status |
|---|---|
| `README.md` | Quick start; update to link here and to reflect the BLoC migration |
| `SYSTEM_OVERVIEW.md` | Good snapshot; superseded by 00 / 02 / 08 |
| `Mess_Modules.md`, `Mess_Screens_Specification.md` | Original requirements (contain `Code` columns — ignore those) |
| `Mess_MockUI_*`, `Mess_LiveStack_*`, `Mess_AppShell_*`, `Mess_BackendFoundation_*`, `Mess_Items_*` | Task registers for completed phases |
| `implementation_plan.md` | Master index: Phases 1–5 Done → points to Flutter + Backend plans |
| `ecuisine_mess/docs/implementation-plan.md` | Flutter FE-0…FE-6 plan (draft / awaiting approval) |
| `task.md` | Execution checklist for the active phase |
| `mock-ui/README.md`, `mock-ui/CLIENT_HANDOVER.md` | Mock usage / demo script |
