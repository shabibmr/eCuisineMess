/* widget-gallery.js - Screen 3, 6, 9: Widget Gallery for Item, Cuisine, and Customer Pickers */

window.Mess = window.Mess || {};

(function(Mess) {
  var itemPicker = null;
  var cuisinePicker = null;
  var customerPicker = null;
  var eventLogs = [];

  Mess.screens.register({
    id: 'widget-gallery',
    route: '/widgets',
    title: 'Widget Gallery',
    nav: { group: 'Bottom', icon: 'component', order: 85 },
    roles: ['admin', 'supervisor', 'counter'],

    template: function() {
      return /* html */ `
        <div class="widget-gallery-screen flex-col gap-lg" style="height: 100%;">
          <header class="flex-row justify-between align-center">
            <div>
              <h2 style="margin: 0;">Picker Widgets Gallery</h2>
              <span class="text-sm color-ink-2">Interactive testing and API playground for Item (Screen 3), Cuisine (Screen 6), and Customer (Screen 9) Pickers</span>
            </div>
            <div class="flex-row gap-xs">
              <button type="button" class="btn btn--secondary btn-clear-logs">
                <i data-lucide="trash"></i> Clear Logs
              </button>
            </div>
          </header>

          <div class="grid-3col gap-md" style="flex: 1; align-items: start;">
            <!-- 1. Item Search Widget Card (Screen 3) -->
            <div class="card flex-col gap-md">
              <div class="flex-row justify-between align-center">
                <h3 style="margin: 0; font-size: 15px;">Item Picker (Screen 3)</h3>
                <span class="badge badge--neutral">F2 / Typeahead</span>
              </div>
              <p class="text-xs color-ink-2" style="margin: 0;">Search item code/name, press F2 for grid picker, or click + New.</p>

              <!-- Filter by Cuisine -->
              <div class="flex-row gap-xs align-center">
                <label class="text-xs color-ink-2">Filter by Cuisine:</label>
                <select class="field-select select-filter-item-cuisine text-xs" style="flex: 1; height: 28px;">
                  <option value="">All Cuisines</option>
                  <option value="SI">South Indian</option>
                  <option value="NI">North Indian</option>
                  <option value="KR">Kerala</option>
                </select>
              </div>

              <!-- Item Picker Host -->
              <div class="item-picker-host"></div>

              <!-- API Buttons -->
              <div class="flex-col gap-xs pt-xs" style="border-top: 1px solid var(--separator);">
                <span class="text-xs font-semibold color-ink-3">API Controls:</span>
                <div class="flex-row wrap gap-xs">
                  <button type="button" class="btn btn--quiet btn--xs btn-item-get">getValue()</button>
                  <button type="button" class="btn btn--quiet btn--xs btn-item-set">setValue('I001')</button>
                  <button type="button" class="btn btn--quiet btn--xs btn-item-clear">clear()</button>
                  <button type="button" class="btn btn--quiet btn--xs btn-item-focus">focus()</button>
                </div>
              </div>
            </div>

            <!-- 2. Cuisine Search Widget Card (Screen 6) -->
            <div class="card flex-col gap-md">
              <div class="flex-row justify-between align-center">
                <h3 style="margin: 0; font-size: 15px;">Cuisine Picker (Screen 6)</h3>
                <span class="badge badge--neutral">Typeahead</span>
              </div>
              <p class="text-xs color-ink-2" style="margin: 0;">Search cuisine code or name. Filters inactive cuisines automatically.</p>

              <!-- Cuisine Picker Host -->
              <div class="cuisine-picker-host" style="margin-top: 36px;"></div>

              <!-- API Buttons -->
              <div class="flex-col gap-xs pt-xs" style="border-top: 1px solid var(--separator); margin-top: auto;">
                <span class="text-xs font-semibold color-ink-3">API Controls:</span>
                <div class="flex-row wrap gap-xs">
                  <button type="button" class="btn btn--quiet btn--xs btn-cuis-get">getValue()</button>
                  <button type="button" class="btn btn--quiet btn--xs btn-cuis-set">setValue('SI')</button>
                  <button type="button" class="btn btn--quiet btn--xs btn-cuis-clear">clear()</button>
                  <button type="button" class="btn btn--quiet btn--xs btn-cuis-focus">focus()</button>
                </div>
              </div>
            </div>

            <!-- 3. Customer Search Widget Card (Screen 9) -->
            <div class="card flex-col gap-md">
              <div class="flex-row justify-between align-center">
                <h3 style="margin: 0; font-size: 15px;">Customer Picker (Screen 9)</h3>
                <span class="badge badge--neutral">RFID Tap / Search</span>
              </div>
              <p class="text-xs color-ink-2" style="margin: 0;">Type code/name/phone, or tap physical card / simulate RFID tap.</p>

              <!-- Customer Picker Host -->
              <div class="customer-picker-host"></div>

              <!-- RFID Simulator Button -->
              <div class="flex-row gap-xs">
                <button type="button" class="btn btn--secondary btn--xs btn-sim-rfid" style="width: 100%;">
                  <i data-lucide="nfc"></i> Simulate Card Tap (M-0042)
                </button>
              </div>

              <!-- API Buttons -->
              <div class="flex-col gap-xs pt-xs" style="border-top: 1px solid var(--separator);">
                <span class="text-xs font-semibold color-ink-3">API Controls:</span>
                <div class="flex-row wrap gap-xs">
                  <button type="button" class="btn btn--quiet btn--xs btn-cust-get">getValue()</button>
                  <button type="button" class="btn btn--quiet btn--xs btn-cust-set">setValue('M-0042')</button>
                  <button type="button" class="btn btn--quiet btn--xs btn-cust-clear">clear()</button>
                  <button type="button" class="btn btn--quiet btn--xs btn-cust-focus">focus()</button>
                </div>
              </div>
            </div>
          </div>

          <!-- Live Event Log Console -->
          <div class="card flex-col gap-xs" style="min-height: 200px;">
            <div class="flex-row justify-between align-center">
              <span class="text-sm font-semibold">Picker Event Stream</span>
              <span class="badge text-xs log-counter-badge">0 events</span>
            </div>
            <div class="event-log-container card-inset font-mono text-xs" style="flex: 1; height: 160px; overflow-y: auto; background: var(--canvas); padding: 8px; border-radius: var(--radius-sm);">
              <div class="color-ink-3">Interact with any picker above to stream events here...</div>
            </div>
          </div>
        </div>
      `;
    },

    component: function(params, targetEl) {
      return {
        init: function(el) {
          var rootEl = el || targetEl || document.getElementById('outlet');
          var logContainer = rootEl.querySelector('.event-log-container');
          var logCountBadge = rootEl.querySelector('.log-counter-badge');
          var clearLogsBtn = rootEl.querySelector('.btn-clear-logs');

          function logEvent(source, eventName, payload) {
            var time = new Date().toLocaleTimeString();
            var line = `[${time}] [${source}] ${eventName}: ${JSON.stringify(payload)}`;
            eventLogs.unshift(line);
            if (eventLogs.length > 50) eventLogs.pop();

            logCountBadge.textContent = `${eventLogs.length} events`;
            logContainer.innerHTML = eventLogs.map(function(l) {
              return `<div style="padding: 2px 0; border-bottom: 1px dashed var(--separator);">${l}</div>`;
            }).join('');
          }

          clearLogsBtn.addEventListener('click', function() {
            eventLogs = [];
            logCountBadge.textContent = '0 events';
            logContainer.innerHTML = '<div class="color-ink-3">Interact with any picker above to stream events here...</div>';
          });

          // 1. Mount Item Picker
          var itemHost = rootEl.querySelector('.item-picker-host');
          if (itemHost && Mess.pickers && Mess.pickers.createItemPicker) {
            itemPicker = Mess.pickers.createItemPicker(itemHost, {
              placeholder: 'Search items (e.g. Idli, Sambar)...',
              onSelect: function(record) {
                logEvent('ItemPicker', 'selected', record ? { id: record.id, code: record.code, name: record.name } : null);
              }
            });
          }

          // Item filter by cuisine
          var filterItemCuis = rootEl.querySelector('.select-filter-item-cuisine');
          if (filterItemCuis && itemPicker) {
            filterItemCuis.addEventListener('change', function() {
              var cuisVal = filterItemCuis.value;
              itemPicker.setCuisine(cuisVal || null);
              logEvent('ItemPicker', 'setCuisine', cuisVal || 'ALL');
            });
          }

          // Item API Buttons
          rootEl.querySelector('.btn-item-get').addEventListener('click', function() {
            var val = itemPicker ? itemPicker.currentId() : null;
            var rec = itemPicker ? itemPicker.getCurrentRecord() : null;
            logEvent('ItemPicker.API', 'currentId()', { id: val, record: rec });
          });
          rootEl.querySelector('.btn-item-set').addEventListener('click', function() {
            if (itemPicker) itemPicker.setCurrentId('I001');
            logEvent('ItemPicker.API', 'setCurrentId("I001")', 'I001');
          });
          rootEl.querySelector('.btn-item-clear').addEventListener('click', function() {
            if (itemPicker) itemPicker.clear();
            logEvent('ItemPicker.API', 'clear()', null);
          });
          rootEl.querySelector('.btn-item-focus').addEventListener('click', function() {
            if (itemPicker) itemPicker.focus();
            logEvent('ItemPicker.API', 'focus()', null);
          });

          // 2. Mount Cuisine Picker
          var cuisHost = rootEl.querySelector('.cuisine-picker-host');
          if (cuisHost && Mess.pickers && Mess.pickers.createCuisinePicker) {
            cuisinePicker = Mess.pickers.createCuisinePicker(cuisHost, {
              placeholder: 'Search cuisines (e.g. South Indian)...',
              onSelect: function(record) {
                logEvent('CuisinePicker', 'selected', record ? { id: record.id, code: record.code, name: record.name } : null);
              }
            });
          }

          // Cuisine API Buttons
          rootEl.querySelector('.btn-cuis-get').addEventListener('click', function() {
            var val = cuisinePicker ? cuisinePicker.currentId() : null;
            logEvent('CuisinePicker.API', 'currentId()', { id: val });
          });
          rootEl.querySelector('.btn-cuis-set').addEventListener('click', function() {
            if (cuisinePicker) cuisinePicker.setCurrentId('SI');
            logEvent('CuisinePicker.API', 'setCurrentId("SI")', 'SI');
          });
          rootEl.querySelector('.btn-cuis-clear').addEventListener('click', function() {
            if (cuisinePicker) cuisinePicker.clear();
            logEvent('CuisinePicker.API', 'clear()', null);
          });
          rootEl.querySelector('.btn-cuis-focus').addEventListener('click', function() {
            if (cuisinePicker) cuisinePicker.focus();
            logEvent('CuisinePicker.API', 'focus()', null);
          });

          // 3. Mount Customer Picker
          var custHost = rootEl.querySelector('.customer-picker-host');
          if (custHost && Mess.pickers && Mess.pickers.createCustomerPicker) {
            customerPicker = Mess.pickers.createCustomerPicker(custHost, {
              placeholder: 'Search member by name or code...',
              onSelect: function(record) {
                logEvent('CustomerPicker', 'selected', record ? { id: record.id, code: record.code, name: record.name, rfid: record.rfid } : null);
              }
            });
          }

          // Simulate RFID tap button
          rootEl.querySelector('.btn-sim-rfid').addEventListener('click', function() {
            // Find Rahul K (M-0042)
            var custs = (Mess.store && Mess.store.list('customers')) || [];
            var rahul = custs.find(function(c) { return c.code === 'M-0042'; });
            var rfid = rahul ? rahul.rfid : '9988776655';

            if (Mess.rfid && Mess.rfid.simulate) {
              Mess.rfid.simulate(rfid);
            } else {
              window.dispatchEvent(new CustomEvent('rfid:read', { detail: { rfid: rfid, code: rfid } }));
            }
            logEvent('RFID', 'Simulated Card Tap', { member: 'Rahul K (M-0042)', rfid: rfid });
          });

          // Customer API Buttons
          rootEl.querySelector('.btn-cust-get').addEventListener('click', function() {
            var val = customerPicker ? customerPicker.currentId() : null;
            logEvent('CustomerPicker.API', 'currentId()', { id: val });
          });
          rootEl.querySelector('.btn-cust-set').addEventListener('click', function() {
            if (customerPicker) customerPicker.setCurrentId('M-0042');
            logEvent('CustomerPicker.API', 'setCurrentId("M-0042")', 'M-0042');
          });
          rootEl.querySelector('.btn-cust-clear').addEventListener('click', function() {
            if (customerPicker) customerPicker.clear();
            logEvent('CustomerPicker.API', 'clear()', null);
          });
          rootEl.querySelector('.btn-cust-focus').addEventListener('click', function() {
            if (customerPicker) customerPicker.focus();
            logEvent('CustomerPicker.API', 'focus()', null);
          });
        },

        destroy: function() {
          itemPicker = null;
          cuisinePicker = null;
          customerPicker = null;
        }
      };
    }
  });
})(window.Mess);
