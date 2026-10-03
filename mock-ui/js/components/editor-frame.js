/* editor-frame.js - Configurable Editor Frame with validation, dirty snapshots & leave guards */

window.Mess = window.Mess || {};

(function(Mess) {
  Mess.createEditorFrame = function(config) {
    var kind = config.kind;
    var entityName = config.entityName || 'Record';
    var listRoute = config.listRoute || '#/' + kind;
    var validateFn = config.validate || function() { return { valid: true, errors: {} }; };

    var initialSnapshot = null;
    var currentData = {};
    var isNew = true;

    function snapshot(data) {
      return JSON.stringify(data || {});
    }

    return {
      template: function(id) {
        isNew = !id || id === 'new';
        var record = isNew ? (config.getNewData ? config.getNewData() : {}) : (Mess.store ? Mess.store.get(kind, id) : {});
        currentData = Object.assign({}, record);
        initialSnapshot = snapshot(currentData);

        var title = isNew ? ('New ' + entityName) : ('Edit ' + entityName + ' – ' + (record.name || record.code || id));

        return /* html */ `
          <div class="editor-frame flex-col gap-lg" style="max-width: 800px; margin: 0 auto; height: 100%;">
            <header class="editor-header flex-row justify-between align-center">
              <div>
                <h2>${title}</h2>
              </div>
              <a href="${listRoute}" class="btn btn--quiet close-editor-btn">
                <i data-lucide="x"></i>
              </a>
            </header>

            <form class="editor-form flex-col gap-md" novalidate onsubmit="return false;">
              ${typeof config.fieldsHtml === 'function' ? config.fieldsHtml(currentData, isNew) : (config.fieldsHtml || '')}
            </form>

            <div class="editor-footer flex-row justify-between align-center" style="margin-top: auto; padding-top: 16px; border-top: 1px solid var(--separator);">
              <button type="button" class="btn btn--secondary cancel-btn">Cancel</button>
              <div class="flex-row gap-sm">
                ${isNew ? '<button type="button" class="btn btn--secondary save-new-btn">Save & new</button>' : ''}
                <button type="button" class="btn btn--primary save-btn">Save</button>
              </div>
            </div>
          </div>
        `;
      },

      init: function(rootEl, id, onSaved) {
        var form = rootEl.querySelector('.editor-form');
        var saveBtn = rootEl.querySelector('.save-btn');
        var saveNewBtn = rootEl.querySelector('.save-new-btn');
        var cancelBtn = rootEl.querySelector('.cancel-btn');

        function checkDirty() {
          var current = typeof config.readForm === 'function' ? config.readForm(form) : {};
          var dirty = snapshot(current) !== initialSnapshot;
          if (Mess.router && Mess.router.setDirty) {
            Mess.router.setDirty(dirty);
          }
          return dirty;
        }

        form.addEventListener('input', checkDirty);
        form.addEventListener('change', checkDirty);

        function doSave(andNew) {
          var data = typeof config.readForm === 'function' ? config.readForm(form) : {};
          var valResult = validateFn(data);

          // Clear previous field errors
          form.querySelectorAll('.field-error-msg').forEach(function(el) { el.style.display = 'none'; });
          form.querySelectorAll('.invalid').forEach(function(el) { el.classList.remove('invalid'); });

          if (!valResult.valid) {
            Object.keys(valResult.errors).forEach(function(fName) {
              var input = form.querySelector('[name="' + fName + '"]');
              if (input) {
                input.classList.add('invalid');
                var errEl = form.querySelector('#err-' + fName) || input.parentNode.querySelector('.field-error-msg');
                if (errEl) {
                  errEl.textContent = valResult.errors[fName];
                  errEl.style.display = 'block';
                }
              }
            });
            return;
          }

          var saveResult = config.onSave ? config.onSave(data, isNew) : Mess.store.save(kind, data);

          if (saveResult && saveResult.success === false) {
            if (Mess.dialog && Mess.dialog.alert) {
              Mess.dialog.alert('Save Error', saveResult.error || 'Failed to save record.');
            }
            return;
          }

          if (Mess.router && Mess.router.setDirty) {
            Mess.router.setDirty(false);
          }

          if (Mess.ui && Mess.ui.toast) {
            Mess.ui.toast('success', entityName + ' saved successfully.');
          }

          if (andNew) {
            window.location.hash = listRoute + '/new';
            window.location.reload();
          } else {
            window.location.hash = listRoute;
          }

          if (typeof onSaved === 'function') onSaved(data);
        }

        if (saveBtn) saveBtn.addEventListener('click', function() { doSave(false); });
        if (saveNewBtn) saveNewBtn.addEventListener('click', function() { doSave(true); });

        if (cancelBtn) {
          cancelBtn.addEventListener('click', function() {
            if (checkDirty()) {
              Mess.dialog.confirmLeave(function(choice) {
                if (choice === 'save') doSave(false);
                else if (choice === 'discard') {
                  Mess.router.setDirty(false);
                  window.location.hash = listRoute;
                }
              });
            } else {
              window.location.hash = listRoute;
            }
          });
        }

        // Ctrl+S hotkey
        var onKeyDown = function(e) {
          if ((e.ctrlKey || e.metaKey) && (e.key === 's' || e.key === 'S')) {
            e.preventDefault();
            doSave(false);
          }
        };
        rootEl.addEventListener('keydown', onKeyDown);

        if (typeof config.onMount === 'function') {
          config.onMount(rootEl, currentData);
        }
      },

      destroy: function() {
        if (Mess.router && Mess.router.setDirty) {
          Mess.router.setDirty(false);
        }
      }
    };
  };
})(window.Mess);
