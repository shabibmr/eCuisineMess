/* token-preview.js - Screen 14: Token Print Layout Preview route */

window.Mess = window.Mess || {};

(function(Mess) {
  var selectedWidth = '80mm';
  var isDuplicate = false;
  var currentBill = null;

  Mess.screens.register({
    id: 'token-preview',
    route: '/token-preview',
    title: 'Token Print Preview',
    nav: { group: 'Operations', icon: 'printer', order: 80 },
    roles: ['admin', 'supervisor', 'counter'],

    template: function(params) {
      var query = (Mess.router && Mess.router.getQuery) ? Mess.router.getQuery() : {};
      var allBills = (Mess.store && Mess.store.list('bills')) || [];

      // Pick bill from query or default to latest non-cancelled bill
      var billId = (params && (params.id || params.voucher)) || query.bill || query.token;
      if (billId) {
        currentBill = allBills.find(function(b) {
          return b.id === billId || b.token_number === billId || b.token_no === billId;
        });
      }
      if (!currentBill && allBills.length > 0) {
        currentBill = allBills[allBills.length - 1];
      }

      var recentBills = allBills.slice(-15).reverse();

      return /* html */ `
        <div class="token-preview-screen flex-col gap-lg" style="max-width: 800px; margin: 0 auto; height: 100%;">
          <header class="flex-row justify-between align-center wrap gap-sm">
            <div>
              <h2 style="margin: 0;">Mess Token (KOT) Print Layout</h2>
              <span class="text-sm color-ink-2">Thermal printer layout conforming to Section 14 specification</span>
            </div>
            <div class="flex-row gap-sm">
              <a href="#/bills" class="btn btn--secondary">
                <i data-lucide="arrow-left"></i> Back to Bills
              </a>
              <button type="button" class="btn btn--primary btn-print-token">
                <i data-lucide="printer"></i> Print Token Now
              </button>
            </div>
          </header>

          <!-- Controls Toolbar Card -->
          <div class="card flex-row justify-between align-center wrap gap-md p-md" style="background: var(--surface);">
            <!-- Choose Bill Selector -->
            <div class="flex-row align-center gap-xs" style="flex: 1; min-width: 240px;">
              <label class="text-xs font-semibold color-ink-2">Select Bill:</label>
              <select class="field-select select-preview-bill text-xs" style="flex: 1;">
                ${recentBills.map(function(b) {
                  var tok = b.token_number || b.token_no || b.id;
                  var sel = (currentBill && currentBill.id === b.id) ? 'selected' : '';
                  return `<option value="${b.id}" ${sel}>${tok} – ${b.customer_name || ''} (${b.date} ${b.time || ''})</option>`;
                }).join('')}
              </select>
            </div>

            <!-- Width Toggle -->
            <div class="flex-row align-center gap-xs">
              <label class="text-xs font-semibold color-ink-2">Width:</label>
              <div class="segmented-control width-toggle-segmented" role="radiogroup" aria-label="Paper width">
                <button type="button" class="${selectedWidth === '80mm' ? 'active' : ''}" data-w="80mm">80 mm</button>
                <button type="button" class="${selectedWidth === '58mm' ? 'active' : ''}" data-w="58mm">58 mm</button>
              </div>
            </div>

            <!-- Duplicate Watermark Switch -->
            <label class="switch-label flex-row align-center gap-xs text-xs font-semibold" style="cursor: pointer;">
              <input type="checkbox" class="switch duplicate-switch" ${isDuplicate ? 'checked' : ''}>
              <span>DUPLICATE Watermark</span>
            </label>
          </div>

          <!-- Paper Canvas Target Card -->
          <div class="card flex-col align-center justify-center p-xl card-inset" 
               style="flex: 1; background: #525252; min-height: 480px; overflow-y: auto; border-radius: var(--radius-panel);">
            <div class="token-paper-wrapper" style="box-shadow: 0 10px 25px rgba(0,0,0,0.5); border-radius: 4px; overflow: hidden;">
              <!-- Rendered dynamically -->
            </div>
          </div>
        </div>
      `;
    },

    component: function(params, targetEl) {
      return {
        init: function(el) {
          var rootEl = el || targetEl || document.getElementById('outlet');
          var paperWrapper = rootEl.querySelector('.token-paper-wrapper');
          var printBtn = rootEl.querySelector('.btn-print-token');
          var billSelect = rootEl.querySelector('.select-preview-bill');
          var widthButtons = rootEl.querySelectorAll('.width-toggle-segmented button');
          var dupSwitch = rootEl.querySelector('.duplicate-switch');

          var allBills = (Mess.store && Mess.store.list('bills')) || [];

          function renderSlip() {
            if (!currentBill) {
              paperWrapper.innerHTML = '<div style="background:#fff; padding:24px; color:#000;">No bill selected.</div>';
              return;
            }

            var html = Mess.renderTokenSlipHtml ? Mess.renderTokenSlipHtml(currentBill, {
              width: selectedWidth,
              isDuplicate: isDuplicate
            }) : `<div style="background:#fff; padding:20px; font-family:monospace; color:#000;">Token: ${currentBill.token_number}</div>`;

            paperWrapper.innerHTML = html;
          }

          // Width switcher
          widthButtons.forEach(function(btn) {
            btn.addEventListener('click', function() {
              widthButtons.forEach(function(b) { b.classList.remove('active'); });
              btn.classList.add('active');
              selectedWidth = btn.getAttribute('data-w');
              renderSlip();
            });
          });

          // Duplicate toggle
          dupSwitch.addEventListener('change', function() {
            isDuplicate = dupSwitch.checked;
            renderSlip();
          });

          // Select bill dropdown
          billSelect.addEventListener('change', function() {
            var bId = billSelect.value;
            currentBill = allBills.find(function(b) { return b.id === bId; });
            renderSlip();
          });

          // Print button
          printBtn.addEventListener('click', function() {
            if (currentBill && Mess.printTokenSlip) {
              Mess.printTokenSlip(currentBill, {
                width: selectedWidth,
                isDuplicate: isDuplicate
              });
            }
          });

          renderSlip();
        },

        destroy: function() {
          currentBill = null;
        }
      };
    }
  });
})(window.Mess);
