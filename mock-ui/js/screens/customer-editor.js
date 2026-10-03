/* customer-editor.js - Screen 8: Customer Master Form View (labelled Member) */

window.Mess = window.Mess || {};

(function(Mess) {
  var frame = null;
  var rfidCaptureInstance = null;

  function getNextMemberCode() {
    var customers = (Mess.store && Mess.store.list('customers')) || [];
    var maxNum = 0;
    customers.forEach(function(c) {
      if (c.code) {
        var match = c.code.match(/M-(\d+)/i);
        if (match) {
          var n = parseInt(match[1], 10);
          if (n > maxNum) maxNum = n;
        }
      }
    });
    var next = maxNum + 1;
    return 'M-' + String(next).padStart(4, '0');
  }

  function getTodayIso() {
    if (Mess.clock && Mess.clock.now) {
      var d = Mess.clock.now();
      var yyyy = d.getFullYear();
      var mm = String(d.getMonth() + 1).padStart(2, '0');
      var dd = String(d.getDate()).padStart(2, '0');
      return yyyy + '-' + mm + '-' + dd;
    }
    return new Date().toISOString().slice(0, 10);
  }

  function generateInitialsSvg(name) {
    var initials = (name || 'Member').split(' ').map(function(p) { return p[0]; }).join('').slice(0, 2).toUpperCase();
    return `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><rect width="96" height="96" rx="48" fill="%23e2e8f0"/><text x="48" y="56" font-family="system-ui, sans-serif" font-size="34" font-weight="600" fill="%23475569" text-anchor="middle">${initials}</text></svg>`;
  }

  function buildAttendanceStripHtml(customerId) {
    if (!customerId || customerId === 'new') {
      return '<div class="text-xs color-ink-3">Attendance history will be recorded once meals are taken.</div>';
    }

    var today = Mess.clock ? Mess.clock.now() : new Date();
    var days = [];
    for (var i = 6; i >= 0; i--) {
      var d = new Date(today);
      d.setDate(d.getDate() - i);
      var yyyy = d.getFullYear();
      var mm = String(d.getMonth() + 1).padStart(2, '0');
      var dd = String(d.getDate()).padStart(2, '0');
      var iso = `${yyyy}-${mm}-${dd}`;
      var dayName = d.toLocaleDateString('en-US', { weekday: 'short' });
      days.push({ iso: iso, dayName: dayName, dateStr: `${dd}/${mm}` });
    }

    var allBills = (Mess.store && Mess.store.list('bills')) || [];
    var memberBills = allBills.filter(function(b) {
      return b.customer_id === customerId && !b.cancelled;
    });

    var pipsHtml = days.map(function(day) {
      var dayBills = memberBills.filter(function(b) { return b.date === day.iso; });
      var hadB = dayBills.some(function(b) { return b.meal_code === 'B'; });
      var hadL = dayBills.some(function(b) { return b.meal_code === 'L'; });
      var hadD = dayBills.some(function(b) { return b.meal_code === 'D'; });

      return `
        <div class="attendance-day-box flex-col align-center gap-xs card-inset" style="flex: 1; padding: 6px 4px; border-radius: var(--radius-sm); background: var(--canvas); text-align: center;">
          <span class="text-xs font-semibold">${day.dayName}</span>
          <span class="text-xs color-ink-3" style="font-size: 10px;">${day.dateStr}</span>
          <div class="flex-row gap-xs pt-xs">
            <span class="badge ${hadB ? 'badge--b' : 'badge--neutral'}" style="font-size: 9px; padding: 1px 4px; opacity: ${hadB ? '1' : '0.3'};">B</span>
            <span class="badge ${hadL ? 'badge--l' : 'badge--neutral'}" style="font-size: 9px; padding: 1px 4px; opacity: ${hadL ? '1' : '0.3'};">L</span>
            <span class="badge ${hadD ? 'badge--d' : 'badge--neutral'}" style="font-size: 9px; padding: 1px 4px; opacity: ${hadD ? '1' : '0.3'};">D</span>
          </div>
        </div>
      `;
    }).join('');

    return `
      <div class="attendance-strip flex-row gap-xs" style="width: 100%; overflow-x: auto;">
        ${pipsHtml}
      </div>
    `;
  }

  Mess.screens.register({
    id: 'customer-editor',
    route: '/customers/:id',
    title: 'Member Editor',
    roles: ['admin', 'supervisor'],

    template: function(params) {
      var id = params && params.id ? params.id : 'new';
      var isNew = !id || id === 'new';

      frame = Mess.createEditorFrame({
        kind: 'customers',
        entityName: 'Member',
        listRoute: '#/customers',

        getNewData: function() {
          var today = getTodayIso();
          var oneYearLater = new Date();
          oneYearLater.setFullYear(oneYearLater.getFullYear() + 1);
          var nextY = oneYearLater.getFullYear();
          var nextM = String(oneYearLater.getMonth() + 1).padStart(2, '0');
          var nextD = String(oneYearLater.getDate()).padStart(2, '0');

          return {
            id: 'cust_' + Date.now(),
            code: getNextMemberCode(),
            name: '',
            phone: '+971 50 ',
            rfid: '',
            cuisine_id: 'cuis_si',
            valid_from: today,
            valid_to: `${nextY}-${nextM}-${nextD}`,
            active: true,
            photo: ''
          };
        },

        fieldsHtml: function(data, isNew) {
          var cuisines = (Mess.store && Mess.store.list('cuisines')) || [];
          var activeCuisines = cuisines.filter(function(c) { return c.active !== false || c.id === data.cuisine_id; });

          var photoSrc = data.photo || generateInitialsSvg(data.name);

          return /* html */ `
            <input type="hidden" name="id" value="${data.id || ''}">
            <input type="hidden" name="photo" class="photo-data-input" value="${data.photo || ''}">

            <div class="card flex-col gap-md">
              <div class="flex-row gap-lg align-center">
                <!-- Photo Drop Zone -->
                <div class="photo-drop-zone flex-col align-center justify-center gap-xs" 
                     style="width: 110px; height: 110px; border-radius: 50%; border: 2px dashed var(--separator); cursor: pointer; position: relative; overflow: hidden; background: var(--canvas);"
                     title="Click or drop photo here">
                  <img src="${photoSrc}" class="member-photo-preview" style="width: 100%; height: 100%; object-fit: cover;" alt="Member photo">
                  <div class="photo-overlay" style="position: absolute; inset: 0; background: rgba(0,0,0,0.4); display: none; align-items: center; justify-content: center; color: #fff;">
                    <i data-lucide="camera" style="width: 24px; height: 24px;"></i>
                  </div>
                  <input type="file" class="photo-file-input" accept="image/*" style="display: none;">
                </div>

                <div class="flex-col gap-xs" style="flex: 1;">
                  <div class="flex-row justify-between align-center">
                    <div>
                      <h3 style="margin: 0; font-size: 16px;">${isNew ? 'New Member Profile' : data.name}</h3>
                      <span class="text-xs color-ink-2">Member card credentials & meal validity</span>
                    </div>
                    <label class="switch-label flex-row align-center gap-sm" style="cursor: pointer;">
                      <input type="checkbox" name="active" class="switch" ${data.active !== false ? 'checked' : ''}>
                      <span class="text-sm font-semibold">Active Member</span>
                    </label>
                  </div>

                  <div class="grid-2col gap-md pt-xs">
                    <!-- Member Code -->
                    <div class="field-group">
                      <label class="field-label required">Member Code</label>
                      <input type="text" name="code" class="field-input font-mono uppercase" 
                             value="${data.code || ''}" placeholder="e.g. M-0042" required>
                      <span class="field-error-msg text-xs color-danger" id="err-code" style="display:none;"></span>
                    </div>

                    <!-- Member Name -->
                    <div class="field-group">
                      <label class="field-label required">Full Name</label>
                      <input type="text" name="name" class="field-input name-input" 
                             value="${data.name || ''}" placeholder="e.g. Rahul K" required>
                      <span class="field-error-msg text-xs color-danger" id="err-name" style="display:none;"></span>
                    </div>
                  </div>
                </div>
              </div>

              <div class="grid-2col gap-md pt-sm" style="border-top: 1px solid var(--separator);">
                <!-- Phone -->
                <div class="field-group">
                  <label class="field-label required">Phone Number</label>
                  <input type="tel" name="phone" class="field-input font-mono" 
                         value="${data.phone || ''}" placeholder="+971 50 123 4567" required>
                  <span class="field-error-msg text-xs color-danger" id="err-phone" style="display:none;"></span>
                </div>

                <!-- Cuisine Selection -->
                <div class="field-group">
                  <label class="field-label required">Subscribed Cuisine</label>
                  <select name="cuisine_id" class="field-select" required>
                    ${activeCuisines.map(function(c) {
                      return `<option value="${c.id}" ${data.cuisine_id === c.id ? 'selected' : ''}>${c.name} (${c.code})</option>`;
                    }).join('')}
                  </select>
                  <span class="field-error-msg text-xs color-danger" id="err-cuisine_id" style="display:none;"></span>
                </div>
              </div>

              <!-- RFID Card Capture Widget Host -->
              <div class="field-group pt-sm" style="border-top: 1px solid var(--separator);">
                <label class="field-label">Assigned RFID Card</label>
                <div class="rfid-capture-host"></div>
                <input type="hidden" name="rfid" class="rfid-value-input" value="${data.rfid || ''}">
              </div>

              <!-- Validity Range with Quick Chips -->
              <div class="field-group pt-sm" style="border-top: 1px solid var(--separator);">
                <div class="flex-row justify-between align-center">
                  <label class="field-label required">Membership Validity Period</label>
                  <div class="validity-quick-chips flex-row wrap gap-xs">
                    <button type="button" class="badge badge--neutral chip-validity-btn text-xs" data-days="30">+30 days</button>
                    <button type="button" class="badge badge--neutral chip-validity-btn text-xs" data-days="90">+90 days</button>
                    <button type="button" class="badge badge--neutral chip-validity-btn text-xs" data-days="365">+1 year</button>
                    <button type="button" class="badge badge--neutral chip-validity-btn text-xs" data-target="end-month">End of month</button>
                    <button type="button" class="badge badge--neutral chip-validity-btn text-xs" data-target="end-year">End of year</button>
                  </div>
                </div>

                <div class="grid-2col gap-md pt-xs">
                  <div>
                    <label class="text-xs color-ink-2">Valid From</label>
                    <input type="date" name="valid_from" class="field-input valid-from-input" 
                           value="${data.valid_from || getTodayIso()}" required>
                  </div>
                  <div>
                    <label class="text-xs color-ink-2">Valid To</label>
                    <input type="date" name="valid_to" class="field-input valid-to-input" 
                           value="${data.valid_to || ''}" required>
                    <span class="field-error-msg text-xs color-danger" id="err-valid_to" style="display:none;"></span>
                  </div>
                </div>
              </div>

              <!-- Attendance Mini-strip Section -->
              <div class="field-group pt-sm" style="border-top: 1px solid var(--separator);">
                <label class="field-label text-xs color-ink-2">Recent Attendance (Last 7 Days)</label>
                ${buildAttendanceStripHtml(data.id)}
              </div>
            </div>
          `;
        },

        readForm: function(form) {
          var id = form.querySelector('[name="id"]').value;
          var code = form.querySelector('[name="code"]').value.trim().toUpperCase();
          var name = form.querySelector('[name="name"]').value.trim();
          var phone = form.querySelector('[name="phone"]').value.trim();
          var cuisine_id = form.querySelector('[name="cuisine_id"]').value;
          var rfid = form.querySelector('.rfid-value-input').value.trim();
          var valid_from = form.querySelector('[name="valid_from"]').value;
          var valid_to = form.querySelector('[name="valid_to"]').value;
          var active = form.querySelector('[name="active"]').checked;
          var photo = form.querySelector('.photo-data-input').value;

          return {
            id: id,
            code: code,
            name: name,
            phone: phone,
            cuisine_id: cuisine_id,
            rfid: rfid,
            valid_from: valid_from,
            valid_to: valid_to,
            active: active,
            photo: photo
          };
        },

        validate: function(data) {
          var errors = {};
          var valid = true;

          if (!data.code) {
            errors.code = 'Member code is required';
            valid = false;
          } else {
            // Duplicate check
            if (Mess.store) {
              var allCust = Mess.store.list('customers') || [];
              var dup = allCust.find(function(c) {
                return c.code && c.code.trim().toUpperCase() === data.code.trim().toUpperCase() && c.id !== data.id;
              });
              if (dup) {
                errors.code = 'Member code already exists';
                valid = false;
              }
            }
          }

          if (!data.name) {
            errors.name = 'Full name is required';
            valid = false;
          }

          if (!data.phone) {
            errors.phone = 'Phone number is required';
            valid = false;
          }

          if (!data.valid_to) {
            errors.valid_to = 'Valid To date is required';
            valid = false;
          } else if (data.valid_from && data.valid_to < data.valid_from) {
            errors.valid_to = 'Valid To date cannot be before Valid From';
            valid = false;
          }

          return { valid: valid, errors: errors };
        },

        onMount: function(rootEl, currentData) {
          var rfidHost = rootEl.querySelector('.rfid-capture-host');
          var rfidInput = rootEl.querySelector('.rfid-value-input');
          var validFromInput = rootEl.querySelector('.valid-from-input');
          var validToInput = rootEl.querySelector('.valid-to-input');
          var quickChips = rootEl.querySelectorAll('.chip-validity-btn');

          // Initialize RFID Capture component
          if (rfidHost) {
            rfidCaptureInstance = Mess.createRfidCapture(rfidHost, {
              value: currentData.rfid || '',
              currentCustomerId: currentData.id,
              onChange: function(val) {
                rfidInput.value = val;
                rfidInput.dispatchEvent(new Event('input', { bubbles: true }));
              }
            });
          }

          // Photo drop zone handling
          var dropZone = rootEl.querySelector('.photo-drop-zone');
          var fileInput = rootEl.querySelector('.photo-file-input');
          var photoImg = rootEl.querySelector('.member-photo-preview');
          var photoData = rootEl.querySelector('.photo-data-input');
          var nameInput = rootEl.querySelector('.name-input');

          if (dropZone && fileInput) {
            dropZone.addEventListener('click', function() {
              fileInput.click();
            });

            fileInput.addEventListener('change', function() {
              if (fileInput.files && fileInput.files[0]) {
                var reader = new FileReader();
                reader.onload = function(e) {
                  photoImg.src = e.target.result;
                  photoData.value = e.target.result;
                  photoData.dispatchEvent(new Event('input', { bubbles: true }));
                };
                reader.readAsDataURL(fileInput.files[0]);
              }
            });
          }

          if (nameInput) {
            nameInput.addEventListener('input', function() {
              if (!photoData.value) {
                photoImg.src = generateInitialsSvg(nameInput.value);
              }
            });
          }

          // Wire validity quick chips
          quickChips.forEach(function(chip) {
            chip.addEventListener('click', function() {
              var fromVal = validFromInput.value || getTodayIso();
              var d = new Date(fromVal);

              var days = chip.getAttribute('data-days');
              var target = chip.getAttribute('data-target');

              if (days) {
                d.setDate(d.getDate() + parseInt(days, 10));
              } else if (target === 'end-month') {
                d = new Date(d.getFullYear(), d.getMonth() + 1, 0);
              } else if (target === 'end-year') {
                d = new Date(d.getFullYear(), 11, 31);
              }

              var yyyy = d.getFullYear();
              var mm = String(d.getMonth() + 1).padStart(2, '0');
              var dd = String(d.getDate()).padStart(2, '0');
              validToInput.value = `${yyyy}-${mm}-${dd}`;
              validToInput.dispatchEvent(new Event('input', { bubbles: true }));

              quickChips.forEach(function(c) { c.className = 'badge badge--neutral chip-validity-btn text-xs'; });
              chip.className = 'badge badge--primary chip-validity-btn text-xs';
            });
          });
        }
      });

      return frame.template(id);
    },

    component: function(params, targetEl) {
      return {
        init: function(el) {
          var rootEl = el || targetEl || document.getElementById('outlet');
          var id = params && params.id ? params.id : 'new';
          if (frame && rootEl) {
            frame.init(rootEl, id);
          }
        },
        destroy: function() {
          if (rfidCaptureInstance) {
            rfidCaptureInstance.destroy();
            rfidCaptureInstance = null;
          }
          if (frame) {
            frame.destroy();
            frame = null;
          }
        }
      };
    }
  });
})(window.Mess);
