/* home.js - Screen: Today Home Dashboard with Timeline, Readiness Matrix & Live KPIs */

window.Mess = window.Mess || {};

(function(Mess) {
  var timelineInstance = null;

  function getTodayIso() {
    if (Mess.clock && Mess.clock.now) {
      var d = Mess.clock.now();
      var yyyy = d.getFullYear();
      var mm = String(d.getMonth() + 1).padStart(2, '0');
      var dd = String(d.getDate()).padStart(2, '0');
      return yyyy + '-' + mm + '-' + dd;
    }
    return new Date().toISOString().slice(0, 10);
  }

  Mess.screens.register({
    id: 'home',
    route: '/',
    title: 'Today',
    nav: { group: 'Operations', icon: 'layout-dashboard', order: 1 },
    roles: ['admin', 'supervisor', 'counter'],

    template: function() {
      var today = getTodayIso();
      var todayFormatted = Mess.format && Mess.format.date ? Mess.format.date(today) : today;
      var currentMeal = Mess.clock && Mess.clock.currentMeal ? Mess.clock.currentMeal() : 'none';

      // Gather active cuisines
      var allCuisines = (Mess.store && Mess.store.list('cuisines')) || [];
      var activeCuisines = allCuisines.filter(function(c) { return c.active !== false; });

      // Menus for today
      var allMenus = (Mess.store && Mess.store.list('menus')) || [];
      var todayMenus = allMenus.filter(function(m) { return m.date === today; });

      // Bills for today
      var allBills = (Mess.store && Mess.store.list('bills')) || [];
      var todayBills = allBills.filter(function(b) { return b.date === today && !b.cancelled; });

      var bCount = todayBills.filter(function(b) { return b.meal_code === 'B'; }).length;
      var lCount = todayBills.filter(function(b) { return b.meal_code === 'L'; }).length;
      var dCount = todayBills.filter(function(b) { return b.meal_code === 'D'; }).length;
      var totalServed = todayBills.length;

      // Build Menu Readiness Rows
      var meals = [
        { code: 'B', name: 'Breakfast', icon: 'sunrise' },
        { code: 'L', name: 'Lunch', icon: 'sun' },
        { code: 'D', name: 'Dinner', icon: 'moon-star' }
      ];

      var readinessRowsHtml = activeCuisines.map(function(c) {
        var cellsHtml = meals.map(function(m) {
          // Find menu for today + cuisine + meal
          var menu = todayMenus.find(function(item) {
            return (item.cuisine_id === c.id || item.cuisineId === c.id || item.cuisine_code === c.code) &&
                   (item.meal_type === m.code || item.mealType === m.code || item.meal_code === m.code);
          });

          var itemCount = (menu && menu.items) ? menu.items.length : 0;
          var isSet = itemCount > 0;

          if (isSet) {
            return `
              <td style="padding: 10px 14px; text-align: center;">
                <a href="#/menu-editor?date=${today}&cuisine=${c.id}&meal=${m.code}" 
                   class="badge badge--success readiness-cell flex-row align-center justify-center gap-xs"
                   style="text-decoration: none; padding: 4px 10px; font-weight: 500;">
                  <i data-lucide="check" style="width: 14px; height: 14px;"></i>
                  <span>${itemCount} item${itemCount === 1 ? '' : 's'}</span>
                </a>
              </td>
            `;
          } else {
            return `
              <td style="padding: 10px 14px; text-align: center;">
                <a href="#/menu-editor?date=${today}&cuisine=${c.id}&meal=${m.code}" 
                   class="badge badge--danger readiness-cell flex-row align-center justify-center gap-xs"
                   style="text-decoration: none; padding: 4px 10px; font-weight: 500;">
                  <i data-lucide="circle-alert" style="width: 14px; height: 14px;"></i>
                  <span>Not set</span>
                </a>
              </td>
            `;
          }
        }).join('');

        return `
          <tr style="border-bottom: 1px solid var(--separator);">
            <td style="padding: 12px 16px; font-weight: 600;">
              <span class="font-mono text-xs color-ink-3" style="margin-right: 6px;">${c.code}</span>
              <span>${c.name}</span>
            </td>
            ${cellsHtml}
          </tr>
        `;
      }).join('');

      // Build Served Breakdown Rows
      var servedRowsHtml = activeCuisines.map(function(c) {
        var cuisBills = todayBills.filter(function(b) {
          return b.cuisine_id === c.id || b.cuisineId === c.id || b.cuisine_code === c.code;
        });
        var bC = cuisBills.filter(function(b) { return b.meal_code === 'B'; }).length;
        var lC = cuisBills.filter(function(b) { return b.meal_code === 'L'; }).length;
        var dC = cuisBills.filter(function(b) { return b.meal_code === 'D'; }).length;
        var tot = cuisBills.length;

        return `
          <tr style="border-bottom: 1px solid var(--separator);">
            <td style="padding: 8px 12px; font-weight: 500;">${c.name}</td>
            <td style="padding: 8px 12px; text-align: right;" class="tabular-nums font-mono">${bC}</td>
            <td style="padding: 8px 12px; text-align: right;" class="tabular-nums font-mono">${lC}</td>
            <td style="padding: 8px 12px; text-align: right;" class="tabular-nums font-mono">${dC}</td>
            <td style="padding: 8px 12px; text-align: right; font-weight: 600;" class="tabular-nums font-mono">${tot}</td>
          </tr>
        `;
      }).join('');

      return /* html */ `
        <div class="today-home-screen flex-col gap-lg" style="height: 100%;">
          <!-- Top Header & Live Timeline -->
          <div class="card flex-col gap-md" style="background: var(--surface);">
            <div class="flex-row justify-between align-center wrap gap-md">
              <div>
                <h1 style="margin: 0; font-size: 24px;">Today's Operations</h1>
                <div class="flex-row align-center gap-xs text-sm color-ink-2 pt-xs">
                  <i data-lucide="calendar" style="width: 15px; height: 15px;"></i>
                  <span>${todayFormatted}</span>
                  <span>·</span>
                  <span class="font-semibold color-ink">Current Service: ${currentMeal.toUpperCase()}</span>
                </div>
              </div>
              <div class="flex-row gap-sm">
                <a href="#/counter" class="btn btn--primary" style="font-weight: 600; padding: 10px 18px;">
                  <i data-lucide="scan"></i> Open Counter (Billing)
                </a>
                <a href="#/menu-editor" class="btn btn--secondary">
                  <i data-lucide="book-open"></i> Daily Menu Editor
                </a>
              </div>
            </div>

            <!-- Meal Timeline component container -->
            <div class="home-timeline-container pt-xs" style="border-top: 1px solid var(--separator);"></div>
          </div>

          <!-- KPI Metric Cards -->
          <div class="grid-4col gap-md">
            <div class="card card-inset flex-col gap-xs p-md" style="background: var(--surface);">
              <span class="text-xs color-ink-2 font-semibold uppercase">Total Meals Served Today</span>
              <span class="text-2xl font-bold font-mono tabular-nums color-ink">${totalServed}</span>
              <span class="text-xs color-ink-3">Live token issuance</span>
            </div>
            <div class="card card-inset flex-col gap-xs p-md" style="background: var(--surface); border-left: 3px solid var(--meal-b);">
              <div class="flex-row justify-between align-center">
                <span class="text-xs color-ink-2 font-semibold uppercase">Breakfast</span>
                <i data-lucide="sunrise" class="color-meal-b" style="width: 16px; height: 16px;"></i>
              </div>
              <span class="text-2xl font-bold font-mono tabular-nums">${bCount}</span>
              <span class="text-xs color-ink-3">06:00 – 10:00</span>
            </div>
            <div class="card card-inset flex-col gap-xs p-md" style="background: var(--surface); border-left: 3px solid var(--meal-l);">
              <div class="flex-row justify-between align-center">
                <span class="text-xs color-ink-2 font-semibold uppercase">Lunch</span>
                <i data-lucide="sun" class="color-meal-l" style="width: 16px; height: 16px;"></i>
              </div>
              <span class="text-2xl font-bold font-mono tabular-nums">${lCount}</span>
              <span class="text-xs color-ink-3">12:00 – 15:00</span>
            </div>
            <div class="card card-inset flex-col gap-xs p-md" style="background: var(--surface); border-left: 3px solid var(--meal-d);">
              <div class="flex-row justify-between align-center">
                <span class="text-xs color-ink-2 font-semibold uppercase">Dinner</span>
                <i data-lucide="moon-star" class="color-meal-d" style="width: 16px; height: 16px;"></i>
              </div>
              <span class="text-2xl font-bold font-mono tabular-nums">${dCount}</span>
              <span class="text-xs color-ink-3">19:00 – 22:30</span>
            </div>
          </div>

          <!-- Main Grid: Menu Readiness Matrix (2/3) + Served Today Breakdown (1/3) -->
          <div class="flex-row gap-md wrap" style="align-items: stretch;">
            <!-- Menu Readiness Matrix -->
            <div class="card flex-col gap-md" style="flex: 2; min-width: 380px;">
              <div class="flex-row justify-between align-center">
                <div>
                  <h3 style="margin: 0; font-size: 16px;">Today's Menu Readiness</h3>
                  <span class="text-xs color-ink-2">Click any cell to edit or complete that meal's menu</span>
                </div>
                <span class="badge badge--neutral text-xs">All Cuisines</span>
              </div>

              <div class="table-well" style="border: 1px solid var(--separator); border-radius: var(--radius-sm); overflow: hidden;">
                <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
                  <thead>
                    <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); text-align: left;">
                      <th style="padding: 10px 16px; font-weight: 600;">Cuisine</th>
                      <th style="padding: 10px 14px; text-align: center; font-weight: 600;"><i data-lucide="sunrise" style="width: 14px; height: 14px; vertical-align: middle;"></i> Breakfast</th>
                      <th style="padding: 10px 14px; text-align: center; font-weight: 600;"><i data-lucide="sun" style="width: 14px; height: 14px; vertical-align: middle;"></i> Lunch</th>
                      <th style="padding: 10px 14px; text-align: center; font-weight: 600;"><i data-lucide="moon-star" style="width: 14px; height: 14px; vertical-align: middle;"></i> Dinner</th>
                    </tr>
                  </thead>
                  <tbody>
                    ${readinessRowsHtml}
                  </tbody>
                </table>
              </div>
            </div>

            <!-- Served Today Breakdown -->
            <div class="card flex-col gap-md" style="flex: 1; min-width: 300px;">
              <div class="flex-row justify-between align-center">
                <div>
                  <h3 style="margin: 0; font-size: 16px;">Served Today</h3>
                  <span class="text-xs color-ink-2">By cuisine and meal</span>
                </div>
                <a href="#/reports/headcount" class="btn btn--quiet btn--xs">Report ↗</a>
              </div>

              <div class="table-well" style="border: 1px solid var(--separator); border-radius: var(--radius-sm); overflow: hidden;">
                <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
                  <thead>
                    <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); text-align: left;">
                      <th style="padding: 8px 12px;">Cuisine</th>
                      <th style="padding: 8px 12px; text-align: right;">B</th>
                      <th style="padding: 8px 12px; text-align: right;">L</th>
                      <th style="padding: 8px 12px; text-align: right;">D</th>
                      <th style="padding: 8px 12px; text-align: right;">Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    ${servedRowsHtml}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <!-- Quick Shortcuts Row -->
          <div class="grid-4col gap-md">
            <a href="#/customers" class="card flex-row align-center gap-sm p-md" style="text-decoration: none; color: inherit; transition: transform var(--motion-fast);">
              <div class="badge badge--neutral p-sm" style="border-radius: var(--radius-sm);"><i data-lucide="users"></i></div>
              <div class="flex-col">
                <span class="text-sm font-semibold">Members</span>
                <span class="text-xs color-ink-2">Manage cards & profiles</span>
              </div>
            </a>
            <a href="#/menu-history" class="card flex-row align-center gap-sm p-md" style="text-decoration: none; color: inherit; transition: transform var(--motion-fast);">
              <div class="badge badge--neutral p-sm" style="border-radius: var(--radius-sm);"><i data-lucide="history"></i></div>
              <div class="flex-col">
                <span class="text-sm font-semibold">Menu History</span>
                <span class="text-xs color-ink-2">Past 30 days archive</span>
              </div>
            </a>
            <a href="#/bill-register" class="card flex-row align-center gap-sm p-md" style="text-decoration: none; color: inherit; transition: transform var(--motion-fast);">
              <div class="badge badge--neutral p-sm" style="border-radius: var(--radius-sm);"><i data-lucide="receipt"></i></div>
              <div class="flex-col">
                <span class="text-sm font-semibold">Bill Register</span>
                <span class="text-xs color-ink-2">Reprint & audit tokens</span>
              </div>
            </a>
            <a href="#/reports/headcount" class="card flex-row align-center gap-sm p-md" style="text-decoration: none; color: inherit; transition: transform var(--motion-fast);">
              <div class="badge badge--neutral p-sm" style="border-radius: var(--radius-sm);"><i data-lucide="bar-chart-3"></i></div>
              <div class="flex-col">
                <span class="text-sm font-semibold">Headcount Report</span>
                <span class="text-xs color-ink-2">Meal analytics & drill-down</span>
              </div>
            </a>
          </div>
        </div>
      `;
    },

    component: function(params, targetEl) {
      return {
        init: function(el) {
          var rootEl = el || targetEl || document.getElementById('outlet');
          var timelineHost = rootEl.querySelector('.home-timeline-container');

          if (timelineHost && Mess.createMealTimeline) {
            timelineInstance = Mess.createMealTimeline(timelineHost, {
              showLabels: true,
              showHeader: true
            });
          }
        },
        destroy: function() {
          if (timelineInstance) {
            timelineInstance.destroy();
            timelineInstance = null;
          }
        }
      };
    }
  });
})(window.Mess);
