/* app.js - Main Application Bootstrapper & Shell Reactive Component */

window.Mess = window.Mess || {};

document.addEventListener('alpine:init', function() {
  Alpine.data('MessShell', function() {
    return {
      sidebarCollapsed: localStorage.getItem('mess-mock:sidebar-collapsed') === 'true',
      currentRoute: '/',
      skin: Mess.theme ? Mess.theme.getSkin() : 'flat',
      mode: Mess.theme ? Mess.theme.getMode() : 'light',
      currentMeal: Mess.clock ? Mess.clock.currentMeal() : 'none',
      currentRole: Mess.roles ? Mess.roles.getRole() : 'admin',
      muted: Mess.audio ? Mess.audio.isMuted() : false,
      todayFormatted: Mess.formatDate ? Mess.formatDate() : '',

      init: function() {
        var self = this;

        window.addEventListener('themechange', function(e) {
          if (e.detail) {
            self.skin = e.detail.skin;
            self.mode = e.detail.mode;
          }
        });

        window.addEventListener('mealchange', function(e) {
          if (e.detail) {
            self.currentMeal = e.detail.meal;
          }
        });

        window.addEventListener('rolechange', function(e) {
          if (e.detail) {
            self.currentRole = e.detail.role;
          }
        });

        window.addEventListener('routechange', function(e) {
          if (e.detail) {
            self.currentRoute = e.detail.path;
          }
        });

        window.addEventListener('mutechange', function(e) {
          if (e.detail) {
            self.muted = e.detail.muted;
          }
        });

        // Initialize sample data seed
        if (Mess.data && Mess.data.build) {
          Mess.data.build();
        }

        // Start Router
        if (Mess.router && Mess.router.start) {
          Mess.router.start();
        }
      },

      toggleSidebar: function() {
        this.sidebarCollapsed = !this.sidebarCollapsed;
        localStorage.setItem('mess-mock:sidebar-collapsed', this.sidebarCollapsed ? 'true' : 'false');
      },

      setSkin: function(skinName, event) {
        if (Mess.theme) Mess.theme.setSkin(skinName, event);
      },

      setMode: function(modeName, event) {
        if (Mess.theme) Mess.theme.setMode(modeName, event);
      },

      toggleMode: function(event) {
        if (Mess.theme) Mess.theme.toggleMode(event);
      },

      setRole: function(roleName) {
        if (Mess.roles) Mess.roles.setRole(roleName);
      },

      toggleMute: function() {
        if (Mess.audio) Mess.audio.toggleMute();
      },

      openCommandPalette: function() {
        if (Mess.commandPalette) Mess.commandPalette.open();
      }
    };
  });
});
