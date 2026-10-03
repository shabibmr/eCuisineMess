/* router.js - Hash routing, role guard, dirty form canLeave guard & View Transitions */

window.Mess = window.Mess || {};

(function(Mess) {
  var currentRouteState = {
    path: '/',
    params: {},
    query: {}
  };

  var dirtyGuardActive = false;

  function parseHash() {
    var hash = window.location.hash.slice(1) || '/';
    var parts = hash.split('?');
    var path = parts[0] || '/';
    var queryStr = parts[1] || '';

    var query = {};
    if (queryStr) {
      queryStr.split('&').forEach(function(pair) {
        var kv = pair.split('=');
        query[decodeURIComponent(kv[0])] = decodeURIComponent(kv[1] || '');
      });
    }

    return { path: path, query: query };
  }

  function matchRoute(path) {
    var screens = Mess.screens ? Mess.screens.getAll() : [];
    
    for (var i = 0; i < screens.length; i++) {
      var scr = screens[i];
      var candidateRoutes = [];
      if (Array.isArray(scr.routes)) {
        candidateRoutes = candidateRoutes.concat(scr.routes);
      }
      if (scr.route && candidateRoutes.indexOf(scr.route) === -1) {
        candidateRoutes.unshift(scr.route);
      }

      // Built-in aliases for navigation consistency
      if (scr.id === 'menu-editor') {
        if (candidateRoutes.indexOf('/menu') === -1) candidateRoutes.push('/menu');
        if (candidateRoutes.indexOf('/menu-editor') === -1) candidateRoutes.push('/menu-editor');
      } else if (scr.id === 'report-time-based') {
        if (candidateRoutes.indexOf('/reports/time') === -1) candidateRoutes.push('/reports/time');
        if (candidateRoutes.indexOf('/reports/time-based') === -1) candidateRoutes.push('/reports/time-based');
      } else if (scr.id === 'token-preview') {
        if (candidateRoutes.indexOf('/token-preview') === -1) candidateRoutes.push('/token-preview');
        if (candidateRoutes.indexOf('/bills/:id/token') === -1) candidateRoutes.push('/bills/:id/token');
        if (candidateRoutes.indexOf('/token-preview/:id') === -1) candidateRoutes.push('/token-preview/:id');
      }

      if (candidateRoutes.length === 0) continue;

      for (var k = 0; k < candidateRoutes.length; k++) {
        var rPattern = candidateRoutes[k];
        // Exact match
        if (rPattern === path) {
          return { screen: scr, params: {} };
        }

        // Parametrized route matching (e.g. /items/:id)
        var routeParts = rPattern.split('/');
        var pathParts = path.split('/');

        if (routeParts.length === pathParts.length) {
          var params = {};
          var match = true;
          for (var j = 0; j < routeParts.length; j++) {
            if (routeParts[j].startsWith(':')) {
              var paramName = routeParts[j].slice(1);
              params[paramName] = decodeURIComponent(pathParts[j]);
            } else if (routeParts[j] !== pathParts[j]) {
              match = false;
              break;
            }
          }
          if (match) return { screen: scr, params: params };
        }
      }
    }

    // Default to Home if no match
    var homeScr = Mess.screens ? Mess.screens.get('home') : null;
    return { screen: homeScr, params: {} };
  }

  function navigateTo(hash, force) {
    if (!force && Mess.router.isDirty && Mess.router.isDirty()) {
      if (Mess.dialog && Mess.dialog.confirmLeave) {
        Mess.dialog.confirmLeave(function(choice) {
          if (choice === 'discard') {
            Mess.router.setDirty(false);
            window.location.hash = hash;
          }
        });
        return;
      }
    }
    window.location.hash = hash;
  }

  function handleRoute() {
    var parsed = parseHash();
    var matched = matchRoute(parsed.path);
    var screen = matched.screen;

    if (!screen) return;

    // Role Guard check
    if (screen.roles && Array.isArray(screen.roles)) {
      var currentRole = Mess.roles ? Mess.roles.getRole() : 'admin';
      if (screen.roles.indexOf(currentRole) === -1) {
        if (Mess.ui && Mess.ui.toast) {
          Mess.ui.toast('error', 'You do not have access to ' + screen.title);
        }
        window.location.hash = '#/';
        return;
      }
    }

    currentRouteState = {
      path: parsed.path,
      params: matched.params,
      query: parsed.query,
      screenId: screen.id
    };

    document.title = (screen.title || 'Mess') + ' – Mess';

    var outletEl = document.getElementById('outlet');
    if (!outletEl) return;

    var prefersReduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    if (document.startViewTransition && !prefersReduced) {
      document.startViewTransition(function() {
        Mess.screens.mount(screen.id, matched.params, outletEl);
      });
    } else {
      Mess.screens.mount(screen.id, matched.params, outletEl);
    }

    window.dispatchEvent(new CustomEvent('routechange', { detail: currentRouteState }));
  }

  Mess.router = {
    start: function() {
      window.addEventListener('hashchange', handleRoute);
      handleRoute();
    },

    navigate: navigateTo,

    getCurrentRoute: function() {
      return currentRouteState;
    },

    setDirty: function(dirty) {
      dirtyGuardActive = !!dirty;
    },

    isDirty: function() {
      return dirtyGuardActive;
    }
  };

})(window.Mess);
