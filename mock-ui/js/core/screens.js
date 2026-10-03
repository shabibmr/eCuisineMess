/* screens.js - Screen registry, router integration, icon helper and Lucide rendering */

window.Mess = window.Mess || {};

(function(Mess) {
  var registry = {};
  var currentScreen = null;

  var MEAL_ICON_MAP = {
    'B': 'sunrise',
    'L': 'sun',
    'D': 'moon-star',
    'none': 'clock'
  };

  Mess.mealIcon = function(meal) {
    return MEAL_ICON_MAP[meal] || 'clock';
  };

  Mess.icon = function(name, extraClass) {
    var cls = 'lucide-icon' + (extraClass ? ' ' + extraClass : '');
    return '<i data-lucide="' + name + '" class="' + cls + '"></i>';
  };

  Mess.refreshIcons = function(container) {
    if (window.lucide && window.lucide.createIcons) {
      window.lucide.createIcons({
        attrs: {
          'stroke-width': 1.5
        },
        nameAttr: 'data-lucide'
      });
    }
  };

  Mess.screens = {
    register: function(definition) {
      if (!definition || !definition.id) {
        console.error('Invalid screen registration:', definition);
        return;
      }
      registry[definition.id] = definition;
    },

    get: function(id) {
      return registry[id];
    },

    getAll: function() {
      return Object.values(registry);
    },

    mount: function(id, params, targetEl) {
      var screen = registry[id];
      if (!screen) {
        console.error('Screen not found:', id);
        return false;
      }

      if (currentScreen && currentScreen.componentInstance && typeof currentScreen.componentInstance.destroy === 'function') {
        try {
          currentScreen.componentInstance.destroy();
        } catch (e) {
          console.warn('Error destroying screen:', e);
        }
      }

      currentScreen = screen;
      targetEl.innerHTML = typeof screen.template === 'function' ? screen.template(params) : (screen.template || '');

      if (window.Alpine && window.Alpine.initTree) {
        window.Alpine.initTree(targetEl);
      }

      if (typeof screen.component === 'function') {
        screen.componentInstance = screen.component(params, targetEl);
        if (screen.componentInstance && typeof screen.componentInstance.init === 'function') {
          screen.componentInstance.init(targetEl, params);
        }
      }

      Mess.refreshIcons(targetEl);
      return true;
    },

    getNavModel: function() {
      var groups = {};
      var all = Object.values(registry);

      all.forEach(function(scr) {
        if (!scr.nav) return;
        var groupName = scr.nav.group || 'Other';
        if (!groups[groupName]) groups[groupName] = [];
        groups[groupName].push({
          id: scr.id,
          title: scr.title,
          route: scr.route,
          icon: scr.nav.icon,
          order: scr.nav.order || 99,
          roles: scr.roles
        });
      });

      Object.keys(groups).forEach(function(g) {
        groups[g].sort(function(a, b) { return a.order - b.order; });
      });

      return groups;
    }
  };
})(window.Mess);
