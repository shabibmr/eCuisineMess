# Mess Module (Frappe App)

Full-featured Mess Billing, Canteen Entitlement, and Member Attendance Suite for Frappe Framework and ERPNext.

## Installation

```bash
# In your bench directory:
bench get-app https://github.com/shabibmr/eCuisineMess.git --branch main
# Or link local folder:
bench get-app mess_module /path/to/frappe_app/mess_module

# Install into site:
bench --site <your-site-name> install-app mess_module

# Run migrations:
bench --site <your-site-name> migrate
```

## Features

- **RFID Tap Entitlement**: Sub-second meal entitlement billing at 0.00 price.
- **Duplicate Protection**: Prevents multiple meal vouchers for the same member in the same meal slot.
- **Daily Menu Planner**: Cuisine-wise meal assignment (Breakfast, Lunch, Dinner).
- **Supervisor Overrides**: Audited manual overrides for exceptions.
- **Analytical Reports**: Headcount matrix, customer attendance, item consumption movement, rush hour distribution.
