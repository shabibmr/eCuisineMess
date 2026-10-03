/* list-frame.js - Configurable List Screen Frame for Master Lists */

window.Mess = window.Mess || {};

(function(Mess) {
  Mess.createListFrame = function(config) {
    var kind = config.kind;
    var title = config.title || 'List';
    var newRoute = config.newRoute || '#/' + kind + '/new';
    var newText = config.newText || '+ New';
    var searchPlaceholder = config.searchPlaceholder || 'Search...';
    var searchFields = config.searchFields || ['code', 'name'];
    var filterSlot = config.filterSlotHtml || '';
    var columns = config.columns || [];
    var onRowOpen = config.onRowOpen || null;

    var grid = null;
    var showInactive = false;
    var searchTerm = '';
    var customFilterFn = config.customFilterFn || null;

    function getFilteredData() {
      var all = Mess.store ? Mess.store.list(kind) : [];
      return all.filter(function(row) {
        if (!showInactive && row.active === false) return false;
        
        if (searchTerm) {
          var term = searchTerm.toLowerCase();
          var match = searchFields.some(function(f) {
            return row[f] && String(row[f]).toLowerCase().indexOf(term) !== -1;
          });
          if (!match) return false;
        }

        if (typeof customFilterFn === 'function') {
          if (!customFilterFn(row)) return false;
        }

        return true;
      });
    }

    function updateFooterCounts(el) {
      var all = Mess.store ? Mess.store.list(kind) : [];
      var inactiveCount = all.filter(function(r) { return r.active === false; }).length;
      var footerEl = el.querySelector('.list-frame-footer-count');
      if (footerEl) {
        footerEl.textContent = all.length + ' ' + (config.unitLabel || 'records') + ' · ' + inactiveCount + ' inactive';
      }
    }

    function refresh() {
      if (grid) {
        grid.setData(getFilteredData());
      }
    }

    return {
      template: function() {
        return /* html */ `
          <div class="list-frame flex-col gap-md" style="height: 100%;">
            <div class="toolbar">
              <div class="toolbar-left">
                <h2>${title}</h2>
              </div>
              <div class="toolbar-right">
                <a href="${newRoute}" class="btn btn--primary">${newText}</a>
              </div>
            </div>

            <div class="toolbar-filters flex-row gap-md wrap align-center">
              <div style="flex: 1; max-width: 320px;">
                <input type="search" class="field-input search-input" placeholder="${searchPlaceholder}">
              </div>
              <label class="checkbox-label">
                <input type="checkbox" class="checkbox inactive-toggle">
                <span>Show inactive</span>
              </label>
              ${filterSlot}
              <div style="margin-left: auto;" class="flex-row gap-xs">
                <button type="button" class="btn btn--secondary export-btn" title="Export CSV / Excel">
                  <i data-lucide="download"></i> Export ▾
                </button>
              </div>
            </div>

            <div class="list-grid-container table-well" style="flex: 1; min-height: 380px;"></div>

            <div class="list-frame-footer flex-row justify-between align-center text-sm color-ink-2 pt-xs">
              <span class="list-frame-footer-count"></span>
            </div>
          </div>
        `;
      },

      init: function(rootEl) {
        var container = rootEl.querySelector('.list-grid-container');
        var searchInput = rootEl.querySelector('.search-input');
        var inactiveToggle = rootEl.querySelector('.inactive-toggle');
        var exportBtn = rootEl.querySelector('.export-btn');

        grid = Mess.createDataGrid(container, {
          data: getFilteredData(),
          columns: columns,
          downloadFileName: kind + '-register',
          onRowOpen: onRowOpen
        });

        updateFooterCounts(rootEl);

        // Debounced search (120ms)
        var debounceTimer = null;
        if (searchInput) {
          searchInput.addEventListener('input', function() {
            clearTimeout(debounceTimer);
            debounceTimer = setTimeout(function() {
              searchTerm = searchInput.value.trim();
              refresh();
            }, 120);
          });
        }

        if (inactiveToggle) {
          inactiveToggle.addEventListener('change', function() {
            showInactive = inactiveToggle.checked;
            refresh();
          });
        }

        if (exportBtn) {
          exportBtn.addEventListener('click', function() {
            if (grid) grid.downloadCSV();
          });
        }

        // Custom filter element hooks
        if (typeof config.onMountFilters === 'function') {
          config.onMountFilters(rootEl, function(fn) {
            customFilterFn = fn;
            refresh();
          });
        }
      },

      handleDeleteRecord: function(id, name, onDeleted) {
        var refs = Mess.store.refsOf(kind, id);
        if (refs.total > 0) {
          var details = [];
          if (refs.refCounts.cuisines) details.push(refs.refCounts.cuisines + ' cuisines');
          if (refs.refCounts.bills) details.push(refs.refCounts.bills + ' bills');
          if (refs.refCounts.members) details.push(refs.refCounts.members + ' members');
          if (refs.refCounts.menus) details.push(refs.refCounts.menus + ' menus');

          var msg = '<strong>' + (name || id) + '</strong> is used in ' + details.join(' and ') + '. ' +
                    'It cannot be deleted.<br><br>Would you like to mark it as <strong>inactive</strong> instead?';

          Mess.dialog.confirm('Cannot Delete', msg, {
            confirmText: 'Mark inactive',
            cancelText: 'Cancel'
          }).then(function(confirmed) {
            if (confirmed) {
              Mess.store.markInactive(kind, id);
              refresh();
              if (typeof onDeleted === 'function') onDeleted(false, true);
            }
          });
          return;
        }

        Mess.dialog.confirm('Delete Record', 'Are you sure you want to delete <strong>' + (name || id) + '</strong>?', {
          confirmText: 'Delete',
          danger: true
        }).then(function(confirmed) {
          if (confirmed) {
            Mess.store.remove(kind, id);
            refresh();
            if (typeof onDeleted === 'function') onDeleted(true, false);
          }
        });
      },

      refresh: refresh,

      destroy: function() {
        if (grid) {
          grid.destroy();
          grid = null;
        }
      }
    };
  };
})(window.Mess);
