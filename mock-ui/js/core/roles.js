/* roles.js - Roles and Session Store with permission matrix */

window.Mess = window.Mess || {};

(function(Mess) {
  var currentRole = 'admin';
  var currentUser = 'admin';
  var counterId = 'C1';

  var PERMISSION_MATRIX = {
    'admin': {
      'masters.edit': true,
      'masters.view': true,
      'menu.edit': true,
      'menu.view': true,
      'counter.use': true,
      'bill.cancel': true,
      'bill.override': true,
      'bill.view': true,
      'reports.view': true
    },
    'supervisor': {
      'masters.edit': false,
      'masters.view': true,
      'menu.edit': false,
      'menu.view': true,
      'counter.use': true,
      'bill.cancel': true,
      'bill.override': true,
      'bill.view': true,
      'reports.view': true
    },
    'counter': {
      'masters.edit': false,
      'masters.view': false,
      'menu.edit': false,
      'menu.view': true,
      'counter.use': true,
      'bill.cancel': false,
      'bill.override': false,
      'bill.view': true,
      'reports.view': false
    }
  };

  Mess.roles = {
    getRole: function() { return currentRole; },
    
    setRole: function(role) {
      if (PERMISSION_MATRIX[role]) {
        currentRole = role;
        currentUser = role === 'admin' ? 'admin' : (role === 'supervisor' ? 'sup.ali' : 'counter1');
        window.dispatchEvent(new CustomEvent('rolechange', { detail: { role: role, user: currentUser } }));
      }
    },

    getUser: function() { return currentUser; },
    getCounterId: function() { return counterId; },

    can: function(action) {
      var rolePerms = PERMISSION_MATRIX[currentRole];
      if (!rolePerms) return false;
      return !!rolePerms[action];
    }
  };

  // Alpine session store integration
  var sessionStore = {
    role: currentRole,
    user: currentUser,
    counterId: counterId,
    setRole: function(r) {
      Mess.roles.setRole(r);
      this.role = Mess.roles.getRole();
      this.user = Mess.roles.getUser();
    },
    can: function(act) {
      return Mess.roles.can(act);
    }
  };

  if (window.Alpine) {
    window.Alpine.store('session', sessionStore);
  } else {
    document.addEventListener('alpine:init', function() {
      window.Alpine.store('session', sessionStore);
    });
  }
})(window.Mess);
