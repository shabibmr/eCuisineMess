/* counter.js - Screen 13: Mess Counter Kiosk with RFID Wedge, State Machine, Overrides & Token Animation */

window.Mess = window.Mess || {};

(function(Mess) {
  var currentState = 'idle'; // 'idle' | 'resolving' | 'loaded' | 'error' | 'saving' | 'printed'
  var currentCustomer = null;
  var currentInvoiceItems = [];
  var currentErrorMessage = '';
  var isOverrideActive = false;
  var overrideReason = '';
  var supervisorName = '';
  var lastTokenIssued = '—';
  var lastServedBill = null;

  var rfidListener = null;
  var clockInterval = null;
  var focusKeeperInterval = null;

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

  function getNextTokenNumber(mealCode, dateStr) {
    var bills = (Mess.store && Mess.store.list('bills')) || [];
    var maxNum = 0;
    bills.forEach(function(b) {
      if (b.date === dateStr && (b.meal_code === mealCode || b.meal === mealCode)) {
        var token = b.token_number || b.token_no || '';
        var match = token.match(/[BLD]-(\d+)/i);
        if (match) {
          var n = parseInt(match[1], 10);
          if (n > maxNum) maxNum = n;
        }
      }
    });
    var next = maxNum + 1;
    return `${mealCode}-${String(next).padStart(4, '0')}`;
  }

  function getServedThisMealCount(dateStr, mealCode) {
    var bills = (Mess.store && Mess.store.list('bills')) || [];
    return bills.filter(function(b) {
      return b.date === dateStr && (b.meal_code === mealCode || b.meal === mealCode) && !b.cancelled;
    }).length;
  }

  Mess.screens.register({
    id: 'counter',
    route: '/counter',
    title: 'Counter Billing',
    nav: { group: 'Operations', icon: 'scan', order: 1 },
    roles: ['admin', 'supervisor', 'counter'],

    template: function() {
      var today = getTodayIso();
      var currentMeal = Mess.clock && Mess.clock.currentMeal ? Mess.clock.currentMeal() : 'L';
      if (currentMeal === 'none') currentMeal = 'L'; // default fallback for preview
      var servedCount = getServedThisMealCount(today, currentMeal);

      return /* html */ `
        <div class="counter-kiosk flex-col gap-md" style="height: 100%; position: relative;">
          <!-- Hidden persistent RFID input -->
          <input type="text" class="hidden-rfid-input" style="position: absolute; opacity: 0; pointer-events: none; left: -9999px;" autocomplete="off">

          <!-- Printer sliding animation overlay host -->
          <div class="printer-feed-overlay-slot" style="position: absolute; top: 12px; right: 24px; z-index: 100; pointer-events: none;"></div>

          <!-- Top Header Bar -->
          <header class="counter-header-bar flex-row justify-between align-center wrap gap-sm">
            <div class="flex-row align-center gap-md">
              <button type="button" class="btn btn--secondary btn--sm btn-counter-leave" title="Leave Counter (Ctrl+Shift+L)">
                <i data-lucide="chevron-left"></i> Leave
              </button>
              <div class="flex-col">
                <h2 style="margin: 0; font-size: 18px; letter-spacing: 0.5px;">MESS COUNTER</h2>
                <div class="flex-row align-center gap-xs text-xs color-ink-2">
                  <span>Current Service:</span>
                  <span class="badge badge--${currentMeal.toLowerCase()} live-meal-badge font-bold">${currentMeal === 'B' ? 'BREAKFAST' : currentMeal === 'L' ? 'LUNCH' : 'DINNER'}</span>
                </div>
              </div>
            </div>

            <div class="flex-row align-center gap-lg">
              <!-- Live Timeline Miniature -->
              <div class="counter-timeline-mini" style="width: 220px;"></div>

              <div class="flex-col align-end">
                <span class="font-mono font-bold text-lg live-clock-text">--:--:--</span>
                <span class="text-xs color-ink-3">Served this meal: <strong class="color-ink served-count-text">${servedCount}</strong></span>
              </div>
            </div>
          </header>

          <!-- Danger / Error Banner (36px+ full width) -->
          <div class="counter-danger-banner banner banner--danger flex-row justify-between align-center gap-md p-md" 
               style="display: none; border-radius: var(--radius-panel); background: rgba(239, 68, 68, 0.12); border-left: 5px solid var(--danger);"
               role="alert" aria-live="assertive">
            <div class="flex-row align-center gap-sm">
              <i data-lucide="alert-circle" class="color-danger" style="width: 24px; height: 24px; flex-shrink: 0;"></i>
              <span class="counter-error-message font-bold text-sm color-danger"></span>
            </div>
            <div class="flex-row gap-xs banner-actions">
              <button type="button" class="btn btn--danger btn--sm btn-supervisor-override" style="display: none;">
                <i data-lucide="shield-alert"></i> Supervisor Override
              </button>
              <button type="button" class="btn btn--quiet btn--sm btn-clear-error">Dismiss (Esc)</button>
            </div>
          </div>

          <!-- Main 2-Column Split Workspace -->
          <div class="counter-main-grid flex-row gap-md" style="flex: 1; min-height: 440px; align-items: stretch;">
            <!-- Left Column: Tap Target & Member Identity Card -->
            <div class="flex-col gap-md" style="flex: 1; max-width: 440px; min-width: 320px;">
              <!-- Tap Card Target Area -->
              <div class="tap-target-area card-inset flex-col align-center justify-center gap-xs p-md" 
                   style="height: 140px; text-align: center; border-radius: var(--radius-panel); background: var(--surface);">
                <i data-lucide="nfc" class="color-primary animate-pulse" style="width: 40px; height: 40px;"></i>
                <span class="font-bold text-base color-ink">Tap RFID Card on Reader</span>
                <span class="text-xs color-ink-3">Or click here / use Demo Panel to simulate card tap</span>
                <span class="text-xs font-mono color-ink-3 rfid-last-read">Ready</span>
              </div>

              <!-- Member Card Profile -->
              <div class="member-profile-card card flex-col gap-md" style="flex: 1; display: none; background: var(--surface); padding: 18px;">
                <div class="flex-row justify-between align-start">
                  <div class="flex-row gap-md align-center">
                    <img src="" class="avatar member-avatar-img" style="width: 64px; height: 64px; object-fit: cover; border-radius: 50%;" alt="Member Avatar">
                    <div class="flex-col">
                      <h3 class="member-name-text" style="margin: 0; font-size: 18px;">Rahul K</h3>
                      <span class="font-mono text-sm color-ink-2 member-code-text">M-0042</span>
                      <span class="badge badge--neutral text-xs member-cuisine-badge" style="margin-top: 4px; width: fit-content;">South Indian</span>
                    </div>
                  </div>
                  <div class="override-badge-wrapper" style="display: none;">
                    <span class="badge badge--danger text-xs font-bold">OVERRIDE</span>
                  </div>
                </div>

                <div class="flex-col gap-xs pt-xs" style="border-top: 1px solid var(--separator);">
                  <div class="flex-row justify-between align-center text-xs">
                    <span class="color-ink-2">Membership Validity:</span>
                    <span class="font-mono font-semibold member-validity-text color-success">31-12-2026 ✔</span>
                  </div>
                  <div class="flex-row justify-between align-center text-xs pt-xs">
                    <span class="color-ink-2">Today's Meals:</span>
                    <div class="member-pips-strip flex-row gap-xs font-mono">
                      <span class="pip-b">B —</span>
                      <span class="pip-l">L —</span>
                      <span class="pip-d">D —</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Right Column: Meal Invoice Table -->
            <div class="card flex-col gap-md invoice-card" style="flex: 1.5; background: var(--surface); padding: 18px;">
              <div class="flex-row justify-between align-center" style="border-bottom: 1px solid var(--separator); padding-bottom: 10px;">
                <div class="flex-col">
                  <h3 style="margin: 0; font-size: 16px;">Meal Invoice</h3>
                  <span class="text-xs color-ink-2">Standard entitlements for current service</span>
                </div>
                <div class="invoice-status-indicator">
                  <span class="badge badge--neutral invoice-state-badge">Waiting for card…</span>
                </div>
              </div>

              <!-- Table Well -->
              <div class="table-well" style="flex: 1; border: 1px solid var(--separator); border-radius: var(--radius-sm); overflow-y: auto;">
                <table class="counter-invoice-table" style="width: 100%; border-collapse: collapse; font-size: 13px;">
                  <thead>
                    <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); text-align: left;">
                      <th style="width: 40px; padding: 10px;">#</th>
                      <th style="padding: 10px;">Item Description</th>
                      <th style="width: 80px; padding: 10px; text-align: right;">Qty</th>
                      <th style="width: 90px; padding: 10px; text-align: right;">Rate</th>
                      <th style="width: 90px; padding: 10px; text-align: right;">Amount</th>
                      <th style="width: 40px; padding: 10px; text-align: center;"></th>
                    </tr>
                  </thead>
                  <tbody class="invoice-tbody">
                    <tr>
                      <td colspan="6" class="text-center color-ink-3" style="padding: 48px 16px;">
                        Tap a member card to load menu entitlements.
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <!-- Invoice Total Line -->
              <div class="flex-row justify-between align-center p-xs font-mono" style="border-top: 2px solid var(--separator); font-size: 16px; font-weight: bold;">
                <span>Total Amount</span>
                <span class="tabular-nums">0.00 AED</span>
              </div>
            </div>
          </div>

          <!-- Bottom Action Footer Bar -->
          <footer class="counter-footer-bar card flex-row justify-between align-center p-md" style="background: var(--surface);">
            <div class="flex-row align-center gap-md">
              <button type="button" class="btn btn--primary btn-save-print" style="font-size: 16px; padding: 12px 24px; font-weight: bold;" disabled>
                <i data-lucide="printer"></i> Save & Print Token (F10)
              </button>
              <button type="button" class="btn btn--secondary btn-clear-counter">
                Clear (Esc)
              </button>
            </div>

            <div class="flex-row align-center gap-md">
              <span class="text-sm color-ink-2">Last Issued Token:</span>
              <span class="badge badge--neutral font-mono font-bold text-base last-token-badge">${lastTokenIssued}</span>
              <button type="button" class="btn btn--quiet btn--sm btn-reprint-last" style="display: none;" title="Reprint last token (DUPLICATE)">
                <i data-lucide="copy"></i> Reprint
              </button>
            </div>
          </footer>
        </div>
      `;
    },

    component: function(params, targetEl) {
      return {
        init: function(el) {
          var rootEl = el || targetEl || document.getElementById('outlet');
          var hiddenRfid = rootEl.querySelector('.hidden-rfid-input');
          var tapArea = rootEl.querySelector('.tap-target-area');
          var lastReadText = rootEl.querySelector('.rfid-last-read');
          var dangerBanner = rootEl.querySelector('.counter-danger-banner');
          var errorMsgEl = rootEl.querySelector('.counter-error-message');
          var supervisorBtn = rootEl.querySelector('.btn-supervisor-override');
          var clearErrorBtn = rootEl.querySelector('.btn-clear-error');

          var memberCard = rootEl.querySelector('.member-profile-card');
          var memberAvatar = rootEl.querySelector('.member-avatar-img');
          var memberName = rootEl.querySelector('.member-name-text');
          var memberCode = rootEl.querySelector('.member-code-text');
          var memberCuisine = rootEl.querySelector('.member-cuisine-badge');
          var memberValidity = rootEl.querySelector('.member-validity-text');
          var pipB = rootEl.querySelector('.pip-b');
          var pipL = rootEl.querySelector('.pip-l');
          var pipD = rootEl.querySelector('.pip-d');
          var overrideBadge = rootEl.querySelector('.override-badge-wrapper');

          var invoiceStateBadge = rootEl.querySelector('.invoice-state-badge');
          var invoiceTbody = rootEl.querySelector('.invoice-tbody');
          var saveBtn = rootEl.querySelector('.btn-save-print');
          var clearBtn = rootEl.querySelector('.btn-clear-counter');
          var lastTokenBadge = rootEl.querySelector('.last-token-badge');
          var reprintBtn = rootEl.querySelector('.btn-reprint-last');
          var servedCountText = rootEl.querySelector('.served-count-text');
          var clockText = rootEl.querySelector('.live-clock-text');
          var leaveBtn = rootEl.querySelector('.btn-counter-leave');
          var timelineHost = rootEl.querySelector('.counter-timeline-mini');
          var printerOverlaySlot = rootEl.querySelector('.printer-feed-overlay-slot');
          var timelineMiniInstance = null;

          // Initialize Timeline miniature
          if (timelineHost && Mess.createMealTimeline) {
            timelineMiniInstance = Mess.createMealTimeline(timelineHost, {
              showLabels: false,
              showHeader: false
            });
          }

          // Live Clock update
          function updateClock() {
            var now = Mess.clock ? Mess.clock.now() : new Date();
            var hh = String(now.getHours()).padStart(2, '0');
            var mm = String(now.getMinutes()).padStart(2, '0');
            var ss = String(now.getSeconds()).padStart(2, '0');
            clockText.textContent = `${hh}:${mm}:${ss}`;
          }
          updateClock();
          clockInterval = setInterval(updateClock, 1000);

          // Focus Pinning to RFID Input
          function ensureRfidFocus() {
            if (document.activeElement && (document.activeElement.tagName === 'INPUT' || document.activeElement.tagName === 'SELECT' || document.activeElement.tagName === 'TEXTAREA' || document.activeElement.closest('.dialog') || document.activeElement.closest('.side-sheet'))) {
              return;
            }
            if (hiddenRfid) hiddenRfid.focus();
          }
          ensureRfidFocus();
          focusKeeperInterval = setInterval(ensureRfidFocus, 1000);

          rootEl.addEventListener('click', function(e) {
            if (!e.target.closest('button, input, select, .dialog, .side-sheet')) {
              ensureRfidFocus();
            }
          });

          // State transitions
          function resetToIdle() {
            currentState = 'idle';
            currentCustomer = null;
            currentInvoiceItems = [];
            currentErrorMessage = '';
            isOverrideActive = false;
            overrideReason = '';
            supervisorName = '';

            dangerBanner.style.display = 'none';
            supervisorBtn.style.display = 'none';
            memberCard.style.display = 'none';
            overrideBadge.style.display = 'none';

            tapArea.classList.add('idle');
            lastReadText.textContent = 'Ready';

            invoiceStateBadge.textContent = 'Waiting for card…';
            invoiceStateBadge.className = 'badge badge--neutral invoice-state-badge';

            invoiceTbody.innerHTML = `
              <tr>
                <td colspan="6" class="text-center color-ink-3" style="padding: 48px 16px;">
                  Tap a member card to load menu entitlements.
                </td>
              </tr>
            `;

            saveBtn.disabled = true;
            ensureRfidFocus();
          }

          function showError(message, allowOverride, existingBill) {
            currentState = 'error';
            currentErrorMessage = message;

            if (Mess.audio && Mess.audio.error) {
              Mess.audio.error();
            }

            errorMsgEl.textContent = message;
            dangerBanner.style.display = 'flex';

            if (allowOverride) {
              supervisorBtn.style.display = 'inline-flex';
              lastServedBill = existingBill;
            } else {
              supervisorBtn.style.display = 'none';
            }

            memberCard.style.display = 'none';
            saveBtn.disabled = true;
            invoiceStateBadge.textContent = 'Error';
            invoiceStateBadge.className = 'badge badge--danger invoice-state-badge';
          }

          // RFID Resolution logic following exact spec validation table
          function resolveCard(cardCode) {
            if (!cardCode) return;
            cardCode = cardCode.trim();

            resetToIdle();
            currentState = 'resolving';
            lastReadText.textContent = `Card: ${cardCode}`;

            var today = getTodayIso();
            var allCustomers = (Mess.store && Mess.store.list('customers')) || [];
            
            // 1. Identify customer from rfid
            var cust = allCustomers.find(function(c) {
              return c.rfid && c.rfid.trim().toLowerCase() === cardCode.toLowerCase();
            });

            if (!cust) {
              showError('Card not registered', false);
              return;
            }

            // 2. Customer active check
            if (cust.active === false) {
              showError('Membership inactive', false);
              return;
            }

            // 3. Today outside Valid From - Valid To
            if (cust.valid_to && cust.valid_to < today) {
              var formattedDate = Mess.format && Mess.format.date ? Mess.format.date(cust.valid_to) : cust.valid_to;
              showError(`Membership expired on ${formattedDate}`, false);
              return;
            }

            // 4. Current time outside every meal window
            var currentMeal = Mess.clock && Mess.clock.currentMeal ? Mess.clock.currentMeal() : 'none';
            if (currentMeal === 'none') {
              var nextM = Mess.clock && Mess.clock.nextMeal ? Mess.clock.nextMeal() : null;
              var nextStartTime = (nextM && (nextM.start_time || nextM.from)) || '06:00';
              var nextStr = nextM ? `Next: ${nextM.name} ${nextStartTime}` : 'Next: Breakfast 06:00';
              showError(`No meal service now. ${nextStr}`, false);
              return;
            }

            // 5. No menu saved for cuisine + current meal today
            var allMenus = (Mess.store && Mess.store.list('menus')) || [];
            var cuisine = (Mess.store && Mess.store.get('cuisines', cust.cuisine_id || cust.cuisineId)) || { name: 'Standard' };
            var menu = allMenus.find(function(m) {
              var matchDate = m.date === today;
              var matchCuis = (m.cuisine_id === cust.cuisine_id || m.cuisineId === cust.cuisine_id || m.cuisine_id === cust.cuisineId || m.cuisineId === cust.cuisineId);
              var matchMeal = (m.meal_type === currentMeal || m.meal === currentMeal);
              return matchDate && matchCuis && matchMeal;
            });

            var mealLabel = currentMeal === 'B' ? 'Breakfast' : currentMeal === 'L' ? 'Lunch' : 'Dinner';
            if (!menu || !menu.items || menu.items.length === 0) {
              showError(`Menu not set for ${cuisine.name} – ${mealLabel}`, false);
              return;
            }

            // 6. Customer already billed for this meal today
            var allBills = (Mess.store && Mess.store.list('bills')) || [];
            var existingBill = allBills.find(function(b) {
              return b.date === today && 
                     (b.customer_id === cust.id || b.memberId === cust.id) &&
                     (b.meal_code === currentMeal || b.meal === currentMeal || b.meal_type === currentMeal) &&
                     !b.cancelled;
            });

            if (existingBill && !isOverrideActive) {
              var timeStr = existingBill.time || '13:05';
              var tok = existingBill.token_number || existingBill.token_no || 'L-0151';
              showError(`Already served ${mealLabel} at ${timeStr} (${tok})`, true, existingBill);
              return;
            }

            // ALL VALIDATIONS PASSED -> LOAD STATE
            loadCustomerInvoice(cust, cuisine, currentMeal, menu.items);
          }

          function loadCustomerInvoice(cust, cuisine, mealCode, items) {
            currentState = 'loaded';
            currentCustomer = cust;
            currentInvoiceItems = items.map(function(it) {
              var itemObj = Mess.store ? Mess.store.get('items', it.itemId || it.item_id) : null;
              return {
                itemId: it.itemId || it.item_id,
                name: itemObj ? itemObj.name : (it.name || 'Entitlement Item'),
                qty: it.qty || it.quantity || (itemObj ? itemObj.default_qty || 1 : 1),
                rate: 0.00,
                amount: 0.00
              };
            });

            if (Mess.audio && Mess.audio.ok) {
              Mess.audio.ok();
            }

            dangerBanner.style.display = 'none';
            memberCard.style.display = 'flex';
            tapArea.classList.remove('idle');

            // Render member card details
            memberAvatar.src = cust.photo || `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><rect width="64" height="64" rx="32" fill="%23cbd5e1"/><text x="32" y="38" font-family="sans-serif" font-size="22" font-weight="bold" fill="%23334155" text-anchor="middle">${(cust.name || 'M')[0]}</text></svg>`;
            memberName.textContent = cust.name;
            memberCode.textContent = cust.code;
            memberCuisine.textContent = cuisine.name;
            memberValidity.textContent = `${cust.valid_to} ✔`;

            // Today's meal pips
            var today = getTodayIso();
            var allBills = (Mess.store && Mess.store.list('bills')) || [];
            var custTodayBills = allBills.filter(function(b) {
              return b.date === today && (b.customer_id === cust.id || b.memberId === cust.id) && !b.cancelled;
            });
            var hadB = custTodayBills.some(function(b) { return b.meal_code === 'B'; });
            var hadL = custTodayBills.some(function(b) { return b.meal_code === 'L'; });
            var hadD = custTodayBills.some(function(b) { return b.meal_code === 'D'; });

            pipB.innerHTML = `B ${hadB ? '<span class="color-success">✔</span>' : '—'}`;
            pipL.innerHTML = `L ${hadL ? '<span class="color-success">✔</span>' : '—'}`;
            pipD.innerHTML = `D ${hadD ? '<span class="color-success">✔</span>' : '—'}`;

            overrideBadge.style.display = isOverrideActive ? 'block' : 'none';

            // Render invoice items
            renderInvoiceTable();

            invoiceStateBadge.textContent = 'Invoice Loaded';
            invoiceStateBadge.className = 'badge badge--success invoice-state-badge';
            saveBtn.disabled = false;

            if (window.lucide && window.lucide.createIcons) {
              window.lucide.createIcons({ root: rootEl });
            }
          }

          function renderInvoiceTable() {
            invoiceTbody.innerHTML = '';
            currentInvoiceItems.forEach(function(item, idx) {
              var tr = document.createElement('tr');
              tr.style.borderBottom = '1px solid var(--separator)';

              tr.innerHTML = `
                <td style="padding: 10px; color: var(--ink-3); font-size: 11px;">${idx + 1}</td>
                <td style="padding: 10px; font-weight: 500;">${item.name}</td>
                <td style="padding: 10px; text-align: right;" class="tabular-nums font-mono">${item.qty}</td>
                <td style="padding: 10px; text-align: right;" class="tabular-nums font-mono">0.00</td>
                <td style="padding: 10px; text-align: right;" class="tabular-nums font-mono">0.00</td>
                <td style="padding: 10px; text-align: center;">
                  ${isOverrideActive ? `
                    <button type="button" class="btn btn--quiet btn--icon btn--xs btn-remove-line" data-idx="${idx}" title="Supervisor remove line">
                      <i data-lucide="x"></i>
                    </button>
                  ` : ''}
                </td>
              `;

              var removeLineBtn = tr.querySelector('.btn-remove-line');
              if (removeLineBtn) {
                removeLineBtn.addEventListener('click', function() {
                  currentInvoiceItems.splice(idx, 1);
                  renderInvoiceTable();
                });
              }

              invoiceTbody.appendChild(tr);
            });
          }

          // Save & Print Token (F10)
          function doSave() {
            if (currentState !== 'loaded' || !currentCustomer) return;
            currentState = 'saving';
            saveBtn.disabled = true;

            var today = getTodayIso();
            var currentMeal = Mess.clock && Mess.clock.currentMeal ? Mess.clock.currentMeal() : 'L';
            if (currentMeal === 'none') currentMeal = 'L';

            var tokenNum = getNextTokenNumber(currentMeal, today);
            var now = Mess.clock ? Mess.clock.now() : new Date();
            var timeStr = Mess.format && Mess.format.time ? Mess.format.time(now) : `${now.getHours()}:${String(now.getMinutes()).padStart(2, '0')}`;

            var billRecord = {
              id: 'bill_' + Date.now(),
              token_number: tokenNum,
              token_no: tokenNum,
              date: today,
              time: timeStr,
              customer_id: currentCustomer.id,
              memberId: currentCustomer.id,
              customer_name: currentCustomer.name,
              customer_code: currentCustomer.code,
              cuisine_id: currentCustomer.cuisine_id || currentCustomer.cuisineId,
              cuisineId: currentCustomer.cuisine_id || currentCustomer.cuisineId,
              cuisine_name: memberCuisine.textContent,
              meal_code: currentMeal,
              meal: currentMeal,
              meal_type: currentMeal,
              counter_id: 'C1',
              user_name: 'admin',
              created_by: 'admin',
              cancelled: false,
              override: isOverrideActive,
              override_reason: overrideReason,
              supervisor: supervisorName,
              items: currentInvoiceItems.slice()
            };

            // Save to store
            Mess.store.save('bills', billRecord);
            if (Mess.persist && Mess.persist.saveCollection) {
              Mess.persist.saveCollection('bills', Mess.store.list('bills'));
            }

            lastTokenIssued = tokenNum;
            lastTokenBadge.textContent = tokenNum;
            reprintBtn.style.display = 'inline-flex';

            // Update served count
            servedCountText.textContent = getServedThisMealCount(today, currentMeal);

            // Animate thermal feed
            if (Mess.animateTokenFeed && printerOverlaySlot) {
              Mess.animateTokenFeed(printerOverlaySlot, billRecord, { width: '80mm' });
            }

            // Print to device if enabled
            if (Mess.print && Mess.print.isPrintToDevice && Mess.print.isPrintToDevice()) {
              Mess.printTokenSlip(billRecord, { width: '80mm' });
            }

            if (Mess.ui && Mess.ui.toast) {
              Mess.ui.toast('success', `Token ${tokenNum} printed`);
            }

            setTimeout(function() {
              resetToIdle();
            }, 800);
          }

          // Supervisor Override Handler
          supervisorBtn.addEventListener('click', function() {
            if (Mess.dialog && Mess.dialog.supervisorAuth) {
              Mess.dialog.supervisorAuth(function(authorized) {
                if (authorized) {
                  Mess.dialog.prompt('Supervisor Override Reason', 'Please enter justification for serving meal again:').then(function(reason) {
                    if (reason && reason.trim()) {
                      isOverrideActive = true;
                      overrideReason = reason.trim();
                      supervisorName = 'admin';

                      // Re-resolve with override active
                      var cardCode = currentCustomer ? currentCustomer.rfid : (hiddenRfid.value || (lastServedBill ? lastServedBill.customer_id : null));
                      if (currentCustomer) {
                        var allMenus = (Mess.store && Mess.store.list('menus')) || [];
                        var currentMeal = Mess.clock && Mess.clock.currentMeal ? Mess.clock.currentMeal() : 'L';
                        var today = getTodayIso();
                        var menu = allMenus.find(function(m) {
                          return m.date === today && m.cuisine_id === currentCustomer.cuisine_id && m.meal_type === currentMeal;
                        });
                        loadCustomerInvoice(currentCustomer, { name: memberCuisine.textContent }, currentMeal, menu ? menu.items : []);
                      } else {
                        resolveCard(cardCode);
                      }
                    }
                  });
                }
              });
            }
          });

          // Simulator click on tap area
          tapArea.addEventListener('click', function() {
            var customers = (Mess.store && Mess.store.list('customers')) || [];
            var quickCustomers = customers.slice(0, 6);

            var optionsHtml = quickCustomers.map(function(c) {
              return `<button type="button" class="btn btn--secondary btn--sm btn-select-demo-card" data-rfid="${c.rfid}" style="width: 100%; text-align: left; justify-content: flex-start;">
                <strong>${c.code}</strong> – ${c.name} (${c.cuisine_id || 'SI'})
              </button>`;
            }).join('');

            var content = document.createElement('div');
            content.className = 'flex-col gap-sm';
            content.innerHTML = `
              <p class="text-sm">Simulate RFID Card Tap on Counter:</p>
              <div class="flex-col gap-xs">${optionsHtml}</div>
              <div class="flex-row gap-xs pt-xs">
                <input type="text" class="field-input manual-rfid-input text-xs" placeholder="Manual card number...">
                <button type="button" class="btn btn--primary btn--xs btn-tap-manual">Tap</button>
              </div>
            `;

            if (Mess.dialog && Mess.dialog.alert) {
              Mess.dialog.alert({
                title: 'Simulate RFID Card Reader',
                content: content
              });

              content.querySelectorAll('.btn-select-demo-card').forEach(function(btn) {
                btn.addEventListener('click', function() {
                  var rfid = btn.getAttribute('data-rfid');
                  if (Mess.dialog && Mess.dialog.close) Mess.dialog.close();
                  resolveCard(rfid);
                });
              });

              content.querySelector('.btn-tap-manual').addEventListener('click', function() {
                var manualRfid = content.querySelector('.manual-rfid-input').value.trim();
                if (manualRfid) {
                  if (Mess.dialog && Mess.dialog.close) Mess.dialog.close();
                  resolveCard(manualRfid);
                }
              });
            }
          });

          // Hotkey and input listeners
          saveBtn.addEventListener('click', doSave);
          clearBtn.addEventListener('click', resetToIdle);
          clearErrorBtn.addEventListener('click', resetToIdle);

          reprintBtn.addEventListener('click', function() {
            if (lastTokenIssued && Mess.showTokenPreviewDialog) {
              var allBills = (Mess.store && Mess.store.list('bills')) || [];
              var b = allBills.find(function(it) { return it.token_number === lastTokenIssued; });
              if (b) {
                Mess.showTokenPreviewDialog(b, { isDuplicate: true });
              }
            }
          });

          // Listen for RFID wedge reader event
          rfidListener = function(e) {
            var code = e.detail && e.detail.code ? e.detail.code : (e.detail && e.detail.rfid ? e.detail.rfid : e.detail);
            if (code) {
              resolveCard(code);
            }
          };
          window.addEventListener('rfid:read', rfidListener);

          // Keyboard hotkeys: F10 to save, Esc to clear, Ctrl+Shift+L to leave
          var onKeyDown = function(e) {
            if (e.key === 'F10') {
              e.preventDefault();
              doSave();
            } else if (e.key === 'Escape') {
              e.preventDefault();
              resetToIdle();
            } else if ((e.ctrlKey || e.metaKey) && e.shiftKey && (e.key === 'L' || e.key === 'l')) {
              e.preventDefault();
              window.location.hash = '#/';
            }
          };
          window.addEventListener('keydown', onKeyDown);

          leaveBtn.addEventListener('click', function() {
            if (currentState === 'loaded') {
              if (Mess.dialog && Mess.dialog.confirm) {
                Mess.dialog.confirm('Leave Counter', 'An invoice is currently loaded. Leave counter now?').then(function(yes) {
                  if (yes) window.location.hash = '#/';
                });
              }
            } else {
              window.location.hash = '#/';
            }
          });

          // Initial state
          resetToIdle();
        },

        destroy: function() {
          if (timelineMiniInstance) {
            timelineMiniInstance.destroy();
            timelineMiniInstance = null;
          }
          if (rfidListener) {
            window.removeEventListener('rfid:read', rfidListener);
            rfidListener = null;
          }
          if (clockInterval) {
            clearInterval(clockInterval);
            clockInterval = null;
          }
          if (focusKeeperInterval) {
            clearInterval(focusKeeperInterval);
            focusKeeperInterval = null;
          }
        }
      };
    }
  });
})(window.Mess);
