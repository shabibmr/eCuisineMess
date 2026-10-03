/* report-items.js - Screen 18: Item-wise Movement Report (Task T-084) */

window.Mess = window.Mess || {};

(function(Mess) {
  var reportFrameInstance = null;
  var activeCharts = [];

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

  function openItemDrilldownDrawer(itemRow, allLines, bills, drawer) {
    var itemLines = allLines.filter(function(l) { return l.itemId === itemRow.itemId; });

    // Group item lines by date
    var dateMap = {};
    itemLines.forEach(function(l) {
      if (!dateMap[l.date]) {
        dateMap[l.date] = { date: l.date, B: 0, L: 0, D: 0, total: 0, bills: [] };
      }
      var m = (l.mealCode || 'L').toUpperCase();
      dateMap[l.date][m] = (dateMap[l.date][m] || 0) + l.qty;
      dateMap[l.date].total += l.qty;
      dateMap[l.date].bills.push(l);
    });

    var dateRows = Object.values(dateMap).sort(function(a, b) {
      return a.date.localeCompare(b.date);
    });

    drawer.push({
      title: `${itemRow.name} (${itemRow.code})`,
      breadcrumbTitle: itemRow.code,
      countText: `${itemRow.totalQty} ${itemRow.unit || 'units'} across ${dateRows.length} day${dateRows.length === 1 ? '' : 's'}`,
      render: function(container, drawerRef) {
        var chartContainerId = 'item-chart-' + Math.floor(Math.random() * 10000);

        var tableRowsHtml = dateRows.map(function(d) {
          return `
            <tr class="item-date-row" data-date="${d.date}" style="cursor: pointer; border-bottom: 1px solid var(--separator);">
              <td style="padding: 8px 10px;" class="font-mono font-bold">${d.date}</td>
              <td style="padding: 8px 10px; text-align: right; color: var(--meal-b);" class="font-mono">${d.B || '—'}</td>
              <td style="padding: 8px 10px; text-align: right; color: var(--meal-l);" class="font-mono">${d.L || '—'}</td>
              <td style="padding: 8px 10px; text-align: right; color: var(--meal-d);" class="font-mono">${d.D || '—'}</td>
              <td style="padding: 8px 10px; text-align: right;" class="font-mono font-bold">${d.total}</td>
              <td style="padding: 8px 10px; text-align: right;">
                <button type="button" class="btn btn--quiet btn--icon btn--xs" title="View tokens">
                  <i data-lucide="chevron-right"></i>
                </button>
              </td>
            </tr>
          `;
        }).join('');

        container.innerHTML = `
          <div class="flex-col gap-md">
            <!-- Summary Header -->
            <div class="flex-row justify-between align-center p-sm card-inset" style="background: var(--canvas); border-radius: var(--radius-sm); border: 1px solid var(--separator);">
              <div class="flex-col">
                <span class="text-xs color-ink-3">Category: ${itemRow.category || 'Standard'}</span>
                <span class="font-bold text-lg">${itemRow.name}</span>
              </div>
              <div class="flex-col align-end">
                <span class="text-xs color-ink-3">Total Movement:</span>
                <span class="font-mono text-xl font-bold color-primary">${itemRow.totalQty} ${itemRow.unit || ''}</span>
              </div>
            </div>

            <!-- Date-wise Chart Container -->
            <div class="card-inset p-sm flex-col gap-xs" style="background: var(--surface); border-radius: var(--radius-sm); border: 1px solid var(--separator);">
              <span class="text-xs font-semibold color-ink-2">Movement by Date (Stacked by Meal)</span>
              <div id="${chartContainerId}" style="height: 180px; width: 100%;"></div>
            </div>

            <!-- Date-wise Quantities Table -->
            <div class="flex-col gap-xs">
              <span class="text-xs font-semibold color-ink-2">Date Breakdown (Click date to view tokens)</span>
              <div class="table-well" style="border: 1px solid var(--separator); border-radius: var(--radius-sm); max-height: 240px; overflow-y: auto;">
                <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
                  <thead>
                    <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); text-align: left;">
                      <th style="padding: 8px 10px;">Date</th>
                      <th style="padding: 8px 10px; text-align: right; color: var(--meal-b);">B</th>
                      <th style="padding: 8px 10px; text-align: right; color: var(--meal-l);">L</th>
                      <th style="padding: 8px 10px; text-align: right; color: var(--meal-d);">D</th>
                      <th style="padding: 8px 10px; text-align: right;">Total Qty</th>
                      <th style="padding: 8px 10px; text-align: right;">Action</th>
                    </tr>
                  </thead>
                  <tbody>${tableRowsHtml || '<tr><td colspan="6" class="p-md text-center color-ink-3">No movements recorded</td></tr>'}</tbody>
                </table>
              </div>
            </div>
          </div>
        `;

        // Render ApexCharts if available
        var chartEl = container.querySelector('#' + chartContainerId);
        if (chartEl && window.ApexCharts && dateRows.length > 0) {
          try {
            var categories = dateRows.map(function(d) { return d.date.slice(5); });
            var seriesB = dateRows.map(function(d) { return d.B; });
            var seriesL = dateRows.map(function(d) { return d.L; });
            var seriesD = dateRows.map(function(d) { return d.D; });

            var chart = new ApexCharts(chartEl, {
              chart: {
                type: 'bar',
                height: 170,
                stacked: true,
                toolbar: { show: false },
                animations: { enabled: false },
                fontFamily: 'inherit'
              },
              plotOptions: {
                bar: { horizontal: false, borderRadius: 2, columnWidth: '55%' }
              },
              colors: ['#f59e0b', '#10b981', '#6366f1'],
              series: [
                { name: 'Breakfast', data: seriesB },
                { name: 'Lunch', data: seriesL },
                { name: 'Dinner', data: seriesD }
              ],
              xaxis: {
                categories: categories,
                labels: { style: { fontSize: '10px' } }
              },
              yaxis: {
                labels: { style: { fontSize: '10px' } }
              },
              legend: {
                position: 'top',
                horizontalAlign: 'right',
                fontSize: '11px'
              },
              dataLabels: { enabled: false }
            });
            chart.render();
            activeCharts.push(chart);
          } catch (e) {
            console.warn('ApexCharts render skipped:', e);
          }
        }

        // Bind drill to Level 2 (Tokens for selected date)
        container.querySelectorAll('.item-date-row').forEach(function(tr) {
          tr.addEventListener('click', function() {
            var dStr = tr.getAttribute('data-date');
            var dayData = dateMap[dStr];
            if (!dayData) return;

            // Level 2 drawer
            drawerRef.push({
              title: `${itemRow.name} on ${dStr}`,
              breadcrumbTitle: dStr,
              countText: `${dayData.bills.length} Tokens issued`,
              render: function(level2Container) {
                var tokenRows = dayData.bills.map(function(b) {
                  return `
                    <tr style="border-bottom: 1px solid var(--separator);">
                      <td style="padding: 8px 10px;" class="font-mono font-bold color-primary">${b.tokenNo || b.voucherNo || 'Token'}</td>
                      <td style="padding: 8px 10px;" class="font-mono text-xs">${b.time ? b.time.slice(0, 5) : '—'}</td>
                      <td style="padding: 8px 10px;">
                        <div class="font-medium text-xs">${b.memberName || ''}</div>
                        <div class="font-mono text-xxs color-ink-3">${b.memberId || ''}</div>
                      </td>
                      <td style="padding: 8px 10px;">
                        <span class="badge badge--${(b.mealCode || 'l').toLowerCase()}">${b.mealCode}</span>
                      </td>
                      <td style="padding: 8px 10px;" class="text-xs">${b.cuisineName || ''}</td>
                      <td style="padding: 8px 10px; text-align: right;" class="font-mono font-bold">${b.qty} ${itemRow.unit || ''}</td>
                    </tr>
                  `;
                }).join('');

                level2Container.innerHTML = `
                  <div class="flex-col gap-sm">
                    <span class="text-xs color-ink-2">Tokens issued on <strong>${dStr}</strong> that contained <strong>${itemRow.name}</strong></span>
                    <div class="table-well" style="border: 1px solid var(--separator); border-radius: var(--radius-sm); max-height: 480px; overflow-y: auto;">
                      <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
                        <thead>
                          <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); text-align: left;">
                            <th style="padding: 8px 10px;">Token</th>
                            <th style="padding: 8px 10px;">Time</th>
                            <th style="padding: 8px 10px;">Member</th>
                            <th style="padding: 8px 10px;">Meal</th>
                            <th style="padding: 8px 10px;">Cuisine</th>
                            <th style="padding: 8px 10px; text-align: right;">Qty</th>
                          </tr>
                        </thead>
                        <tbody>${tokenRows}</tbody>
                      </table>
                    </div>
                  </div>
                `;
              }
            });
          });
        });
      }
    });
  }

  Mess.screens.register({
    id: 'report-items',
    route: '/reports/items',
    title: 'Item-wise Movement Report',
    nav: { group: 'Reports', icon: 'package', order: 30 },
    roles: ['admin', 'supervisor'],

    template: function() {
      var allItems = (Mess.store && Mess.store.list('items')) || [];
      var itemOptions = allItems.map(function(it) {
        return `<option value="${it.id}">${it.code} – ${it.name} (${it.unit})</option>`;
      }).join('');

      var extraFiltersHtml = `
        <div class="flex-row gap-xs align-center">
          <label class="text-xs font-semibold color-ink-2">Item</label>
          <select class="field-select filter-item-picker text-xs" style="width: 180px; height: 32px;">
            <option value="all">All Items</option>
            ${itemOptions}
          </select>
        </div>

        <div class="flex-row gap-xs align-center">
          <label class="text-xs font-semibold color-ink-2">Group By</label>
          <div class="segmented-control filter-grouping-segmented" role="radiogroup" aria-label="Item report grouping">
            <button type="button" class="active" data-group="none">Flat</button>
            <button type="button" data-group="cuisine">Cuisine</button>
            <button type="button" data-group="date">Date</button>
          </div>
        </div>
      `;

      reportFrameInstance = Mess.createReportFrame({
        title: 'Item-wise Movement Report',
        subtitle: 'Inventory movement and consumed quantities per item across Breakfast, Lunch and Dinner',
        extraFiltersHtml: extraFiltersHtml,

        readExtraFilters: function(rootEl) {
          var itemSelect = rootEl.querySelector('.filter-item-picker');
          var groupBtn = rootEl.querySelector('.filter-grouping-segmented button.active');
          return {
            selectedItemId: itemSelect ? itemSelect.value : 'all',
            groupBy: groupBtn ? groupBtn.getAttribute('data-group') : 'none'
          };
        },

        onGenerate: function(filters) {
          var validBills = Mess.reportHelpers.getValidBills(filters);
          var derivedLines = Mess.reportHelpers.getDerivedItemLines(validBills);

          if (filters.selectedItemId && filters.selectedItemId !== 'all') {
            derivedLines = derivedLines.filter(function(l) { return l.itemId === filters.selectedItemId; });
          }

          return {
            bills: validBills,
            lines: derivedLines,
            filters: filters
          };
        },

        renderResults: function(container, resultData, filters, viewId, drawer) {
          var lines = resultData.lines || [];
          var bills = resultData.bills || [];
          var groupBy = filters.groupBy || 'none';

          // Group by item
          var itemMap = {};
          lines.forEach(function(l) {
            var key = groupBy === 'cuisine' ? (l.cuisineId + '_' + l.itemId) :
                      groupBy === 'date' ? (l.date + '_' + l.itemId) : l.itemId;

            if (!itemMap[key]) {
              itemMap[key] = {
                key: key,
                itemId: l.itemId,
                code: (Mess.store && Mess.store.get('items', l.itemId) ? Mess.store.get('items', l.itemId).code : l.itemId),
                name: l.name,
                category: l.category,
                unit: l.unit,
                cuisineId: l.cuisineId,
                cuisineName: l.cuisineName,
                date: l.date,
                qtyB: 0,
                qtyL: 0,
                qtyD: 0,
                totalQty: 0
              };
            }
            var m = (l.mealCode || 'L').toUpperCase();
            if (m === 'B') itemMap[key].qtyB += l.qty;
            else if (m === 'L') itemMap[key].qtyL += l.qty;
            else if (m === 'D') itemMap[key].qtyD += l.qty;
            itemMap[key].totalQty += l.qty;
          });

          var aggregated = Object.values(itemMap);

          // Sort aggregated
          if (groupBy === 'cuisine') {
            aggregated.sort(function(a, b) {
              return (a.cuisineName || '').localeCompare(b.cuisineName || '') || a.name.localeCompare(b.name);
            });
          } else if (groupBy === 'date') {
            aggregated.sort(function(a, b) {
              return (a.date || '').localeCompare(b.date || '') || a.name.localeCompare(b.name);
            });
          } else {
            aggregated.sort(function(a, b) { return a.name.localeCompare(b.name); });
          }

          var grandB = 0, grandL = 0, grandD = 0, grandTotal = 0;
          aggregated.forEach(function(r) {
            grandB += r.qtyB;
            grandL += r.qtyL;
            grandD += r.qtyD;
            grandTotal += r.totalQty;
          });

          var rowsHtml = aggregated.map(function(r) {
            var groupPrefixTd = '';
            if (groupBy === 'cuisine') {
              groupPrefixTd = `<td style="padding: 10px 14px;"><span class="badge badge--neutral">${r.cuisineName}</span></td>`;
            } else if (groupBy === 'date') {
              groupPrefixTd = `<td style="padding: 10px 14px;" class="font-mono font-medium">${r.date}</td>`;
            }

            return `
              <tr class="item-movement-row" data-key="${r.key}" style="border-bottom: 1px solid var(--separator); cursor: pointer;">
                ${groupPrefixTd}
                <td style="padding: 10px 14px;" class="font-mono font-bold color-primary">${r.code}</td>
                <td style="padding: 10px 14px; font-weight: 500;">
                  <div>${r.name}</div>
                  <div class="text-xxs color-ink-3">${r.category || ''}</div>
                </td>
                <td style="padding: 10px 14px;" class="color-ink-2">${r.unit || 'Plate'}</td>
                <td style="padding: 10px 14px; text-align: right; color: var(--meal-b);" class="font-mono">${r.qtyB || '—'}</td>
                <td style="padding: 10px 14px; text-align: right; color: var(--meal-l);" class="font-mono">${r.qtyL || '—'}</td>
                <td style="padding: 10px 14px; text-align: right; color: var(--meal-d);" class="font-mono">${r.qtyD || '—'}</td>
                <td style="padding: 10px 14px; text-align: right;" class="font-mono font-bold">${r.totalQty}</td>
                <td style="padding: 10px 14px; text-align: right;">
                  <button type="button" class="btn btn--quiet btn--icon btn--xs" title="Drill into date breakdown">
                    <i data-lucide="chevron-right"></i>
                  </button>
                </td>
              </tr>
            `;
          }).join('');

          var groupHeaderTh = '';
          if (groupBy === 'cuisine') groupHeaderTh = '<th style="padding: 12px 14px; text-align: left; width: 140px;">Cuisine</th>';
          if (groupBy === 'date') groupHeaderTh = '<th style="padding: 12px 14px; text-align: left; width: 120px;">Date</th>';

          var colSpanTotal = groupBy === 'none' ? 3 : 4;

          container.innerHTML = `
            <div class="flex-col gap-sm" style="height: 100%; padding: 16px; overflow-y: auto;">
              <div class="flex-row justify-between align-center">
                <div class="text-xs color-ink-2">
                  Showing <strong>${aggregated.length}</strong> items across <strong>${bills.length}</strong> tokens · Click row to inspect date breakdown & chart
                </div>
                <div class="flex-row gap-xs text-xs">
                  <span class="badge badge--b">Breakfast</span>
                  <span class="badge badge--l">Lunch</span>
                  <span class="badge badge--d">Dinner</span>
                </div>
              </div>

              <div class="table-well" style="border: 1px solid var(--separator); border-radius: var(--radius-panel); overflow: hidden; background: var(--surface);">
                <table class="items-table" style="width: 100%; border-collapse: collapse; font-size: 13px;">
                  <thead>
                    <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator);">
                      ${groupHeaderTh}
                      <th style="padding: 12px 14px; text-align: left; width: 110px;">Item Code</th>
                      <th style="padding: 12px 14px; text-align: left;">Item Name</th>
                      <th style="padding: 12px 14px; text-align: left; width: 90px;">Unit</th>
                      <th style="padding: 12px 14px; text-align: right; width: 120px; color: var(--meal-b);">Breakfast Qty</th>
                      <th style="padding: 12px 14px; text-align: right; width: 120px; color: var(--meal-l);">Lunch Qty</th>
                      <th style="padding: 12px 14px; text-align: right; width: 120px; color: var(--meal-d);">Dinner Qty</th>
                      <th style="padding: 12px 14px; text-align: right; width: 130px;">Total Qty</th>
                      <th style="padding: 12px 14px; text-align: right; width: 60px;">Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    ${rowsHtml || `<tr><td colspan="${colSpanTotal + 5}" class="p-lg text-center color-ink-3">No movements found matching filters</td></tr>`}
                  </tbody>
                  <tfoot>
                    <tr style="background: var(--canvas); border-top: 2px solid var(--separator); font-size: 14px; font-weight: bold;">
                      <td colspan="${colSpanTotal}" style="padding: 12px 14px;">Grand Total Quantities</td>
                      <td style="padding: 12px 14px; text-align: right; color: var(--meal-b);" class="font-mono">${grandB}</td>
                      <td style="padding: 12px 14px; text-align: right; color: var(--meal-l);" class="font-mono">${grandL}</td>
                      <td style="padding: 12px 14px; text-align: right; color: var(--meal-d);" class="font-mono">${grandD}</td>
                      <td style="padding: 12px 14px; text-align: right; color: var(--primary);" class="font-mono">${grandTotal}</td>
                      <td></td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </div>
          `;

          // Bind row click for drill-down
          container.querySelectorAll('.item-movement-row').forEach(function(tr) {
            tr.addEventListener('click', function() {
              var key = tr.getAttribute('data-key');
              var found = itemMap[key];
              if (found) {
                openItemDrilldownDrawer(found, lines, bills, drawer);
              }
            });
          });
        },

        onExport: function(type, filename) {
          var filters = reportFrameInstance ? reportFrameInstance.filters : {};
          var validBills = Mess.reportHelpers.getValidBills(filters);
          var derivedLines = Mess.reportHelpers.getDerivedItemLines(validBills);

          if (filters.selectedItemId && filters.selectedItemId !== 'all') {
            derivedLines = derivedLines.filter(function(l) { return l.itemId === filters.selectedItemId; });
          }

          var itemMap = {};
          derivedLines.forEach(function(l) {
            if (!itemMap[l.itemId]) {
              itemMap[l.itemId] = {
                code: (Mess.store && Mess.store.get('items', l.itemId) ? Mess.store.get('items', l.itemId).code : l.itemId),
                name: l.name,
                unit: l.unit,
                qtyB: 0,
                qtyL: 0,
                qtyD: 0,
                totalQty: 0
              };
            }
            var m = (l.mealCode || 'L').toUpperCase();
            if (m === 'B') itemMap[l.itemId].qtyB += l.qty;
            else if (m === 'L') itemMap[l.itemId].qtyL += l.qty;
            else if (m === 'D') itemMap[l.itemId].qtyD += l.qty;
            itemMap[l.itemId].totalQty += l.qty;
          });

          var rows = Object.values(itemMap);

          if (type === 'csv') {
            // Strictly enforce '|' delimiter as per user rules!
            var headers = ['Item Code', 'Item Name', 'Unit', 'Breakfast Qty', 'Lunch Qty', 'Dinner Qty', 'Total Qty'];
            var csv = headers.join('|') + '\n';
            rows.forEach(function(r) {
              csv += `${r.code}|${r.name}|${r.unit}|${r.qtyB}|${r.qtyL}|${r.qtyD}|${r.totalQty}\n`;
            });
            var blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            var url = URL.createObjectURL(blob);
            var a = document.createElement('a');
            a.href = url;
            a.download = filename;
            a.click();
            URL.revokeObjectURL(url);
          } else if (type === 'xlsx' && window.XLSX) {
            var exportData = rows.map(function(r) {
              return {
                'Item Code': r.code,
                'Item Name': r.name,
                'Unit': r.unit,
                'Breakfast Qty': r.qtyB,
                'Lunch Qty': r.qtyL,
                'Dinner Qty': r.qtyD,
                'Total Qty': r.totalQty
              };
            });
            var ws = XLSX.utils.json_to_sheet(exportData);
            var wb = XLSX.utils.book_new();
            XLSX.utils.book_append_sheet(wb, ws, 'Item Movement');
            XLSX.writeFile(wb, filename);
          } else if (type === 'pdf' && window.jspdf) {
            var doc = new window.jspdf.jsPDF();
            doc.text('Item-wise Movement Report', 14, 15);
            var body = rows.map(function(r) {
              return [r.code, r.name, r.unit, r.qtyB, r.qtyL, r.qtyD, r.totalQty];
            });
            if (doc.autoTable) {
              doc.autoTable({
                head: [['Code', 'Name', 'Unit', 'B Qty', 'L Qty', 'D Qty', 'Total']],
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

          // Wire grouping segmented buttons
          var segButtons = rootEl.querySelectorAll('.filter-grouping-segmented button');
          segButtons.forEach(function(btn) {
            btn.addEventListener('click', function() {
              segButtons.forEach(function(b) { b.classList.remove('active'); });
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
