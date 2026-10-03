/* bill-register.js - Screen 15: Mess Bill Register with Filters, Reprint DUPLICATE & Supervisor Cancel */

window.Mess = window.Mess || {};

(function(Mess) {
  var grid = null;

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
    return `${yyyy}-${mm}-${dd}`;
  }

  Mess.screens.register({
    id: 'bill-register',
    route: '/bills',
    title: 'Bill Register',
    nav: { group: 'Billing', icon: 'receipt', order: 10 },
    roles: ['admin', 'supervisor', 'counter'],

    template: function() {
      var today = getTodayIso();
      var sevenDaysAgo = getDaysAgoIso(7);

      var cuisines = (Mess.store && Mess.store.list('cuisines')) || [];
      var cuisineOptions = cuisines.map(function(c) {
        return `<option value="${c.id}">${c.name}</option>`;
      }).join('');

      return /* html */ `
        <div class="bill-register-screen flex-col gap-md" style="height: 100%;">
          <div class="toolbar flex-row justify-between align-center">
            <div>
              <h2 style="margin: 0;">Mess Bill Register</h2>
              <span class="text-sm color-ink-2">Audit issued tokens, reprints, cancellations and supervisor overrides</span>
            </div>
            <div class="flex-row gap-sm">
              <a href="#/counter" class="btn btn--primary">
                <i data-lucide="scan"></i> Go to Counter
              </a>
            </div>
          </div>

          <!-- Filter Bar -->
          <div class="toolbar-filters card-inset flex-row gap-md wrap align-center" style="padding: 12px 16px; border-radius: var(--radius-panel); background: var(--surface);">
            <div class="flex-row gap-xs align-center">
              <label class="text-xs font-semibold color-ink-2">From</label>
              <input type="date" class="field-input bills-from-date text-xs" value="${sevenDaysAgo}" style="width: 130px; height: 32px;">
            </div>

            <div class="flex-row gap-xs align-center">
              <label class="text-xs font-semibold color-ink-2">To</label>
              <input type="date" class="field-input bills-to-date text-xs" value="${today}" style="width: 130px; height: 32px;">
            </div>

            <div class="flex-row gap-xs align-center">
              <label class="text-xs font-semibold color-ink-2">Meal</label>
              <div class="segmented-control bills-meal-segmented" role="radiogroup" aria-label="Meal filter">
                <button type="button" class="active" data-meal="all">All</button>
                <button type="button" data-meal="B">B</button>
                <button type="button" data-meal="L">L</button>
                <button type="button" data-meal="D">D</button>
              </div>
            </div>

            <div class="flex-row gap-xs align-center">
              <label class="text-xs font-semibold color-ink-2">Cuisine</label>
              <select class="field-select bills-cuisine-select text-xs" style="width: 130px; height: 32px;">
                <option value="all">All Cuisines</option>
                ${cuisineOptions}
              </select>
            </div>

            <div style="flex: 1; min-width: 180px;">
              <input type="search" class="field-input bills-search-input text-xs" placeholder="Search token, member name, code...">
            </div>

            <div style="margin-left: auto;">
              <button type="button" class="btn btn--secondary bills-export-btn">
                <i data-lucide="download"></i> Export ▾
              </button>
            </div>
          </div>

          <!-- Tabulator Grid Host -->
          <div class="bills-grid-container table-well" style="flex: 1; min-height: 400px;"></div>

          <!-- Footer Count -->
          <div class="bills-footer flex-row justify-between align-center text-sm color-ink-2 pt-xs">
            <span class="bills-summary-count"></span>
          </div>
        </div>
      `;
    },

    component: function(params, targetEl) {
      return {
        init: function(el) {
          var rootEl = el || targetEl || document.getElementById('outlet');
          var gridHost = rootEl.querySelector('.bills-grid-container');
          var fromInput = rootEl.querySelector('.bills-from-date');
          var toInput = rootEl.querySelector('.bills-to-date');
          var mealButtons = rootEl.querySelectorAll('.bills-meal-segmented button');
          var cuisineSelect = rootEl.querySelector('.bills-cuisine-select');
          var searchInput = rootEl.querySelector('.bills-search-input');
          var exportBtn = rootEl.querySelector('.bills-export-btn');
          var summaryCount = rootEl.querySelector('.bills-summary-count');

          var selectedMeal = 'all';

          function getFilteredBills() {
            var from = fromInput.value;
            var to = toInput.value;
            var cuis = cuisineSelect.value;
            var search = (searchInput.value || '').trim().toLowerCase();

            var allBills = (Mess.store && Mess.store.list('bills')) || [];

            var filtered = allBills.filter(function(b) {
              if (b.date < from || b.date > to) return false;
              if (selectedMeal !== 'all' && (b.meal_code !== selectedMeal && b.meal !== selectedMeal)) return false;
              if (cuis !== 'all' && (b.cuisine_id !== cuis && b.cuisineId !== cuis)) return false;

              if (search) {
                var tok = (b.token_number || b.token_no || '').toLowerCase();
                var cName = (b.customer_name || '').toLowerCase();
                var cCode = (b.customer_code || '').toLowerCase();
                var uName = (b.user_name || '').toLowerCase();
                if (tok.indexOf(search) === -1 && cName.indexOf(search) === -1 && cCode.indexOf(search) === -1 && uName.indexOf(search) === -1) {
                  return false;
                }
              }
              return true;
            });

            // Sort descending by date & time
            filtered.sort(function(a, b) {
              if (a.date !== b.date) return b.date.localeCompare(a.date);
              return (b.time || '').localeCompare(a.time || '');
            });

            return filtered;
          }

          function viewBillSheet(bill) {
            var itemsHtml = (bill.items || []).map(function(it, idx) {
              return `
                <tr style="border-bottom: 1px solid var(--separator);">
                  <td style="padding: 6px 10px;">${idx + 1}</td>
                  <td style="padding: 6px 10px; font-weight: 500;">${it.name || it.item_name || 'Entitlement Item'}</td>
                  <td style="padding: 6px 10px; text-align: right;" class="font-mono">${it.qty || 1}</td>
                  <td style="padding: 6px 10px; text-align: right;" class="font-mono">0.00</td>
                </tr>
              `;
            }).join('');

            var content = document.createElement('div');
            content.className = 'flex-col gap-md';
            content.innerHTML = `
              <div class="flex-row justify-between align-center p-sm card-inset" style="background: var(--canvas); border-radius: var(--radius-sm);">
                <div class="flex-col">
                  <span class="text-xs color-ink-3">Token Number:</span>
                  <span class="font-mono text-xl font-bold color-primary">${bill.token_number || bill.token_no}</span>
                </div>
                <div class="flex-col align-end">
                  <span class="text-xs color-ink-3">${bill.date} ${bill.time || ''}</span>
                  <span class="badge badge--${(bill.meal_code || 'l').toLowerCase()}">${bill.meal_code === 'B' ? 'Breakfast' : bill.meal_code === 'L' ? 'Lunch' : 'Dinner'}</span>
                </div>
              </div>

              <div class="grid-2col gap-md text-xs">
                <div>
                  <span class="color-ink-3">Member:</span>
                  <div class="font-semibold text-sm">${bill.customer_name} (${bill.customer_code || 'M'})</div>
                </div>
                <div>
                  <span class="color-ink-3">Cuisine:</span>
                  <div class="font-semibold text-sm">${bill.cuisine_name || 'Standard'}</div>
                </div>
                <div>
                  <span class="color-ink-3">Issued By:</span>
                  <div class="font-mono">${bill.user_name || 'admin'} · Counter: ${bill.counter_id || 'C1'}</div>
                </div>
                <div>
                  <span class="color-ink-3">Status:</span>
                  <div>${bill.cancelled ? '<span class="badge badge--danger">Cancelled</span>' : '<span class="badge badge--success">Active</span>'}</div>
                </div>
              </div>

              ${bill.override ? `
                <div class="banner banner--warning flex-row align-center gap-xs p-xs text-xs" style="border-radius: var(--radius-sm);">
                  <i data-lucide="shield-alert"></i>
                  <span>Supervisor Override by <strong>${bill.supervisor || 'admin'}</strong>: ${bill.override_reason || 'Approved'}</span>
                </div>
              ` : ''}

              <div class="table-well" style="border: 1px solid var(--separator); border-radius: var(--radius-sm); max-height: 220px; overflow-y: auto;">
                <table style="width: 100%; border-collapse: collapse; font-size: 12px;">
                  <thead>
                    <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); text-align: left;">
                      <th style="padding: 6px 10px;">#</th>
                      <th style="padding: 6px 10px;">Item</th>
                      <th style="padding: 6px 10px; text-align: right;">Qty</th>
                      <th style="padding: 6px 10px; text-align: right;">Rate</th>
                    </tr>
                  </thead>
                  <tbody>${itemsHtml}</tbody>
                </table>
              </div>

              <div class="flex-row justify-between align-center pt-xs">
                <button type="button" class="btn btn--secondary btn--sm btn-sheet-reprint">
                  <i data-lucide="printer"></i> Reprint (DUPLICATE)
                </button>
                <button type="button" class="btn btn--quiet btn--sm btn-sheet-close">Close</button>
              </div>
            `;

            if (Mess.dialog && Mess.dialog.sheet) {
              Mess.dialog.sheet(`Bill Voucher – ${bill.token_number || bill.token_no}`, content, function(sheetEl, closeSheet) {
                var reprintBtn = content.querySelector('.btn-sheet-reprint');
                var closeBtn = content.querySelector('.btn-sheet-close');

                reprintBtn.addEventListener('click', function() {
                  closeSheet();
                  if (Mess.showTokenPreviewDialog) {
                    Mess.showTokenPreviewDialog(bill, { isDuplicate: true });
                  }
                });

                closeBtn.addEventListener('click', closeSheet);
              });
            }
          }

          function cancelBill(bill) {
            function proceedCancel() {
              Mess.dialog.prompt('Cancel Bill Voucher', 'Enter reason for cancellation (required):').then(function(reason) {
                if (reason && reason.trim()) {
                  bill.cancelled = true;
                  bill.cancelled_reason = reason.trim();
                  bill.cancelled_at = new Date().toISOString();
                  bill.cancelled_by = 'admin';

                  Mess.store.save('bills', bill);
                  if (Mess.persist && Mess.persist.saveCollection) {
                    Mess.persist.saveCollection('bills', Mess.store.list('bills'));
                  }

                  if (Mess.ui && Mess.ui.toast) {
                    Mess.ui.toast('success', `Bill ${bill.token_number || bill.token_no} cancelled.`);
                  }

                  refresh();
                }
              });
            }

            var currentRole = Mess.roles ? Mess.roles.getRole() : 'admin';
            if (currentRole === 'counter') {
              if (Mess.dialog && Mess.dialog.supervisorAuth) {
                Mess.dialog.supervisorAuth(function(authorized) {
                  if (authorized) proceedCancel();
                });
              }
            } else {
              proceedCancel();
            }
          }

          function refresh() {
            var data = getFilteredBills();
            var cancelledCount = data.filter(function(b) { return b.cancelled; }).length;
            summaryCount.textContent = `Showing ${data.length} bills · ${cancelledCount} cancelled`;

            if (grid) {
              grid.setData(data);
            }
          }

          var columns = [
            {
              title: 'Token No',
              field: 'token_number',
              width: 110,
              formatter: function(cell) {
                var row = cell.getRow().getData();
                var tok = cell.getValue() || row.token_no;
                var style = row.cancelled ? 'text-decoration: line-through; opacity: 0.6;' : 'font-weight: bold;';
                return `<span class="font-mono text-xs" style="${style}">${tok || ''}</span>`;
              }
            },
            {
              title: 'Date & Time',
              field: 'date',
              width: 140,
              formatter: function(cell) {
                var row = cell.getRow().getData();
                var formatted = Mess.format && Mess.format.date ? Mess.format.date(row.date) : row.date;
                return `<span class="font-mono text-xs">${formatted} <span class="color-ink-3">${row.time || ''}</span></span>`;
              }
            },
            {
              title: 'Member',
              field: 'customer_name',
              formatter: function(cell) {
                var row = cell.getRow().getData();
                var code = row.customer_code ? `<span class="font-mono text-xs color-ink-3">(${row.customer_code})</span>` : '';
                return `<span>${cell.getValue() || ''} ${code}</span>`;
              }
            },
            {
              title: 'Cuisine',
              field: 'cuisine_name',
              width: 120,
              formatter: function(cell) {
                return `<span class="text-xs badge badge--neutral">${cell.getValue() || 'Standard'}</span>`;
              }
            },
            {
              title: 'Meal',
              field: 'meal_code',
              width: 80,
              hozAlign: 'center',
              headerHozAlign: 'center',
              formatter: function(cell) {
                var val = (cell.getValue() || '').toLowerCase();
                return `<span class="badge badge--${val}" style="font-size:11px;">${(cell.getValue() || '').toUpperCase()}</span>`;
              }
            },
            {
              title: 'Items',
              field: 'items',
              width: 90,
              hozAlign: 'right',
              headerHozAlign: 'right',
              formatter: function(cell) {
                var items = cell.getValue() || [];
                return `<span class="font-mono text-xs">${items.length} item${items.length === 1 ? '' : 's'}</span>`;
              }
            },
            {
              title: 'Staff',
              field: 'user_name',
              width: 90,
              formatter: function(cell) {
                return `<span class="text-xs color-ink-2">${cell.getValue() || 'admin'}</span>`;
              }
            },
            {
              title: 'Override',
              field: 'override',
              width: 90,
              hozAlign: 'center',
              headerHozAlign: 'center',
              formatter: function(cell) {
                var row = cell.getRow().getData();
                if (row.override) {
                  return `<span class="badge badge--danger text-xs" title="Supervisor: ${row.supervisor || 'admin'} (${row.override_reason || ''})">Override</span>`;
                }
                return '<span class="color-ink-3">—</span>';
              }
            },
            {
              title: 'Status',
              field: 'cancelled',
              width: 90,
              hozAlign: 'center',
              headerHozAlign: 'center',
              formatter: function(cell) {
                return cell.getValue()
                  ? '<span class="badge badge--danger" style="font-size:10px;">Cancelled</span>'
                  : '<span class="badge badge--success" style="font-size:10px;">Active</span>';
              }
            },
            {
              title: '',
              field: 'actions',
              width: 100,
              hozAlign: 'right',
              headerSort: false,
              formatter: function(cell) {
                var row = cell.getRow().getData();
                return `
                  <div class="flex-row gap-xs justify-end action-cell">
                    <button type="button" class="btn btn--quiet btn--icon btn--xs btn-view-bill" title="View Bill" data-id="${row.id}">
                      <i data-lucide="eye"></i>
                    </button>
                    <button type="button" class="btn btn--quiet btn--icon btn--xs btn-reprint-bill" title="Reprint Token (DUPLICATE)" data-id="${row.id}">
                      <i data-lucide="printer"></i>
                    </button>
                    ${!row.cancelled ? `
                      <button type="button" class="btn btn--quiet btn--icon btn--xs btn-cancel-bill" title="Cancel Bill" data-id="${row.id}">
                        <i data-lucide="ban"></i>
                      </button>
                    ` : ''}
                  </div>
                `;
              }
            }
          ];

          if (Mess.createDataGrid && gridHost) {
            grid = Mess.createDataGrid(gridHost, {
              data: getFilteredBills(),
              columns: columns,
              paginationSize: 50,
              onRowOpen: function(row) {
                viewBillSheet(row);
              }
            });

            refresh();

            // Bind click delegation for row actions
            gridHost.addEventListener('click', function(e) {
              var allBills = Mess.store.list('bills') || [];

              var viewBtn = e.target.closest('.btn-view-bill');
              if (viewBtn) {
                e.stopPropagation();
                var b = allBills.find(function(it) { return it.id === viewBtn.getAttribute('data-id'); });
                if (b) viewBillSheet(b);
                return;
              }

              var reprintBtn = e.target.closest('.btn-reprint-bill');
              if (reprintBtn) {
                e.stopPropagation();
                var b = allBills.find(function(it) { return it.id === reprintBtn.getAttribute('data-id'); });
                if (b && Mess.showTokenPreviewDialog) {
                  Mess.showTokenPreviewDialog(b, { isDuplicate: true });
                }
                return;
              }

              var cancelBtn = e.target.closest('.btn-cancel-bill');
              if (cancelBtn) {
                e.stopPropagation();
                var b = allBills.find(function(it) { return it.id === cancelBtn.getAttribute('data-id'); });
                if (b) cancelBill(b);
                return;
              }
            });
          }

          // Meal filter buttons
          mealButtons.forEach(function(btn) {
            btn.addEventListener('click', function() {
              mealButtons.forEach(function(b) { b.classList.remove('active'); });
              btn.classList.add('active');
              selectedMeal = btn.getAttribute('data-meal');
              refresh();
            });
          });

          fromInput.addEventListener('change', refresh);
          toInput.addEventListener('change', refresh);
          cuisineSelect.addEventListener('change', refresh);
          searchInput.addEventListener('input', refresh);

          exportBtn.addEventListener('click', function() {
            if (grid && grid.downloadCSV) {
              grid.downloadCSV('mess-bills-' + getTodayIso());
            }
          });
        },

        destroy: function() {
          if (grid) {
            grid.destroy();
            grid = null;
          }
        }
      };
    }
  });
})(window.Mess);
