/* dialog.js - Promise-based dialog, sheet, confirm, prompt & supervisor auth */

window.Mess = window.Mess || {};

(function(Mess) {
  var activeTrigger = null;

  function createDialogContainer() {
    var d = document.createElement('dialog');
    d.className = 'mess-modal-dialog';
    document.body.appendChild(d);
    return d;
  }

  function cleanupDialog(dlg, trigger) {
    if (dlg) {
      if (dlg.open) dlg.close();
      if (dlg.parentNode) dlg.parentNode.removeChild(dlg);
    }
    if (trigger && typeof trigger.focus === 'function') {
      try { trigger.focus(); } catch (e) {}
    }
  }

  Mess.dialog = {
    alert: function(title, messageHtml) {
      activeTrigger = document.activeElement;
      return new Promise(function(resolve) {
        var dlg = createDialogContainer();
        dlg.innerHTML = /* html */ `
          <div class="dialog-header">
            <h3 class="dialog-title">${title || 'Notice'}</h3>
            <button type="button" class="btn btn--icon close-btn" aria-label="Close"><i data-lucide="x"></i></button>
          </div>
          <div class="dialog-body">
            <div>${messageHtml}</div>
          </div>
          <div class="dialog-footer">
            <button type="button" class="btn btn--primary ok-btn">OK</button>
          </div>
        `;
        if (Mess.refreshIcons) Mess.refreshIcons(dlg);

        function close() {
          cleanupDialog(dlg, activeTrigger);
          resolve();
        }

        dlg.querySelector('.close-btn').addEventListener('click', close);
        dlg.querySelector('.ok-btn').addEventListener('click', close);
        dlg.addEventListener('cancel', function(e) {
          e.preventDefault();
          close();
        });

        dlg.showModal();
        var okBtn = dlg.querySelector('.ok-btn');
        if (okBtn) okBtn.focus();
      });
    },

    confirm: function(title, messageHtml, options) {
      activeTrigger = document.activeElement;
      var opt = options || {};
      var confirmLabel = opt.confirmText || 'Confirm';
      var cancelLabel = opt.cancelText || 'Cancel';
      var isDanger = !!opt.danger;

      return new Promise(function(resolve) {
        var dlg = createDialogContainer();
        dlg.innerHTML = /* html */ `
          <div class="dialog-header">
            <h3 class="dialog-title">${title || 'Confirm Action'}</h3>
            <button type="button" class="btn btn--icon close-btn" aria-label="Close"><i data-lucide="x"></i></button>
          </div>
          <div class="dialog-body">
            <div>${messageHtml}</div>
          </div>
          <div class="dialog-footer">
            <button type="button" class="btn btn--secondary cancel-btn">${cancelLabel}</button>
            <button type="button" class="btn ${isDanger ? 'btn--danger' : 'btn--primary'} confirm-btn">${confirmLabel}</button>
          </div>
        `;
        if (Mess.refreshIcons) Mess.refreshIcons(dlg);

        function handleDone(val) {
          cleanupDialog(dlg, activeTrigger);
          resolve(val);
        }

        dlg.querySelector('.close-btn').addEventListener('click', function() { handleDone(false); });
        dlg.querySelector('.cancel-btn').addEventListener('click', function() { handleDone(false); });
        dlg.querySelector('.confirm-btn').addEventListener('click', function() { handleDone(true); });
        dlg.addEventListener('cancel', function(e) {
          e.preventDefault();
          handleDone(false);
        });

        dlg.showModal();
        var confirmBtn = dlg.querySelector('.confirm-btn');
        if (confirmBtn) confirmBtn.focus();
      });
    },

    prompt: function(title, label, defaultValue) {
      activeTrigger = document.activeElement;
      return new Promise(function(resolve) {
        var dlg = createDialogContainer();
        dlg.innerHTML = /* html */ `
          <div class="dialog-header">
            <h3 class="dialog-title">${title}</h3>
            <button type="button" class="btn btn--icon close-btn" aria-label="Close"><i data-lucide="x"></i></button>
          </div>
          <div class="dialog-body">
            <div class="field-group">
              <label class="field-label">${label || 'Enter value:'}</label>
              <input type="text" class="field-input prompt-val" value="${defaultValue || ''}">
            </div>
          </div>
          <div class="dialog-footer">
            <button type="button" class="btn btn--secondary cancel-btn">Cancel</button>
            <button type="button" class="btn btn--primary ok-btn">OK</button>
          </div>
        `;
        if (Mess.refreshIcons) Mess.refreshIcons(dlg);

        var input = dlg.querySelector('.prompt-val');

        function handleDone(val) {
          cleanupDialog(dlg, activeTrigger);
          resolve(val);
        }

        dlg.querySelector('.close-btn').addEventListener('click', function() { handleDone(null); });
        dlg.querySelector('.cancel-btn').addEventListener('click', function() { handleDone(null); });
        dlg.querySelector('.ok-btn').addEventListener('click', function() { handleDone(input.value); });
        input.addEventListener('keydown', function(e) {
          if (e.key === 'Enter') handleDone(input.value);
        });
        dlg.addEventListener('cancel', function(e) {
          e.preventDefault();
          handleDone(null);
        });

        dlg.showModal();
        if (input) {
          input.focus();
          input.select();
        }
      });
    },

    supervisorAuth: function(titleOrCb, maybeCb) {
      activeTrigger = document.activeElement;
      var actionTitle = typeof titleOrCb === 'string' ? titleOrCb : 'Supervisor Authorization';
      var cb = typeof titleOrCb === 'function' ? titleOrCb : (typeof maybeCb === 'function' ? maybeCb : null);

      return new Promise(function(resolve, reject) {
        var dlg = createDialogContainer();
        dlg.innerHTML = /* html */ `
          <div class="dialog-header">
            <h3 class="dialog-title">${actionTitle}</h3>
            <button type="button" class="btn btn--icon close-btn" aria-label="Close"><i data-lucide="x"></i></button>
          </div>
          <div class="dialog-body">
            <p class="text-sm color-ink-2">Enter supervisor PIN/password to proceed (Demo PIN: <strong>1234</strong>):</p>
            <div class="field-group">
              <label class="field-label">Password</label>
              <input type="password" class="field-input sup-pwd" placeholder="Enter PIN">
              <span class="field-error-msg pwd-err" style="display: none;">Incorrect supervisor password.</span>
            </div>
          </div>
          <div class="dialog-footer">
            <button type="button" class="btn btn--secondary cancel-btn">Cancel</button>
            <button type="button" class="btn btn--primary auth-btn">Authorize</button>
          </div>
        `;
        if (Mess.refreshIcons) Mess.refreshIcons(dlg);

        var pwdInput = dlg.querySelector('.sup-pwd');
        var errEl = dlg.querySelector('.pwd-err');

        function verify() {
          if (pwdInput.value === '1234') {
            cleanupDialog(dlg, activeTrigger);
            if (cb) cb(true, { supervisor: 'sup.ali', authorized: true });
            resolve({ supervisor: 'sup.ali', authorized: true });
          } else {
            errEl.style.display = 'block';
            pwdInput.classList.add('invalid');
            pwdInput.focus();
            pwdInput.select();
          }
        }

        function cancel() {
          cleanupDialog(dlg, activeTrigger);
          if (cb) cb(false);
          reject(new Error('Supervisor authorization cancelled.'));
        }

        dlg.querySelector('.close-btn').addEventListener('click', cancel);
        dlg.querySelector('.cancel-btn').addEventListener('click', cancel);
        dlg.querySelector('.auth-btn').addEventListener('click', verify);
        pwdInput.addEventListener('keydown', function(e) {
          if (e.key === 'Enter') verify();
        });
        dlg.addEventListener('cancel', function(e) {
          e.preventDefault();
          cancel();
        });

        dlg.showModal();
        pwdInput.focus();
      });
    },

    reasonPrompt: function(title, label) {
      activeTrigger = document.activeElement;
      return new Promise(function(resolve, reject) {
        var dlg = createDialogContainer();
        dlg.innerHTML = /* html */ `
          <div class="dialog-header">
            <h3 class="dialog-title">${title || 'Reason Required'}</h3>
            <button type="button" class="btn btn--icon close-btn" aria-label="Close"><i data-lucide="x"></i></button>
          </div>
          <div class="dialog-body">
            <div class="field-group">
              <label class="field-label">${label || 'Reason'}</label>
              <input type="text" class="field-input reason-input" placeholder="Enter reason...">
              <span class="field-error-msg reason-err" style="display: none;">Reason is required.</span>
            </div>
          </div>
          <div class="dialog-footer">
            <button type="button" class="btn btn--secondary cancel-btn">Cancel</button>
            <button type="button" class="btn btn--primary submit-btn">Submit</button>
          </div>
        `;
        if (Mess.refreshIcons) Mess.refreshIcons(dlg);

        var input = dlg.querySelector('.reason-input');
        var errEl = dlg.querySelector('.reason-err');

        function submit() {
          var val = (input.value || '').trim();
          if (!val) {
            errEl.style.display = 'block';
            input.classList.add('invalid');
            input.focus();
            return;
          }
          cleanupDialog(dlg, activeTrigger);
          resolve(val);
        }

        function cancel() {
          cleanupDialog(dlg, activeTrigger);
          reject(new Error('Reason prompt cancelled.'));
        }

        dlg.querySelector('.close-btn').addEventListener('click', cancel);
        dlg.querySelector('.cancel-btn').addEventListener('click', cancel);
        dlg.querySelector('.submit-btn').addEventListener('click', submit);
        input.addEventListener('keydown', function(e) {
          if (e.key === 'Enter') submit();
        });
        dlg.addEventListener('cancel', function(e) {
          e.preventDefault();
          cancel();
        });

        dlg.showModal();
        input.focus();
      });
    },

    confirmLeave: function(onChoice) {
      activeTrigger = document.activeElement;
      var dlg = createDialogContainer();
      dlg.innerHTML = /* html */ `
        <div class="dialog-header">
          <h3 class="dialog-title">Unsaved Changes</h3>
          <button type="button" class="btn btn--icon close-btn" aria-label="Close"><i data-lucide="x"></i></button>
        </div>
        <div class="dialog-body">
          <p class="text-sm">You have unsaved changes in this editor. What would you like to do?</p>
        </div>
        <div class="dialog-footer">
          <button type="button" class="btn btn--secondary cancel-btn">Cancel</button>
          <button type="button" class="btn btn--danger discard-btn">Discard Changes</button>
          <button type="button" class="btn btn--primary save-btn">Save</button>
        </div>
      `;
      if (Mess.refreshIcons) Mess.refreshIcons(dlg);

      function done(choice) {
        cleanupDialog(dlg, activeTrigger);
        if (typeof onChoice === 'function') onChoice(choice);
      }

      dlg.querySelector('.close-btn').addEventListener('click', function() { done('cancel'); });
      dlg.querySelector('.cancel-btn').addEventListener('click', function() { done('cancel'); });
      dlg.querySelector('.discard-btn').addEventListener('click', function() { done('discard'); });
      dlg.querySelector('.save-btn').addEventListener('click', function() { done('save'); });
      dlg.addEventListener('cancel', function(e) {
        e.preventDefault();
        done('cancel');
      });

      dlg.showModal();
      var saveBtn = dlg.querySelector('.save-btn');
      if (saveBtn) saveBtn.focus();
    },

    sheet: function(title, bodyHtml, onMount) {
      activeTrigger = document.activeElement;
      var sheetEl = document.createElement('div');
      sheetEl.className = 'side-sheet';
      sheetEl.innerHTML = /* html */ `
        <div class="sheet-header">
          <h3 class="font-bold text-base">${title}</h3>
          <button type="button" class="btn btn--icon close-sheet-btn"><i data-lucide="x"></i></button>
        </div>
        <div class="sheet-body">${bodyHtml}</div>
      `;

      var backdropEl = document.createElement('div');
      backdropEl.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,0.4);z-index:var(--z-drawer);backdrop-filter:blur(2px);';

      document.body.appendChild(backdropEl);
      document.body.appendChild(sheetEl);
      if (Mess.refreshIcons) Mess.refreshIcons(sheetEl);

      // Trigger slide-in
      setTimeout(function() { sheetEl.classList.add('open'); }, 10);

      function closeSheet() {
        sheetEl.classList.remove('open');
        setTimeout(function() {
          if (sheetEl.parentNode) sheetEl.parentNode.removeChild(sheetEl);
          if (backdropEl.parentNode) backdropEl.parentNode.removeChild(backdropEl);
          if (activeTrigger && typeof activeTrigger.focus === 'function') activeTrigger.focus();
        }, 200);
      }

      sheetEl.querySelector('.close-sheet-btn').addEventListener('click', closeSheet);
      backdropEl.addEventListener('click', closeSheet);

      if (typeof onMount === 'function') {
        onMount(sheetEl, closeSheet);
      }

      return { close: closeSheet, el: sheetEl };
    }
  };
})(window.Mess);
