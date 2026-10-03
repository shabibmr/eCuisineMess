/* dual-pane.js - Dual-pane selector component with multi-select, drag reordering, and veto hooks */

window.Mess = window.Mess || {};

(function(Mess) {
  Mess.createDualPane = function(containerEl, options) {
    options = options || {};
    var availableTitle = options.availableTitle || 'Available Items';
    var selectedTitle = options.selectedTitle || 'Mapped Items';
    var availableItems = (options.available || []).slice();
    var selectedItems = (options.selected || []).slice();
    var categories = options.categories || [];
    var onChange = options.onChange || null;
    var beforeRemove = options.beforeRemove || null; // function(items): boolean | { allowed, reason } | Promise

    var leftSearch = '';
    var leftCategory = 'all';
    var rightSearch = '';

    var sortableInstance = null;

    // Build markup
    var html = `
      <div class="dual-pane">
        <!-- Left Pane: Available -->
        <div class="pane-box pane-box--left flex-col">
          <div class="pane-header flex-row justify-between align-center">
            <span class="pane-title">${availableTitle}</span>
            <span class="badge left-count-badge">0</span>
          </div>

          <div class="pane-toolbar flex-row gap-xs p-xs" style="padding: 8px; border-bottom: 1px solid var(--separator); background: var(--canvas);">
            <input type="search" class="field-input left-search-input text-xs" placeholder="Search available..." style="flex: 1; padding: 4px 8px; height: 28px;">
            ${categories.length > 0 ? `
              <select class="field-select left-cat-select text-xs" style="width: 110px; height: 28px; padding: 2px 6px;">
                <option value="all">All Cats</option>
                ${categories.map(function(c) { return `<option value="${c}">${c}</option>`; }).join('')}
              </select>
            ` : ''}
          </div>

          <div class="pane-body left-pane-list" style="flex: 1; overflow-y: auto; padding: 6px;"></div>

          <div class="pane-footer p-xs flex-row justify-between align-center text-xs color-ink-3" style="padding: 4px 8px; border-top: 1px solid var(--separator); background: var(--canvas);">
            <button type="button" class="btn btn--quiet btn--xs select-all-left">Select all</button>
            <span class="left-selected-count">0 selected</span>
          </div>
        </div>

        <!-- Center Controls -->
        <div class="pane-controls">
          <button type="button" class="btn btn--secondary btn--icon btn-move-right" title="Move selected right">
            <i data-lucide="chevron-right"></i>
          </button>
          <button type="button" class="btn btn--quiet btn--icon btn-move-all-right" title="Move all right">
            <i data-lucide="chevrons-right"></i>
          </button>
          <button type="button" class="btn btn--secondary btn--icon btn-move-left" title="Move selected left">
            <i data-lucide="chevron-left"></i>
          </button>
          <button type="button" class="btn btn--quiet btn--icon btn-move-all-left" title="Move all left">
            <i data-lucide="chevrons-left"></i>
          </button>
        </div>

        <!-- Right Pane: Selected -->
        <div class="pane-box pane-box--right flex-col">
          <div class="pane-header flex-row justify-between align-center">
            <span class="pane-title">${selectedTitle}</span>
            <span class="badge badge--primary right-count-badge">0</span>
          </div>

          <div class="pane-toolbar flex-row gap-xs p-xs" style="padding: 8px; border-bottom: 1px solid var(--separator); background: var(--canvas);">
            <input type="search" class="field-input right-search-input text-xs" placeholder="Search mapped..." style="flex: 1; padding: 4px 8px; height: 28px;">
          </div>

          <div class="pane-body right-pane-list" style="flex: 1; overflow-y: auto; padding: 6px;"></div>

          <div class="pane-footer p-xs flex-row justify-between align-center text-xs color-ink-3" style="padding: 4px 8px; border-top: 1px solid var(--separator); background: var(--canvas);">
            <button type="button" class="btn btn--quiet btn--xs select-all-right">Select all</button>
            <span class="right-selected-count">0 selected</span>
          </div>
        </div>
      </div>
    `;

    containerEl.innerHTML = html;

    var leftListEl = containerEl.querySelector('.left-pane-list');
    var rightListEl = containerEl.querySelector('.right-pane-list');
    var leftSearchInput = containerEl.querySelector('.left-search-input');
    var leftCatSelect = containerEl.querySelector('.left-cat-select');
    var rightSearchInput = containerEl.querySelector('.right-search-input');
    var leftCountBadge = containerEl.querySelector('.left-count-badge');
    var rightCountBadge = containerEl.querySelector('.right-count-badge');
    var leftSelectedCount = containerEl.querySelector('.left-selected-count');
    var rightSelectedCount = containerEl.querySelector('.right-selected-count');

    var moveRightBtn = containerEl.querySelector('.btn-move-right');
    var moveAllRightBtn = containerEl.querySelector('.btn-move-all-right');
    var moveLeftBtn = containerEl.querySelector('.btn-move-left');
    var moveAllLeftBtn = containerEl.querySelector('.btn-move-all-left');
    var selectAllLeftBtn = containerEl.querySelector('.select-all-left');
    var selectAllRightBtn = containerEl.querySelector('.select-all-right');

    // AutoAnimate if available
    if (window.autoAnimate) {
      window.autoAnimate(leftListEl);
      window.autoAnimate(rightListEl);
    }

    // SortableJS on right list for reordering
    if (window.Sortable) {
      sortableInstance = new Sortable(rightListEl, {
        animation: 150,
        ghostClass: 'sortable-ghost',
        handle: '.item-drag-handle',
        onEnd: function() {
          // Sync selectedItems array order with DOM elements
          var orderedIds = Array.from(rightListEl.children).map(function(el) {
            return el.getAttribute('data-id');
          });
          var itemMap = {};
          selectedItems.forEach(function(item) { itemMap[item.id] = item; });
          selectedItems = orderedIds.map(function(id) { return itemMap[id]; }).filter(Boolean);
          notifyChange();
        }
      });
    }

    function renderItem(item, isRight) {
      var div = document.createElement('div');
      div.className = 'dual-pane-item flex-row align-center gap-xs p-xs' + (item.active === false ? ' opacity-50' : '');
      div.setAttribute('data-id', item.id);
      div.style.padding = '6px 8px';
      div.style.borderRadius = 'var(--radius-sm)';
      div.style.cursor = 'pointer';
      div.style.userSelect = 'none';
      div.style.border = '1px solid transparent';

      div.innerHTML = `
        <input type="checkbox" class="checkbox item-checkbox" style="margin: 0; pointer-events: none;">
        ${isRight ? '<i data-lucide="grip-vertical" class="item-drag-handle color-ink-3" style="cursor: grab; width: 14px; height: 14px;"></i>' : ''}
        <span class="item-code text-xs font-mono color-ink-2">${item.code || ''}</span>
        <span class="item-name text-sm font-medium" style="flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${item.name || ''}</span>
        ${item.category ? `<span class="badge text-xs" style="font-size: 10px; padding: 1px 6px;">${item.category}</span>` : ''}
      `;

      // Single click selects/unselects checkbox
      div.addEventListener('click', function(e) {
        if (e.target.classList.contains('item-drag-handle')) return;
        var cb = div.querySelector('.item-checkbox');
        cb.checked = !cb.checked;
        div.classList.toggle('selected', cb.checked);
        div.style.backgroundColor = cb.checked ? 'var(--highlight)' : 'transparent';
        updateSelectionCounts();
      });

      // Double-click moves item
      div.addEventListener('dblclick', function(e) {
        e.preventDefault();
        if (isRight) {
          tryMoveLeft([item]);
        } else {
          moveRight([item]);
        }
      });

      return div;
    }

    function renderLeft() {
      leftListEl.innerHTML = '';
      var filtered = availableItems.filter(function(item) {
        if (leftSearch) {
          var s = leftSearch.toLowerCase();
          var match = (item.name && item.name.toLowerCase().indexOf(s) !== -1) ||
                      (item.code && item.code.toLowerCase().indexOf(s) !== -1);
          if (!match) return false;
        }
        if (leftCategory !== 'all' && item.category !== leftCategory) {
          return false;
        }
        return true;
      });

      filtered.forEach(function(item) {
        leftListEl.appendChild(renderItem(item, false));
      });

      leftCountBadge.textContent = availableItems.length;
      updateSelectionCounts();
      if (window.lucide && window.lucide.createIcons) {
        window.lucide.createIcons({ root: leftListEl });
      }
    }

    function renderRight() {
      rightListEl.innerHTML = '';
      var filtered = selectedItems.filter(function(item) {
        if (rightSearch) {
          var s = rightSearch.toLowerCase();
          var match = (item.name && item.name.toLowerCase().indexOf(s) !== -1) ||
                      (item.code && item.code.toLowerCase().indexOf(s) !== -1);
          if (!match) return false;
        }
        return true;
      });

      filtered.forEach(function(item) {
        rightListEl.appendChild(renderItem(item, true));
      });

      rightCountBadge.textContent = selectedItems.length;
      updateSelectionCounts();
      if (window.lucide && window.lucide.createIcons) {
        window.lucide.createIcons({ root: rightListEl });
      }
    }

    function updateSelectionCounts() {
      var leftChecked = leftListEl.querySelectorAll('.item-checkbox:checked').length;
      var rightChecked = rightListEl.querySelectorAll('.item-checkbox:checked').length;
      leftSelectedCount.textContent = `${leftChecked} selected`;
      rightSelectedCount.textContent = `${rightChecked} selected`;
    }

    function moveRight(itemsToMove) {
      if (!itemsToMove || itemsToMove.length === 0) return;
      var idsToMove = new Set(itemsToMove.map(function(i) { return i.id; }));

      availableItems = availableItems.filter(function(i) { return !idsToMove.has(i.id); });
      selectedItems = selectedItems.concat(itemsToMove);

      renderLeft();
      renderRight();
      notifyChange();
    }

    function tryMoveLeft(itemsToMove) {
      if (!itemsToMove || itemsToMove.length === 0) return;

      // Check veto hook
      if (typeof beforeRemove === 'function') {
        var check = beforeRemove(itemsToMove);
        Promise.resolve(check).then(function(result) {
          if (result === false) {
            // Vetoed without specific message
            return;
          }
          if (result && result.allowed === false) {
            // Vetoed with reason
            if (Mess.dialog && Mess.dialog.alert) {
              Mess.dialog.alert({
                title: 'Cannot Unmap Item',
                message: result.reason || 'This item cannot be removed because it is referenced.',
                type: 'danger'
              });
            } else {
              alert(result.reason || 'Cannot unmap item');
            }
            return;
          }
          doMoveLeft(itemsToMove);
        });
      } else {
        doMoveLeft(itemsToMove);
      }
    }

    function doMoveLeft(itemsToMove) {
      var idsToMove = new Set(itemsToMove.map(function(i) { return i.id; }));

      selectedItems = selectedItems.filter(function(i) { return !idsToMove.has(i.id); });
      availableItems = availableItems.concat(itemsToMove);

      renderLeft();
      renderRight();
      notifyChange();
    }

    function notifyChange() {
      if (typeof onChange === 'function') {
        onChange(selectedItems.slice());
      }
    }

    // Button event handlers
    moveRightBtn.addEventListener('click', function() {
      var checkedEls = leftListEl.querySelectorAll('.dual-pane-item.selected');
      var ids = Array.from(checkedEls).map(function(el) { return el.getAttribute('data-id'); });
      var toMove = availableItems.filter(function(i) { return ids.indexOf(i.id) !== -1; });
      moveRight(toMove);
    });

    moveAllRightBtn.addEventListener('click', function() {
      moveRight(availableItems.slice());
    });

    moveLeftBtn.addEventListener('click', function() {
      var checkedEls = rightListEl.querySelectorAll('.dual-pane-item.selected');
      var ids = Array.from(checkedEls).map(function(el) { return el.getAttribute('data-id'); });
      var toMove = selectedItems.filter(function(i) { return ids.indexOf(i.id) !== -1; });
      tryMoveLeft(toMove);
    });

    moveAllLeftBtn.addEventListener('click', function() {
      tryMoveLeft(selectedItems.slice());
    });

    selectAllLeftBtn.addEventListener('click', function() {
      var items = leftListEl.querySelectorAll('.dual-pane-item');
      var allChecked = Array.from(items).every(function(it) {
        return it.classList.contains('selected');
      });
      items.forEach(function(it) {
        var cb = it.querySelector('.item-checkbox');
        cb.checked = !allChecked;
        it.classList.toggle('selected', !allChecked);
        it.style.backgroundColor = !allChecked ? 'var(--highlight)' : 'transparent';
      });
      updateSelectionCounts();
    });

    selectAllRightBtn.addEventListener('click', function() {
      var items = rightListEl.querySelectorAll('.dual-pane-item');
      var allChecked = Array.from(items).every(function(it) {
        return it.classList.contains('selected');
      });
      items.forEach(function(it) {
        var cb = it.querySelector('.item-checkbox');
        cb.checked = !allChecked;
        it.classList.toggle('selected', !allChecked);
        it.style.backgroundColor = !allChecked ? 'var(--highlight)' : 'transparent';
      });
      updateSelectionCounts();
    });

    // Search and filter listeners
    leftSearchInput.addEventListener('input', function() {
      leftSearch = leftSearchInput.value.trim();
      renderLeft();
    });

    if (leftCatSelect) {
      leftCatSelect.addEventListener('change', function() {
        leftCategory = leftCatSelect.value;
        renderLeft();
      });
    }

    rightSearchInput.addEventListener('input', function() {
      rightSearch = rightSearchInput.value.trim();
      renderRight();
    });

    // Initial render
    renderLeft();
    renderRight();

    if (window.lucide && window.lucide.createIcons) {
      window.lucide.createIcons({ root: containerEl });
    }

    return {
      getSelected: function() {
        return selectedItems.slice();
      },
      getSelectedIds: function() {
        return selectedItems.map(function(i) { return i.id; });
      },
      setSelected: function(newSelected) {
        selectedItems = (newSelected || []).slice();
        var selectedIds = new Set(selectedItems.map(function(i) { return i.id; }));
        availableItems = availableItems.filter(function(i) { return !selectedIds.has(i.id); });
        renderLeft();
        renderRight();
      },
      setAvailable: function(newAvailable) {
        var selectedIds = new Set(selectedItems.map(function(i) { return i.id; }));
        availableItems = (newAvailable || []).filter(function(i) { return !selectedIds.has(i.id); });
        renderLeft();
      },
      destroy: function() {
        if (sortableInstance) {
          sortableInstance.destroy();
          sortableInstance = null;
        }
        containerEl.innerHTML = '';
      }
    };
  };
})(window.Mess);
