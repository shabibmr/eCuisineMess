/* report-time-based.js - Screen 20: Time-based Report (Tasks T-087 & T-088) */

window.Mess = window.Mess || {};

(function(Mess) {
  var reportFrameInstance = null;
  var activeCharts = [];

  function pad(n) {
    return n < 10 ? '0' + n : '' + n;
  }

  function minutesToTime(m) {
    var h = Math.floor(m / 60);
    var mins = m % 60;
    return pad(h) + ':' + pad(mins);
  }

  function timeToMinutes(t) {
    if (!t) return 0;
    var parts = t.split(':');
    return parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
  }

  function openTimeSlotDrawer(slotTitle, slotBills, drawer) {
    drawer.push({
      title: slotTitle,
      breadcrumbTitle: slotTitle.split('(')[0].trim(),
      countText: `${slotBills.length} Token${slotBills.length === 1 ? '' : 's'}`,
      render: function(container, drawerRef) {
        var rowsHtml = slotBills.map(function(b) {
          var tokenNo = b.token_number || b.token_no || b.tokenNo || 'Token';
          var m = (b.meal_code || b.meal || b.meal_type || 'L').toUpperCase();
          return `
            <tr class="slot-token-row" data-id="${b.id}" style="border-bottom: 1px solid var(--separator); cursor: pointer;">
              <td style="padding: 8px 10px;" class="font-mono font-bold color-primary">${tokenNo}</td>
              <td style="padding: 8px 10px;" class="font-mono text-xs">${b.date}</td>
              <td style="padding: 8px 10px;" class="font-mono text-xs">${b.time ? b.time.slice(0, 5) : '—'}</td>
              <td style="padding: 8px 10px;">
                <span class="badge badge--${m.toLowerCase()}">${m}</span>
              </td>
              <td style="padding: 8px 10px;" class="text-xs">
                <div>${b.customer_name || b.memberName || ''}</div>
                <div class="font-mono text-xxs color-ink-3">${b.customer_code || b.memberCode || ''}</div>
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
            <span class="text-xs color-ink-2">Tokens issued during <strong>${slotTitle}</strong></span>
            <div class="table-well" style="border: 1px solid var(--separator); border-radius: var(--radius-sm); max-height: 480px; overflow-y: auto;">
              <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
                <thead>
                  <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); text-align: left;">
                    <th style="padding: 8px 10px;">Token</th>
                    <th style="padding: 8px 10px;">Date</th>
                    <th style="padding: 8px 10px;">Time</th>
                    <th style="padding: 8px 10px;">Meal</th>
                    <th style="padding: 8px 10px;">Member</th>
                    <th style="padding: 8px 10px; text-align: right;">Action</th>
                  </tr>
                </thead>
                <tbody>${rowsHtml || '<tr><td colspan="6" class="p-md text-center color-ink-3">No tokens in this slot</td></tr>'}</tbody>
              </table>
            </div>
          </div>
        `;

        container.querySelectorAll('.slot-token-row').forEach(function(tr) {
          tr.addEventListener('click', function() {
            var bId = tr.getAttribute('data-id');
            var found = slotBills.find(function(it) { return it.id === bId; });
            if (found && Mess.showTokenPreviewDialog) {
              Mess.showTokenPreviewDialog(found, { isDuplicate: true });
            }
          });
        });
      }
    });
  }

  Mess.screens.register({
    id: 'report-time-based',
    route: '/reports/time',
    title: 'Time-based Report',
    nav: { group: 'Reports', icon: 'clock', order: 50 },
    roles: ['admin', 'supervisor'],

    template: function() {
      var extraFiltersHtml = `
        <div class="flex-row gap-xs align-center">
          <label class="text-xs font-semibold color-ink-2">Interval</label>
          <div class="segmented-control filter-interval-segmented" role="radiogroup" aria-label="Interval selection">
            <button type="button" data-interval="15">15m</button>
            <button type="button" class="active" data-interval="30">30m</button>
            <button type="button" data-interval="60">60m</button>
          </div>
        </div>
      `;

      reportFrameInstance = Mess.createReportFrame({
        title: 'Time-based Report',
        subtitle: 'Distribution of token issuances across time slots, peak hour identification and hourly heat maps',
        extraFiltersHtml: extraFiltersHtml,
        views: [
          { id: 'slots', label: 'Time-slot View', icon: 'bar-chart-2' },
          { id: 'hourly', label: 'Hourly by Date', icon: 'grid' }
        ],

        readExtraFilters: function(rootEl) {
          var intBtn = rootEl.querySelector('.filter-interval-segmented button.active');
          return {
            intervalMinutes: intBtn ? parseInt(intBtn.getAttribute('data-interval'), 10) : 30
          };
        },

        onGenerate: function(filters, viewId) {
          var validBills = Mess.reportHelpers.getValidBills(filters);
          return {
            bills: validBills,
            filters: filters,
            viewId: viewId
          };
        },

        renderResults: function(container, resultData, filters, viewId, drawer) {
          var bills = resultData.bills || [];
          var interval = filters.intervalMinutes || 30;

          // Meal configurations (default window ranges if not found in store)
          var mealConfigs = [
            { code: 'B', name: 'Breakfast', startM: 6 * 60, endM: 10 * 60, color: '#f59e0b' },
            { code: 'L', name: 'Lunch', startM: 12 * 60, endM: 15 * 60, color: '#10b981' },
            { code: 'D', name: 'Dinner', startM: 19 * 60, endM: 22 * 60, color: '#6366f1' }
          ];

          // Filter by meal if meal filter is not 'all'
          if (filters.mealType && filters.mealType !== 'all') {
            mealConfigs = mealConfigs.filter(function(m) { return m.code === filters.mealType; });
          }

          if (viewId === 'slots') {
            // View 1: Time-slot view (Task T-087)
            // Generate slots for each meal config
            var allSlots = [];
            var mealSummaries = [];

            mealConfigs.forEach(function(mCfg) {
              var mealBills = bills.filter(function(b) {
                var m = (b.meal_code || b.meal || b.meal_type || '').toUpperCase();
                return m === mCfg.code;
              });

              var slotsForMeal = [];
              for (var m = mCfg.startM; m < mCfg.endM; m += interval) {
                var slotStart = m;
                var slotEnd = Math.min(mCfg.endM, m + interval);
                var label = minutesToTime(slotStart) + ' – ' + minutesToTime(slotEnd);

                var slotBills = mealBills.filter(function(b) {
                  var tM = timeToMinutes(b.time);
                  return tM >= slotStart && tM < slotEnd;
                });

                slotsForMeal.push({
                  mealCode: mCfg.code,
                  mealName: mCfg.name,
                  color: mCfg.color,
                  slotStart: slotStart,
                  slotEnd: slotEnd,
                  label: label,
                  count: slotBills.length,
                  bills: slotBills
                });
              }

              // Calculate peak slot for this meal
              var peakCount = 0;
              var peakSlot = null;
              slotsForMeal.forEach(function(s) {
                if (s.count > peakCount) {
                  peakCount = s.count;
                  peakSlot = s;
                }
              });

              if (peakSlot) {
                peakSlot.isPeak = true;
              }

              // Calculate % of meal
              var mealTotal = mealBills.length;
              slotsForMeal.forEach(function(s) {
                s.percentage = mealTotal > 0 ? ((s.count / mealTotal) * 100).toFixed(1) : '0.0';
                allSlots.push(s);
              });

              // First and last token time
              var firstTokenTime = '—';
              var lastTokenTime = '—';
              if (mealBills.length > 0) {
                var sortedBills = mealBills.slice().sort(function(a, b) {
                  return (a.time || '').localeCompare(b.time || '');
                });
                firstTokenTime = sortedBills[0].time ? sortedBills[0].time.slice(0, 5) : '—';
                lastTokenTime = sortedBills[sortedBills.length - 1].time ? sortedBills[sortedBills.length - 1].time.slice(0, 5) : '—';
              }

              var avgPerSlot = slotsForMeal.length > 0 ? (mealTotal / slotsForMeal.length).toFixed(1) : '0';

              mealSummaries.push({
                code: mCfg.code,
                name: mCfg.name,
                color: mCfg.color,
                total: mealTotal,
                firstToken: firstTokenTime,
                lastToken: lastTokenTime,
                peakSlot: peakSlot ? `${peakSlot.label} (${peakSlot.count} tokens)` : '—',
                avgPerSlot: avgPerSlot
              });
            });

            // Summary strip table HTML
            var summaryStripHtml = mealSummaries.map(function(s) {
              return `
                <tr style="border-bottom: 1px solid var(--separator);">
                  <td style="padding: 8px 12px; font-weight: bold; color: ${s.color};">
                    <span class="badge badge--${s.code.toLowerCase()}">${s.name}</span>
                  </td>
                  <td style="padding: 8px 12px; text-align: right;" class="font-mono font-bold">${s.total}</td>
                  <td style="padding: 8px 12px; text-align: center;" class="font-mono text-xs">${s.firstToken}</td>
                  <td style="padding: 8px 12px; text-align: center;" class="font-mono text-xs">${s.lastToken}</td>
                  <td style="padding: 8px 12px;" class="font-mono font-bold color-primary">${s.peakSlot}</td>
                  <td style="padding: 8px 12px; text-align: right;" class="font-mono">${s.avgPerSlot}</td>
                </tr>
              `;
            }).join('');

            // Slot table rows HTML
            var slotRowsHtml = allSlots.map(function(s) {
              var peakClass = s.isPeak ? 'font-bold' : '';
              var peakBadge = s.isPeak ? '<span class="badge badge--danger text-xxs font-mono" style="margin-left:6px;">PEAK</span>' : '';

              return `
                <tr class="time-slot-row ${peakClass}" data-meal="${s.mealCode}" data-slot="${s.label}" style="border-bottom: 1px solid var(--separator); cursor: pointer; ${s.isPeak ? 'background: rgba(239, 68, 68, 0.05);' : ''}">
                  <td style="padding: 8px 12px; font-weight: 500;">
                    <span class="font-mono">${s.label}</span>
                    ${peakBadge}
                  </td>
                  <td style="padding: 8px 12px;">
                    <span class="badge badge--${s.mealCode.toLowerCase()}" style="font-size: 10px;">${s.mealName}</span>
                  </td>
                  <td style="padding: 8px 12px; text-align: right; color: ${s.color};" class="font-mono font-bold">
                    ${s.count}
                  </td>
                  <td style="padding: 8px 12px; text-align: right;" class="font-mono text-xs color-ink-2">
                    ${s.percentage} %
                  </td>
                  <td style="padding: 8px 12px; text-align: right;">
                    <button type="button" class="btn btn--quiet btn--icon btn--xs" title="View tokens in slot">
                      <i data-lucide="chevron-right"></i>
                    </button>
                  </td>
                </tr>
              `;
            }).join('');

            var chartElId = 'timeslot-chart-' + Math.floor(Math.random() * 10000);

            container.innerHTML = `
              <div class="flex-col gap-md" style="height: 100%; padding: 16px; overflow-y: auto;">
                <!-- Summary Strip -->
                <div class="card-inset p-sm flex-col gap-xs" style="background: var(--surface); border: 1px solid var(--separator); border-radius: var(--radius-panel);">
                  <div class="flex-row justify-between align-center">
                    <span class="text-xs font-semibold color-ink-2">Meal Window Summaries</span>
                    <span class="text-xs color-ink-3">Interval: <strong>${interval} min</strong></span>
                  </div>
                  <div class="table-well" style="border: 1px solid var(--separator); border-radius: var(--radius-sm); overflow: hidden;">
                    <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
                      <thead>
                        <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); text-align: left;">
                          <th style="padding: 8px 12px;">Meal</th>
                          <th style="padding: 8px 12px; text-align: right;">Tokens</th>
                          <th style="padding: 8px 12px; text-align: center;">First Token</th>
                          <th style="padding: 8px 12px; text-align: center;">Last Token</th>
                          <th style="padding: 8px 12px;">Peak Slot</th>
                          <th style="padding: 8px 12px; text-align: right;">Avg / Slot</th>
                        </tr>
                      </thead>
                      <tbody>${summaryStripHtml}</tbody>
                    </table>
                  </div>
                </div>

                <!-- ApexChart Container -->
                <div class="card-inset p-sm flex-col gap-xs" style="background: var(--surface); border: 1px solid var(--separator); border-radius: var(--radius-panel);">
                  <span class="text-xs font-semibold color-ink-2">Token Issuance Distribution by Time Slot</span>
                  <div id="${chartElId}" style="height: 220px; width: 100%;"></div>
                </div>

                <!-- Slots Table -->
                <div class="flex-col gap-xs">
                  <span class="text-xs font-semibold color-ink-2">Detailed Slot Breakdown (Click slot to view tokens)</span>
                  <div class="table-well" style="border: 1px solid var(--separator); border-radius: var(--radius-panel); overflow: hidden; background: var(--surface); border: 1px solid var(--separator);">
                    <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
                      <thead>
                        <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); text-align: left;">
                          <th style="padding: 8px 12px;">Time Slot</th>
                          <th style="padding: 8px 12px;">Meal</th>
                          <th style="padding: 8px 12px; text-align: right;">Token Count</th>
                          <th style="padding: 8px 12px; text-align: right;">% of Meal Total</th>
                          <th style="padding: 8px 12px; text-align: right; width: 60px;">Action</th>
                        </tr>
                      </thead>
                      <tbody>${slotRowsHtml || '<tr><td colspan="5" class="p-md text-center color-ink-3">No tokens recorded</td></tr>'}</tbody>
                    </table>
                  </div>
                </div>
              </div>
            `;

            // Render ApexCharts for Slots
            var chartEl = container.querySelector('#' + chartElId);
            if (chartEl && window.ApexCharts && allSlots.length > 0) {
              try {
                var categories = allSlots.map(function(s) { return s.label.split('–')[0].trim(); });
                var data = allSlots.map(function(s) { return s.count; });
                var colors = allSlots.map(function(s) { return s.color; });

                var chart = new ApexCharts(chartEl, {
                  chart: {
                    type: 'bar',
                    height: 210,
                    toolbar: { show: false },
                    animations: { enabled: false },
                    fontFamily: 'inherit'
                  },
                  plotOptions: {
                    bar: {
                      distributed: true,
                      borderRadius: 2,
                      columnWidth: '60%'
                    }
                  },
                  colors: colors,
                  series: [{ name: 'Tokens', data: data }],
                  xaxis: {
                    categories: categories,
                    labels: { style: { fontSize: '10px' }, rotate: -45 }
                  },
                  yaxis: {
                    labels: { style: { fontSize: '10px' } }
                  },
                  legend: { show: false },
                  dataLabels: { enabled: false }
                });
                chart.render();
                activeCharts.push(chart);
              } catch (e) {
                console.warn('ApexCharts slot render error:', e);
              }
            }

            // Bind click on slots
            container.querySelectorAll('.time-slot-row').forEach(function(tr) {
              tr.addEventListener('click', function() {
                var slotLabel = tr.getAttribute('data-slot');
                var mealCode = tr.getAttribute('data-meal');
                var found = allSlots.find(function(s) { return s.label === slotLabel && s.mealCode === mealCode; });
                if (found) {
                  openTimeSlotDrawer(`${found.mealName} Slot: ${found.label}`, found.bills, drawer);
                }
              });
            });

          } else {
            // View 2: Hourly by Date Heat Map (Task T-088)
            var datesMap = {};
            bills.forEach(function(b) { datesMap[b.date] = true; });
            var datesList = Object.keys(datesMap).sort();
            if (datesList.length === 0 && filters.fromDate) {
              datesList = [filters.fromDate];
            }

            // Hours from 06 to 22 (17 hours)
            var hours = [];
            for (var h = 6; h <= 22; h++) {
              hours.push(h);
            }

            // Calculate max count for heat shading
            var maxHourCount = 1;
            var matrix = {};
            datesList.forEach(function(d) {
              matrix[d] = {};
              hours.forEach(function(h) {
                matrix[d][h] = [];
              });
            });

            bills.forEach(function(b) {
              if (b.time && matrix[b.date]) {
                var h = parseInt(b.time.split(':')[0], 10);
                if (matrix[b.date][h]) {
                  matrix[b.date][h].push(b);
                  if (matrix[b.date][h].length > maxHourCount) {
                    maxHourCount = matrix[b.date][h].length;
                  }
                }
              }
            });

            function getHourMealColor(h) {
              if (h >= 6 && h < 10) return 'var(--meal-b-soft)';
              if (h >= 12 && h < 15) return 'var(--meal-l-soft)';
              if (h >= 19 && h < 22) return 'var(--meal-d-soft)';
              return 'transparent';
            }

            var hoursHeaderHtml = hours.map(function(h) {
              var mealBg = getHourMealColor(h);
              return `
                <th style="padding: 8px 4px; text-align: center; min-width: 44px; border-left: 1px solid var(--separator); background: ${mealBg}; font-mono text-xs;">
                  ${pad(h)}:00
                </th>
              `;
            }).join('');

            var heatRowsHtml = datesList.map(function(dStr) {
              var dayTotal = 0;
              var hourCellsHtml = hours.map(function(h) {
                var cellBills = matrix[dStr][h] || [];
                var count = cellBills.length;
                dayTotal += count;

                var bg = 'transparent';
                if (count > 0) {
                  var ratio = (count / maxHourCount).toFixed(2);
                  var alpha = (0.12 + ratio * 0.55).toFixed(2);
                  // Use ink-scale tint
                  bg = `rgba(37, 99, 235, ${alpha})`;
                }

                return `
                  <td class="hourly-cell" data-date="${dStr}" data-hour="${h}" style="padding: 6px 2px; text-align: center; border-left: 1px solid var(--separator); background: ${bg}; cursor: pointer;" title="${dStr} ${pad(h)}:00 - ${count} tokens">
                    ${count > 0 ? `<strong class="font-mono text-xs">${count}</strong>` : '<span class="color-ink-3 text-xxs">–</span>'}
                  </td>
                `;
              }).join('');

              return `
                <tr style="border-bottom: 1px solid var(--separator);">
                  <td style="padding: 8px 12px; position: sticky; left: 0; background: var(--surface); z-index: 2; border-right: 2px solid var(--separator);" class="font-mono font-bold">
                    ${dStr}
                  </td>
                  ${hourCellsHtml}
                  <td style="padding: 8px 12px; text-align: right; background: var(--surface-strong); border-left: 2px solid var(--separator);" class="font-mono font-bold color-primary">
                    ${dayTotal}
                  </td>
                </tr>
              `;
            }).join('');

            container.innerHTML = `
              <div class="flex-col gap-sm" style="height: 100%; padding: 16px; overflow: hidden;">
                <!-- Legend & Meal Window Bands -->
                <div class="flex-row justify-between align-center">
                  <div class="text-xs color-ink-2">
                    Heat map of token issuances across hours (06:00 to 22:00) · Shaded headers denote active meal windows
                  </div>
                  <div class="flex-row gap-md text-xs">
                    <span class="badge badge--b">Breakfast Window (06-10)</span>
                    <span class="badge badge--l">Lunch Window (12-15)</span>
                    <span class="badge badge--d">Dinner Window (19-22)</span>
                  </div>
                </div>

                <!-- Heat Map Table -->
                <div class="table-well" style="flex: 1; border: 1px solid var(--separator); border-radius: var(--radius-panel); overflow: auto; background: var(--surface);">
                  <table style="border-collapse: collapse; font-size: 12px; width: max-content; min-width: 100%;">
                    <thead>
                      <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); position: sticky; top: 0; z-index: 3;">
                        <th style="padding: 8px 12px; text-align: left; position: sticky; left: 0; background: var(--canvas); z-index: 4; border-right: 2px solid var(--separator); min-width: 120px;">
                          Date
                        </th>
                        ${hoursHeaderHtml}
                        <th style="padding: 8px 12px; text-align: right; min-width: 80px; border-left: 2px solid var(--separator);">
                          Day Total
                        </th>
                      </tr>
                    </thead>
                    <tbody>${heatRowsHtml}</tbody>
                  </table>
                </div>
              </div>
            `;

            // Bind click on heat cells
            container.querySelectorAll('.hourly-cell').forEach(function(td) {
              td.addEventListener('click', function() {
                var dStr = td.getAttribute('data-date');
                var h = parseInt(td.getAttribute('data-hour'), 10);
                var cellBills = (matrix[dStr] && matrix[dStr][h]) || [];
                if (cellBills.length > 0) {
                  openTimeSlotDrawer(`${dStr} at ${pad(h)}:00 – ${pad(h+1)}:00`, cellBills, drawer);
                }
              });
            });
          }
        },

        onExport: function(type, filename) {
          var filters = reportFrameInstance ? reportFrameInstance.filters : {};
          var validBills = Mess.reportHelpers.getValidBills(filters);
          var interval = (filters && filters.intervalMinutes) || 30;

          // Export time slot aggregations
          var rows = [];
          var mealConfigs = [
            { code: 'B', name: 'Breakfast', startM: 6 * 60, endM: 10 * 60 },
            { code: 'L', name: 'Lunch', startM: 12 * 60, endM: 15 * 60 },
            { code: 'D', name: 'Dinner', startM: 19 * 60, endM: 22 * 60 }
          ];

          mealConfigs.forEach(function(mCfg) {
            var mealBills = validBills.filter(function(b) {
              var m = (b.meal_code || b.meal || b.meal_type || '').toUpperCase();
              return m === mCfg.code;
            });
            for (var m = mCfg.startM; m < mCfg.endM; m += interval) {
              var slotStart = m;
              var slotEnd = Math.min(mCfg.endM, m + interval);
              var label = minutesToTime(slotStart) + ' – ' + minutesToTime(slotEnd);
              var slotCount = mealBills.filter(function(b) {
                var tM = timeToMinutes(b.time);
                return tM >= slotStart && tM < slotEnd;
              }).length;

              rows.push({
                Meal: mCfg.name,
                TimeSlot: label,
                Tokens: slotCount,
                PercentOfMeal: mealBills.length > 0 ? ((slotCount / mealBills.length) * 100).toFixed(1) + '%' : '0%'
              });
            }
          });

          if (type === 'csv') {
            // Strictly enforce '|' delimiter as per user rules!
            var headers = ['Meal', 'TimeSlot', 'Tokens', 'PercentOfMeal'];
            var csv = headers.join('|') + '\n';
            rows.forEach(function(r) {
              csv += `${r.Meal}|${r.TimeSlot}|${r.Tokens}|${r.PercentOfMeal}\n`;
            });
            var blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            var url = URL.createObjectURL(blob);
            var a = document.createElement('a');
            a.href = url;
            a.download = filename;
            a.click();
            URL.revokeObjectURL(url);
          } else if (type === 'xlsx' && window.XLSX) {
            var ws = XLSX.utils.json_to_sheet(rows);
            var wb = XLSX.utils.book_new();
            XLSX.utils.book_append_sheet(wb, ws, 'TimeBased');
            XLSX.writeFile(wb, filename);
          } else if (type === 'pdf' && window.jspdf) {
            var doc = new window.jspdf.jsPDF();
            doc.text('Time-based Report', 14, 15);
            var body = rows.map(function(r) {
              return [r.Meal, r.TimeSlot, r.Tokens, r.PercentOfMeal];
            });
            if (doc.autoTable) {
              doc.autoTable({
                head: [['Meal', 'Time Slot', 'Tokens', '% of Meal']],
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

          var intButtons = rootEl.querySelectorAll('.filter-interval-segmented button');
          intButtons.forEach(function(btn) {
            btn.addEventListener('click', function() {
              intButtons.forEach(function(b) { b.classList.remove('active'); });
              btn.classList.add('active');
            });
          });

          if (reportFrameInstance) {
            reportFrameInstance.init(rootEl);
          }
        },
        destroy: function() {
          activeCharts.forEach(function(c) {
            try { c.destroy(); } catch (e) {}
          });
          activeCharts = [];
          if (reportFrameInstance) {
            reportFrameInstance.destroy();
            reportFrameInstance = null;
          }
        }
      };
    }
  });
})(window.Mess);
