/* item-list.js - Screen 1: Item Master List View */

window.Mess = window.Mess || {};

(function(Mess) {
  var frame = null;

  Mess.screens.register({
    id: 'items',
    route: '/items',
    title: 'Items',
    nav: { group: 'Masters', icon: 'utensils', order: 10 },
    roles: ['admin', 'supervisor'],

    template: function() {
      // Gather distinct categories
      var items = (Mess.store && Mess.store.list('items')) || [];
      var cats = Array.from(new Set(items.map(function(i) { return i.category; }).filter(Boolean))).sort();

      var catOptions = cats.map(function(c) {
        return `<option value="${c}">${c}</option>`;
      }).join('');

      var filterSlotHtml = `
        <div class="flex-row gap-xs align-center">
          <label class="text-xs font-semibold color-ink-2">Category</label>
          <select class="field-select filter-item-category text-xs" style="width: 140px; height: 32px;">
            <option value="all">All Categories</option>
            ${catOptions}
          </select>
        </div>
      `;

      var columns = [
        {
          title: 'Code',
          field: 'code',
          width: 110,
          formatter: function(cell) {
            var val = cell.getValue();
            var row = cell.getRow().getData();
            var dimmed = row.active === false ? 'opacity-50' : '';
            return `<span class="font-mono font-bold ${dimmed}">${val || ''}</span>`;
          }
        },
        {
          title: 'Item Name',
          field: 'name',
          formatter: function(cell) {
            var val = cell.getValue();
            var row = cell.getRow().getData();
            var dimmed = row.active === false ? 'opacity-50' : '';
            return `<span class="font-medium ${dimmed}">${val || ''}</span>`;
          }
        },
        {
          title: 'Category',
          field: 'category',
          width: 130,
          formatter: function(cell) {
            var val = cell.getValue();
            return val ? `<span class="badge badge--neutral">${val}</span>` : '—';
          }
        },
        {
          title: 'Unit',
          field: 'unit',
          width: 90,
          formatter: function(cell) {
            return cell.getValue() || 'pcs';
          }
        },
        {
          title: 'Default Qty',
          field: 'default_qty',
          width: 110,
          hozAlign: 'right',
          headerHozAlign: 'right',
          formatter: function(cell) {
            return `<span class="tabular-nums font-mono">${cell.getValue() != null ? cell.getValue() : 1}</span>`;
          }
        },
        {
          title: 'Status',
          field: 'active',
          width: 100,
          hozAlign: 'center',
          headerHozAlign: 'center',
          formatter: function(cell) {
            var active = cell.getValue() !== false;
            return active 
              ? '<span class="badge badge--success" style="font-size:11px;">Active</span>' 
              : '<span class="badge badge--danger" style="font-size:11px;">Inactive</span>';
          }
        },
        {
          title: '',
          field: 'actions',
          width: 90,
          hozAlign: 'right',
          headerSort: false,
          formatter: function(cell) {
            var row = cell.getRow().getData();
            return `
              <div class="flex-row gap-xs justify-end action-cell">
                <a href="#/items/${row.id}" class="btn btn--quiet btn--icon btn--xs" title="Edit item">
                  <i data-lucide="edit-2"></i>
                </a>
                <button type="button" class="btn btn--quiet btn--icon btn--xs btn-delete-item" data-id="${row.id}" data-name="${row.name}" title="Delete item">
                  <i data-lucide="trash-2"></i>
                </button>
              </div>
            `;
          }
        }
      ];

      frame = Mess.createListFrame({
        kind: 'items',
        title: 'Items',
        unitLabel: 'items',
        newRoute: '#/items/new',
        newText: '+ New Item',
        searchPlaceholder: 'Search items by code or name...',
        searchFields: ['code', 'name', 'category'],
        filterSlotHtml: filterSlotHtml,
        columns: columns,
        onRowOpen: function(item) {
          window.location.hash = '#/items/' + item.id;
        },
        onMountFilters: function(rootEl, setFilterFn) {
          var select = rootEl.querySelector('.filter-item-category');
          if (select) {
            select.addEventListener('change', function() {
              var cat = select.value;
              if (cat === 'all') {
                setFilterFn(null);
              } else {
                setFilterFn(function(row) {
                  return row.category === cat;
                });
              }
            });
          }
        }
      });

      return frame.template();
    },

    component: function(params, targetEl) {
      return {
        init: function(el) {
          var rootEl = el || targetEl || document.getElementById('outlet');
          if (frame && rootEl) {
            frame.init(rootEl);

            // Bind click delegation for delete buttons
            rootEl.addEventListener('click', function(e) {
              var btn = e.target.closest('.btn-delete-item');
              if (btn) {
                e.stopPropagation();
                var id = btn.getAttribute('data-id');
                var name = btn.getAttribute('data-name');
                frame.handleDeleteRecord(id, name);
              }
            });
          }
        },
        destroy: function() {
          if (frame) {
            frame.destroy();
            frame = null;
          }
        }
      };
    }
  });
})(window.Mess);
