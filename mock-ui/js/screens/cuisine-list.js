/* cuisine-list.js - Screen 4: Cuisine Master List View */

window.Mess = window.Mess || {};

(function(Mess) {
  var frame = null;

  Mess.screens.register({
    id: 'cuisines',
    route: '/cuisines',
    title: 'Cuisines',
    nav: { group: 'Masters', icon: 'compass', order: 20 },
    roles: ['admin', 'supervisor'],

    template: function() {
      var columns = [
        {
          title: 'Code',
          field: 'code',
          width: 120,
          formatter: function(cell) {
            var val = cell.getValue();
            var row = cell.getRow().getData();
            var dimmed = row.active === false ? 'opacity-50' : '';
            return `<span class="font-mono font-bold ${dimmed}">${val || ''}</span>`;
          }
        },
        {
          title: 'Cuisine Name',
          field: 'name',
          formatter: function(cell) {
            var val = cell.getValue();
            var row = cell.getRow().getData();
            var dimmed = row.active === false ? 'opacity-50' : '';
            return `<span class="font-medium ${dimmed}">${val || ''}</span>`;
          }
        },
        {
          title: 'Description',
          field: 'description',
          formatter: function(cell) {
            return `<span class="color-ink-2 text-sm">${cell.getValue() || '—'}</span>`;
          }
        },
        {
          title: 'Mapped Items',
          field: 'id',
          width: 140,
          hozAlign: 'right',
          headerHozAlign: 'right',
          formatter: function(cell) {
            var cuisineId = cell.getValue();
            var count = 0;
            if (Mess.store) {
              var mappings = Mess.store.list('cuisine_items') || [];
              count = mappings.filter(function(m) { return m.cuisine_id === cuisineId; }).length;
            }
            return `<span class="tabular-nums font-mono font-semibold">${count} items</span>`;
          }
        },
        {
          title: 'Active Members',
          field: 'id',
          width: 140,
          hozAlign: 'right',
          headerHozAlign: 'right',
          formatter: function(cell) {
            var cuisineId = cell.getValue();
            var count = 0;
            if (Mess.store) {
              var customers = Mess.store.list('customers') || [];
              count = customers.filter(function(c) { 
                return c.cuisine_id === cuisineId && c.active !== false; 
              }).length;
            }
            return `<span class="tabular-nums font-mono">${count} members</span>`;
          }
        },
        {
          title: 'Status',
          field: 'active',
          width: 110,
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
                <a href="#/cuisines/${row.id}" class="btn btn--quiet btn--icon btn--xs" title="Edit cuisine">
                  <i data-lucide="edit-2"></i>
                </a>
                <button type="button" class="btn btn--quiet btn--icon btn--xs btn-delete-cuisine" data-id="${row.id}" data-name="${row.name}" title="Delete cuisine">
                  <i data-lucide="trash-2"></i>
                </button>
              </div>
            `;
          }
        }
      ];

      frame = Mess.createListFrame({
        kind: 'cuisines',
        title: 'Cuisines',
        unitLabel: 'cuisines',
        newRoute: '#/cuisines/new',
        newText: '+ New Cuisine',
        searchPlaceholder: 'Search cuisines by code or name...',
        searchFields: ['code', 'name', 'description'],
        columns: columns,
        onRowOpen: function(item) {
          window.location.hash = '#/cuisines/' + item.id;
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
              var btn = e.target.closest('.btn-delete-cuisine');
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
