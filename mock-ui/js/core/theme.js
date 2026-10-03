/* theme.js - Theme manager with skin, mode, auto OS listener, View Transition reveal & themechange event */

window.Mess = window.Mess || {};

(function(Mess) {
  var STORAGE_KEY = 'mess-mock:theme';

  var state = {
    skin: 'flat',
    mode: 'light',
    meal: 'none'
  };

  var mediaListener = null;

  function loadPersisted() {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        var parsed = JSON.parse(raw);
        if (parsed.skin) state.skin = parsed.skin;
        if (parsed.mode) state.mode = parsed.mode;
      }
    } catch (e) {
      console.warn('Failed to load theme from localStorage:', e);
    }
  }

  function savePersisted() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({
        skin: state.skin,
        mode: state.mode
      }));
    } catch (e) {
      console.warn('Failed to save theme to localStorage:', e);
    }
  }

  function getEffectiveMode() {
    if (state.mode === 'auto') {
      return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    }
    return state.mode;
  }

  function applyDOMAttributes() {
    var effectiveMode = getEffectiveMode();
    var root = document.documentElement;
    root.setAttribute('data-skin', state.skin);
    root.setAttribute('data-mode', effectiveMode);
    root.setAttribute('data-meal', state.meal);
  }

  function notifyChange() {
    var effectiveMode = getEffectiveMode();
    window.dispatchEvent(new CustomEvent('themechange', {
      detail: {
        skin: state.skin,
        mode: state.mode,
        effectiveMode: effectiveMode,
        meal: state.meal
      }
    }));
  }

  function updateThemeWithTransition(updateFn, event) {
    var prefersReduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    if (!document.startViewTransition || prefersReduced || !event) {
      updateFn();
      applyDOMAttributes();
      savePersisted();
      notifyChange();
      return;
    }

    var x = event.clientX;
    var y = event.clientY;
    var endRadius = Math.hypot(
      Math.max(x, window.innerWidth - x),
      Math.max(y, window.innerHeight - y)
    );

    var transition = document.startViewTransition(function() {
      updateFn();
      applyDOMAttributes();
    });

    transition.ready.then(function() {
      document.documentElement.animate(
        {
          clipPath: [
            'circle(0px at ' + x + 'px ' + y + 'px)',
            'circle(' + endRadius + 'px at ' + x + 'px ' + y + 'px)'
          ]
        },
        {
          duration: 350,
          easing: 'ease-in-out',
          pseudoElement: '::view-transition-new(root)'
        }
      );
    }).catch(function() {
      // Fallback if animation fails
    });

    savePersisted();
    notifyChange();
  }

  function setupOSListener() {
    if (!window.matchMedia) return;
    var query = window.matchMedia('(prefers-color-scheme: dark)');
    
    mediaListener = function() {
      if (state.mode === 'auto') {
        applyDOMAttributes();
        notifyChange();
      }
    };

    if (query.addEventListener) {
      query.addEventListener('change', mediaListener);
    } else if (query.addListener) {
      query.addListener(mediaListener);
    }
  }

  Mess.theme = {
    init: function() {
      loadPersisted();
      applyDOMAttributes();
      setupOSListener();
    },

    getSkin: function() { return state.skin; },
    getMode: function() { return state.mode; },
    getEffectiveMode: getEffectiveMode,

    setSkin: function(skin, event) {
      if (skin !== 'flat' && skin !== 'clay' && skin !== 'glass') return;
      updateThemeWithTransition(function() {
        state.skin = skin;
      }, event);
    },

    setMode: function(mode, event) {
      if (mode !== 'light' && mode !== 'dark' && mode !== 'auto') return;
      updateThemeWithTransition(function() {
        state.mode = mode;
      }, event);
    },

    toggleMode: function(event) {
      var next = state.mode === 'light' ? 'dark' : 'light';
      Mess.theme.setMode(next, event);
    },

    setMeal: function(meal) {
      if (state.meal === meal) return;
      state.meal = meal || 'none';
      document.documentElement.setAttribute('data-meal', state.meal);
      notifyChange();
    }
  };

  // Run initial DOM application synchronously
  Mess.theme.init();

})(window.Mess);
