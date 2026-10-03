/* report-members.js - Screen 16: Members Register Report */

window.Mess = window.Mess || {};

(function(Mess) {
  var report = null;

  function getDaysDiff(fromIso, toIso) {
    if (!toIso) return null;
    var d1 = new Date(fromIso);
    var d2 = new Date(toIso);
    var diffTime = d2.getTime() - d1.getTime();
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }

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

  Mess.screens.register({
    id: 'report-members',
    route: '/reports/members',
    title: 'Members Register Report',
    nav: { group: 'Reports', icon: 'file-text', order: 10 },
    roles: ['admin', 'supervisor'],

    template: function() {
      var extraFiltersHtml = `
        <div class="flex-row gap-xs align-center">
          <label class="text-xs font-semibold color-ink-2">Status</label>
          <select class="field-select filter-member-status text-xs" style="width: 140px; height: 32px;">
            <option value="all">All Members</option>
            <option value="active">Active Only</option>
            <option value="expiring">Expiring Soon</option>
            <option value="expired">Expired</option>
            <option value="inactive">Inactive</option>
          </select>
        </div>

        <div class="flex-row gap-xs align-center filter-expiring-days-wrapper" style="display:none;">
          <label class="text-xs font-semibold color-ink-2">Within</label>
          <input type="number" class="field-input filter-expiring-days text-center font-mono text-xs" value="7" min="1" max="90" style="width: 55px; height: 32px;">
          <span class="text-xs color-ink-3">days</span>
        </div>
      `;

      var columns = [
        {
          title: 'Member Code',
          field: 'code',
          width: 110,
          formatter: function(cell) {
            return `<span class="font-mono font-bold">${cell.getValue() || ''}</span>`;
          }
        },
        {
          title: 'Full Name',
          field: 'name',
          formatter: function(cell) {
            return `<span class="font-medium">${cell.getValue() || ''}</span>`;
          }
        },
        {
          title: 'Phone',
          field: 'phone',
          width: 130,
          formatter: function(cell) {
            return `<span class="font-mono text-xs">${cell.getValue() || '—'}</span>`;
          }
        },
        {
          title: 'RFID (Masked)',
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
          field: 'cuisineName',
          width: 130,
          formatter: function(cell) {
            return `<span class="badge badge--neutral text-xs">${cell.getValue() || 'Standard'}</span>`;
          }
        },
        {
          title: 'Valid From',
          field: 'valid_from',
          width: 110,
          formatter: function(cell) {
            var val = cell.getValue();
            return `<span class="font-mono text-xs">${Mess.format && Mess.format.date ? Mess.format.date(val) : val}</span>`;
          }
        },
        {
          title: 'Valid To',
          field: 'valid_to',
          width: 110,
          formatter: function(cell) {
            var val = cell.getValue();
            return `<span class="font-mono text-xs">${Mess.format && Mess.format.date ? Mess.format.date(val) : val}</span>`;
          }
        },
        {
          title: 'Days Left',
          field: 'daysLeft',
          width: 100,
          hozAlign: 'right',
          headerHozAlign: 'right',
          formatter: function(cell) {
            var row = cell.getRow().getData();
            if (row.active === false) return '<span class="color-ink-3">—</span>';
            var val = cell.getValue();
            if (val == null) return '—';
            if (val < 0) {
              return `<span class="font-mono font-bold color-danger">${val} d</span>`;
            } else if (val <= 7) {
              return `<span class="font-mono font-bold color-warning">${val} d</span>`;
            }
            return `<span class="font-mono">${val} d</span>`;
          }
        },
        {
          title: 'Status',
          field: 'status',
          width: 100,
          hozAlign: 'center',
          headerHozAlign: 'center',
          formatter: function(cell) {
            var s = cell.getValue();
            if (s === 'Active') return '<span class="badge badge--success" style="font-size:10px;">Active</span>';
            if (s === 'Expiring') return '<span class="badge badge--warning" style="font-size:10px;">Expiring</span>';
            if (s === 'Expired') return '<span class="badge badge--danger" style="font-size:10px;">Expired</span>';
            return '<span class="badge badge--neutral" style="font-size:10px;">Inactive</span>';
          }
        }
      ];

      report = Mess.createReportFrame({
        title: 'Members Register Report',
        subtitle: 'Complete roster of enrolled members, card numbers, validity horizons, and cuisine subscriptions',
        extraFiltersHtml: extraFiltersHtml,
        columns: columns,

        readExtraFilters: function(rootEl) {
          var statusSelect = rootEl.querySelector('.filter-member-status');
          var daysInput = rootEl.querySelector('.filter-expiring-days');
          return {
            memberStatus: statusSelect ? statusSelect.value : 'all',
            expiringDays: daysInput ? (parseInt(daysInput.value, 10) || 7) : 7
          };
        },

        onGenerate: function(filters) {
          var allCustomers = (Mess.store && Mess.store.list('customers')) || [];
          var allCuisines = (Mess.store && Mess.store.list('cuisines')) || [];
          var cuisineMap = {};
          allCuisines.forEach(function(c) { cuisineMap[c.id] = c.name; });

          var today = getTodayIso();
          var statusFilter = filters.memberStatus || 'all';
          var expDays = filters.expiringDays || 7;
          var selectedCuisine = filters.cuisineId;

          var rows = [];

          allCustomers.forEach(function(c) {
            var cId = c.cuisine_id || c.cuisineId;
            if (selectedCuisine && selectedCuisine !== 'all' && cId !== selectedCuisine) {
              return;
            }

            var daysLeft = getDaysDiff(today, c.valid_to);
            var status = 'Active';
            if (c.active === false) {
              status = 'Inactive';
            } else if (daysLeft < 0) {
              status = 'Expired';
            } else if (daysLeft <= expDays) {
              status = 'Expiring';
            }

            if (statusFilter === 'active' && (status === 'Expired' || status === 'Inactive')) return;
            if (statusFilter === 'expiring' && status !== 'Expiring') return;
            if (statusFilter === 'expired' && status !== 'Expired') return;
            if (statusFilter === 'inactive' && status !== 'Inactive') return;

            rows.push({
              id: c.id,
              code: c.code,
              name: c.name,
              phone: c.phone,
              rfid: c.rfid,
              cuisineId: cId,
              cuisineName: cuisineMap[cId] || 'Standard',
              valid_from: c.valid_from,
              valid_to: c.valid_to,
              daysLeft: daysLeft,
              status: status,
              active: c.active
            });
          });

          // Sort by days left ascending, then name
          rows.sort(function(a, b) {
            if (a.daysLeft !== b.daysLeft) return (a.daysLeft || 0) - (b.daysLeft || 0);
            return a.name.localeCompare(b.name);
          });

          return rows;
        }
      });

      return report.template();
    },

    component: function(params, targetEl) {
      return {
        init: function(el) {
          var rootEl = el || targetEl || document.getElementById('outlet');
          if (report && rootEl) {
            report.init(rootEl);

            var statusSelect = rootEl.querySelector('.filter-member-status');
            var expiringWrapper = rootEl.querySelector('.filter-expiring-days-wrapper');
            if (statusSelect && expiringWrapper) {
              statusSelect.addEventListener('change', function() {
                expiringWrapper.style.display = statusSelect.value === 'expiring' ? 'flex' : 'none';
              });
            }
          }
        },
        destroy: function() {
          if (report) {
            report.destroy();
            report = null;
          }
        }
      };
    }
  });
})(window.Mess);
