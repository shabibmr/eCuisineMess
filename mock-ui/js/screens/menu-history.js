/* menu-history.js - Screen 12: Daily Menu History (last 30 days archive & read-only viewer) */

window.Mess = window.Mess || {};

(function(Mess) {
  var frame = null;

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
    id: 'menu-history',
    route: '/menu-history',
    title: 'Daily Menu History',
    nav: { group: 'Operations', icon: 'history', order: 3 },
    roles: ['admin', 'supervisor'],

    template: function() {
      var today = getTodayIso();
      var thirtyDaysAgo = getDaysAgoIso(30);

      var cuisines = (Mess.store && Mess.store.list('cuisines')) || [];
      var cuisineOptions = cuisines.map(function(c) {
        return `<option value="${c.id}">${c.name}</option>`;
      }).join('');

      var filterSlotHtml = `
        <div class="flex-row gap-xs align-center">
          <label class="text-xs font-semibold color-ink-2">From</label>
          <input type="date" class="field-input history-from-date text-xs" value="${thirtyDaysAgo}" style="width: 130px; height: 32px;">
        </div>
        <div class="flex-row gap-xs align-center">
          <label class="text-xs font-semibold color-ink-2">To</label>
          <input type="date" class="field-input history-to-date text-xs" value="${today}" style="width: 130px; height: 32px;">
        </div>
        <div class="flex-row gap-xs align-center">
          <label class="text-xs font-semibold color-ink-2">Cuisine</label>
          <select class="field-select history-cuisine-filter text-xs" style="width: 140px; height: 32px;">
            <option value="all">All Cuisines</option>
            ${cuisineOptions}
          </select>
        </div>
      `;

      var columns = [
        {
          title: 'Date',
          field: 'date',
          width: 110,
          formatter: function(cell) {
            var val = cell.getValue();
            var formatted = Mess.format && Mess.format.date ? Mess.format.date(val) : val;
            return `<span class="font-mono font-bold text-xs">${formatted}</span>`;
          }
        },
        {
          title: 'Cuisine',
          field: 'cuisineName',
          formatter: function(cell) {
            var row = cell.getRow().getData();
            return `
              <div class="flex-row align-center gap-xs">
                <span class="font-mono text-xs color-ink-3">${row.cuisineCode || ''}</span>
                <span class="font-medium">${cell.getValue() || ''}</span>
              </div>
            `;
          }
        },
        {
          title: 'Breakfast',
          field: 'bCount',
          width: 110,
          hozAlign: 'center',
          headerHozAlign: 'center',
          formatter: function(cell) {
            var count = cell.getValue() || 0;
            return count > 0 
              ? `<span class="badge badge--b" style="font-size:11px;">${count} items</span>` 
              : '<span class="color-ink-3 text-xs">Empty</span>';
          }
        },
        {
          title: 'Lunch',
          field: 'lCount',
          width: 110,
          hozAlign: 'center',
          headerHozAlign: 'center',
          formatter: function(cell) {
            var count = cell.getValue() || 0;
            return count > 0 
              ? `<span class="badge badge--l" style="font-size:11px;">${count} items</span>` 
              : '<span class="color-ink-3 text-xs">Empty</span>';
          }
        },
        {
          title: 'Dinner',
          field: 'dCount',
          width: 110,
          hozAlign: 'center',
          headerHozAlign: 'center',
          formatter: function(cell) {
            var count = cell.getValue() || 0;
            return count > 0 
              ? `<span class="badge badge--d" style="font-size:11px;">${count} items</span>` 
              : '<span class="color-ink-3 text-xs">Empty</span>';
          }
        },
        {
          title: 'Saved By',
          field: 'savedBy',
          width: 110,
          formatter: function(cell) {
            return `<span class="text-xs color-ink-2">${cell.getValue() || 'admin'}</span>`;
          }
        },
        {
          title: 'Saved At',
          field: 'savedAt',
          width: 140,
          formatter: function(cell) {
            var val = cell.getValue();
            return `<span class="font-mono text-xs color-ink-3">${val || '—'}</span>`;
          }
        },
        {
          title: '',
          field: 'actions',
          width: 80,
          hozAlign: 'center',
          headerSort: false,
          formatter: function(cell) {
            var row = cell.getRow().getData();
            return `
              <a href="#/menu-editor?date=${row.date}&cuisine=${row.cuisineId}" class="btn btn--quiet btn--icon btn--xs" title="View history menu">
                <i data-lucide="eye"></i>
              </a>
            `;
          }
        }
      ];

      return /* html */ `
        <div class="menu-history-screen flex-col gap-md" style="height: 100%;">
          <div class="toolbar flex-row justify-between align-center">
            <div>
              <h2 style="margin: 0;">Daily Menu History</h2>
              <span class="text-sm color-ink-2">Archive of past daily menus across all cuisines</span>
            </div>
            <div class="flex-row gap-sm">
              <a href="#/menu-editor" class="btn btn--primary">
                <i data-lucide="plus"></i> Open Menu Editor
              </a>
            </div>
          </div>

          <div class="toolbar-filters card-inset flex-row gap-md wrap align-center" style="padding: 12px 16px; border-radius: var(--radius-panel); background: var(--surface);">
            <div style="flex: 1; max-width: 280px;">
              <input type="search" class="field-input history-search-input text-xs" placeholder="Search cuisine or saved by...">
            </div>
            ${filterSlotHtml}
            <div style="margin-left: auto;">
              <button type="button" class="btn btn--secondary history-export-btn">
                <i data-lucide="download"></i> Export ▾
              </button>
            </div>
          </div>

          <div class="history-grid-container table-well" style="flex: 1; min-height: 380px;"></div>

          <div class="history-footer flex-row justify-between align-center text-sm color-ink-2 pt-xs">
            <span class="history-count-text"></span>
          </div>
        </div>
      `;
    },

    component: function(params, targetEl) {
      return {
        init: function(el) {
          var rootEl = el || targetEl || document.getElementById('outlet');
          var gridHost = rootEl.querySelector('.history-grid-container');
          var fromInput = rootEl.querySelector('.history-from-date');
          var toInput = rootEl.querySelector('.history-to-date');
          var cuisineSelect = rootEl.querySelector('.history-cuisine-filter');
          var searchInput = rootEl.querySelector('.history-search-input');
          var countText = rootEl.querySelector('.history-count-text');
          var exportBtn = rootEl.querySelector('.history-export-btn');

          var allCuisines = (Mess.store && Mess.store.list('cuisines')) || [];
          var cuisineMap = {};
          allCuisines.forEach(function(c) { cuisineMap[c.id] = c; });

          function getAggregatedData() {
            var fromDate = fromInput.value;
            var toDate = toInput.value;
            var selectedCuis = cuisineSelect.value;
            var search = (searchInput.value || '').trim().toLowerCase();

            var allMenus = (Mess.store && Mess.store.list('menus')) || [];
            
            // Group menus by date + cuisineId
            var groups = {};
            allMenus.forEach(function(m) {
              if (m.date < fromDate || m.date > toDate) return;
              var cId = m.cuisine_id || m.cuisineId;
              if (selectedCuis !== 'all' && cId !== selectedCuis) return;

              var key = m.date + '_' + cId;
              if (!groups[key]) {
                var cObj = cuisineMap[cId] || { name: cId, code: '' };
                groups[key] = {
                  id: key,
                  date: m.date,
                  cuisineId: cId,
                  cuisineName: cObj.name,
                  cuisineCode: cObj.code,
                  bCount: 0,
                  lCount: 0,
                  dCount: 0,
                  savedBy: m.saved_by || m.savedBy || 'admin',
                  savedAt: m.saved_at || m.savedAt || ''
                };
              }

              var meal = (m.meal_type || m.meal || 'B').toUpperCase();
              var count = (m.items || []).length;
              if (meal === 'B') groups[key].bCount = count;
              if (meal === 'L') groups[key].lCount = count;
              if (meal === 'D') groups[key].dCount = count;
            });

            var rows = Object.values(groups);

            // Filter search text
            if (search) {
              rows = rows.filter(function(r) {
                return (r.cuisineName && r.cuisineName.toLowerCase().indexOf(search) !== -1) ||
                       (r.savedBy && r.savedBy.toLowerCase().indexOf(search) !== -1) ||
                       (r.date && r.date.indexOf(search) !== -1);
              });
            }

            // Sort descending by date
            rows.sort(function(a, b) {
              if (a.date !== b.date) return b.date.localeCompare(a.date);
              return a.cuisineName.localeCompare(b.cuisineName);
            });

            return rows;
          }

          var grid = null;

          function refresh() {
            var data = getAggregatedData();
            countText.textContent = `${data.length} menu records archived`;
            if (grid) {
              grid.setData(data);
            }
          }

          if (Mess.createDataGrid && gridHost) {
            grid = Mess.createDataGrid(gridHost, {
              data: getAggregatedData(),
              columns: [
                {
                  title: 'Date',
                  field: 'date',
                  width: 120,
                  formatter: function(cell) {
                    var val = cell.getValue();
                    var formatted = Mess.format && Mess.format.date ? Mess.format.date(val) : val;
                    return `<span class="font-mono font-bold text-xs">${formatted}</span>`;
                  }
                },
                {
                  title: 'Cuisine',
                  field: 'cuisineName',
                  formatter: function(cell) {
                    var row = cell.getRow().getData();
                    return `
                      <div class="flex-row align-center gap-xs">
                        <span class="font-mono text-xs color-ink-3">${row.cuisineCode || ''}</span>
                        <span class="font-medium">${cell.getValue() || ''}</span>
                      </div>
                    `;
                  }
                },
                {
                  title: 'Breakfast',
                  field: 'bCount',
                  width: 110,
                  hozAlign: 'center',
                  headerHozAlign: 'center',
                  formatter: function(cell) {
                    var count = cell.getValue() || 0;
                    return count > 0 
                      ? `<span class="badge badge--b" style="font-size:11px;">${count} items</span>` 
                      : '<span class="color-ink-3 text-xs">Empty</span>';
                  }
                },
                {
                  title: 'Lunch',
                  field: 'lCount',
                  width: 110,
                  hozAlign: 'center',
                  headerHozAlign: 'center',
                  formatter: function(cell) {
                    var count = cell.getValue() || 0;
                    return count > 0 
                      ? `<span class="badge badge--l" style="font-size:11px;">${count} items</span>` 
                      : '<span class="color-ink-3 text-xs">Empty</span>';
                  }
                },
                {
                  title: 'Dinner',
                  field: 'dCount',
                  width: 110,
                  hozAlign: 'center',
                  headerHozAlign: 'center',
                  formatter: function(cell) {
                    var count = cell.getValue() || 0;
                    return count > 0 
                      ? `<span class="badge badge--d" style="font-size:11px;">${count} items</span>` 
                      : '<span class="color-ink-3 text-xs">Empty</span>';
                  }
                },
                {
                  title: 'Saved By',
                  field: 'savedBy',
                  width: 110,
                  formatter: function(cell) {
                    return `<span class="text-xs color-ink-2">${cell.getValue() || 'admin'}</span>`;
                  }
                },
                {
                  title: 'Saved At',
                  field: 'savedAt',
                  width: 160,
                  formatter: function(cell) {
                    var val = cell.getValue();
                    return `<span class="font-mono text-xs color-ink-3">${val || '—'}</span>`;
                  }
                },
                {
                  title: '',
                  field: 'actions',
                  width: 80,
                  hozAlign: 'center',
                  headerSort: false,
                  formatter: function(cell) {
                    var row = cell.getRow().getData();
                    return `
                      <a href="#/menu-editor?date=${row.date}&cuisine=${row.cuisineId}" class="btn btn--quiet btn--icon btn--xs" title="View history menu">
                        <i data-lucide="eye"></i>
                      </a>
                    `;
                  }
                }
              ],
              onRowOpen: function(row) {
                window.location.hash = `#/menu-editor?date=${row.date}&cuisine=${row.cuisineId}`;
              }
            });

            refresh();
          }

          fromInput.addEventListener('change', refresh);
          toInput.addEventListener('change', refresh);
          cuisineSelect.addEventListener('change', refresh);
          searchInput.addEventListener('input', refresh);

          exportBtn.addEventListener('click', function() {
            if (grid && grid.downloadCSV) {
              grid.downloadCSV('menu-history-' + getTodayIso());
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
