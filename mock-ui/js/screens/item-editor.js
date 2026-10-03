/* item-editor.js - Screen 2: Item Master Form View */

window.Mess = window.Mess || {};

(function(Mess) {
  var frame = null;

  function getNextItemCode() {
    var items = (Mess.store && Mess.store.list('items')) || [];
    var maxNum = 0;
    items.forEach(function(item) {
      if (item.code) {
        var match = item.code.match(/ITM-(\d+)/i);
        if (match) {
          var n = parseInt(match[1], 10);
          if (n > maxNum) maxNum = n;
        }
      }
    });
    var next = maxNum + 1;
    return 'ITM-' + String(next).padStart(3, '0');
  }

  Mess.screens.register({
    id: 'item-editor',
    route: '/items/:id',
    title: 'Item Editor',
    roles: ['admin', 'supervisor'],

    template: function(params) {
      var id = params && params.id ? params.id : 'new';
      
      frame = Mess.createEditorFrame({
        kind: 'items',
        entityName: 'Item',
        listRoute: '#/items',

        getNewData: function() {
          return {
            id: 'item_' + Date.now(),
            code: getNextItemCode(),
            name: '',
            category: 'Main',
            unit: 'plate',
            default_qty: 1,
            active: true
          };
        },

        fieldsHtml: function(data, isNew) {
          var items = (Mess.store && Mess.store.list('items')) || [];
          var cats = Array.from(new Set(items.map(function(i) { return i.category; }).filter(Boolean))).sort();
          if (data.category && cats.indexOf(data.category) === -1) {
            cats.push(data.category);
          }

          var unitChips = ['pcs', 'plate', 'bowl', 'cup', 'glass', 'portion', 'pack'];

          // Mapped cuisines query
          var mappedCuisines = [];
          if (!isNew && data.id && Mess.store) {
            var mappings = Mess.store.list('cuisine_items') || [];
            var allCuisines = Mess.store.list('cuisines') || [];
            var cuisineMap = {};
            allCuisines.forEach(function(c) { cuisineMap[c.id] = c; });

            mappings.forEach(function(m) {
              if (m.item_id === data.id && cuisineMap[m.cuisine_id]) {
                mappedCuisines.push(cuisineMap[m.cuisine_id]);
              }
            });
          }

          var mappedHtml = '';
          if (isNew) {
            mappedHtml = '<span class="text-sm color-ink-3">New item — save first to map to cuisines.</span>';
          } else if (mappedCuisines.length === 0) {
            mappedHtml = '<span class="text-sm color-ink-3">Not mapped to any cuisine yet.</span>';
          } else {
            mappedHtml = mappedCuisines.map(function(c) {
              return `<a href="#/cuisines/${c.id}" class="badge badge--neutral text-sm flex-row align-center gap-xs" style="text-decoration:none;">
                <i data-lucide="compass"></i> ${c.name}
              </a>`;
            }).join(' ');
          }

          return /* html */ `
            <input type="hidden" name="id" value="${data.id || ''}">

            <div class="card flex-col gap-md">
              <div class="grid-2col gap-md">
                <!-- Item Code -->
                <div class="field-group">
                  <label class="field-label required">Item Code</label>
                  <input type="text" name="code" class="field-input font-mono uppercase" 
                         value="${data.code || ''}" placeholder="e.g. ITM-001" required>
                  <span class="field-error-msg text-xs color-danger" id="err-code" style="display:none;"></span>
                </div>

                <!-- Active Toggle -->
                <div class="field-group justify-end" style="align-self: center;">
                  <label class="switch-label flex-row align-center gap-sm" style="cursor: pointer;">
                    <input type="checkbox" name="active" class="switch" ${data.active !== false ? 'checked' : ''}>
                    <span class="text-sm font-semibold">Active Status</span>
                  </label>
                </div>
              </div>

              <!-- Item Name -->
              <div class="field-group">
                <label class="field-label required">Item Name</label>
                <input type="text" name="name" class="field-input" 
                       value="${data.name || ''}" placeholder="e.g. Idli or Sambar" required>
                <span class="field-error-msg text-xs color-danger" id="err-name" style="display:none;"></span>
              </div>

              <div class="grid-2col gap-md">
                <!-- Category with inline add -->
                <div class="field-group">
                  <div class="flex-row justify-between align-center">
                    <label class="field-label required">Category</label>
                    <button type="button" class="btn btn--quiet btn--xs btn-add-category">
                      <i data-lucide="plus"></i> Add category
                    </button>
                  </div>
                  <select name="category" class="field-select category-select" required>
                    ${cats.map(function(c) {
                      return `<option value="${c}" ${data.category === c ? 'selected' : ''}>${c}</option>`;
                    }).join('')}
                  </select>
                  <span class="field-error-msg text-xs color-danger" id="err-category" style="display:none;"></span>
                </div>

                <!-- Unit & Quick Chips -->
                <div class="field-group">
                  <label class="field-label required">Unit of Measure</label>
                  <input type="text" name="unit" class="field-input unit-input" 
                         value="${data.unit || 'plate'}" placeholder="e.g. plate, pcs" required>
                  <div class="unit-chips flex-row wrap gap-xs pt-xs">
                    ${unitChips.map(function(u) {
                      var active = (data.unit || 'plate').toLowerCase() === u.toLowerCase() ? 'badge--primary' : 'badge--neutral';
                      return `<button type="button" class="badge ${active} unit-chip-btn text-xs" data-unit="${u}" style="cursor:pointer; border:none;">${u}</button>`;
                    }).join('')}
                  </div>
                  <span class="field-error-msg text-xs color-danger" id="err-unit" style="display:none;"></span>
                </div>
              </div>

              <!-- Default Quantity with Stepper -->
              <div class="field-group" style="max-width: 240px;">
                <label class="field-label">Default Quantity</label>
                <div class="stepper flex-row align-center">
                  <button type="button" class="btn btn--secondary btn-step-down" style="border-top-right-radius:0; border-bottom-right-radius:0;">-</button>
                  <input type="number" name="default_qty" class="field-input text-center font-mono qty-input" 
                         value="${data.default_qty != null ? data.default_qty : 1}" min="1" max="99" 
                         style="border-radius: 0; width: 64px; text-align: center;">
                  <button type="button" class="btn btn--secondary btn-step-up" style="border-top-left-radius:0; border-bottom-left-radius:0;">+</button>
                </div>
              </div>

              <!-- Read-only Mapped Cuisines Section -->
              <div class="field-group pt-md" style="border-top: 1px solid var(--separator);">
                <label class="field-label text-xs color-ink-2">Mapped Cuisines (Read-only)</label>
                <div class="mapped-cuisines-list flex-row wrap gap-xs pt-xs">
                  ${mappedHtml}
                </div>
              </div>
            </div>
          `;
        },

        readForm: function(form) {
          var id = form.querySelector('[name="id"]').value;
          var code = form.querySelector('[name="code"]').value.trim().toUpperCase();
          var name = form.querySelector('[name="name"]').value.trim();
          var category = form.querySelector('[name="category"]').value;
          var unit = form.querySelector('[name="unit"]').value.trim();
          var default_qty = parseInt(form.querySelector('[name="default_qty"]').value, 10) || 1;
          var active = form.querySelector('[name="active"]').checked;

          return {
            id: id,
            code: code,
            name: name,
            category: category,
            unit: unit,
            default_qty: default_qty,
            active: active
          };
        },

        validate: function(data) {
          var errors = {};
          var valid = true;

          if (!data.code) {
            errors.code = 'Item code is required';
            valid = false;
          } else {
            // Check for duplicate code
            if (Mess.store) {
              var allItems = Mess.store.list('items') || [];
              var dup = allItems.find(function(it) {
                return it.code && it.code.trim().toUpperCase() === data.code.trim().toUpperCase() && it.id !== data.id;
              });
              if (dup) {
                errors.code = 'Item code already exists';
                valid = false;
              }
            }
          }

          if (!data.name) {
            errors.name = 'Item name is required';
            valid = false;
          }

          if (!data.category) {
            errors.category = 'Category is required';
            valid = false;
          }

          if (!data.unit) {
            errors.unit = 'Unit is required';
            valid = false;
          }

          return { valid: valid, errors: errors };
        },

        onMount: function(rootEl, currentData) {
          // Wire stepper buttons
          var downBtn = rootEl.querySelector('.btn-step-down');
          var upBtn = rootEl.querySelector('.btn-step-up');
          var qtyInput = rootEl.querySelector('.qty-input');

          if (downBtn && upBtn && qtyInput) {
            downBtn.addEventListener('click', function() {
              var val = parseInt(qtyInput.value, 10) || 1;
              if (val > 1) {
                qtyInput.value = val - 1;
                qtyInput.dispatchEvent(new Event('input', { bubbles: true }));
              }
            });
            upBtn.addEventListener('click', function() {
              var val = parseInt(qtyInput.value, 10) || 1;
              if (val < 99) {
                qtyInput.value = val + 1;
                qtyInput.dispatchEvent(new Event('input', { bubbles: true }));
              }
            });
          }

          // Wire unit chips
          var unitInput = rootEl.querySelector('.unit-input');
          var unitChips = rootEl.querySelectorAll('.unit-chip-btn');
          unitChips.forEach(function(chip) {
            chip.addEventListener('click', function() {
              var u = chip.getAttribute('data-unit');
              if (unitInput) {
                unitInput.value = u;
                unitInput.dispatchEvent(new Event('input', { bubbles: true }));
              }
              unitChips.forEach(function(c) {
                c.className = 'badge badge--neutral unit-chip-btn text-xs';
              });
              chip.className = 'badge badge--primary unit-chip-btn text-xs';
            });
          });

          // Wire inline add category
          var addCatBtn = rootEl.querySelector('.btn-add-category');
          var catSelect = rootEl.querySelector('.category-select');
          if (addCatBtn && catSelect) {
            addCatBtn.addEventListener('click', function() {
              if (Mess.dialog && Mess.dialog.prompt) {
                Mess.dialog.prompt('New Category', 'Enter category name:').then(function(newCat) {
                  if (newCat && newCat.trim()) {
                    var val = newCat.trim();
                    var opt = document.createElement('option');
                    opt.value = val;
                    opt.textContent = val;
                    catSelect.appendChild(opt);
                    catSelect.value = val;
                    catSelect.dispatchEvent(new Event('change', { bubbles: true }));
                  }
                });
              }
            });
          }
        }
      });

      return frame.template(id);
    },

    component: function(params, targetEl) {
      return {
        init: function(el) {
          var rootEl = el || targetEl || document.getElementById('outlet');
          var id = params && params.id ? params.id : 'new';
          if (frame && rootEl) {
            frame.init(rootEl, id);
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
