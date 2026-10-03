# Mess Billing & Canteen Management Module

A comprehensive Mess Management Module featuring complete functional specifications, workflow documentation, and a fully interactive, zero-dependency offline Mock UI replicating the counter billing, member management, menu planning, and reporting workflows.

---

## 📁 Repository Structure

```
Mess_Module/
├── mock-ui/                             # Interactive HTML5/CSS3/Alpine.js Mock Application
│   ├── assets/                          # Local webfonts (IBM Plex Sans Arabic, Nunito)
│   ├── css/                             # Modular styling (Flat, Clay, Glass themes)
│   ├── js/                              # Data store, state machine, views & controllers
│   ├── qa/                              # Automated test suites & verification scripts
│   ├── vendor/                          # Offline vendor libraries (Alpine, Tabulator, ApexCharts, etc.)
│   ├── index.html                       # Application entry point
│   ├── CLIENT_HANDOVER.md               # Acceptance criteria & client handover document
│   └── README.md                        # Mock UI demo guide & keyboard map
├── Mess_Modules.md                      # Core functional specifications breakdown
├── Mess_Screens_Specification.md        # Detailed screen-by-screen architectural spec
├── Mess_MockUI_Implementation_Plan.md   # Architectural and implementation blueprint
├── Mess_MockUI_Tasks_Register.md        # Task execution register and progress log
└── WhatsApp Image 2026-09-15 at 6.07.07 PM.jpeg  # Reference hardware & receipt layout
```

---

## 🚀 Quick Start (Mock UI)

The interactive UI is designed to run directly without build steps or node dependencies:

1. Open [`mock-ui/index.html`](mock-ui/index.html) directly in any modern browser (`Chrome`, `Edge`, `Firefox`, `Safari`).
2. Or serve locally with any static web server:
   ```bash
   cd mock-ui
   python -m http.server 8080
   ```
   Navigate to `http://localhost:8080`.

---

## ✨ Key Features & Highlights

- **RFID Tap-to-Bill Kiosk**: Sub-second meal entitlement billing at 0.00 price, duplicate-serve prevention, supervisor override authorization, and simulated thermal token slip printing.
- **Dynamic Daily Menu Planning**: Cuisine-wise meal assignment (Breakfast, Lunch, Dinner) with automated item quantity mappings and bill locks.
- **Member Management**: RFID card assignment, cuisine preferences, validity tracking, and renewal management.
- **Reporting & Analytics**:
  - Members Register with validity countdowns
  - Cuisine × Meal Type Headcount Matrix (with 2-level drill-down)
  - Item-wise Movement & Consumption
  - Customer Attendance (Summary & Heatmap Grid)
  - Rush Hour & Time-based Distribution
- **Delimited CSV Exports**: All analytical exports adhere to standard pipe (`|`) delimiter compliance.
- **Multi-Theme Design System**: Instant switching between **Flat**, **Clay** (Neumorphic), and **Glass** (Glassmorphic) themes with Light/Dark mode toggles.
