/* hotkeys.js - Scoped hotkey registry and '?' help sheet */

window.Mess = window.Mess || {};

(function(Mess) {
  var activeScopeMap = {};

  Mess.hotkeys = {
    bindScope: function(screenId, keyMap) {
      activeScopeMap = keyMap || {};
      
      if (!window.hotkeys) return;
      window.hotkeys.unbind();

      // Bind global shortcut '?' for help sheet
      window.hotkeys('shift+/', function(e) {
        if (['INPUT', 'TEXTAREA', 'SELECT'].indexOf(e.target.tagName) !== -1) return;
        e.preventDefault();
        Mess.hotkeys.showHelpSheet();
      });

      // Bind screen shortcuts
      Object.keys(activeScopeMap).forEach(function(keyCombo) {
        var handlerNameOrFn = activeScopeMap[keyCombo];
        window.hotkeys(keyCombo, function(e) {
          // Ignore input typing for single-character hotkeys
          if (['INPUT', 'TEXTAREA', 'SELECT'].indexOf(e.target.tagName) !== -1 && keyCombo.length === 1) {
            return;
          }
          e.preventDefault();
          if (typeof handlerNameOrFn === 'function') {
            handlerNameOrFn(e);
          } else {
            window.dispatchEvent(new CustomEvent('hotkey:' + handlerNameOrFn, { detail: { key: keyCombo } }));
          }
        });
      });
    },

    showHelpSheet: function() {
      var helpHtml = '<div class="flex-col gap-sm">';
      helpHtml += '<h3>Keyboard Shortcuts</h3>';
      helpHtml += '<ul class="flex-col gap-xs">';
      helpHtml += '<li><kbd>Ctrl+K</kbd> Open Command Palette</li>';
      helpHtml += '<li><kbd>?</kbd> Show Keyboard Help</li>';
      helpHtml += '<li><kbd>F10</kbd> Save & Print Token (Counter)</li>';
      helpHtml += '<li><kbd>Esc</kbd> Clear / Close Modal</li>';
      
      Object.keys(activeScopeMap).forEach(function(combo) {
        var action = activeScopeMap[combo];
        var actionName = typeof action === 'string' ? action : 'Custom Action';
        helpHtml += '<li><kbd>' + combo.toUpperCase() + '</kbd> ' + actionName + '</li>';
      });

      helpHtml += '</ul></div>';

      if (Mess.dialog && Mess.dialog.alert) {
        Mess.dialog.alert('Shortcut Help', helpHtml);
      } else {
        alert('Shortcuts:\nCtrl+K: Command Palette\n?: Help\nF10: Save Token\nEsc: Clear');
      }
    }
  };
})(window.Mess);
