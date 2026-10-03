/* meal-time-settings.js - Screen 10: Meal Time Settings with live timeline preview & overlap validation */

window.Mess = window.Mess || {};

(function(Mess) {
  var timelinePreview = null;

  function timeToMinutes(tStr) {
    if (!tStr) return 0;
    var parts = tStr.split(':');
    return parseInt(parts[0], 10) * 60 + parseInt(parts[1] || 0, 10);
  }

  Mess.screens.register({
    id: 'meal-time-settings',
    route: '/settings/meal-times',
    title: 'Meal Time Settings',
    nav: { group: 'Operations', icon: 'clock', order: 5 },
    roles: ['admin', 'supervisor'],

    template: function() {
      var allMeals = (Mess.store && Mess.store.list('meal_times')) || [
        { id: 'b', code: 'B', name: 'Breakfast', start_time: '06:00', end_time: '10:00', active: true },
        { id: 'l', code: 'L', name: 'Lunch', start_time: '12:00', end_time: '15:00', active: true },
        { id: 'd', code: 'D', name: 'Dinner', start_time: '19:00', end_time: '22:30', active: true }
      ];

      var mealMap = {};
      allMeals.forEach(function(m) {
        var k = (m.code || m.id || '').toUpperCase();
        mealMap[k] = m;
      });

      var b = mealMap['B'] || { code: 'B', name: 'Breakfast', start_time: '06:00', end_time: '10:00', active: true };
      var l = mealMap['L'] || { code: 'L', name: 'Lunch', start_time: '12:00', end_time: '15:00', active: true };
      var d = mealMap['D'] || { code: 'D', name: 'Dinner', start_time: '19:00', end_time: '22:30', active: true };

      return /* html */ `
        <div class="meal-times-screen flex-col gap-lg" style="max-width: 840px; margin: 0 auto; height: 100%;">
          <!-- Header -->
          <div class="toolbar flex-row justify-between align-center">
            <div>
              <h2 style="margin: 0;">Meal Time Settings</h2>
              <span class="text-sm color-ink-2">Define operating service windows for Breakfast, Lunch, and Dinner</span>
            </div>
            <div class="flex-row gap-sm">
              <button type="button" class="btn btn--secondary btn-reset-defaults">Reset to Defaults</button>
              <button type="button" class="btn btn--primary btn-save-times">
                <i data-lucide="check"></i> Save Settings
              </button>
            </div>
          </div>

          <!-- Overlap Error Banner -->
          <div class="overlap-error-banner banner banner--danger flex-row align-center gap-sm" style="display: none; padding: 10px 16px; border-radius: var(--radius-panel);">
            <i data-lucide="alert-octagon" style="width: 20px; height: 20px; flex-shrink: 0;"></i>
            <span class="overlap-error-text text-sm font-semibold"></span>
          </div>

          <!-- Live Timeline Preview Card -->
          <div class="card flex-col gap-sm" style="background: var(--surface);">
            <div class="flex-row justify-between align-center">
              <span class="text-xs font-semibold color-ink-2 uppercase tracking-wide">Live Operating Timeline Preview</span>
              <span class="badge badge--neutral text-xs">06:00 – 22:30</span>
            </div>
            <div class="meal-times-timeline-host pt-xs"></div>
          </div>

          <!-- Time Windows Form Card -->
          <div class="card flex-col gap-md">
            <h3 style="margin: 0; font-size: 15px;">Service Windows</h3>
            <div class="flex-col gap-sm meal-rows-container">
              <!-- Breakfast Row -->
              <div class="meal-row card-inset flex-row align-center justify-between gap-md p-md" data-meal="B" 
                   style="border-radius: var(--radius-sm); border: 1px solid var(--separator); background: var(--canvas); transition: border-color var(--motion-fast);">
                <div class="flex-row align-center gap-md" style="min-width: 180px;">
                  <div class="badge badge--b p-sm" style="border-radius: var(--radius-sm);">
                    <i data-lucide="sunrise"></i>
                  </div>
                  <div class="flex-col">
                    <span class="font-bold text-sm">Breakfast (B)</span>
                    <span class="text-xs color-ink-3">Morning meal window</span>
                  </div>
                </div>

                <div class="flex-row align-center gap-sm">
                  <div class="flex-col gap-xs">
                    <label class="text-xs color-ink-2">Start Time</label>
                    <input type="time" class="field-input meal-start-time" value="${b.start_time || '06:00'}" style="width: 120px;">
                  </div>
                  <span class="color-ink-3 pt-md">—</span>
                  <div class="flex-col gap-xs">
                    <label class="text-xs color-ink-2">End Time</label>
                    <input type="time" class="field-input meal-end-time" value="${b.end_time || '10:00'}" style="width: 120px;">
                  </div>
                </div>

                <label class="switch-label flex-row align-center gap-sm" style="cursor: pointer;">
                  <input type="checkbox" class="switch meal-active-switch" ${b.active !== false ? 'checked' : ''}>
                  <span class="text-xs font-semibold">Active</span>
                </label>
              </div>

              <!-- Lunch Row -->
              <div class="meal-row card-inset flex-row align-center justify-between gap-md p-md" data-meal="L" 
                   style="border-radius: var(--radius-sm); border: 1px solid var(--separator); background: var(--canvas); transition: border-color var(--motion-fast);">
                <div class="flex-row align-center gap-md" style="min-width: 180px;">
                  <div class="badge badge--l p-sm" style="border-radius: var(--radius-sm);">
                    <i data-lucide="sun"></i>
                  </div>
                  <div class="flex-col">
                    <span class="font-bold text-sm">Lunch (L)</span>
                    <span class="text-xs color-ink-3">Afternoon meal window</span>
                  </div>
                </div>

                <div class="flex-row align-center gap-sm">
                  <div class="flex-col gap-xs">
                    <label class="text-xs color-ink-2">Start Time</label>
                    <input type="time" class="field-input meal-start-time" value="${l.start_time || '12:00'}" style="width: 120px;">
                  </div>
                  <span class="color-ink-3 pt-md">—</span>
                  <div class="flex-col gap-xs">
                    <label class="text-xs color-ink-2">End Time</label>
                    <input type="time" class="field-input meal-end-time" value="${l.end_time || '15:00'}" style="width: 120px;">
                  </div>
                </div>

                <label class="switch-label flex-row align-center gap-sm" style="cursor: pointer;">
                  <input type="checkbox" class="switch meal-active-switch" ${l.active !== false ? 'checked' : ''}>
                  <span class="text-xs font-semibold">Active</span>
                </label>
              </div>

              <!-- Dinner Row -->
              <div class="meal-row card-inset flex-row align-center justify-between gap-md p-md" data-meal="D" 
                   style="border-radius: var(--radius-sm); border: 1px solid var(--separator); background: var(--canvas); transition: border-color var(--motion-fast);">
                <div class="flex-row align-center gap-md" style="min-width: 180px;">
                  <div class="badge badge--d p-sm" style="border-radius: var(--radius-sm);">
                    <i data-lucide="moon-star"></i>
                  </div>
                  <div class="flex-col">
                    <span class="font-bold text-sm">Dinner (D)</span>
                    <span class="text-xs color-ink-3">Evening meal window</span>
                  </div>
                </div>

                <div class="flex-row align-center gap-sm">
                  <div class="flex-col gap-xs">
                    <label class="text-xs color-ink-2">Start Time</label>
                    <input type="time" class="field-input meal-start-time" value="${d.start_time || '19:00'}" style="width: 120px;">
                  </div>
                  <span class="color-ink-3 pt-md">—</span>
                  <div class="flex-col gap-xs">
                    <label class="text-xs color-ink-2">End Time</label>
                    <input type="time" class="field-input meal-end-time" value="${d.end_time || '22:30'}" style="width: 120px;">
                  </div>
                </div>

                <label class="switch-label flex-row align-center gap-sm" style="cursor: pointer;">
                  <input type="checkbox" class="switch meal-active-switch" ${d.active !== false ? 'checked' : ''}>
                  <span class="text-xs font-semibold">Active</span>
                </label>
              </div>
            </div>
          </div>
        </div>
      `;
    },

    component: function(params, targetEl) {
      return {
        init: function(el) {
          var rootEl = el || targetEl || document.getElementById('outlet');
          var timelineHost = rootEl.querySelector('.meal-times-timeline-host');
          var saveBtn = rootEl.querySelector('.btn-save-times');
          var resetBtn = rootEl.querySelector('.btn-reset-defaults');
          var errBanner = rootEl.querySelector('.overlap-error-banner');
          var errText = rootEl.querySelector('.overlap-error-text');

          var rows = rootEl.querySelectorAll('.meal-row');

          function readFormMeals() {
            var result = [];
            rows.forEach(function(row) {
              var code = row.getAttribute('data-meal');
              var name = code === 'B' ? 'Breakfast' : code === 'L' ? 'Lunch' : 'Dinner';
              var start = row.querySelector('.meal-start-time').value;
              var end = row.querySelector('.meal-end-time').value;
              var active = row.querySelector('.meal-active-switch').checked;

              result.push({
                id: code.toLowerCase(),
                code: code,
                name: name,
                start_time: start,
                end_time: end,
                active: active
              });
            });
            return result;
          }

          function validateAndSync() {
            var meals = readFormMeals();
            var hasOverlap = false;
            var overlapMsg = '';

            // Reset row highlighting
            rows.forEach(function(r) {
              r.style.borderColor = 'var(--separator)';
              r.style.backgroundColor = 'var(--canvas)';
            });

            // Check each pair of active meals for overlap
            for (var i = 0; i < meals.length; i++) {
              for (var j = i + 1; j < meals.length; j++) {
                var m1 = meals[i];
                var m2 = meals[j];
                if (!m1.active || !m2.active) continue;

                var s1 = timeToMinutes(m1.start_time);
                var e1 = timeToMinutes(m1.end_time);
                var s2 = timeToMinutes(m2.start_time);
                var e2 = timeToMinutes(m2.end_time);

                // Start must be before end for each
                if (e1 <= s1) {
                  hasOverlap = true;
                  overlapMsg = `${m1.name} end time (${m1.end_time}) must be after start time (${m1.start_time}).`;
                  highlightRow(m1.code);
                  break;
                }

                // Window overlap check: s1 < e2 && s2 < e1
                if (s1 < e2 && s2 < e1) {
                  hasOverlap = true;
                  highlightRow(m1.code);
                  highlightRow(m2.code);

                  if (s2 < e1 && s1 < s2) {
                    overlapMsg = `${m2.name} starts before ${m1.name} ends (${m2.start_time} < ${m1.end_time}).`;
                  } else {
                    overlapMsg = `${m1.name} and ${m2.name} time windows overlap.`;
                  }
                  break;
                }
              }
              if (hasOverlap) break;
            }

            if (hasOverlap) {
              errText.textContent = overlapMsg;
              errBanner.style.display = 'flex';
              saveBtn.disabled = true;
            } else {
              errBanner.style.display = 'none';
              saveBtn.disabled = false;
            }

            // Live update the timeline preview
            if (timelinePreview) {
              timelinePreview.setMeals(meals);
            }

            if (Mess.router && Mess.router.setDirty) {
              Mess.router.setDirty(true);
            }
          }

          function highlightRow(mealCode) {
            rows.forEach(function(r) {
              if (r.getAttribute('data-meal') === mealCode) {
                r.style.borderColor = 'var(--danger)';
                r.style.backgroundColor = 'rgba(239, 68, 68, 0.08)';
              }
            });
          }

          // Mount Timeline Preview
          if (timelineHost && Mess.createMealTimeline) {
            timelinePreview = Mess.createMealTimeline(timelineHost, {
              meals: readFormMeals(),
              showLabels: true,
              showHeader: true
            });
          }

          // Bind inputs
          rootEl.querySelectorAll('.meal-start-time, .meal-end-time, .meal-active-switch').forEach(function(input) {
            input.addEventListener('input', validateAndSync);
            input.addEventListener('change', validateAndSync);
          });

          // Reset to defaults
          resetBtn.addEventListener('click', function() {
            var defaults = {
              'B': { start: '06:00', end: '10:00' },
              'L': { start: '12:00', end: '15:00' },
              'D': { start: '19:00', end: '22:30' }
            };

            rows.forEach(function(r) {
              var code = r.getAttribute('data-meal');
              if (defaults[code]) {
                r.querySelector('.meal-start-time').value = defaults[code].start;
                r.querySelector('.meal-end-time').value = defaults[code].end;
                r.querySelector('.meal-active-switch').checked = true;
              }
            });

            validateAndSync();
            if (Mess.ui && Mess.ui.toast) {
              Mess.ui.toast('info', 'Meal times reset to standard operating hours.');
            }
          });

          // Save settings
          saveBtn.addEventListener('click', function() {
            var meals = readFormMeals();

            // Persist to store
            meals.forEach(function(m) {
              Mess.store.save('meal_times', m);
            });

            if (Mess.persist && Mess.persist.saveCollection) {
              Mess.persist.saveCollection('meal_times', meals);
            }

            // Immediately notify Clock service so counter & topbar update
            if (Mess.clock && Mess.clock.syncMealTimes) {
              Mess.clock.syncMealTimes(meals);
            } else if (Mess.clock && Mess.clock.tick) {
              Mess.clock.tick();
            }

            window.dispatchEvent(new CustomEvent('mealchange', {
              detail: { meal: Mess.clock ? Mess.clock.currentMeal() : 'none' }
            }));

            if (Mess.router && Mess.router.setDirty) {
              Mess.router.setDirty(false);
            }

            if (Mess.ui && Mess.ui.toast) {
              Mess.ui.toast('success', 'Meal time settings saved successfully.');
            }
          });
        },

        destroy: function() {
          if (timelinePreview) {
            timelinePreview.destroy();
            timelinePreview = null;
          }
          if (Mess.router && Mess.router.setDirty) {
            Mess.router.setDirty(false);
          }
        }
      };
    }
  });
})(window.Mess);
