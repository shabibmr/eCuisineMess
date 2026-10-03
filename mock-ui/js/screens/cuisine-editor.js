/* cuisine-editor.js - Screen 5: Cuisine Master Form & Item Mapping */

window.Mess = window.Mess || {};

(function(Mess) {
  var dualPaneInstance = null;
  var currentCuisineId = null;

  function getNextCuisineCode() {
    var cuisines = (Mess.store && Mess.store.list('cuisines')) || [];
    var maxNum = 0;
    cuisines.forEach(function(c) {
      if (c.code) {
        var match = c.code.match(/CUIS-(\d+)/i);
        if (match) {
          var n = parseInt(match[1], 10);
          if (n > maxNum) maxNum = n;
        }
      }
    });
    var next = maxNum + 1;
    return 'CUIS-' + String(next).padStart(2, '0');
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
    id: 'cuisine-editor',
    route: '/cuisines/:id',
    title: 'Cuisine Editor',
    roles: ['admin', 'supervisor'],

    template: function(params) {
      var id = params && params.id ? params.id : 'new';
      var isNew = !id || id === 'new';
      currentCuisineId = id;

      var cuisine = isNew ? {
        id: 'cuis_' + Date.now(),
        code: getNextCuisineCode(),
        name: '',
        description: '',
        active: true
      } : (Mess.store ? Mess.store.get('cuisines', id) : {});

      var title = isNew ? 'New Cuisine' : ('Edit Cuisine – ' + (cuisine.name || cuisine.code || id));

      return /* html */ `
        <div class="cuisine-editor-screen flex-col gap-lg" style="height: 100%;">
          <!-- Header -->
          <div class="toolbar flex-row justify-between align-center">
            <div>
              <h2 style="margin: 0;">${title}</h2>
              <span class="text-sm color-ink-2">Define cuisine details and mapped items</span>
            </div>
            <div class="flex-row gap-sm">
              <a href="#/cuisines" class="btn btn--secondary cancel-btn">Cancel</a>
              <button type="button" class="btn btn--primary save-cuisine-btn">
                <i data-lucide="check"></i> Save Cuisine
              </button>
            </div>
          </div>

          <!-- No-Mapping Warning Banner -->
          <div class="no-mapping-warning banner banner--warning flex-row align-center gap-sm" style="display: none; padding: 10px 16px; border-radius: var(--radius-panel); background: var(--surface); border: 1px solid var(--meal-b);">
            <i data-lucide="alert-triangle" class="color-meal-b" style="width: 20px; height: 20px; flex-shrink: 0;"></i>
            <div class="flex-col" style="flex: 1;">
              <span class="text-sm font-semibold">No items mapped to this cuisine yet.</span>
              <span class="text-xs color-ink-2">Members assigned to this cuisine will have no default items on the counter. Map items below.</span>
            </div>
          </div>

          <!-- Cuisine Details Card -->
          <div class="card flex-col gap-md">
            <h3 style="margin: 0; font-size: 15px;">General Details</h3>
            <div class="grid-3col gap-md">
              <div class="field-group">
                <label class="field-label required">Cuisine Code</label>
                <input type="text" class="field-input font-mono uppercase cuisine-code-input" 
                       value="${cuisine.code || ''}" placeholder="e.g. CUIS-01" required>
                <span class="field-error-msg text-xs color-danger err-code" style="display:none;"></span>
              </div>

              <div class="field-group">
                <label class="field-label required">Cuisine Name</label>
                <input type="text" class="field-input cuisine-name-input" 
                       value="${cuisine.name || ''}" placeholder="e.g. South Indian" required>
                <span class="field-error-msg text-xs color-danger err-name" style="display:none;"></span>
              </div>

              <div class="field-group">
                <label class="field-label">Active Status</label>
                <label class="switch-label flex-row align-center gap-sm pt-xs" style="cursor: pointer;">
                  <input type="checkbox" class="switch cuisine-active-switch" ${cuisine.active !== false ? 'checked' : ''}>
                  <span class="text-sm">Active in menus & member selection</span>
                </label>
              </div>
            </div>

            <div class="field-group">
              <label class="field-label">Description / Region</label>
              <input type="text" class="field-input cuisine-desc-input" 
                     value="${cuisine.description || ''}" placeholder="e.g. Rice, sambar, rasam and traditional sides">
            </div>
          </div>

          <!-- Item Mapping Section -->
          <div class="card flex-col gap-md" style="flex: 1; min-height: 440px;">
            <div class="flex-row justify-between align-center">
              <div>
                <h3 style="margin: 0; font-size: 15px;">Item Mapping</h3>
                <span class="text-xs color-ink-2">Select items available for daily menus in this cuisine</span>
              </div>
              <div class="flex-row gap-xs">
                <button type="button" class="btn btn--secondary btn--sm btn-copy-mapping">
                  <i data-lucide="copy"></i> Copy mapping from…
                </button>
              </div>
            </div>

            <!-- Dual-pane host container -->
            <div class="dual-pane-container" style="flex: 1; display: flex;"></div>
          </div>
        </div>
      `;
    },

    component: function(params, targetEl) {
      return {
        init: function(el) {
          var rootEl = el || targetEl || document.getElementById('outlet');
          var id = params && params.id ? params.id : 'new';
          var isNew = !id || id === 'new';

          var codeInput = rootEl.querySelector('.cuisine-code-input');
          var nameInput = rootEl.querySelector('.cuisine-name-input');
          var descInput = rootEl.querySelector('.cuisine-desc-input');
          var activeSwitch = rootEl.querySelector('.cuisine-active-switch');
          var saveBtn = rootEl.querySelector('.save-cuisine-btn');
          var copyBtn = rootEl.querySelector('.btn-copy-mapping');
          var warningBanner = rootEl.querySelector('.no-mapping-warning');
          var dualPaneHost = rootEl.querySelector('.dual-pane-container');
          var errCode = rootEl.querySelector('.err-code');
          var errName = rootEl.querySelector('.err-name');

          // Gather all items and existing mappings
          var allItems = (Mess.store && Mess.store.list('items')) || [];
          var mappings = (Mess.store && Mess.store.list('cuisine_items')) || [];
          var mappedItemIds = new Set(
            mappings.filter(function(m) { return m.cuisine_id === id; }).map(function(m) { return m.item_id; })
          );

          var selectedItems = [];
          var availableItems = [];

          allItems.forEach(function(item) {
            if (mappedItemIds.has(item.id)) {
              selectedItems.push(item);
            } else {
              availableItems.push(item);
            }
          });

          // Categories for dual-pane filter
          var categories = Array.from(new Set(allItems.map(function(i) { return i.category; }).filter(Boolean))).sort();

          function updateWarning() {
            var count = dualPaneInstance ? dualPaneInstance.getSelected().length : selectedItems.length;
            warningBanner.style.display = count === 0 ? 'flex' : 'none';
          }

          // Unmap check hook (Rule: Cannot unmap if used in upcoming menu)
          function checkBeforeRemove(itemsToRemove) {
            if (isNew) return true;
            var todayStr = getTodayIso();
            var menus = (Mess.store && Mess.store.list('menus')) || [];
            var futureMenus = menus.filter(function(m) {
              return m.cuisine_id === id && m.date >= todayStr;
            });

            var blockedItem = null;
            var blockedDates = [];

            for (var i = 0; i < itemsToRemove.length; i++) {
              var item = itemsToRemove[i];
              for (var j = 0; j < futureMenus.length; j++) {
                var menu = futureMenus[j];
                var hasItem = (menu.items || []).some(function(line) {
                  return (line.item_id === item.id) || (line.name === item.name);
                });
                if (hasItem) {
                  blockedItem = item;
                  if (blockedDates.indexOf(menu.date) === -1) {
                    blockedDates.push(menu.date);
                  }
                }
              }
              if (blockedItem) break;
            }

            if (blockedItem) {
              var dateList = blockedDates.join(', ');
              var msg = `Cannot unmap "${blockedItem.name}": Used in daily menu on ${dateList}. Remove it from the daily menu first.`;
              
              if (Mess.dialog && Mess.dialog.confirm) {
                Mess.dialog.confirm('Item In Use on Daily Menu', msg, {
                  confirmText: 'Open Daily Menu',
                  cancelText: 'OK'
                }).then(function(openMenu) {
                  if (openMenu) {
                    window.location.hash = `#/menu-editor?date=${blockedDates[0]}&cuisine=${id}`;
                  }
                });
              } else {
                alert(msg);
              }

              return { allowed: false, reason: msg };
            }

            return true;
          }

          // Initialize Dual Pane
          dualPaneInstance = Mess.createDualPane(dualPaneHost, {
            availableTitle: 'Available Items',
            selectedTitle: 'Mapped Items for this Cuisine',
            available: availableItems,
            selected: selectedItems,
            categories: categories,
            beforeRemove: checkBeforeRemove,
            onChange: function(newSelected) {
              updateWarning();
              if (Mess.router && Mess.router.setDirty) {
                Mess.router.setDirty(true);
              }
            }
          });

          updateWarning();

          // Copy mapping from other cuisine button
          copyBtn.addEventListener('click', function() {
            var cuisines = (Mess.store && Mess.store.list('cuisines')) || [];
            var others = cuisines.filter(function(c) { return c.id !== id; });

            if (others.length === 0) {
              if (Mess.ui && Mess.ui.toast) Mess.ui.toast('error', 'No other cuisines available to copy from.');
              return;
            }

            var promptDiv = document.createElement('div');
            promptDiv.className = 'flex-col gap-sm';
            promptDiv.innerHTML = `
              <label class="text-sm font-semibold">Select source cuisine:</label>
              <select class="field-select source-cuisine-select">
                ${others.map(function(c) { return `<option value="${c.id}">${c.name} (${c.code})</option>`; }).join('')}
              </select>
              <span class="text-xs color-ink-3">Items will be added to the current mapping. Existing mapped items are preserved.</span>
            `;

            if (Mess.dialog && Mess.dialog.confirm) {
              Mess.dialog.confirm('Copy Mapping from Cuisine', promptDiv, {
                confirmText: 'Copy Mapping',
                cancelText: 'Cancel'
              }).then(function(confirmed) {
                if (!confirmed) return;
                var selectEl = promptDiv.querySelector('.source-cuisine-select');
                var sourceId = selectEl.value;
                var sourceCuisine = others.find(function(c) { return c.id === sourceId; });

                var sourceMappings = (Mess.store && Mess.store.list('cuisine_items')) || [];
                var sourceItemIds = new Set(
                  sourceMappings.filter(function(m) { return m.cuisine_id === sourceId; }).map(function(m) { return m.item_id; })
                );

                var currentSelected = dualPaneInstance.getSelected();
                var currentIds = new Set(currentSelected.map(function(i) { return i.id; }));

                var addedCount = 0;
                var skippedCount = 0;

                allItems.forEach(function(item) {
                  if (sourceItemIds.has(item.id)) {
                    if (currentIds.has(item.id)) {
                      skippedCount++;
                    } else {
                      currentSelected.push(item);
                      addedCount++;
                    }
                  }
                });

                dualPaneInstance.setSelected(currentSelected);
                updateWarning();
                if (Mess.router && Mess.router.setDirty) {
                  Mess.router.setDirty(true);
                }

                if (Mess.ui && Mess.ui.toast) {
                  Mess.ui.toast('success', `Added ${addedCount} items from ${sourceCuisine.name} (${skippedCount} duplicates skipped).`);
                }
              });
            }
          });

          // Save handler
          saveBtn.addEventListener('click', function() {
            var code = codeInput.value.trim().toUpperCase();
            var name = nameInput.value.trim();
            var description = descInput.value.trim();
            var active = activeSwitch.checked;

            errCode.style.display = 'none';
            errName.style.display = 'none';
            codeInput.classList.remove('invalid');
            nameInput.classList.remove('invalid');

            var hasError = false;
            if (!code) {
              errCode.textContent = 'Cuisine code is required';
              errCode.style.display = 'block';
              codeInput.classList.add('invalid');
              hasError = true;
            } else {
              // Duplicate check
              var allCuisines = (Mess.store && Mess.store.list('cuisines')) || [];
              var dup = allCuisines.find(function(c) {
                return c.code && c.code.trim().toUpperCase() === code && c.id !== id;
              });
              if (dup) {
                errCode.textContent = 'Cuisine code already exists';
                errCode.style.display = 'block';
                codeInput.classList.add('invalid');
                hasError = true;
              }
            }

            if (!name) {
              errName.textContent = 'Cuisine name is required';
              errName.style.display = 'block';
              nameInput.classList.add('invalid');
              hasError = true;
            }

            if (hasError) return;

            // 1. Save cuisine header
            var cuisineRecord = {
              id: id === 'new' ? ('cuis_' + Date.now()) : id,
              code: code,
              name: name,
              description: description,
              active: active
            };

            Mess.store.save('cuisines', cuisineRecord);

            // 2. Save mappings in cuisine_items
            var selectedList = dualPaneInstance.getSelected();
            var currentMappings = (Mess.store.list('cuisine_items') || []).slice();

            // Remove existing mappings for this cuisine
            var filteredMappings = currentMappings.filter(function(m) {
              return m.cuisine_id !== cuisineRecord.id;
            });

            // Add new mappings
            selectedList.forEach(function(item) {
              filteredMappings.push({
                id: 'ci_' + cuisineRecord.id + '_' + item.id,
                cuisine_id: cuisineRecord.id,
                item_id: item.id
              });
            });

            // Persist mappings collection
            if (Mess.store._data) {
              Mess.store._data['cuisine_items'] = filteredMappings;
              if (Mess.persist && Mess.persist.saveCollection) {
                Mess.persist.saveCollection('cuisine_items', filteredMappings);
              }
            }

            if (Mess.router && Mess.router.setDirty) {
              Mess.router.setDirty(false);
            }

            if (Mess.ui && Mess.ui.toast) {
              Mess.ui.toast('success', `Cuisine "${name}" saved with ${selectedList.length} mapped items.`);
            }

            window.location.hash = '#/cuisines';
          });
        },

        destroy: function() {
          if (dualPaneInstance) {
            dualPaneInstance.destroy();
            dualPaneInstance = null;
          }
          if (Mess.router && Mess.router.setDirty) {
            Mess.router.setDirty(false);
          }
        }
      };
    }
  });
})(window.Mess);
