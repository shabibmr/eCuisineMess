# Auth & Security

Code: `core/security.py`, `routers/auth.py`, `schemas/auth.py`. Rules: BR-U1…U5, BR-O2.

## 1. Authentication (implemented)

| Aspect | Implementation |
|---|---|
| Credentials | `mess_users.username` + bcrypt `password_hash` (`bcrypt.hashpw/checkpw`) |
| Login | `POST /api/v1/auth/login` → `{success, token, user:{id,username,display_name,is_active}}`; bad creds or inactive → 401 `Invalid username or password` (same message for both — no user enumeration) |
| Session | `secrets.token_hex(32)` (64 hex chars) stored in `mess_user_sessions` (`expires_at = now + MESS_SESSION_DAYS`, default 7) |
| Use | `Authorization: Bearer <token>`; `get_current_user` joins session+user, requires `expires_at > NOW()` and `u.is_active = 1` |
| Logout | `POST /auth/logout` deletes the token row (idempotent, always `{success:true}`) |
| `GET /auth/me` | current user |
| `POST /auth/change-password` | requires old password; min new length 4 |
| `GET/POST /users` | list / create (hashes password); requires any valid session |
| Seed user | `admin` / `admin123` (**change on go-live**) |

Client behaviour on `401` anywhere: clear the session locally and return to Login (no logout call).

## 2. Authorization — **not yet enforced** (F2/F3)

`Depends(get_current_user)` is applied **only** to `/auth/me`, `/auth/change-password`, `/users` (GET/POST). **Every business endpoint is open**: members, items, cuisines, menus, meal-times, counter tap/issue, bills (list/get/cancel), reports.

### Target (P1 → P5)

1. **P1 — authenticate everything** except `GET /health` and `POST /auth/login`: add a router-level dependency
   ```python
   router = APIRouter(dependencies=[Depends(get_current_user)])
   ```
   (or `app.include_router(x.router, dependencies=[Depends(get_current_user)])`). The Flutter client already sends the Bearer token.
2. **P5 — roles:** add `mess_users.role` (`admin|supervisor|counter`) and a dependency factory:
   ```python
   def require(*perms: str):
       def dep(user = Depends(get_current_user)):
           if not any(PERMISSIONS[user["role"]].get(p) for p in perms): raise ForbiddenException()
           return user
       return dep
   ```
   Matrix = [00 §2](../../docs/00-product-overview.md): masters edit → admin; menu edit → admin; counter use → all; bill cancel/override → supervisor+admin; reports → supervisor+admin.
3. `user_public` includes `role`; client hides nav and guards routes by it — but **the API remains the enforcement point**.

## 3. Supervisor verification (override/cancel) — F3

Current: `POST /auth/verify-supervisor {pin}` compares to `settings.SUPERVISOR_PIN_DEFAULT` (`MESS_SUPERVISOR_PIN`, default `1234`). `issue_token` re-checks a PIN **only if one is sent**; cancel checks nothing. `override_by` / `cancelled_by` are free-text from the client.

Target:
- `POST /auth/verify-supervisor {username, password}` (or a per-supervisor PIN stored hashed in `mess_users.pin_hash`) → returns `{success, supervisor:{id, display_name}}` for a user with role `supervisor|admin`.
- `issue-token` with `is_override=1` **requires** a verified supervisor (short-lived signed override token, or credentials in the same request) — reject otherwise.
- `cancel` requires `bill.cancel`; `cancelled_by` = authenticated user (or verified supervisor); never taken from the body.
- Remove `SUPERVISOR_PIN_DEFAULT` and the demo PIN from client code when this ships.
- Rate-limit verification (e.g. 5 failures → 1 min lockout) and log every override/cancel with actor.

## 4. Password & token hygiene

- bcrypt (default cost 12) ✔. Enforce min length ≥ 8 for non-demo (schema min is 4 today).
- Sessions are never extended automatically; consider sliding expiry for counters or a 12-hour kiosk TTL.
- Purge expired sessions weekly ([03 §8](../../docs/03-database-design.md)).
- Invalidate sessions when a user is deactivated (the join on `is_active` already does) or changes password (delete other sessions).
- Don't log tokens, passwords or full RFID tags.
- `GET /users` currently returns all users to any authenticated caller — restrict to admin.

## 5. Transport & network

- Plain HTTP on a trusted LAN is the baseline. For anything beyond one room, terminate TLS (Caddy/nginx/IIS ARR reverse-proxy → uvicorn on 127.0.0.1) and update the client API URL to `https://`.
- Expose **only TCP 8000** (or 443 via proxy) to counters; keep MariaDB (3306) bound to localhost/server-only.
- CORS: `allow_origins=["*"]` with `allow_credentials=True` is invalid in browsers and unnecessary for the Windows desktop client; restrict via config in prod.

## 6. Data protection

- RFID tags and phone numbers are PII-ish: mask in lists/logs/reports (BR-M6); the tap rejection currently returns the **entire member row** — trim.
- DB user: create `mess_api` with `SELECT, INSERT, UPDATE, DELETE` on `ecuisine_mess.*` only; stop using `root`/empty password.
- Backups contain password hashes and PII — store securely.

## 7. Security checklist before go-live

- [ ] All business routes behind `get_current_user`; roles enforced (P5)
- [ ] Supervisor verification real; demo PIN removed
- [ ] `admin` password changed; users created per person
- [ ] Dedicated DB user + password via env
- [ ] CORS restricted / TLS decided
- [ ] Token sequence & double-serve race fixed ([database-access §4](database-access.md))
- [ ] Inputs validated (enums, dates, quantities)
- [ ] Logs free of secrets
