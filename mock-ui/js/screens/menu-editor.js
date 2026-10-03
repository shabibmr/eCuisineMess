/* menu-editor.js - Screen 11: Daily Menu Editor (all cuisines × all meals on one date) */

window.Mess = window.Mess || {};

(function(Mess) {
  var currentDate = null;
  var currentCuisineId = null;
  var currentMealCode = 'B'; // 'B', 'L', 'D'

  // Working state for the current date: { cuisineId: { 'B': [...items], 'L': [...items], 'D': [...items] } }
  var workingMenus = {};
  var initialSnapshot = '';
  var isReadOnlyPast = false;

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

  function shiftDate(dateStr, days) {
    var d = new Date(dateStr);
    d.setDate(d.getDate() + days);
    var yyyy = d.getFullYear();
    var mm = String(d.getMonth() + 1).padStart(2, '0');
    var dd = String(d.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  }

  function getActiveCuisines() {
    var all = (Mess.store && Mess.store.list('cuisines')) || [];
    return all.filter(function(c) { return c.active !== false; });
  }

  function getMappedItemIds(cuisineId) {
    var mappings = (Mess.store && Mess.store.list('cuisine_items')) || [];
    return mappings
      .filter(function(m) { return m.cuisine_id === cuisineId || m.cuisineId === cuisineId; })
      .map(function(m) { return m.item_id || m.itemId; });
  }

  function getBillCountForMeal(date, cuisineId, mealCode) {
    var bills = (Mess.store && Mess.store.list('bills')) || [];
    return bills.filter(function(b) {
      var matchDate = b.date === date;
      var matchCuis = b.cuisine_id === cuisineId || b.cuisineId === cuisineId;
      var matchMeal = b.meal_code === mealCode || b.meal === mealCode || b.meal_type === mealCode;
      return matchDate && matchCuis && matchMeal && !b.cancelled;
    }).length;
  }

  function loadWorkingMenusForDate(dateStr) {
    workingMenus = {};
    var activeCuisines = getActiveCuisines();
    var storedMenus = (Mess.store && Mess.store.list('menus')) || [];

    activeCuisines.forEach(function(c) {
      workingMenus[c.id] = { 'B': [], 'L': [], 'D': [] };
    });

    storedMenus.forEach(function(m) {
      if (m.date !== dateStr) return;
      var cId = m.cuisine_id || m.cuisineId;
      var mCode = (m.meal_type || m.meal || 'B').toUpperCase();
      if (workingMenus[cId] && workingMenus[cId][mCode]) {
        var items = (m.items || []).map(function(it) {
          return {
            itemId: it.item_id || it.itemId,
            qty: it.qty || it.quantity || 1
          };
        });
        workingMenus[cId][mCode] = items;
      }
    });

    initialSnapshot = JSON.stringify(workingMenus);
    if (Mess.router && Mess.router.setDirty) {
      Mess.router.setDirty(false);
    }
  }

  Mess.screens.register({
    id: 'menu-editor',
    route: '/menu-editor',
    title: 'Daily Menu Editor',
    nav: { group: 'Operations', icon: 'utensils-crossed', order: 2 },
    roles: ['admin', 'supervisor'],

    template: function(params) {
      var query = (Mess.router && Mess.router.getQuery) ? Mess.router.getQuery() : {};
      currentDate = (params && params.date) || query.date || getTodayIso();
      var activeCuisines = getActiveCuisines();
      currentCuisineId = query.cuisine || (activeCuisines.length > 0 ? activeCuisines[0].id : null);
      currentMealCode = query.meal || 'B';

      var today = getTodayIso();
      isReadOnlyPast = currentDate < today;

      loadWorkingMenusForDate(currentDate);

      return /* html */ `
        <div class="menu-editor-screen flex-col gap-md" style="height: 100%;">
          <!-- Top Date Bar & Action Controls -->
          <div class="toolbar card flex-row justify-between align-center wrap gap-md p-md" style="background: var(--surface);">
            <div class="flex-row align-center gap-sm">
              <span class="text-sm font-bold color-ink-2">Date:</span>
              <button type="button" class="btn btn--secondary btn--icon btn-prev-day" title="Previous Day">
                <i data-lucide="chevron-left"></i>
              </button>
              <input type="date" class="field-input menu-date-input" value="${currentDate}" style="width: 150px; font-weight: 600;">
              <button type="button" class="btn btn--secondary btn--icon btn-next-day" title="Next Day">
                <i data-lucide="chevron-right"></i>
              </button>
              <button type="button" class="btn btn--quiet btn--sm btn-jump-today">Today</button>
            </div>

            <div class="flex-row gap-sm align-center">
              <button type="button" class="btn btn--secondary btn-copy-from-date" ${isReadOnlyPast ? 'disabled' : ''}>
                <i data-lucide="copy"></i> Copy From Date…
              </button>
              <a href="#/menu-history" class="btn btn--secondary">
                <i data-lucide="history"></i> History
              </a>
              <button type="button" class="btn btn--quiet btn-reset-menu" ${isReadOnlyPast ? 'disabled' : ''}>Reset</button>
              <button type="button" class="btn btn--primary btn-save-menu" ${isReadOnlyPast ? 'disabled' : ''}>
                <i data-lucide="save"></i> Save Menu
              </button>
            </div>
          </div>

          <!-- Past Date Read-Only Banner -->
          <div class="past-date-banner banner banner--neutral flex-row align-center gap-sm" 
               style="display: ${isReadOnlyPast ? 'flex' : 'none'}; padding: 8px 16px; border-radius: var(--radius-panel);">
            <i data-lucide="info" style="width: 18px; height: 18px; flex-shrink: 0;"></i>
            <span class="text-sm font-medium">History – Read Only. Past dates cannot be modified.</span>
          </div>

          <!-- Main Dual-Pane Workspace -->
          <div class="menu-editor-workspace flex-row gap-md" style="flex: 1; min-height: 480px;">
            <!-- Left Pane: Cuisines List with Status Indicators -->
            <div class="card flex-col gap-xs cuisines-nav-pane" style="width: 250px; min-width: 220px; padding: 12px; background: var(--surface);">
              <div class="flex-row justify-between align-center pb-xs" style="border-bottom: 1px solid var(--separator);">
                <span class="text-xs font-bold uppercase color-ink-3">Cuisines</span>
                <span class="badge text-xs cuisines-count-badge">${activeCuisines.length}</span>
              </div>

              <div class="cuisines-list flex-col gap-xs pt-xs" style="flex: 1; overflow-y: auto;">
                <!-- Populated dynamically -->
              </div>
            </div>

            <!-- Right Pane: Meal Tabs & Item Grid -->
            <div class="card flex-col gap-md meal-content-pane" style="flex: 1; background: var(--surface); padding: 16px; min-width: 480px;">
              <!-- Meal Tabs Header -->
              <div class="flex-row justify-between align-center wrap gap-sm" style="border-bottom: 1px solid var(--separator); padding-bottom: 10px;">
                <div class="segmented-control meal-tabs-segmented" role="radiogroup" aria-label="Meal type">
                  <button type="button" class="meal-tab-btn" data-meal="B" role="radio">
                    <i data-lucide="sunrise"></i> Breakfast <span class="tab-count tab-count-b">0</span>
                  </button>
                  <button type="button" class="meal-tab-btn" data-meal="L" role="radio">
                    <i data-lucide="sun"></i> Lunch <span class="tab-count tab-count-l">0</span>
                  </button>
                  <button type="button" class="meal-tab-btn" data-meal="D" role="radio">
                    <i data-lucide="moon-star"></i> Dinner <span class="tab-count tab-count-d">0</span>
                  </button>
                </div>

                <div class="flex-row gap-xs">
                  <button type="button" class="btn btn--secondary btn--sm btn-add-all-mapped" ${isReadOnlyPast ? 'disabled' : ''}>
                    <i data-lucide="list-plus"></i> Add All Mapped
                  </button>
                  <button type="button" class="btn btn--quiet btn--sm btn-copy-to-cuisines" ${isReadOnlyPast ? 'disabled' : ''}>
                    <i data-lucide="copy-check"></i> Copy to other cuisines…
                  </button>
                </div>
              </div>

              <!-- Meal Locked Banner -->
              <div class="meal-locked-banner banner banner--neutral flex-row align-center gap-sm" style="display: none; padding: 8px 12px; border-radius: var(--radius-sm);">
                <i data-lucide="lock" style="width: 16px; height: 16px; flex-shrink: 0;"></i>
                <span class="text-xs font-semibold">This meal is locked because bills have already been issued on this date.</span>
              </div>

              <!-- Unmapped Cuisine Empty State -->
              <div class="unmapped-cuisine-empty empty-state flex-col align-center justify-center gap-sm" style="display: none; flex: 1; padding: 40px; text-align: center;">
                <i data-lucide="compass" class="color-ink-3" style="width: 44px; height: 44px;"></i>
                <h3 style="margin: 0;">No items mapped to this cuisine yet</h3>
                <p class="text-sm color-ink-2" style="max-width: 360px; margin: 0;">Open the Cuisine Editor to map dishes before creating daily menus.</p>
                <a href="#/cuisines" class="btn btn--primary btn--sm open-cuisine-editor-link">Open Cuisine Editor</a>
              </div>

              <!-- Items Table Container -->
              <div class="menu-items-table-container flex-col" style="flex: 1; overflow-y: auto;">
                <table class="menu-items-table" style="width: 100%; border-collapse: collapse; font-size: 13px;">
                  <thead>
                    <tr style="background: var(--canvas); border-bottom: 2px solid var(--separator); text-align: left;">
                      <th style="width: 40px; padding: 8px;">#</th>
                      <th style="padding: 8px;">Item Name</th>
                      <th style="width: 120px; padding: 8px;">Qty</th>
                      <th style="width: 100px; padding: 8px;">Unit</th>
                      <th style="width: 50px; padding: 8px; text-align: center;"></th>
                    </tr>
                  </thead>
                  <tbody class="menu-items-tbody">
                    <!-- Populated dynamically -->
                  </tbody>
                </table>

                <!-- Inline Add Item Row -->
                <div class="inline-add-row flex-row gap-sm align-center pt-sm" style="padding-top: 12px;">
                  <select class="field-select select-add-item text-xs" style="flex: 1;" ${isReadOnlyPast ? 'disabled' : ''}>
                    <option value="">+ Add item from mapped items…</option>
                  </select>
                </div>
              </div>

              <!-- Footer Status Strip -->
              <div class="menu-footer-status flex-row justify-between align-center pt-xs text-xs color-ink-2" style="border-top: 1px solid var(--separator);">
                <span class="cuisine-meal-status-text">Status: checking…</span>
                <span class="save-status-info text-xs color-ink-3">Changes saved across all cuisines for this date</span>
              </div>
            </div>
          </div>
        </div>
      `;
    },

    component: function(params, targetEl) {
      return {
        init: function(el) {
          var rootEl = el || targetEl || document.getElementById('outlet');
          var dateInput = rootEl.querySelector('.menu-date-input');
          var prevBtn = rootEl.querySelector('.btn-prev-day');
          var nextBtn = rootEl.querySelector('.btn-next-day');
          var todayBtn = rootEl.querySelector('.btn-jump-today');
          var saveBtn = rootEl.querySelector('.btn-save-menu');
          var resetBtn = rootEl.querySelector('.btn-reset-menu');
          var copyFromDateBtn = rootEl.querySelector('.btn-copy-from-date');
          var addAllMappedBtn = rootEl.querySelector('.btn-add-all-mapped');
          var copyToCuisinesBtn = rootEl.querySelector('.btn-copy-to-cuisines');

          var cuisinesListEl = rootEl.querySelector('.cuisines-list');
          var mealTabButtons = rootEl.querySelectorAll('.meal-tab-btn');
          var mealLockedBanner = rootEl.querySelector('.meal-locked-banner');
          var unmappedEmpty = rootEl.querySelector('.unmapped-cuisine-empty');
          var tableContainer = rootEl.querySelector('.menu-items-table-container');
          var tbody = rootEl.querySelector('.menu-items-tbody');
          var selectAddItem = rootEl.querySelector('.select-add-item');
          var statusText = rootEl.querySelector('.cuisine-meal-status-text');
          var openCuisineLink = rootEl.querySelector('.open-cuisine-editor-link');

          var allItems = (Mess.store && Mess.store.list('items')) || [];
          var allItemsMap = {};
          allItems.forEach(function(it) { allItemsMap[it.id] = it; });

          function isCurrentMealLocked() {
            if (isReadOnlyPast) return true;
            return getBillCountForMeal(currentDate, currentCuisineId, currentMealCode) > 0;
          }

          function renderCuisinesList() {
            cuisinesListEl.innerHTML = '';
            var activeCuisines = getActiveCuisines();

            activeCuisines.forEach(function(c) {
              var meals = workingMenus[c.id] || { 'B': [], 'L': [], 'D': [] };
              var hasB = meals['B'] && meals['B'].length > 0;
              var hasL = meals['L'] && meals['L'].length > 0;
              var hasD = meals['D'] && meals['D'].length > 0;

              var statusIcon = '○';
              var statusClass = 'color-ink-3';
              if (hasB && hasL && hasD) {
                statusIcon = '✔';
                statusClass = 'color-success font-bold';
              } else if (hasB || hasL || hasD) {
                statusIcon = '◐';
                statusClass = 'color-warning font-bold';
              }

              var isSelected = c.id === currentCuisineId;
              var rowDiv = document.createElement('div');
              rowDiv.className = `cuisine-nav-item flex-row justify-between align-center p-xs ${isSelected ? 'active' : ''}`;
              rowDiv.style.padding = '8px 10px';
              rowDiv.style.borderRadius = 'var(--radius-sm)';
              rowDiv.style.cursor = 'pointer';
              rowDiv.style.backgroundColor = isSelected ? 'var(--highlight)' : 'transparent';
              rowDiv.style.fontWeight = isSelected ? '600' : 'normal';

              rowDiv.innerHTML = `
                <div class="flex-row align-center gap-xs" style="overflow: hidden;">
                  <span class="status-pip ${statusClass}" style="width: 14px; text-align: center;">${statusIcon}</span>
                  <span class="cuisine-name text-sm" style="overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${c.name}</span>
                </div>
                <span class="text-xs font-mono color-ink-3">${c.code}</span>
              `;

              rowDiv.addEventListener('click', function() {
                if (currentCuisineId === c.id) return;
                currentCuisineId = c.id;
                renderCuisinesList();
                renderWorkspace();
              });

              cuisinesListEl.appendChild(rowDiv);
            });
          }

          function renderWorkspace() {
            var activeCuisines = getActiveCuisines();
            var cuisine = activeCuisines.find(function(c) { return c.id === currentCuisineId; });
            if (!cuisine) return;

            var mappedItemIds = getMappedItemIds(currentCuisineId);

            // Handle unmapped cuisine empty state
            if (mappedItemIds.length === 0) {
              unmappedEmpty.style.display = 'flex';
              tableContainer.style.display = 'none';
              openCuisineLink.href = `#/cuisines/${currentCuisineId}`;
              openCuisineLink.textContent = `Open ${cuisine.name}`;
              return;
            } else {
              unmappedEmpty.style.display = 'none';
              tableContainer.style.display = 'flex';
            }

            // Update Meal Tabs active state and counts
            var cMeals = workingMenus[currentCuisineId] || { 'B': [], 'L': [], 'D': [] };
            mealTabButtons.forEach(function(btn) {
              var m = btn.getAttribute('data-meal');
              btn.classList.toggle('active', m === currentMealCode);
              btn.setAttribute('aria-checked', m === currentMealCode ? 'true' : 'false');

              var count = (cMeals[m] || []).length;
              var countBadge = btn.querySelector('.tab-count');
              if (countBadge) countBadge.textContent = count;
            });

            // Locked banner check
            var locked = isCurrentMealLocked();
            mealLockedBanner.style.display = locked ? 'flex' : 'none';
            addAllMappedBtn.disabled = locked || isReadOnlyPast;
            copyToCuisinesBtn.disabled = locked || isReadOnlyPast;
            selectAddItem.disabled = locked || isReadOnlyPast;

            // Render Items in Grid
            tbody.innerHTML = '';
            var itemsList = cMeals[currentMealCode] || [];

            if (itemsList.length === 0) {
              tbody.innerHTML = `
                <tr>
                  <td colspan="5" class="text-center p-md color-ink-3" style="padding: 24px;">
                    No items in this meal yet. Click <strong>Add All Mapped</strong> or choose items below.
                  </td>
                </tr>
              `;
            } else {
              itemsList.forEach(function(line, idx) {
                var it = allItemsMap[line.itemId] || { name: line.itemId, unit: 'plate', code: '' };
                var tr = document.createElement('tr');
                tr.style.borderBottom = '1px solid var(--separator)';

                tr.innerHTML = `
                  <td style="padding: 8px; color: var(--ink-3); font-size: 11px;">${idx + 1}</td>
                  <td style="padding: 8px;">
                    <span class="font-medium">${it.name}</span>
                    <span class="text-xs color-ink-3 font-mono" style="margin-left: 6px;">${it.code || ''}</span>
                  </td>
                  <td style="padding: 8px;">
                    <input type="number" class="field-input item-qty-input text-center" 
                           value="${line.qty || 1}" min="1" max="99" style="width: 70px; height: 28px;"
                           ${locked || isReadOnlyPast ? 'disabled' : ''}>
                  </td>
                  <td style="padding: 8px; color: var(--ink-2);">${it.unit || 'plate'}</td>
                  <td style="padding: 8px; text-align: center;">
                    <button type="button" class="btn btn--quiet btn--icon btn--xs btn-remove-item" 
                            title="Remove item" ${locked || isReadOnlyPast ? 'disabled' : ''}>
                      <i data-lucide="x"></i>
                    </button>
                  </td>
                `;

                var qtyInput = tr.querySelector('.item-qty-input');
                qtyInput.addEventListener('input', function() {
                  line.qty = parseInt(qtyInput.value, 10) || 1;
                  markDirty();
                });

                var removeBtn = tr.querySelector('.btn-remove-item');
                removeBtn.addEventListener('click', function() {
                  itemsList.splice(idx, 1);
                  markDirty();
                  renderCuisinesList();
                  renderWorkspace();
                });

                tbody.appendChild(tr);
              });
            }

            // Populate select add item dropdown (mapped items not yet in this meal)
            var currentAddedIds = new Set(itemsList.map(function(line) { return line.itemId; }));
            selectAddItem.innerHTML = '<option value="">+ Add item from mapped items…</option>';

            mappedItemIds.forEach(function(itemId) {
              if (!currentAddedIds.has(itemId)) {
                var it = allItemsMap[itemId];
                if (it) {
                  var opt = document.createElement('option');
                  opt.value = it.id;
                  opt.textContent = `${it.name} (${it.category || ''} · ${it.unit || 'pcs'})`;
                  selectAddItem.appendChild(opt);
                }
              }
            });

            // Update footer status text
            var hasB = cMeals['B'] && cMeals['B'].length > 0;
            var hasL = cMeals['L'] && cMeals['L'].length > 0;
            var hasD = cMeals['D'] && cMeals['D'].length > 0;

            statusText.innerHTML = `
              Status for <strong>${cuisine.name}</strong>: 
              B ${hasB ? '<span class="color-success">✔</span>' : '<span class="color-danger">✖</span>'} &nbsp;
              L ${hasL ? '<span class="color-success">✔</span>' : '<span class="color-danger">✖</span>'} &nbsp;
              D ${hasD ? '<span class="color-success">✔</span>' : '<span class="color-danger">✖</span>'}
            `;

            if (window.lucide && window.lucide.createIcons) {
              window.lucide.createIcons({ root: rootEl });
            }
          }

          function markDirty() {
            if (Mess.router && Mess.router.setDirty) {
              var isDirty = JSON.stringify(workingMenus) !== initialSnapshot;
              Mess.router.setDirty(isDirty);
            }
          }

          // Meal Tabs switcher
          mealTabButtons.forEach(function(btn) {
            btn.addEventListener('click', function() {
              currentMealCode = btn.getAttribute('data-meal');
              renderWorkspace();
            });
          });

          // Add selected item from dropdown
          selectAddItem.addEventListener('change', function() {
            var itemId = selectAddItem.value;
            if (!itemId) return;

            var it = allItemsMap[itemId];
            var defQty = it && it.default_qty ? it.default_qty : (it && it.defaultQty ? it.defaultQty : 1);

            var itemsList = workingMenus[currentCuisineId][currentMealCode];
            itemsList.push({ itemId: itemId, qty: defQty });

            markDirty();
            renderCuisinesList();
            renderWorkspace();
          });

          // Add All Mapped button
          addAllMappedBtn.addEventListener('click', function() {
            var mappedItemIds = getMappedItemIds(currentCuisineId);
            var itemsList = workingMenus[currentCuisineId][currentMealCode];
            var currentSet = new Set(itemsList.map(function(i) { return i.itemId; }));

            var added = 0;
            mappedItemIds.forEach(function(itemId) {
              if (!currentSet.has(itemId)) {
                var it = allItemsMap[itemId];
                var defQty = it && it.default_qty ? it.default_qty : (it && it.defaultQty ? it.defaultQty : 1);
                itemsList.push({ itemId: itemId, qty: defQty });
                added++;
              }
            });

            markDirty();
            renderCuisinesList();
            renderWorkspace();

            if (Mess.ui && Mess.ui.toast) {
              Mess.ui.toast('success', `Added ${added} mapped items to ${currentMealCode === 'B' ? 'Breakfast' : currentMealCode === 'L' ? 'Lunch' : 'Dinner'}.`);
            }
          });

          // Copy to other cuisines button
          copyToCuisinesBtn.addEventListener('click', function() {
            var currentItems = workingMenus[currentCuisineId][currentMealCode] || [];
            if (currentItems.length === 0) {
              if (Mess.ui && Mess.ui.toast) Mess.ui.toast('error', 'Current meal tab has no items to copy.');
              return;
            }

            var otherCuisines = getActiveCuisines().filter(function(c) { return c.id !== currentCuisineId; });
            var dialogHtml = document.createElement('div');
            dialogHtml.className = 'flex-col gap-sm';
            dialogHtml.innerHTML = `
              <p class="text-sm">Copy ${currentItems.length} items from this meal to target cuisines:</p>
              <div class="target-cuisines-checks flex-col gap-xs p-xs card-inset" style="max-height: 200px; overflow-y: auto;">
                ${otherCuisines.map(function(c) {
                  return `
                    <label class="checkbox-label text-sm flex-row align-center gap-xs">
                      <input type="checkbox" class="checkbox target-cuisine-cb" value="${c.id}" checked>
                      <span>${c.name} (${c.code})</span>
                    </label>
                  `;
                }).join('')}
              </div>
              <span class="text-xs color-ink-3">Items not mapped to target cuisine will be skipped.</span>
            `;

            if (Mess.dialog && Mess.dialog.confirm) {
              Mess.dialog.confirm('Copy Meal to Other Cuisines', dialogHtml, {
                confirmText: 'Copy Meal',
                cancelText: 'Cancel'
              }).then(function(confirmed) {
                if (!confirmed) return;
                var checkedEls = dialogHtml.querySelectorAll('.target-cuisine-cb:checked');
                var targetIds = Array.from(checkedEls).map(function(cb) { return cb.value; });

                var summary = [];
                targetIds.forEach(function(targetId) {
                  var targetCuis = otherCuisines.find(function(c) { return c.id === targetId; });
                  var targetMapped = new Set(getMappedItemIds(targetId));
                  var targetMealItems = workingMenus[targetId][currentMealCode];
                  var existingSet = new Set(targetMealItems.map(function(i) { return i.itemId; }));

                  var added = 0;
                  var skippedUnmapped = 0;

                  currentItems.forEach(function(line) {
                    if (targetMapped.has(line.itemId)) {
                      if (!existingSet.has(line.itemId)) {
                        targetMealItems.push({ itemId: line.itemId, qty: line.qty });
                        added++;
                      }
                    } else {
                      skippedUnmapped++;
                    }
                  });

                  summary.push(`${targetCuis.name}: +${added} (${skippedUnmapped} skipped)`);
                });

                markDirty();
                renderCuisinesList();
                renderWorkspace();

                if (Mess.ui && Mess.ui.toast) {
                  Mess.ui.toast('success', `Copied meal: ${summary.join(' · ')}`);
                }
              });
            }
          });

          // Copy from another date button
          copyFromDateBtn.addEventListener('click', function() {
            var promptDiv = document.createElement('div');
            promptDiv.className = 'flex-col gap-sm';
            promptDiv.innerHTML = `
              <label class="text-sm font-semibold">Select source date to copy full menu from:</label>
              <input type="date" class="field-input source-copy-date" value="${shiftDate(currentDate, -1)}" max="${currentDate}">
              <span class="text-xs color-ink-3">Copies Breakfast, Lunch, and Dinner across all cuisines.</span>
            `;

            if (Mess.dialog && Mess.dialog.confirm) {
              Mess.dialog.confirm('Copy Full Menu from Date', promptDiv, {
                confirmText: 'Copy Menu',
                cancelText: 'Cancel'
              }).then(function(confirmed) {
                if (!confirmed) return;
                var srcDate = promptDiv.querySelector('.source-copy-date').value;
                if (!srcDate) return;

                var storedMenus = (Mess.store && Mess.store.list('menus')) || [];
                var srcMenus = storedMenus.filter(function(m) { return m.date === srcDate; });

                if (srcMenus.length === 0) {
                  if (Mess.ui && Mess.ui.toast) Mess.ui.toast('error', `No menu found for source date ${srcDate}.`);
                  return;
                }

                var activeCuisines = getActiveCuisines();
                activeCuisines.forEach(function(c) {
                  var targetMapped = new Set(getMappedItemIds(c.id));
                  ['B', 'L', 'D'].forEach(function(meal) {
                    var srcM = srcMenus.find(function(m) {
                      var cId = m.cuisine_id || m.cuisineId;
                      var mType = (m.meal_type || m.meal || '').toUpperCase();
                      return cId === c.id && mType === meal;
                    });
                    if (srcM && srcM.items) {
                      workingMenus[c.id][meal] = srcM.items
                        .filter(function(it) { return targetMapped.has(it.itemId || it.item_id); })
                        .map(function(it) { return { itemId: it.itemId || it.item_id, qty: it.qty || 1 }; });
                    }
                  });
                });

                markDirty();
                renderCuisinesList();
                renderWorkspace();

                if (Mess.ui && Mess.ui.toast) {
                  Mess.ui.toast('success', `Copied menus from ${srcDate} to ${currentDate}.`);
                }
              });
            }
          });

          // Date navigation
          function changeDate(newDate) {
            currentDate = newDate;
            dateInput.value = currentDate;
            var today = getTodayIso();
            isReadOnlyPast = currentDate < today;
            rootEl.querySelector('.past-date-banner').style.display = isReadOnlyPast ? 'flex' : 'none';
            saveBtn.disabled = isReadOnlyPast;
            resetBtn.disabled = isReadOnlyPast;
            copyFromDateBtn.disabled = isReadOnlyPast;

            loadWorkingMenusForDate(currentDate);
            renderCuisinesList();
            renderWorkspace();
          }

          dateInput.addEventListener('change', function() { changeDate(dateInput.value); });
          prevBtn.addEventListener('click', function() { changeDate(shiftDate(currentDate, -1)); });
          nextBtn.addEventListener('click', function() { changeDate(shiftDate(currentDate, 1)); });
          todayBtn.addEventListener('click', function() { changeDate(getTodayIso()); });

          // Reset Menu
          resetBtn.addEventListener('click', function() {
            loadWorkingMenusForDate(currentDate);
            renderCuisinesList();
            renderWorkspace();
            if (Mess.ui && Mess.ui.toast) Mess.ui.toast('info', 'Menu reset to saved state.');
          });

          // Single-Transaction Save
          saveBtn.addEventListener('click', function() {
            if (isReadOnlyPast) return;

            var activeCuisines = getActiveCuisines();
            var allStored = (Mess.store && Mess.store.list('menus')) || [];
            
            // Remove existing menus for this date
            var remaining = allStored.filter(function(m) { return m.date !== currentDate; });

            // Build new menu records
            activeCuisines.forEach(function(c) {
              ['B', 'L', 'D'].forEach(function(meal) {
                var items = workingMenus[c.id][meal] || [];
                if (items.length > 0) {
                  remaining.push({
                    id: `${currentDate}_${c.id}_${meal}`,
                    date: currentDate,
                    cuisine_id: c.id,
                    cuisineId: c.id,
                    meal_type: meal,
                    meal: meal,
                    items: items,
                    saved_by: 'admin',
                    saved_at: new Date().toISOString()
                  });
                }
              });
            });

            // Update store and persistence
            if (Mess.store._data) {
              Mess.store._data['menus'] = remaining;
            }
            if (Mess.persist && Mess.persist.saveCollection) {
              Mess.persist.saveCollection('menus', remaining);
            }

            initialSnapshot = JSON.stringify(workingMenus);
            if (Mess.router && Mess.router.setDirty) {
              Mess.router.setDirty(false);
            }

            if (Mess.ui && Mess.ui.toast) {
              Mess.ui.toast('success', `Daily menu for ${currentDate} saved across all cuisines.`);
            }

            renderCuisinesList();
            renderWorkspace();
          });

          // Initial Render
          renderCuisinesList();
          renderWorkspace();
        },

        destroy: function() {
          if (Mess.router && Mess.router.setDirty) {
            Mess.router.setDirty(false);
          }
        }
      };
    }
  });
})(window.Mess);
