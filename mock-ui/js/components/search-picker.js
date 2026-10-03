/* search-picker.js - Core search picker with Fuse contains-matching & keyboard nav */

window.Mess = window.Mess || {};

(function(Mess) {
  Mess.createSearchPicker = function(containerEl, options) {
    var el = typeof containerEl === 'string' ? document.querySelector(containerEl) : containerEl;
    if (!el) return null;

    var opt = options || {};
    var placeholder = opt.placeholder || 'Search or select...';
    var keys = opt.keys || ['code', 'name'];
    var activeOnly = opt.activeOnly !== false;
    var data = opt.data || [];
    var currentRecord = null;
    var focusedIndex = -1;
    var currentMatches = [];

    // Markup setup
    el.innerHTML = /* html */ `
      <div class="search-picker">
        <div class="flex-row gap-xs align-center">
          <input type="text" class="field-input picker-input" placeholder="${placeholder}" autocomplete="off">
          <button type="button" class="btn btn--quiet btn--icon picker-clear-btn" title="Clear selection" style="display: none;">
            <i data-lucide="x"></i>
          </button>
        </div>
        <div class="picker-popover" style="display: none;"></div>
      </div>
    `;
    if (Mess.refreshIcons) Mess.refreshIcons(el);

    var input = el.querySelector('.picker-input');
    var popover = el.querySelector('.picker-popover');
    var clearBtn = el.querySelector('.picker-clear-btn');

    function getFilteredPool() {
      if (!activeOnly) return data;
      return data.filter(function(r) { return r.active !== false; });
    }

    function highlightMatch(text, query) {
      if (!query || !text) return text || '';
      var idx = String(text).toLowerCase().indexOf(query.toLowerCase());
      if (idx === -1) return text;
      var qLen = query.length;
      return String(text).substring(0, idx) +
             '<strong>' + String(text).substring(idx, idx + qLen) + '</strong>' +
             String(text).substring(idx + qLen);
    }

    function renderPopover(matches, query) {
      if (matches.length === 0) {
        popover.innerHTML = '<div class="picker-row text-sm color-ink-2" style="cursor: default;">No matching records</div>';
        popover.style.display = 'block';
        return;
      }

      currentMatches = matches.slice(0, 8); // max 8 rows
      var html = '';

      currentMatches.forEach(function(item, idx) {
        var label = typeof opt.formatRow === 'function' ? opt.formatRow(item, query) : (item.code + ' – ' + item.name);
        var isFocused = idx === focusedIndex;
        html += '<div class="picker-row ' + (isFocused ? 'focused' : '') + '" data-idx="' + idx + '">' + label + '</div>';
      });

      if (opt.hasNewAction) {
        html += '<div class="picker-row picker-new-action font-semibold" style="color: var(--primary); border-top: 1px dashed var(--separator);"><i data-lucide="plus"></i> + New record</div>';
      }

      popover.innerHTML = html;
      popover.style.display = 'block';
      if (Mess.refreshIcons) Mess.refreshIcons(popover);
    }

    function search(query) {
      var pool = getFilteredPool();
      var q = (query || '').trim();

      if (!q) {
        renderPopover(pool, '');
        return;
      }

      if (window.Fuse) {
        var fuse = new window.Fuse(pool, {
          keys: keys,
          threshold: 0.3,
          ignoreLocation: true
        });
        var res = fuse.search(q).map(function(r) { return r.item; });
        renderPopover(res, q);
      } else {
        // Fallback contains-search
        var qLower = q.toLowerCase();
        var res = pool.filter(function(item) {
          return keys.some(function(k) {
            return item[k] && String(item[k]).toLowerCase().indexOf(qLower) !== -1;
          });
        });
        renderPopover(res, q);
      }
    }

    function selectRecord(rec) {
      currentRecord = rec;
      popover.style.display = 'none';
      focusedIndex = -1;

      if (rec) {
        input.value = typeof opt.formatDisplay === 'function' ? opt.formatDisplay(rec) : (rec.code + ' – ' + rec.name);
        clearBtn.style.display = 'inline-flex';
        el.dispatchEvent(new CustomEvent('selected', { detail: { id: rec.id, record: rec } }));
        if (typeof opt.onSelect === 'function') opt.onSelect(rec);
      } else {
        input.value = '';
        clearBtn.style.display = 'none';
        el.dispatchEvent(new CustomEvent('selected', { detail: { id: null, record: null } }));
        if (typeof opt.onSelect === 'function') opt.onSelect(null);
      }
    }

    // Input events
    input.addEventListener('focus', function() {
      search(input.value);
    });

    input.addEventListener('input', function() {
      focusedIndex = -1;
      search(input.value);
    });

    input.addEventListener('keydown', function(e) {
      if (popover.style.display === 'block' && currentMatches.length > 0) {
        if (e.key === 'ArrowDown') {
          e.preventDefault();
          focusedIndex = (focusedIndex + 1) % currentMatches.length;
          renderPopover(currentMatches, input.value);
          return;
        }
        if (e.key === 'ArrowUp') {
          e.preventDefault();
          focusedIndex = (focusedIndex - 1 + currentMatches.length) % currentMatches.length;
          renderPopover(currentMatches, input.value);
          return;
        }
        if (e.key === 'Enter') {
          e.preventDefault();
          if (focusedIndex >= 0 && focusedIndex < currentMatches.length) {
            selectRecord(currentMatches[focusedIndex]);
          } else if (currentMatches.length > 0) {
            selectRecord(currentMatches[0]);
          }
          return;
        }
        if (e.key === 'Escape') {
          popover.style.display = 'none';
          return;
        }
      }

      if (e.key === 'F2') {
        e.preventDefault();
        if (typeof opt.onF2 === 'function') opt.onF2();
      }
    });

    popover.addEventListener('click', function(e) {
      var row = e.target.closest('.picker-row');
      if (!row) return;

      if (row.classList.contains('picker-new-action')) {
        popover.style.display = 'none';
        if (typeof opt.onNew === 'function') opt.onNew();
        return;
      }

      var idx = parseInt(row.getAttribute('data-idx'), 10);
      if (!isNaN(idx) && currentMatches[idx]) {
        selectRecord(currentMatches[idx]);
      }
    });

    clearBtn.addEventListener('click', function() {
      selectRecord(null);
      input.focus();
    });

    // Close when clicking outside
    document.addEventListener('click', function(e) {
      if (!el.contains(e.target)) {
        popover.style.display = 'none';
      }
    });

    return {
      currentId: function() {
        return currentRecord ? currentRecord.id : null;
      },

      getCurrentRecord: function() {
        return currentRecord;
      },

      setCurrentId: function(id) {
        if (!id) {
          selectRecord(null);
          return;
        }
        var found = data.find(function(r) { return r.id === id || r.code === id; });
        if (found) {
          selectRecord(found);
        }
      },

      setData: function(newData) {
        data = newData || [];
      },

      clear: function() {
        selectRecord(null);
      },

      focus: function() {
        input.focus();
      }
    };
  };
})(window.Mess);
