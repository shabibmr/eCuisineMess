/* command-palette.js - Global Command Palette (Ctrl+K) for Screens, Records & Actions (Task T-097) */

window.Mess = window.Mess || {};

(function(Mess) {
  var paletteEl = null;
  var backdropEl = null;
  var inputEl = null;
  var resultsEl = null;
  var selectedIndex = 0;
  var currentResults = [];

  function getCommands() {
    var commands = [];

    // 1. Screens
    var screens = (Mess.screens && Mess.screens.list) || [];
    screens.forEach(function(s) {
      commands.push({
        category: 'Screens',
        icon: s.nav && s.nav.icon ? s.nav.icon : 'layout',
        title: s.title,
        subtitle: s.route,
        keywords: [s.title, s.route, s.id],
        action: function() {
          if (Mess.router && Mess.router.navigate) {
            Mess.router.navigate(s.route);
          } else {
            window.location.hash = '#' + s.route;
          }
        }
      });
    });

    // 2. Actions / System Commands
    commands.push({
      category: 'Actions',
      icon: 'palette',
      title: 'Switch Skin: Flat',
      subtitle: 'Modern Clean HIG Design',
      keywords: ['flat', 'skin', 'theme'],
      action: function() { if (Mess.theme) Mess.theme.setSkin('flat'); }
    });
    commands.push({
      category: 'Actions',
      icon: 'box',
      title: 'Switch Skin: Clay',
      subtitle: 'Tactile Neumorphic 3D Design',
      keywords: ['clay', 'skin', 'theme', 'tactile'],
      action: function() { if (Mess.theme) Mess.theme.setSkin('clay'); }
    });
    commands.push({
      category: 'Actions',
      icon: 'sparkles',
      title: 'Switch Skin: Glass',
      subtitle: 'Vibrant Glassmorphic Glow Design',
      keywords: ['glass', 'skin', 'theme', 'glow'],
      action: function() { if (Mess.theme) Mess.theme.setSkin('glass'); }
    });
    commands.push({
      category: 'Actions',
      icon: 'moon',
      title: 'Toggle Dark / Light Mode',
      subtitle: 'Cycle display color mode',
      keywords: ['dark', 'light', 'mode', 'theme'],
      action: function() { if (Mess.theme) Mess.theme.toggleMode(); }
    });
    commands.push({
      category: 'Actions',
      icon: 'volume-2',
      title: 'Toggle Audio Mute',
      subtitle: 'Enable or disable kiosk audio cues',
      keywords: ['mute', 'audio', 'sound', 'beep'],
      action: function() { if (Mess.audio) Mess.audio.toggleMute(); }
    });
    commands.push({
      category: 'Actions',
      icon: 'sliders',
      title: 'Open Demo Panel',
      subtitle: 'Access scenario cards, time overrides & mock tools (Ctrl+Shift+D)',
      keywords: ['demo', 'panel', 'scenario', 'clock'],
      action: function() {
        if (Mess.demoPanel && Mess.demoPanel.toggle) Mess.demoPanel.toggle();
      }
    });

    // 3. Records (Customers, Items, Cuisines)
    var items = (Mess.store && Mess.store.list('items')) || [];
    items.slice(0, 15).forEach(function(it) {
      commands.push({
        category: 'Items',
        icon: 'package',
        title: it.name,
        subtitle: `${it.code} · ${it.category || 'Item'} (${it.unit})`,
        keywords: [it.name, it.code, it.category || ''],
        action: function() {
          window.location.hash = `#/items/${it.id}`;
        }
      });
    });

    var customers = (Mess.store && Mess.store.list('customers')) || [];
    customers.slice(0, 15).forEach(function(m) {
      commands.push({
        category: 'Members',
        icon: 'user',
        title: m.name,
        subtitle: `${m.code} · Valid: ${m.validTo || 'Active'}`,
        keywords: [m.name, m.code, m.phone || ''],
        action: function() {
          window.location.hash = `#/customers/${m.id}`;
        }
      });
    });

    return commands;
  }

  function filterCommands(query) {
    var all = getCommands();
    if (!query || !query.trim()) {
      return all.slice(0, 12);
    }

    var q = query.trim().toLowerCase();
    return all.filter(function(item) {
      if (item.title.toLowerCase().indexOf(q) !== -1) return true;
      if (item.subtitle.toLowerCase().indexOf(q) !== -1) return true;
      if (item.category.toLowerCase().indexOf(q) !== -1) return true;
      return item.keywords.some(function(k) { return k.toLowerCase().indexOf(q) !== -1; });
    }).slice(0, 15);
  }

  function renderList() {
    if (!resultsEl) return;
    if (currentResults.length === 0) {
      resultsEl.innerHTML = '<div class="p-md text-center color-ink-3 text-sm">No matching screens, records or actions found.</div>';
      return;
    }

    // Group by category
    var html = '';
    var lastCat = '';
    currentResults.forEach(function(cmd, idx) {
      if (cmd.category !== lastCat) {
        lastCat = cmd.category;
        html += `<div class="palette-category text-xxs font-semibold color-ink-3" style="padding: 6px 12px; background: var(--canvas); text-transform: uppercase; letter-spacing: 0.5px;">${lastCat}</div>`;
      }
      var isSelected = idx === selectedIndex;
      html += `
        <div class="palette-item flex-row align-center gap-sm ${isSelected ? 'selected' : ''}" data-index="${idx}" style="padding: 8px 12px; cursor: pointer; border-radius: var(--radius-sm); margin: 2px 4px; ${isSelected ? 'background: var(--surface-strong);' : ''}">
          <div class="palette-item-icon color-ink-2" style="display:flex; align-items:center;">
            <i data-lucide="${cmd.icon || 'chevron-right'}" style="width: 16px; height: 16px;"></i>
          </div>
          <div class="palette-item-text flex-col flex-1">
            <span class="text-xs font-semibold color-ink">${cmd.title}</span>
            <span class="text-xxs color-ink-3">${cmd.subtitle}</span>
          </div>
          ${isSelected ? '<kbd class="shortcut-badge text-xxs">↵ Enter</kbd>' : ''}
        </div>
      `;
    });

    resultsEl.innerHTML = html;
    if (window.lucide && window.lucide.createIcons) {
      window.lucide.createIcons({ root: resultsEl });
    }

    var selectedEl = resultsEl.querySelector('.palette-item.selected');
    if (selectedEl) {
      selectedEl.scrollIntoView({ block: 'nearest' });
    }
  }

  function initPalette() {
    var container = document.getElementById('command-palette-container');
    if (!container) {
      container = document.createElement('div');
      container.id = 'command-palette-container';
      document.body.appendChild(container);
    }

    container.innerHTML = `
      <div class="palette-backdrop" style="display:none; position:fixed; inset:0; background:rgba(0,0,0,0.4); backdrop-filter:blur(3px); z-index:var(--z-popover);"></div>
      <div class="palette-modal card-elevated" style="display:none; position:fixed; top:18%; left:50%; transform:translateX(-50%); width:540px; max-width:92vw; background:var(--surface); border:1px solid var(--separator); border-radius:var(--radius-panel); box-shadow:var(--elev-sheet); z-index:calc(var(--z-popover) + 1); overflow:hidden; flex-direction:column;">
        <div class="palette-input-wrapper flex-row align-center gap-sm p-sm" style="border-bottom: 1px solid var(--separator); background: var(--canvas);">
          <i data-lucide="search" style="width: 18px; height: 18px; color: var(--ink-3);"></i>
          <input type="text" class="palette-search-input font-medium text-sm" placeholder="Type a screen, member, item, or command..." style="flex:1; border:none; background:transparent; outline:none; color:var(--ink);">
          <kbd class="shortcut-badge">Esc</kbd>
        </div>
        <div class="palette-results flex-col" style="max-height: 340px; overflow-y: auto; padding: 4px 0;"></div>
        <div class="palette-footer flex-row justify-between align-center p-xs px-sm text-xxs color-ink-3" style="border-top: 1px solid var(--separator); background: var(--canvas);">
          <span>Use <kbd>↑</kbd> <kbd>↓</kbd> to navigate, <kbd>Enter</kbd> to select</span>
          <span>Mess Module Palette</span>
        </div>
      </div>
    `;

    backdropEl = container.querySelector('.palette-backdrop');
    paletteEl = container.querySelector('.palette-modal');
    inputEl = container.querySelector('.palette-search-input');
    resultsEl = container.querySelector('.palette-results');

    backdropEl.addEventListener('click', Mess.commandPalette.close);

    inputEl.addEventListener('input', function() {
      selectedIndex = 0;
      currentResults = filterCommands(inputEl.value);
      renderList();
    });

    inputEl.addEventListener('keydown', function(e) {
      if (e.key === 'ArrowDown') {
        e.preventDefault();
        selectedIndex = (selectedIndex + 1) % Math.max(1, currentResults.length);
        renderList();
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        selectedIndex = (selectedIndex - 1 + currentResults.length) % Math.max(1, currentResults.length);
        renderList();
      } else if (e.key === 'Enter') {
        e.preventDefault();
        if (currentResults[selectedIndex]) {
          Mess.commandPalette.close();
          currentResults[selectedIndex].action();
        }
      } else if (e.key === 'Escape') {
        e.preventDefault();
        Mess.commandPalette.close();
      }
    });

    resultsEl.addEventListener('click', function(e) {
      var itemEl = e.target.closest('.palette-item');
      if (itemEl) {
        var idx = parseInt(itemEl.getAttribute('data-index'), 10);
        if (currentResults[idx]) {
          Mess.commandPalette.close();
          currentResults[idx].action();
        }
      }
    });

    // Global Hotkey Ctrl+K / Cmd+K
    window.addEventListener('keydown', function(e) {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        Mess.commandPalette.toggle();
      }
    });
  }

  Mess.commandPalette = {
    open: function() {
      if (!paletteEl) initPalette();
      selectedIndex = 0;
      currentResults = filterCommands('');
      inputEl.value = '';
      paletteEl.style.display = 'flex';
      backdropEl.style.display = 'block';
      renderList();
      setTimeout(function() { inputEl.focus(); }, 50);
    },

    close: function() {
      if (paletteEl) paletteEl.style.display = 'none';
      if (backdropEl) backdropEl.style.display = 'none';
    },

    toggle: function() {
      if (paletteEl && paletteEl.style.display === 'flex') {
        this.close();
      } else {
        this.open();
      }
    }
  };

  // Pre-init on DOMContentLoaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initPalette);
  } else {
    initPalette();
  }
})(window.Mess);
