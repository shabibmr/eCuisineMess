/* report-attendance.js - Screen 19: Customer-wise Attendance Report (Tasks T-085 & T-086) */

window.Mess = window.Mess || {};

(function(Mess) {
  var reportFrameInstance = null;

  function getDaysBetween(fromIso, toIso) {
    var d1 = new Date(fromIso);
    var d2 = new Date(toIso);
    var diffTime = d2.getTime() - d1.getTime();
    return Math.max(1, Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1);
  }

  function getDatesArray(fromIso, toIso) {
    var dates = [];
    var curr = new Date(fromIso);
    var end = new Date(toIso);
    while (curr <= end) {
      var yyyy = curr.getFullYear();
      var mm = String(curr.getMonth() + 1).padStart(2, '0');
      var dd = String(curr.getDate()).padStart(2, '0');
      dates.push(yyyy + '-' + mm + '-' + dd);
      curr.setDate(curr.getDate() + 1);
    }
    return dates;
  }

  function isWeekend(dateStr) {
    var day = new Date(dateStr).getDay();
    return day === 0 || day === 6; // Sunday or Saturday
  }

  function openCustomerTokenDrawer(member, bills, drawer) {
    var memberBills = bills.filter(function(b) {
      return (b.customer_id || b.memberId) === member.id || (b.customer_code || b.memberCode) === member.code;
    });

    // Sort descending by date & time
    memberBills.sort(function(a, b) {
      if (a.date !== b.date) return b.date.localeCompare(a.date);
      return (b.time || '').localeCompare(a.time || '');
    });

    var cuisineObj = Mess.store && Mess.store.get('cuisines', member.cuisineId);
    var cuisineName = cuisineObj ? cuisineObj.name : (member.cuisineName || 'Standard');

    drawer.push({
      title: `${member.name} (${member.code})`,
      breadcrumbTitle: member.code,
      countText: `${memberBills.length} Meal Token${memberBills.length === 1 ? '' : 's'}`,
      render: function(container, drawerRef) {
        var rowsHtml = memberBills.map(function(b) {
          var tokenNo = b.token_number || b.token_no || b.tokenNo || 'Token';
          var mCode = (b.meal_code || b.meal || b.meal_type || 'L').toUpperCase();
          var timeStr = b.time ? b.time.slice(0, 5) : '—';
          return `
            <tr class="member-token-row" data-id="${b.id}" style="cursor: pointer; border-bottom: 1px solid var(--separator);">
              <td style="padding: 8px 10px;" class="font-mono font-bold color-primary">${tokenNo}</td>
              <td style="padding: 8px 10px;" class="font-mono text-xs">${b.date}</td>
              <td style="padding: 8px 10px;" class="font-mono text-xs">${timeStr}</td>
              <td style="padding: 8px 10px;">
                <span class="badge badge--${mCode.toLowerCase()}">${mCode === 'B' ? 'Breakfast' : mCode === 'L' ? 'Lunch' : 'Dinner'}</span>
              </td>
              <td style="padding: 8px 10px; text-align: right;">
                <button type="button" class="btn btn--quiet btn--icon btn--xs" title="View voucher">
                  <i data-lucide="chevron-right"></i>
                </button>
              </td>
            </tr>
          `;
        }).join('');

        container.innerHTML = `
          <div class="flex-col gap-md">
            <!-- Member Header -->
            <div class="card-inset p-sm flex-row justify-between align-center" style="background: var(--canvas); border-radius: var(--radius-sm); border: 1px solid var(--separator);">
              <div class="flex-col">
                <span class="font-bold text-base">${member.name}</span>
                <span class="text-xs color-ink-3">Code: ${member.code} · ${cuisineName}</span>
              </div>
              <div class="flex-col align-end">
                <span class="text-xs color-ink-3">Total Tokens in Range</span>
                <span class="font-mono text-xl font-bold color-primary">${memberBills.length}</span>
              </div>
            </div>

            <!-- Token History Table -->
            <div class="flex-col gap-xs">
              <span class="text-xs font-semibold color-ink-2">Attended Meals & Issued Tokens</span>
              <div class="table-well" style="border: 1px solid var(--separator); border-radius: var(--radius-sm); max-height: 440px; overflow-y: auto;">
                <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
                  <thead>
                    <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); text-align: left;">
                      <th style="padding: 8px 10px;">Token</th>
                      <th style="padding: 8px 10px;">Date</th>
                      <th style="padding: 8px 10px;">Time</th>
                      <th style="padding: 8px 10px;">Meal</th>
                      <th style="padding: 8px 10px; text-align: right;">Action</th>
                    </tr>
                  </thead>
                  <tbody>${rowsHtml || '<tr><td colspan="5" class="p-md text-center color-ink-3">No meals taken in selected period</td></tr>'}</tbody>
                </table>
              </div>
            </div>
          </div>
        `;

        // Bind click on row to Level 2 (Bill details with reprint)
        container.querySelectorAll('.member-token-row').forEach(function(tr) {
          tr.addEventListener('click', function() {
            var bId = tr.getAttribute('data-id');
            var found = memberBills.find(function(it) { return it.id === bId; });
            if (found) {
              var tokenNo = found.token_number || found.token_no || found.tokenNo || 'Token';
              drawerRef.push({
                title: `Voucher ${tokenNo}`,
                breadcrumbTitle: tokenNo,
                countText: `${found.date} ${found.time || ''}`,
                render: function(level2Container) {
                  level2Container.innerHTML = `
                    <div class="flex-col gap-md">
                      <div class="card-inset p-sm flex-row justify-between align-center" style="background: var(--canvas); border-radius: var(--radius-sm); border: 1px solid var(--separator);">
                        <div>
                          <span class="text-xs color-ink-3">Token:</span>
                          <div class="font-mono text-xl font-bold color-primary">${tokenNo}</div>
                        </div>
                        <div class="text-right">
                          <span class="text-xs color-ink-3">${found.date} ${found.time || ''}</span>
                          <div><span class="badge badge--${(found.meal_code || found.meal || 'l').toLowerCase()}">${found.meal_code || found.meal}</span></div>
                        </div>
                      </div>

                      <div class="grid-2col gap-md text-xs card-inset p-sm" style="background: var(--surface); border: 1px solid var(--separator); border-radius: var(--radius-sm);">
                        <div>
                          <span class="color-ink-3">Member:</span>
                          <div class="font-semibold">${member.name} (${member.code})</div>
                        </div>
                        <div>
                          <span class="color-ink-3">Cuisine:</span>
                          <div class="font-semibold">${found.cuisine_name || cuisineName}</div>
                        </div>
                        <div>
                          <span class="color-ink-3">Voucher:</span>
                          <div class="font-mono">${found.voucherNo || found.voucher_no || found.id}</div>
                        </div>
                        <div>
                          <span class="color-ink-3">Status:</span>
                          <div>${found.cancelled ? '<span class="badge badge--danger">Cancelled</span>' : '<span class="badge badge--success">Active</span>'}</div>
                        </div>
                      </div>

                      <div class="pt-sm flex-row justify-between align-center">
                        <button type="button" class="btn btn--primary btn-attendance-reprint">
                          <i data-lucide="printer"></i> Reprint Token Slip (DUPLICATE)
                        </button>
                      </div>
                    </div>
                  `;

                  var btn = level2Container.querySelector('.btn-attendance-reprint');
                  if (btn) {
                    btn.addEventListener('click', function() {
                      if (Mess.showTokenPreviewDialog) {
                        Mess.showTokenPreviewDialog(found, { isDuplicate: true });
                      }
                    });
                  }
                }
              });
            }
          });
        });
      }
    });
  }

  Mess.screens.register({
    id: 'report-attendance',
    route: '/reports/attendance',
    title: 'Customer-wise Attendance Report',
    nav: { group: 'Reports', icon: 'calendar-check', order: 40 },
    roles: ['admin', 'supervisor'],

    template: function() {
      var allCustomers = (Mess.store && Mess.store.list('customers')) || [];
      var customerOptions = allCustomers.map(function(m) {
        return `<option value="${m.id}">${m.code} – ${m.name}</option>`;
      }).join('');

      var extraFiltersHtml = `
        <div class="flex-row gap-xs align-center">
          <label class="text-xs font-semibold color-ink-2">Customer</label>
          <select class="field-select filter-attendance-customer text-xs" style="width: 170px; height: 32px;">
            <option value="all">All Customers</option>
            ${customerOptions}
          </select>
        </div>

        <div class="flex-row gap-xs align-center">
          <label class="check-container text-xs font-semibold color-ink-2" style="display:flex; align-items:center; gap:6px; cursor:pointer;">
            <input type="checkbox" class="filter-only-absentees">
            <span>Show only absentees</span>
          </label>
        </div>
      `;

      reportFrameInstance = Mess.createReportFrame({
        title: 'Customer-wise Attendance Report',
        subtitle: 'Audit member meal consumption, daily presence, absentees and B/L/D attendance matrix',
        extraFiltersHtml: extraFiltersHtml,
        views: [
          { id: 'summary', label: 'Summary View', icon: 'list' },
          { id: 'detail', label: 'Calendar Grid', icon: 'calendar' }
        ],

        readExtraFilters: function(rootEl) {
          var custSelect = rootEl.querySelector('.filter-attendance-customer');
          var absenteeChk = rootEl.querySelector('.filter-only-absentees');
          return {
            selectedCustomerId: custSelect ? custSelect.value : 'all',
            onlyAbsentees: absenteeChk ? absenteeChk.checked : false
          };
        },

        onGenerate: function(filters, viewId) {
          var validBills = Mess.reportHelpers.getValidBills(filters);
          var allCustomers = (Mess.store && Mess.store.list('customers')) || [];

          // Filter customers by selected customer or cuisine
          var targetCustomers = allCustomers.filter(function(m) {
            if (filters.selectedCustomerId && filters.selectedCustomerId !== 'all') {
              return m.id === filters.selectedCustomerId;
            }
            if (filters.cuisineId && filters.cuisineId !== 'all') {
              return m.cuisineId === filters.cuisineId;
            }
            return true;
          });

          return {
            bills: validBills,
            customers: targetCustomers,
            filters: filters,
            viewId: viewId
          };
        },

        renderResults: function(container, resultData, filters, viewId, drawer) {
          var bills = resultData.bills || [];
          var customers = resultData.customers || [];
          var fromDate = filters.fromDate;
          var toDate = filters.toDate;
          var daysInPeriod = getDaysBetween(fromDate, toDate);
          var dateList = getDatesArray(fromDate, toDate);

          // Build attendance records per customer
          var customerAttendance = customers.map(function(m) {
            var mBills = bills.filter(function(b) {
              return (b.customer_id || b.memberId) === m.id || (b.customer_code || b.memberCode) === m.code;
            });

            var countB = 0, countL = 0, countD = 0;
            var daysAttendedMap = {};

            mBills.forEach(function(b) {
              var meal = (b.meal_code || b.meal || b.meal_type || 'L').toUpperCase();
              if (meal === 'B') countB++;
              else if (meal === 'L') countL++;
              else if (meal === 'D') countD++;
              daysAttendedMap[b.date] = true;
            });

            var daysAttended = Object.keys(daysAttendedMap).length;
            var daysAbsent = Math.max(0, daysInPeriod - daysAttended);
            var totalMeals = countB + countL + countD;

            return {
              member: m,
              id: m.id,
              code: m.code,
              name: m.name,
              cuisineName: (Mess.store && Mess.store.get('cuisines', m.cuisineId) ? Mess.store.get('cuisines', m.cuisineId).name : 'Standard'),
              countB: countB,
              countL: countL,
              countD: countD,
              totalMeals: totalMeals,
              daysInPeriod: daysInPeriod,
              daysAbsent: daysAbsent,
              bills: mBills
            };
          });

          // Apply 'Show only absentees' filter
          if (filters.onlyAbsentees) {
            customerAttendance = customerAttendance.filter(function(rec) {
              return rec.totalMeals === 0 || rec.daysAbsent >= daysInPeriod;
            });
          }

          if (viewId === 'summary') {
            // View 1: Summary Table
            var grandB = 0, grandL = 0, grandD = 0, grandMeals = 0;
            customerAttendance.forEach(function(r) {
              grandB += r.countB;
              grandL += r.countL;
              grandD += r.countD;
              grandMeals += r.totalMeals;
            });

            var rowsHtml = customerAttendance.map(function(r) {
              var absentBadge = r.daysAbsent > 0
                ? `<span class="badge ${r.totalMeals === 0 ? 'badge--danger' : 'badge--warning'} font-mono">${r.daysAbsent} d</span>`
                : '<span class="color-ink-3">0</span>';

              return `
                <tr class="attendance-summary-row" data-id="${r.id}" style="border-bottom: 1px solid var(--separator); cursor: pointer;">
                  <td style="padding: 10px 14px;" class="font-mono font-bold color-primary">${r.code}</td>
                  <td style="padding: 10px 14px; font-weight: 500;">${r.name}</td>
                  <td style="padding: 10px 14px;"><span class="badge badge--neutral text-xs">${r.cuisineName}</span></td>
                  <td style="padding: 10px 14px; text-align: right;" class="font-mono">${r.daysInPeriod}</td>
                  <td style="padding: 10px 14px; text-align: right; color: var(--meal-b);" class="font-mono">${r.countB || '—'}</td>
                  <td style="padding: 10px 14px; text-align: right; color: var(--meal-l);" class="font-mono">${r.countL || '—'}</td>
                  <td style="padding: 10px 14px; text-align: right; color: var(--meal-d);" class="font-mono">${r.countD || '—'}</td>
                  <td style="padding: 10px 14px; text-align: right;" class="font-mono font-bold">${r.totalMeals}</td>
                  <td style="padding: 10px 14px; text-align: right;">${absentBadge}</td>
                  <td style="padding: 10px 14px; text-align: right;">
                    <button type="button" class="btn btn--quiet btn--icon btn--xs" title="View member tokens">
                      <i data-lucide="chevron-right"></i>
                    </button>
                  </td>
                </tr>
              `;
            }).join('');

            container.innerHTML = `
              <div class="flex-col gap-sm" style="height: 100%; padding: 16px; overflow-y: auto;">
                <div class="flex-row justify-between align-center">
                  <div class="text-xs color-ink-2">
                    Showing <strong>${customerAttendance.length}</strong> members across <strong>${daysInPeriod}</strong> days (${fromDate} to ${toDate}) · Click row to view tokens
                  </div>
                  <div class="flex-row gap-xs text-xs">
                    <span class="badge badge--b">Breakfast</span>
                    <span class="badge badge--l">Lunch</span>
                    <span class="badge badge--d">Dinner</span>
                  </div>
                </div>

                <div class="table-well" style="border: 1px solid var(--separator); border-radius: var(--radius-panel); overflow: hidden; background: var(--surface);">
                  <table class="attendance-table" style="width: 100%; border-collapse: collapse; font-size: 13px;">
                    <thead>
                      <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator);">
                        <th style="padding: 12px 14px; text-align: left; width: 110px;">Member Code</th>
                        <th style="padding: 12px 14px; text-align: left;">Full Name</th>
                        <th style="padding: 12px 14px; text-align: left; width: 130px;">Cuisine</th>
                        <th style="padding: 12px 14px; text-align: right; width: 110px;">Days in Period</th>
                        <th style="padding: 12px 14px; text-align: right; width: 110px; color: var(--meal-b);">Breakfast (B)</th>
                        <th style="padding: 12px 14px; text-align: right; width: 110px; color: var(--meal-l);">Lunch (L)</th>
                        <th style="padding: 12px 14px; text-align: right; width: 110px; color: var(--meal-d);">Dinner (D)</th>
                        <th style="padding: 12px 14px; text-align: right; width: 120px;">Total Meals</th>
                        <th style="padding: 12px 14px; text-align: right; width: 110px;">Days Absent</th>
                        <th style="padding: 12px 14px; text-align: right; width: 60px;">Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      ${rowsHtml || '<tr><td colspan="10" class="p-lg text-center color-ink-3">No member attendance records found</td></tr>'}
                    </tbody>
                    <tfoot>
                      <tr style="background: var(--canvas); border-top: 2px solid var(--separator); font-size: 14px; font-weight: bold;">
                        <td colspan="4" style="padding: 12px 14px;">Summary Totals</td>
                        <td style="padding: 12px 14px; text-align: right; color: var(--meal-b);" class="font-mono">${grandB}</td>
                        <td style="padding: 12px 14px; text-align: right; color: var(--meal-l);" class="font-mono">${grandL}</td>
                        <td style="padding: 12px 14px; text-align: right; color: var(--meal-d);" class="font-mono">${grandD}</td>
                        <td style="padding: 12px 14px; text-align: right; color: var(--primary);" class="font-mono">${grandMeals}</td>
                        <td colspan="2"></td>
                      </tr>
                    </tfoot>
                  </table>
                </div>
              </div>
            `;

            container.querySelectorAll('.attendance-summary-row').forEach(function(tr) {
              tr.addEventListener('click', function() {
                var mId = tr.getAttribute('data-id');
                var found = customerAttendance.find(function(it) { return it.id === mId; });
                if (found) {
                  openCustomerTokenDrawer(found.member, bills, drawer);
                }
              });
            });

          } else {
            // View 2: Calendar Grid Detail View (Task T-086)
            var datesHeaderHtml = dateList.map(function(dStr) {
              var isWknd = isWeekend(dStr);
              var dObj = new Date(dStr);
              var dayLetter = ['S', 'M', 'T', 'W', 'T', 'F', 'S'][dObj.getDay()];
              var dayNum = dStr.slice(8);
              return `
                <th class="cal-col-header ${isWknd ? 'cal-weekend-header' : ''}" style="padding: 6px 4px; text-align: center; min-width: 48px; border-left: 1px solid var(--separator); ${isWknd ? 'background: var(--canvas);' : ''}">
                  <div class="text-xxs color-ink-3">${dayLetter}</div>
                  <div class="font-mono text-xs font-bold">${dayNum}</div>
                </th>
              `;
            }).join('');

            var calRowsHtml = customerAttendance.map(function(r) {
              // Pre-index bills for this member by date
              var dateMealMap = {};
              r.bills.forEach(function(b) {
                if (!dateMealMap[b.date]) dateMealMap[b.date] = {};
                var m = (b.meal_code || b.meal || b.meal_type || 'L').toUpperCase();
                dateMealMap[b.date][m] = b;
              });

              var dateCellsHtml = dateList.map(function(dStr) {
                var isWknd = isWeekend(dStr);
                var dayMeals = dateMealMap[dStr] || {};
                var billB = dayMeals['B'];
                var billL = dayMeals['L'];
                var billD = dayMeals['D'];

                var hasB = !!billB;
                var hasL = !!billL;
                var hasD = !!billD;

                var tooltipB = hasB ? `Breakfast ${billB.time || ''} (${billB.token_no || billB.tokenNo || ''})` : 'No Breakfast';
                var tooltipL = hasL ? `Lunch ${billL.time || ''} (${billL.token_no || billL.tokenNo || ''})` : 'No Lunch';
                var tooltipD = hasD ? `Dinner ${billD.time || ''} (${billD.token_no || billD.tokenNo || ''})` : 'No Dinner';

                return `
                  <td class="cal-grid-cell ${isWknd ? 'cal-weekend-cell' : ''}" tabindex="0" role="gridcell" aria-label="${r.name} on ${dStr}: B:${hasB?'Y':'N'} L:${hasL?'Y':'N'} D:${hasD?'Y':'N'}" style="padding: 6px 2px; text-align: center; border-left: 1px solid var(--separator); ${isWknd ? 'background: rgba(0,0,0,0.02);' : ''}">
                    <div class="flex-row gap-xxs justify-center align-center">
                      <span class="cal-pip ${hasB ? 'cal-pip--b' : 'cal-pip--empty'}" title="${tooltipB}">
                        <span class="sr-only">B</span>B
                      </span>
                      <span class="cal-pip ${hasL ? 'cal-pip--l' : 'cal-pip--empty'}" title="${tooltipL}">
                        <span class="sr-only">L</span>L
                      </span>
                      <span class="cal-pip ${hasD ? 'cal-pip--d' : 'cal-pip--empty'}" title="${tooltipD}">
                        <span class="sr-only">D</span>D
                      </span>
                    </div>
                  </td>
                `;
              }).join('');

              return `
                <tr class="cal-member-row" data-id="${r.id}" style="border-bottom: 1px solid var(--separator);">
                  <td class="cal-sticky-col" style="padding: 8px 12px; position: sticky; left: 0; background: var(--surface); z-index: 2; border-right: 2px solid var(--separator); cursor: pointer;">
                    <div class="font-medium text-xs color-ink">${r.name}</div>
                    <div class="font-mono text-xxs color-ink-3">${r.code} · ${r.totalMeals} meals</div>
                  </td>
                  ${dateCellsHtml}
                </tr>
              `;
            }).join('');

            container.innerHTML = `
              <div class="flex-col gap-sm" style="height: 100%; padding: 16px; overflow: hidden;">
                <!-- Legend & Status -->
                <div class="flex-row justify-between align-center">
                  <div class="text-xs color-ink-2">
                    Keyboard grid: use <kbd class="shortcut-badge">Tab</kbd> / <kbd class="shortcut-badge">↑</kbd><kbd class="shortcut-badge">↓</kbd><kbd class="shortcut-badge">←</kbd><kbd class="shortcut-badge">→</kbd> to navigate · Click member to view tokens
                  </div>
                  <div class="flex-row gap-md align-center text-xs">
                    <div class="flex-row align-center gap-xs">
                      <span class="cal-pip cal-pip--b" style="display:inline-block;">B</span>
                      <span>Breakfast</span>
                    </div>
                    <div class="flex-row align-center gap-xs">
                      <span class="cal-pip cal-pip--l" style="display:inline-block;">L</span>
                      <span>Lunch</span>
                    </div>
                    <div class="flex-row align-center gap-xs">
                      <span class="cal-pip cal-pip--d" style="display:inline-block;">D</span>
                      <span>Dinner</span>
                    </div>
                    <div class="flex-row align-center gap-xs">
                      <span class="cal-pip cal-pip--empty" style="display:inline-block;">–</span>
                      <span class="color-ink-3">Not taken</span>
                    </div>
                  </div>
                </div>

                <!-- Sticky Calendar Grid -->
                <div class="table-well cal-grid-container" style="flex: 1; border: 1px solid var(--separator); border-radius: var(--radius-panel); overflow: auto; background: var(--surface);">
                  <table class="cal-grid-table" role="grid" aria-label="Customer attendance calendar grid" style="border-collapse: collapse; font-size: 11px; width: max-content; min-width: 100%;">
                    <thead>
                      <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); position: sticky; top: 0; z-index: 3;">
                        <th class="cal-sticky-col-header" style="padding: 10px 12px; text-align: left; position: sticky; left: 0; background: var(--canvas); z-index: 4; border-right: 2px solid var(--separator); min-width: 180px;">
                          Member Name & Code
                        </th>
                        ${datesHeaderHtml}
                      </tr>
                    </thead>
                    <tbody>
                      ${calRowsHtml || '<tr><td colspan="35" class="p-lg text-center color-ink-3">No members to display</td></tr>'}
                    </tbody>
                  </table>
                </div>
              </div>
            `;

            // Bind click on member header cell to open drawer
            container.querySelectorAll('.cal-sticky-col').forEach(function(td) {
              td.addEventListener('click', function() {
                var mId = td.closest('tr').getAttribute('data-id');
                var found = customerAttendance.find(function(it) { return it.id === mId; });
                if (found) {
                  openCustomerTokenDrawer(found.member, bills, drawer);
                }
              });
            });

            // Grid keyboard arrow navigation
            var gridTable = container.querySelector('.cal-grid-table');
            if (gridTable) {
              gridTable.addEventListener('keydown', function(e) {
                var active = document.activeElement;
                if (!active || !active.classList.contains('cal-grid-cell')) return;

                var td = active;
                var tr = td.parentElement;
                var cellIndex = Array.prototype.indexOf.call(tr.children, td);

                var target = null;
                if (e.key === 'ArrowRight') {
                  target = td.nextElementSibling;
                } else if (e.key === 'ArrowLeft') {
                  target = td.previousElementSibling && td.previousElementSibling.classList.contains('cal-grid-cell') ? td.previousElementSibling : null;
                } else if (e.key === 'ArrowDown') {
                  var nextTr = tr.nextElementSibling;
                  if (nextTr && nextTr.children[cellIndex]) target = nextTr.children[cellIndex];
                } else if (e.key === 'ArrowUp') {
                  var prevTr = tr.previousElementSibling;
                  if (prevTr && prevTr.children[cellIndex]) target = prevTr.children[cellIndex];
                } else if (e.key === 'Enter') {
                  var mId = tr.getAttribute('data-id');
                  var found = customerAttendance.find(function(it) { return it.id === mId; });
                  if (found) openCustomerTokenDrawer(found.member, bills, drawer);
                  return;
                }

                if (target) {
                  e.preventDefault();
                  target.focus();
                }
              });
            }
          }
        },

        onExport: function(type, filename) {
          var filters = reportFrameInstance ? reportFrameInstance.filters : {};
          var validBills = Mess.reportHelpers.getValidBills(filters);
          var allCustomers = (Mess.store && Mess.store.list('customers')) || [];
          var fromDate = filters.fromDate;
          var toDate = filters.toDate;
          var daysInPeriod = getDaysBetween(fromDate, toDate);

          var exportRows = allCustomers.map(function(m) {
            var mBills = validBills.filter(function(b) {
              return (b.customer_id || b.memberId) === m.id || (b.customer_code || b.memberCode) === m.code;
            });

            var countB = 0, countL = 0, countD = 0;
            var daysMap = {};
            mBills.forEach(function(b) {
              var meal = (b.meal_code || b.meal || b.meal_type || 'L').toUpperCase();
              if (meal === 'B') countB++;
              else if (meal === 'L') countL++;
              else if (meal === 'D') countD++;
              daysMap[b.date] = true;
            });

            var daysAttended = Object.keys(daysMap).length;
            var daysAbsent = Math.max(0, daysInPeriod - daysAttended);

            return {
              Code: m.code,
              Name: m.name,
              Cuisine: (Mess.store && Mess.store.get('cuisines', m.cuisineId) ? Mess.store.get('cuisines', m.cuisineId).name : 'Standard'),
              DaysInPeriod: daysInPeriod,
              Breakfast: countB,
              Lunch: countL,
              Dinner: countD,
              TotalMeals: countB + countL + countD,
              DaysAbsent: daysAbsent
            };
          });

          if (type === 'csv') {
            // Strictly enforce '|' delimiter as per user rules!
            var headers = ['Code', 'Name', 'Cuisine', 'DaysInPeriod', 'Breakfast', 'Lunch', 'Dinner', 'TotalMeals', 'DaysAbsent'];
            var csv = headers.join('|') + '\n';
            exportRows.forEach(function(r) {
              csv += `${r.Code}|${r.Name}|${r.Cuisine}|${r.DaysInPeriod}|${r.Breakfast}|${r.Lunch}|${r.Dinner}|${r.TotalMeals}|${r.DaysAbsent}\n`;
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
            XLSX.utils.book_append_sheet(wb, ws, 'Attendance');
            XLSX.writeFile(wb, filename);
          } else if (type === 'pdf' && window.jspdf) {
            var doc = new window.jspdf.jsPDF();
            doc.text('Customer-wise Attendance Report', 14, 15);
            var body = exportRows.map(function(r) {
              return [r.Code, r.Name, r.Cuisine, r.Breakfast, r.Lunch, r.Dinner, r.TotalMeals, r.DaysAbsent];
            });
            if (doc.autoTable) {
              doc.autoTable({
                head: [['Code', 'Name', 'Cuisine', 'B', 'L', 'D', 'Total', 'Absent']],
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
