/* report-headcount.js - Screen 17: Cuisine x Meal Headcount Report (Tasks T-082 & T-083) */

window.Mess = window.Mess || {};

(function(Mess) {
  var reportFrameInstance = null;

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

  function getDaysAgoIso(days) {
    var d = Mess.clock ? Mess.clock.now() : new Date();
    d.setDate(d.getDate() - days);
    var yyyy = d.getFullYear();
    var mm = String(d.getMonth() + 1).padStart(2, '0');
    var dd = String(d.getDate()).padStart(2, '0');
    return yyyy + '-' + mm + '-' + dd;
  }

  function openTokenDetailDrawer(bill, drawer, parentBreadcrumb) {
    var menus = (Mess.store && Mess.store.list('menus')) || [];
    var items = (Mess.store && Mess.store.list('items')) || [];
    var itemMap = {};
    items.forEach(function(it) { itemMap[it.id] = it; });

    var cId = bill.cuisine_id || bill.cuisineId;
    var meal = bill.meal_code || bill.meal || bill.meal_type || 'L';
    var billItems = bill.items;
    if (!billItems || billItems.length === 0) {
      var menuKey = bill.date + '_' + cId + '_' + meal;
      var menuObj = menus.find(function(m) { return m.id === menuKey; });
      billItems = menuObj ? (menuObj.items || []) : [];
    }

    var itemsHtml = billItems.map(function(it, idx) {
      var itId = it.itemId || it.item_id || it.id;
      var itObj = itemMap[itId];
      var name = it.name || it.item_name || (itObj ? itObj.name : itId);
      var qty = it.qty || it.quantity || (itObj ? itObj.defaultQty : 1);
      var unit = itObj ? itObj.unit : 'Plate';
      return `
        <tr style="border-bottom: 1px solid var(--separator);">
          <td style="padding: 6px 10px;">${idx + 1}</td>
          <td style="padding: 6px 10px; font-weight: 500;">${name}</td>
          <td style="padding: 6px 10px; text-align: right;" class="font-mono">${qty} ${unit}</td>
          <td style="padding: 6px 10px; text-align: right;" class="font-mono">0.00</td>
        </tr>
      `;
    }).join('');

    var tokenNo = bill.token_number || bill.token_no || bill.tokenNo || 'Token';
    var mealLabel = meal === 'B' ? 'Breakfast' : meal === 'L' ? 'Lunch' : 'Dinner';

    drawer.push({
      title: `Token ${tokenNo}`,
      breadcrumbTitle: tokenNo,
      countText: `${bill.date} ${bill.time || ''}`,
      render: function(container) {
        container.innerHTML = `
          <div class="flex-col gap-md">
            <div class="flex-row justify-between align-center p-sm card-inset" style="background: var(--canvas); border-radius: var(--radius-sm); border: 1px solid var(--separator);">
              <div class="flex-col">
                <span class="text-xs color-ink-3">Token Number:</span>
                <span class="font-mono text-2xl font-bold color-primary">${tokenNo}</span>
              </div>
              <div class="flex-col align-end">
                <span class="text-xs color-ink-3">${bill.date} ${bill.time || ''}</span>
                <span class="badge badge--${meal.toLowerCase()}">${mealLabel}</span>
              </div>
            </div>

            <div class="grid-2col gap-md text-xs card-inset p-sm" style="background: var(--surface); border-radius: var(--radius-sm); border: 1px solid var(--separator);">
              <div>
                <span class="color-ink-3">Member:</span>
                <div class="font-semibold text-sm">${bill.customer_name || bill.memberName || 'Member'} (${bill.customer_code || bill.memberCode || ''})</div>
              </div>
              <div>
                <span class="color-ink-3">Cuisine:</span>
                <div class="font-semibold text-sm">${bill.cuisine_name || bill.cuisineName || cId}</div>
              </div>
              <div>
                <span class="color-ink-3">Voucher:</span>
                <div class="font-mono">${bill.voucherNo || bill.voucher_no || bill.id || '—'}</div>
              </div>
              <div>
                <span class="color-ink-3">Status:</span>
                <div>${bill.cancelled ? '<span class="badge badge--danger">Cancelled</span>' : '<span class="badge badge--success">Active</span>'}</div>
              </div>
            </div>

            ${bill.override ? `
              <div class="banner banner--warning flex-row align-center gap-xs p-xs text-xs" style="border-radius: var(--radius-sm);">
                <i data-lucide="shield-alert"></i>
                <span>Supervisor Override by <strong>${bill.supervisor || bill.overrideBy || 'admin'}</strong>: ${bill.override_reason || bill.overrideReason || 'Approved'}</span>
              </div>
            ` : ''}

            <div class="flex-col gap-xs">
              <span class="text-xs font-semibold color-ink-2">Included Items (${billItems.length})</span>
              <div class="table-well" style="border: 1px solid var(--separator); border-radius: var(--radius-sm); max-height: 240px; overflow-y: auto;">
                <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
                  <thead>
                    <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); text-align: left;">
                      <th style="padding: 6px 10px;">#</th>
                      <th style="padding: 6px 10px;">Item</th>
                      <th style="padding: 6px 10px; text-align: right;">Qty</th>
                      <th style="padding: 6px 10px; text-align: right;">Rate</th>
                    </tr>
                  </thead>
                  <tbody>${itemsHtml || '<tr><td colspan="4" class="p-sm text-center color-ink-3">No items specified</td></tr>'}</tbody>
                </table>
              </div>
            </div>

            <div class="flex-row justify-between align-center pt-xs">
              <button type="button" class="btn btn--primary btn-drawer-reprint">
                <i data-lucide="printer"></i> Reprint Slip (DUPLICATE)
              </button>
            </div>
          </div>
        `;

        var reprintBtn = container.querySelector('.btn-drawer-reprint');
        if (reprintBtn) {
          reprintBtn.addEventListener('click', function() {
            if (Mess.showTokenPreviewDialog) {
              Mess.showTokenPreviewDialog(bill, { isDuplicate: true });
            }
          });
        }
      }
    });
  }

  function openTokenListDrawer(cellBills, cellLabel, drawer) {
    drawer.push({
      title: cellLabel,
      breadcrumbTitle: cellLabel.split('(')[0].trim(),
      countText: `${cellBills.length} Token${cellBills.length === 1 ? '' : 's'}`,
      render: function(container, drawerRef) {
        var rowsHtml = cellBills.map(function(b, idx) {
          var tokenNo = b.token_number || b.token_no || b.tokenNo || 'Token';
          var mCode = (b.meal_code || b.meal || b.meal_type || 'L').toUpperCase();
          var timeStr = b.time ? b.time.slice(0, 5) : '—';
          return `
            <tr class="token-row" data-id="${b.id}" style="cursor: pointer; border-bottom: 1px solid var(--separator);">
              <td style="padding: 8px 10px;" class="font-mono font-bold color-primary">${tokenNo}</td>
              <td style="padding: 8px 10px;" class="font-mono text-xs">${b.date} ${timeStr}</td>
              <td style="padding: 8px 10px;">
                <div class="font-medium text-xs">${b.customer_name || b.memberName || ''}</div>
                <div class="font-mono text-xxs color-ink-3">${b.customer_code || b.memberCode || ''}</div>
              </td>
              <td style="padding: 8px 10px;">
                <span class="badge badge--${mCode.toLowerCase()}" style="font-size: 10px;">${mCode}</span>
              </td>
              <td style="padding: 8px 10px; text-align: right;">
                <button type="button" class="btn btn--quiet btn--icon btn--xs" title="View details">
                  <i data-lucide="chevron-right"></i>
                </button>
              </td>
            </tr>
          `;
        }).join('');

        container.innerHTML = `
          <div class="flex-col gap-sm">
            <span class="text-xs color-ink-2">Click any token to inspect voucher details and reprint slips.</span>
            <div class="table-well" style="border: 1px solid var(--separator); border-radius: var(--radius-sm); max-height: 480px; overflow-y: auto;">
              <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
                <thead>
                  <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); text-align: left;">
                    <th style="padding: 8px 10px;">Token</th>
                    <th style="padding: 8px 10px;">Date & Time</th>
                    <th style="padding: 8px 10px;">Member</th>
                    <th style="padding: 8px 10px;">Meal</th>
                    <th style="padding: 8px 10px; text-align: right;">Action</th>
                  </tr>
                </thead>
                <tbody>
                  ${rowsHtml || '<tr><td colspan="5" class="p-md text-center color-ink-3">No tokens found</td></tr>'}
                </tbody>
              </table>
            </div>
          </div>
        `;

        var trs = container.querySelectorAll('.token-row');
        trs.forEach(function(tr) {
          tr.addEventListener('click', function() {
            var bId = tr.getAttribute('data-id');
            var found = cellBills.find(function(it) { return it.id === bId; });
            if (found) {
              openTokenDetailDrawer(found, drawerRef, cellLabel);
            }
          });
        });
      }
    });
  }

  Mess.screens.register({
    id: 'report-headcount',
    route: '/reports/headcount',
    title: 'Cuisine × Meal Headcount Report',
    nav: { group: 'Reports', icon: 'users', order: 20 },
    roles: ['admin', 'supervisor', 'counter'],

    template: function() {
      var extraFiltersHtml = `
        <div class="flex-row gap-xs align-center">
          <label class="check-container text-xs font-semibold color-ink-2" style="display:flex; align-items:center; gap:6px; cursor:pointer;">
            <input type="checkbox" class="filter-group-date">
            <span>Group by Date</span>
          </label>
        </div>
      `;

      reportFrameInstance = Mess.createReportFrame({
        title: 'Cuisine × Meal Headcount Report',
        subtitle: 'Matrix breakdown of meal attendance by cuisine and meal type with heat-scale shading',
        extraFiltersHtml: extraFiltersHtml,

        readExtraFilters: function(rootEl) {
          var chk = rootEl.querySelector('.filter-group-date');
          return {
            groupByDate: chk ? chk.checked : false
          };
        },

        onGenerate: function(filters, viewId, drawer) {
          var validBills = Mess.reportHelpers.getValidBills(filters);
          return {
            bills: validBills,
            filters: filters
          };
        },

        renderResults: function(container, resultData, filters, viewId, drawer) {
          var bills = resultData.bills || [];
          var groupByDate = filters.groupByDate;
          var cuisines = (Mess.store && Mess.store.list('cuisines')) || [];
          var activeCuisines = cuisines.filter(function(c) {
            if (filters.cuisineId && filters.cuisineId !== 'all') {
              return c.id === filters.cuisineId;
            }
            return c.active;
          });

          // Precompute distinct dates if groupByDate is true
          var datesMap = {};
          bills.forEach(function(b) {
            datesMap[b.date] = true;
          });
          var datesList = Object.keys(datesMap).sort();
          if (datesList.length === 0 && filters.fromDate) {
            datesList = [filters.fromDate];
          }

          function getSoftColor(mealCode, ratio) {
            // Meal hues: B = Amber/Gold (#f59e0b / #d97706), L = Emerald/Green (#10b981 / #059669), D = Indigo/Purple (#6366f1 / #4f46e5)
            // Alpha scaling from 0.08 to 0.40 based on ratio
            var alpha = (0.08 + ratio * 0.32).toFixed(2);
            if (mealCode === 'B') return `rgba(245, 158, 11, ${alpha})`;
            if (mealCode === 'L') return `rgba(16, 185, 129, ${alpha})`;
            if (mealCode === 'D') return `rgba(99, 102, 241, ${alpha})`;
            return `rgba(100, 116, 139, ${alpha})`;
          }

          if (!groupByDate) {
            // Standard Cuisine x Meal Matrix
            // Calculate matrix: counts[cuisineId][meal] = bills
            var matrix = {};
            var maxB = 1, maxL = 1, maxD = 1;

            activeCuisines.forEach(function(c) {
              matrix[c.id] = { B: [], L: [], D: [] };
            });

            bills.forEach(function(b) {
              var cId = b.cuisine_id || b.cuisineId;
              var meal = (b.meal_code || b.meal || b.meal_type || 'L').toUpperCase();
              if (matrix[cId] && matrix[cId][meal]) {
                matrix[cId][meal].push(b);
              }
            });

            // Calculate max counts for heat tints
            activeCuisines.forEach(function(c) {
              if (matrix[c.id].B.length > maxB) maxB = matrix[c.id].B.length;
              if (matrix[c.id].L.length > maxL) maxL = matrix[c.id].L.length;
              if (matrix[c.id].D.length > maxD) maxD = matrix[c.id].D.length;
            });

            var grandTotalB = 0, grandTotalL = 0, grandTotalD = 0;

            var rowsHtml = activeCuisines.map(function(c) {
              var listB = matrix[c.id].B;
              var listL = matrix[c.id].L;
              var listD = matrix[c.id].D;

              var countB = listB.length;
              var countL = listL.length;
              var countD = listD.length;
              var rowTotal = countB + countL + countD;

              grandTotalB += countB;
              grandTotalL += countL;
              grandTotalD += countD;

              var bgB = countB > 0 ? getSoftColor('B', countB / maxB) : 'transparent';
              var bgL = countL > 0 ? getSoftColor('L', countL / maxL) : 'transparent';
              var bgD = countD > 0 ? getSoftColor('D', countD / maxD) : 'transparent';

              return `
                <tr style="border-bottom: 1px solid var(--separator);">
                  <td style="padding: 10px 14px; font-weight: 600;">
                    <div class="flex-row align-center gap-xs">
                      <span class="badge badge--neutral font-mono text-xs">${c.code}</span>
                      <span>${c.name}</span>
                    </div>
                  </td>
                  <td class="cell-headcount font-mono" data-cuisine="${c.id}" data-cuisine-name="${c.name}" data-meal="B" style="padding: 10px 14px; text-align: right; background: ${bgB}; cursor: pointer;">
                    ${countB > 0 ? `<strong>${countB}</strong>` : '<span class="color-ink-3">0</span>'}
                  </td>
                  <td class="cell-headcount font-mono" data-cuisine="${c.id}" data-cuisine-name="${c.name}" data-meal="L" style="padding: 10px 14px; text-align: right; background: ${bgL}; cursor: pointer;">
                    ${countL > 0 ? `<strong>${countL}</strong>` : '<span class="color-ink-3">0</span>'}
                  </td>
                  <td class="cell-headcount font-mono" data-cuisine="${c.id}" data-cuisine-name="${c.name}" data-meal="D" style="padding: 10px 14px; text-align: right; background: ${bgD}; cursor: pointer;">
                    ${countD > 0 ? `<strong>${countD}</strong>` : '<span class="color-ink-3">0</span>'}
                  </td>
                  <td class="cell-headcount-row-total font-mono font-bold" data-cuisine="${c.id}" data-cuisine-name="${c.name}" style="padding: 10px 14px; text-align: right; background: var(--surface-strong); cursor: pointer;">
                    ${rowTotal}
                  </td>
                </tr>
              `;
            }).join('');

            var grandTotalAll = grandTotalB + grandTotalL + grandTotalD;

            container.innerHTML = `
              <div class="flex-col gap-sm" style="height: 100%; padding: 16px; overflow-y: auto;">
                <div class="flex-row justify-between align-center">
                  <div class="text-xs color-ink-2">
                    Date Range: <strong>${filters.fromDate}</strong> to <strong>${filters.toDate}</strong> · Click any cell to inspect tokens
                  </div>
                  <div class="flex-row gap-xs text-xs">
                    <span class="badge badge--b">Breakfast</span>
                    <span class="badge badge--l">Lunch</span>
                    <span class="badge badge--d">Dinner</span>
                  </div>
                </div>

                <div class="table-well" style="border: 1px solid var(--separator); border-radius: var(--radius-panel); overflow: hidden; background: var(--surface);">
                  <table class="headcount-table" style="width: 100%; border-collapse: collapse; font-size: 13px;">
                    <thead>
                      <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator);">
                        <th style="padding: 12px 14px; text-align: left;">Cuisine</th>
                        <th style="padding: 12px 14px; text-align: right; width: 140px; color: var(--meal-b);">Breakfast (B)</th>
                        <th style="padding: 12px 14px; text-align: right; width: 140px; color: var(--meal-l);">Lunch (L)</th>
                        <th style="padding: 12px 14px; text-align: right; width: 140px; color: var(--meal-d);">Dinner (D)</th>
                        <th style="padding: 12px 14px; text-align: right; width: 150px;">Total Headcount</th>
                      </tr>
                    </thead>
                    <tbody>
                      ${rowsHtml}
                    </tbody>
                    <tfoot>
                      <tr style="background: var(--canvas); border-top: 2px solid var(--separator); font-size: 14px; font-weight: bold;">
                        <td style="padding: 12px 14px;">Grand Total</td>
                        <td class="cell-headcount-col-total font-mono" data-meal="B" style="padding: 12px 14px; text-align: right; color: var(--meal-b); cursor: pointer;">
                          ${grandTotalB}
                        </td>
                        <td class="cell-headcount-col-total font-mono" data-meal="L" style="padding: 12px 14px; text-align: right; color: var(--meal-l); cursor: pointer;">
                          ${grandTotalL}
                        </td>
                        <td class="cell-headcount-col-total font-mono" data-meal="D" style="padding: 12px 14px; text-align: right; color: var(--meal-d); cursor: pointer;">
                          ${grandTotalD}
                        </td>
                        <td class="cell-headcount-grand-total font-mono color-primary" style="padding: 12px 14px; text-align: right; cursor: pointer;">
                          ${grandTotalAll}
                        </td>
                      </tr>
                    </tfoot>
                  </table>
                </div>
              </div>
            `;

            // Bind click handlers for drill-down
            container.querySelectorAll('.cell-headcount').forEach(function(td) {
              td.addEventListener('click', function() {
                var cId = td.getAttribute('data-cuisine');
                var cName = td.getAttribute('data-cuisine-name');
                var meal = td.getAttribute('data-meal');
                var cellTokens = (matrix[cId] && matrix[cId][meal]) || [];
                var mealName = meal === 'B' ? 'Breakfast' : meal === 'L' ? 'Lunch' : 'Dinner';
                openTokenListDrawer(cellTokens, `${cName} – ${mealName}`, drawer);
              });
            });

            container.querySelectorAll('.cell-headcount-row-total').forEach(function(td) {
              td.addEventListener('click', function() {
                var cId = td.getAttribute('data-cuisine');
                var cName = td.getAttribute('data-cuisine-name');
                var rowTokens = [].concat(matrix[cId].B, matrix[cId].L, matrix[cId].D);
                openTokenListDrawer(rowTokens, `${cName} – All Meals`, drawer);
              });
            });

            container.querySelectorAll('.cell-headcount-col-total').forEach(function(td) {
              td.addEventListener('click', function() {
                var meal = td.getAttribute('data-meal');
                var colTokens = bills.filter(function(b) {
                  return (b.meal_code || b.meal || b.meal_type || '').toUpperCase() === meal;
                });
                var mealName = meal === 'B' ? 'Breakfast' : meal === 'L' ? 'Lunch' : 'Dinner';
                openTokenListDrawer(colTokens, `All Cuisines – ${mealName}`, drawer);
              });
            });

            container.querySelectorAll('.cell-headcount-grand-total').forEach(function(td) {
              td.addEventListener('click', function() {
                openTokenListDrawer(bills, 'All Cuisines & Meals', drawer);
              });
            });

          } else {
            // Group by Date Matrix Breakdown
            var dateSectionsHtml = datesList.map(function(dateStr) {
              var dayBills = bills.filter(function(b) { return b.date === dateStr; });
              var dayMatrix = {};
              var dayMaxB = 1, dayMaxL = 1, dayMaxD = 1;

              activeCuisines.forEach(function(c) {
                dayMatrix[c.id] = { B: [], L: [], D: [] };
              });

              dayBills.forEach(function(b) {
                var cId = b.cuisine_id || b.cuisineId;
                var meal = (b.meal_code || b.meal || b.meal_type || 'L').toUpperCase();
                if (dayMatrix[cId] && dayMatrix[cId][meal]) {
                  dayMatrix[cId][meal].push(b);
                }
              });

              activeCuisines.forEach(function(c) {
                if (dayMatrix[c.id].B.length > dayMaxB) dayMaxB = dayMatrix[c.id].B.length;
                if (dayMatrix[c.id].L.length > dayMaxL) dayMaxL = dayMatrix[c.id].L.length;
                if (dayMatrix[c.id].D.length > dayMaxD) dayMaxD = dayMatrix[c.id].D.length;
              });

              var dayTotalB = 0, dayTotalL = 0, dayTotalD = 0;

              var cRows = activeCuisines.map(function(c) {
                var listB = dayMatrix[c.id].B;
                var listL = dayMatrix[c.id].L;
                var listD = dayMatrix[c.id].D;

                var countB = listB.length;
                var countL = listL.length;
                var countD = listD.length;
                var rTotal = countB + countL + countD;

                dayTotalB += countB;
                dayTotalL += countL;
                dayTotalD += countD;

                var bgB = countB > 0 ? getSoftColor('B', countB / dayMaxB) : 'transparent';
                var bgL = countL > 0 ? getSoftColor('L', countL / dayMaxL) : 'transparent';
                var bgD = countD > 0 ? getSoftColor('D', countD / dayMaxD) : 'transparent';

                return `
                  <tr style="border-bottom: 1px solid var(--separator);">
                    <td style="padding: 8px 12px; font-weight: 500;">
                      <div class="flex-row align-center gap-xs">
                        <span class="badge badge--neutral font-mono text-xxs">${c.code}</span>
                        <span>${c.name}</span>
                      </div>
                    </td>
                    <td class="cell-headcount-day font-mono" data-date="${dateStr}" data-cuisine="${c.id}" data-cuisine-name="${c.name}" data-meal="B" style="padding: 8px 12px; text-align: right; background: ${bgB}; cursor: pointer;">
                      ${countB > 0 ? `<strong>${countB}</strong>` : '<span class="color-ink-3">0</span>'}
                    </td>
                    <td class="cell-headcount-day font-mono" data-date="${dateStr}" data-cuisine="${c.id}" data-cuisine-name="${c.name}" data-meal="L" style="padding: 8px 12px; text-align: right; background: ${bgL}; cursor: pointer;">
                      ${countL > 0 ? `<strong>${countL}</strong>` : '<span class="color-ink-3">0</span>'}
                    </td>
                    <td class="cell-headcount-day font-mono" data-date="${dateStr}" data-cuisine="${c.id}" data-cuisine-name="${c.name}" data-meal="D" style="padding: 8px 12px; text-align: right; background: ${bgD}; cursor: pointer;">
                      ${countD > 0 ? `<strong>${countD}</strong>` : '<span class="color-ink-3">0</span>'}
                    </td>
                    <td class="font-mono font-bold" style="padding: 8px 12px; text-align: right; background: var(--surface-strong);">
                      ${rTotal}
                    </td>
                  </tr>
                `;
              }).join('');

              var dayGrand = dayTotalB + dayTotalL + dayTotalD;

              return `
                <div class="date-group-card mb-md" style="border: 1px solid var(--separator); border-radius: var(--radius-panel); overflow: hidden; background: var(--surface);">
                  <div class="date-header flex-row justify-between align-center p-sm" style="background: var(--canvas); border-bottom: 1px solid var(--separator);">
                    <div class="flex-row align-center gap-sm">
                      <i data-lucide="calendar" style="width: 16px; height: 16px; color: var(--primary);"></i>
                      <strong class="font-mono">${Mess.format && Mess.format.date ? Mess.format.date(dateStr) : dateStr}</strong>
                      <span class="text-xs color-ink-3">(${dayBills.length} tokens)</span>
                    </div>
                    <div class="font-mono text-xs font-semibold">
                      Subtotal: ${dayGrand}
                    </div>
                  </div>
                  <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
                    <thead>
                      <tr style="background: var(--surface-strong); border-bottom: 1px solid var(--separator);">
                        <th style="padding: 6px 12px; text-align: left;">Cuisine</th>
                        <th style="padding: 6px 12px; text-align: right; width: 120px; color: var(--meal-b);">Breakfast (B)</th>
                        <th style="padding: 6px 12px; text-align: right; width: 120px; color: var(--meal-l);">Lunch (L)</th>
                        <th style="padding: 6px 12px; text-align: right; width: 120px; color: var(--meal-d);">Dinner (D)</th>
                        <th style="padding: 6px 12px; text-align: right; width: 130px;">Date Total</th>
                      </tr>
                    </thead>
                    <tbody>
                      ${cRows}
                    </tbody>
                    <tfoot>
                      <tr style="background: var(--canvas); font-weight: bold; border-top: 1px solid var(--separator);">
                        <td style="padding: 8px 12px;">Date Subtotal</td>
                        <td style="padding: 8px 12px; text-align: right; color: var(--meal-b);">${dayTotalB}</td>
                        <td style="padding: 8px 12px; text-align: right; color: var(--meal-l);">${dayTotalL}</td>
                        <td style="padding: 8px 12px; text-align: right; color: var(--meal-d);">${dayTotalD}</td>
                        <td style="padding: 8px 12px; text-align: right; color: var(--primary);">${dayGrand}</td>
                      </tr>
                    </tfoot>
                  </table>
                </div>
              `;
            }).join('');

            container.innerHTML = `
              <div class="flex-col gap-sm" style="height: 100%; padding: 16px; overflow-y: auto;">
                <div class="flex-row justify-between align-center mb-xs">
                  <span class="text-xs color-ink-2">Grouped by Date (${datesList.length} dates) · Click cells to view tokens</span>
                  <span class="text-xs font-bold font-mono">Overall Headcount: ${bills.length}</span>
                </div>
                ${dateSectionsHtml}
              </div>
            `;

            container.querySelectorAll('.cell-headcount-day').forEach(function(td) {
              td.addEventListener('click', function() {
                var dStr = td.getAttribute('data-date');
                var cId = td.getAttribute('data-cuisine');
                var cName = td.getAttribute('data-cuisine-name');
                var meal = td.getAttribute('data-meal');
                var matching = bills.filter(function(b) {
                  var bC = b.cuisine_id || b.cuisineId;
                  var bM = (b.meal_code || b.meal || b.meal_type || '').toUpperCase();
                  return b.date === dStr && bC === cId && bM === meal;
                });
                var mealName = meal === 'B' ? 'Breakfast' : meal === 'L' ? 'Lunch' : 'Dinner';
                openTokenListDrawer(matching, `${dStr}: ${cName} – ${mealName}`, drawer);
              });
            });
          }
        },

        onExport: function(type, filename) {
          var filters = reportFrameInstance ? reportFrameInstance.filters : {};
          var validBills = Mess.reportHelpers.getValidBills(filters);
          var cuisines = (Mess.store && Mess.store.list('cuisines')) || [];

          // Build rows for export
          var exportRows = [];
          cuisines.forEach(function(c) {
            var cBills = validBills.filter(function(b) { return (b.cuisine_id || b.cuisineId) === c.id; });
            var bCount = cBills.filter(function(b) { return (b.meal_code || b.meal || b.meal_type || '').toUpperCase() === 'B'; }).length;
            var lCount = cBills.filter(function(b) { return (b.meal_code || b.meal || b.meal_type || '').toUpperCase() === 'L'; }).length;
            var dCount = cBills.filter(function(b) { return (b.meal_code || b.meal || b.meal_type || '').toUpperCase() === 'D'; }).length;
            exportRows.push({
              Cuisine: c.name,
              Breakfast: bCount,
              Lunch: lCount,
              Dinner: dCount,
              Total: bCount + lCount + dCount
            });
          });

          if (type === 'csv') {
            // Strictly enforce '|' delimiter as per user rules!
            var headers = ['Cuisine', 'Breakfast', 'Lunch', 'Dinner', 'Total'];
            var csv = headers.join('|') + '\n';
            exportRows.forEach(function(r) {
              csv += `${r.Cuisine}|${r.Breakfast}|${r.Lunch}|${r.Dinner}|${r.Total}\n`;
            });
            var blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            var url = URL.createObjectURL(blob);
            var a = document.createElement('a');
            a.href = url;
            a.download = filename;
            a.click();
            URL.revokeObjectURL(url);
          } else if (type === 'xlsx' && window.XLSX) {
            var ws = XLSX.utils.json_to_sheet(exportRows);
            var wb = XLSX.utils.book_new();
            XLSX.utils.book_append_sheet(wb, ws, 'Headcount');
            XLSX.writeFile(wb, filename);
          } else if (type === 'pdf' && window.jspdf) {
            var doc = new window.jspdf.jsPDF();
            doc.text('Cuisine x Meal Headcount Report', 14, 15);
            var body = exportRows.map(function(r) {
              return [r.Cuisine, r.Breakfast, r.Lunch, r.Dinner, r.Total];
            });
            if (doc.autoTable) {
              doc.autoTable({
                head: [['Cuisine', 'Breakfast', 'Lunch', 'Dinner', 'Total']],
                body: body,
                startY: 20
              });
            }
            doc.save(filename);
          }
        }
      });

      return reportFrameInstance.template();
    },

    component: function(params, targetEl) {
      return {
        init: function(el) {
          var rootEl = el || targetEl || document.getElementById('outlet');
          if (reportFrameInstance) {
            reportFrameInstance.init(rootEl);
          }
        },
        destroy: function() {
          if (reportFrameInstance) {
            reportFrameInstance.destroy();
            reportFrameInstance = null;
          }
        }
      };
    }
  });
})(window.Mess);
