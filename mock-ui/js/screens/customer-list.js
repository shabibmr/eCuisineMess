/* customer-list.js - Screen 7: Customer Master List View (labelled Members) */

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

  function getDaysDiff(fromIso, toIso) {
    if (!toIso) return null;
    var d1 = new Date(fromIso);
    var d2 = new Date(toIso);
    var diffTime = d2.getTime() - d1.getTime();
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }

  Mess.screens.register({
    id: 'customers',
    route: '/customers',
    title: 'Members',
    nav: { group: 'Masters', icon: 'users', order: 30 },
    roles: ['admin', 'supervisor'],

    template: function() {
      var cuisines = (Mess.store && Mess.store.list('cuisines')) || [];
      var cuisineOptions = cuisines.map(function(c) {
        return `<option value="${c.id}">${c.name}</option>`;
      }).join('');

      var filterSlotHtml = `
        <div class="flex-row gap-xs align-center">
          <label class="text-xs font-semibold color-ink-2">Cuisine</label>
          <select class="field-select filter-member-cuisine text-xs" style="width: 130px; height: 32px;">
            <option value="all">All Cuisines</option>
            ${cuisineOptions}
          </select>
        </div>

        <div class="flex-row gap-xs align-center">
          <label class="text-xs font-semibold color-ink-2">Validity</label>
          <select class="field-select filter-member-validity text-xs" style="width: 140px; height: 32px;">
            <option value="all">All Status</option>
            <option value="active">Active & Valid</option>
            <option value="expiring">Expiring in 7 days</option>
            <option value="expired">Expired</option>
          </select>
        </div>
      `;

      var columns = [
        {
          title: '',
          field: 'photo',
          width: 52,
          hozAlign: 'center',
          headerSort: false,
          formatter: function(cell) {
            var row = cell.getRow().getData();
            var src = row.photo;
            if (!src && row.name) {
              var initials = row.name.split(' ').map(function(p) { return p[0]; }).join('').slice(0, 2).toUpperCase();
              return `<div class="avatar avatar--initials" style="width:32px; height:32px; font-size:12px; line-height:32px;">${initials}</div>`;
            }
            return `<img src="${src || ''}" class="avatar" style="width:32px; height:32px; object-fit:cover;" alt="${row.name || ''}">`;
          }
        },
        {
          title: 'Code',
          field: 'code',
          width: 100,
          formatter: function(cell) {
            var val = cell.getValue();
            var row = cell.getRow().getData();
            var dimmed = row.active === false ? 'opacity-50' : '';
            return `<span class="font-mono font-bold ${dimmed}">${val || ''}</span>`;
          }
        },
        {
          title: 'Member Name',
          field: 'name',
          formatter: function(cell) {
            var val = cell.getValue();
            var row = cell.getRow().getData();
            var dimmed = row.active === false ? 'opacity-50' : '';
            return `<span class="font-medium ${dimmed}">${val || ''}</span>`;
          }
        },
        {
          title: 'Phone',
          field: 'phone',
          width: 130,
          formatter: function(cell) {
            return `<span class="font-mono text-sm">${cell.getValue() || '—'}</span>`;
          }
        },
        {
          title: 'RFID Card',
          field: 'rfid',
          width: 120,
          formatter: function(cell) {
            var val = cell.getValue();
            if (!val) return '<span class="color-ink-3">Unassigned</span>';
            var masked = Mess.format && Mess.format.maskRfid ? Mess.format.maskRfid(val) : ('••••••' + val.slice(-4));
            return `<span class="font-mono text-xs">${masked}</span>`;
          }
        },
        {
          title: 'Cuisine',
          field: 'cuisine_name',
          width: 130,
          formatter: function(cell) {
            var val = cell.getValue();
            var row = cell.getRow().getData();
            if (!val && row.cuisine_id && Mess.store) {
              var c = Mess.store.get('cuisines', row.cuisine_id);
              val = c ? c.name : '—';
            }
            return `<span class="badge badge--neutral text-xs">${val || '—'}</span>`;
          }
        },
        {
          title: 'Valid To',
          field: 'valid_to',
          width: 110,
          formatter: function(cell) {
            var val = cell.getValue();
            var formatted = Mess.format && Mess.format.date ? Mess.format.date(val) : val;
            return `<span class="font-mono text-xs">${formatted || '—'}</span>`;
          }
        },
        {
          title: 'Validity',
          field: 'valid_to',
          width: 120,
          formatter: function(cell) {
            var val = cell.getValue();
            var row = cell.getRow().getData();
            if (row.active === false) {
              return '<span class="badge badge--neutral" style="font-size:10px;">Inactive</span>';
            }
            if (!val) return '—';
            var today = getTodayIso();
            var diff = getDaysDiff(today, val);

            if (diff < 0) {
              return '<span class="badge badge--danger" style="font-size:10px;">Expired</span>';
            } else if (diff <= 7) {
              return `<span class="badge badge--warning" style="font-size:10px;">${diff} day${diff === 1 ? '' : 's'} left</span>`;
            } else {
              return `<span class="badge badge--success" style="font-size:10px;">${diff} days left</span>`;
            }
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
                <a href="#/customers/${row.id}" class="btn btn--quiet btn--icon btn--xs" title="Edit member">
                  <i data-lucide="edit-2"></i>
                </a>
                <button type="button" class="btn btn--quiet btn--icon btn--xs btn-delete-customer" data-id="${row.id}" data-name="${row.name}" title="Delete member">
                  <i data-lucide="trash-2"></i>
                </button>
              </div>
            `;
          }
        }
      ];

      var selectedCuisine = 'all';
      var selectedValidity = 'all';

      frame = Mess.createListFrame({
        kind: 'customers',
        title: 'Members',
        unitLabel: 'members',
        newRoute: '#/customers/new',
        newText: '+ New Member',
        searchPlaceholder: 'Search members by code, name, phone, RFID...',
        searchFields: ['code', 'name', 'phone', 'rfid'],
        filterSlotHtml: filterSlotHtml,
        columns: columns,
        onRowOpen: function(item) {
          window.location.hash = '#/customers/' + item.id;
        },
        onMountFilters: function(rootEl, setFilterFn) {
          var cuisineSelect = rootEl.querySelector('.filter-member-cuisine');
          var validitySelect = rootEl.querySelector('.filter-member-validity');

          function applyCombinedFilter() {
            var today = getTodayIso();
            setFilterFn(function(row) {
              if (selectedCuisine !== 'all' && row.cuisine_id !== selectedCuisine) {
                return false;
              }
              if (selectedValidity === 'active') {
                if (!row.valid_to || getDaysDiff(today, row.valid_to) < 0 || row.active === false) return false;
              } else if (selectedValidity === 'expiring') {
                var diff = getDaysDiff(today, row.valid_to);
                if (diff < 0 || diff > 7 || row.active === false) return false;
              } else if (selectedValidity === 'expired') {
                var diff = getDaysDiff(today, row.valid_to);
                if (diff >= 0) return false;
              }
              return true;
            });
          }

          if (cuisineSelect) {
            cuisineSelect.addEventListener('change', function() {
              selectedCuisine = cuisineSelect.value;
              applyCombinedFilter();
            });
          }

          if (validitySelect) {
            validitySelect.addEventListener('change', function() {
              selectedValidity = validitySelect.value;
              applyCombinedFilter();
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
              var btn = e.target.closest('.btn-delete-customer');
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
