/* meal-timeline.js - 06:00 to 22:30 Meal timeline with active windows and live clock marker */

window.Mess = window.Mess || {};

(function(Mess) {
  // Timeline bounds: 06:00 (360m) to 22:30 (1350m) = 990m total
  var START_MINUTES = 360;
  var END_MINUTES = 1350;
  var TOTAL_MINUTES = END_MINUTES - START_MINUTES;

  function timeToMinutes(str) {
    if (!str) return 0;
    var parts = str.split(':');
    return parseInt(parts[0], 10) * 60 + parseInt(parts[1] || 0, 10);
  }

  Mess.createMealTimeline = function(containerEl, options) {
    options = options || {};
    var showLabels = options.showLabels !== false;
    var showHeader = options.showHeader !== false;
    var customMeals = options.meals || null;

    var tickListener = null;

    var html = `
      <div class="meal-timeline-container flex-col gap-xs" style="width: 100%;">
        ${showHeader ? `
          <div class="timeline-header flex-row justify-between align-center text-xs">
            <span class="timeline-status-badge badge badge--neutral">Checking schedule…</span>
            <span class="timeline-current-time font-mono color-ink-2">--:--</span>
          </div>
        ` : ''}

        <div class="timeline-track" style="position: relative; height: 18px; border-radius: var(--radius-pill); overflow: hidden; background: var(--canvas); border: 1px solid var(--separator);">
          <div class="timeline-windows-layer" style="position: absolute; inset: 0;"></div>
          <div class="timeline-now-marker" style="display: none; position: absolute; top: -2px; bottom: -2px; width: 4px; border-radius: 2px; background: var(--ink); box-shadow: 0 0 6px rgba(0,0,0,0.5); z-index: 10;"></div>
        </div>

        ${showLabels ? `
          <div class="timeline-ticks flex-row justify-between text-xs color-ink-3 font-mono" style="font-size: 10px; padding: 0 2px;">
            <span>06:00</span>
            <span>10:00</span>
            <span>12:00</span>
            <span>15:00</span>
            <span>19:00</span>
            <span>22:30</span>
          </div>
        ` : ''}
      </div>
    `;

    containerEl.innerHTML = html;

    var windowsLayer = containerEl.querySelector('.timeline-windows-layer');
    var markerEl = containerEl.querySelector('.timeline-now-marker');
    var statusBadge = containerEl.querySelector('.timeline-status-badge');
    var currentTimeEl = containerEl.querySelector('.timeline-current-time');

    function getMeals() {
      if (customMeals) return customMeals;
      if (Mess.store) {
        var list = Mess.store.list('meal_times');
        if (list && list.length > 0) return list;
      }
      return [
        { id: 'b', code: 'B', name: 'Breakfast', start_time: '06:00', end_time: '10:00', active: true },
        { id: 'l', code: 'L', name: 'Lunch', start_time: '12:00', end_time: '15:00', active: true },
        { id: 'd', code: 'D', name: 'Dinner', start_time: '19:00', end_time: '22:30', active: true }
      ];
    }

    function renderWindows() {
      windowsLayer.innerHTML = '';
      var meals = getMeals();

      meals.forEach(function(m) {
        if (m.active === false) return;
        var startM = timeToMinutes(m.start_time);
        var endM = timeToMinutes(m.end_time);

        // Clamp to timeline range
        var clampedStart = Math.max(START_MINUTES, Math.min(END_MINUTES, startM));
        var clampedEnd = Math.max(START_MINUTES, Math.min(END_MINUTES, endM));
        if (clampedEnd <= clampedStart) return;

        var leftPct = ((clampedStart - START_MINUTES) / TOTAL_MINUTES) * 100;
        var widthPct = ((clampedEnd - clampedStart) / TOTAL_MINUTES) * 100;

        var codeLower = (m.code || m.id || 'b').toLowerCase();
        var winDiv = document.createElement('div');
        winDiv.className = `timeline-window timeline-window--${codeLower}`;
        winDiv.setAttribute('title', `${m.name}: ${m.start_time} - ${m.end_time}`);
        winDiv.style.position = 'absolute';
        winDiv.style.top = '0';
        winDiv.style.bottom = '0';
        winDiv.style.left = leftPct + '%';
        winDiv.style.width = widthPct + '%';
        winDiv.style.borderRadius = 'var(--radius-sm)';

        // Add small text label inside window if wide enough
        if (widthPct > 15) {
          winDiv.innerHTML = `<span style="font-size: 10px; font-weight: 600; padding-left: 6px; line-height: 18px; color: var(--ink); opacity: 0.8;">${m.name}</span>`;
        }

        windowsLayer.appendChild(winDiv);
      });
    }

    function updateMarker() {
      var now = Mess.clock ? Mess.clock.now() : new Date();
      var hours = now.getHours();
      var minutes = now.getMinutes();
      var totalNowMinutes = hours * 60 + minutes;

      if (currentTimeEl) {
        var hh = String(hours).padStart(2, '0');
        var mm = String(minutes).padStart(2, '0');
        currentTimeEl.textContent = `${hh}:${mm}`;
      }

      // Marker positioning
      if (totalNowMinutes < START_MINUTES) {
        markerEl.style.display = 'block';
        markerEl.style.left = '0%';
      } else if (totalNowMinutes > END_MINUTES) {
        markerEl.style.display = 'block';
        markerEl.style.left = '100%';
      } else {
        var pct = ((totalNowMinutes - START_MINUTES) / TOTAL_MINUTES) * 100;
        markerEl.style.display = 'block';
        markerEl.style.left = Math.min(100, Math.max(0, pct)) + '%';
      }

      // Determine active meal / next meal status
      if (statusBadge) {
        var activeMeal = null;
        var nextMeal = null;
        var meals = getMeals().filter(function(m) { return m.active !== false; });

        for (var i = 0; i < meals.length; i++) {
          var s = timeToMinutes(meals[i].start_time);
          var e = timeToMinutes(meals[i].end_time);
          if (totalNowMinutes >= s && totalNowMinutes < e) {
            activeMeal = meals[i];
            break;
          }
          if (totalNowMinutes < s && !nextMeal) {
            nextMeal = meals[i];
          }
        }

        if (activeMeal) {
          statusBadge.className = `timeline-status-badge badge badge--${(activeMeal.code || 'B').toLowerCase()}`;
          statusBadge.textContent = `Active: ${activeMeal.name} (until ${activeMeal.end_time})`;
        } else if (nextMeal) {
          var minsUntil = timeToMinutes(nextMeal.start_time) - totalNowMinutes;
          var h = Math.floor(minsUntil / 60);
          var m = minsUntil % 60;
          var inStr = h > 0 ? `${h}h ${m}m` : `${m}m`;
          statusBadge.className = 'timeline-status-badge badge badge--neutral';
          statusBadge.textContent = `Next: ${nextMeal.name} in ${inStr}`;
        } else {
          statusBadge.className = 'timeline-status-badge badge badge--neutral';
          statusBadge.textContent = 'Service Closed';
        }
      }
    }

    renderWindows();
    updateMarker();

    // Listen to clock ticks
    tickListener = function() {
      updateMarker();
    };
    window.addEventListener('clock:tick', tickListener);

    return {
      update: function() {
        renderWindows();
        updateMarker();
      },
      setMeals: function(newMeals) {
        customMeals = newMeals;
        renderWindows();
        updateMarker();
      },
      destroy: function() {
        if (tickListener) {
          window.removeEventListener('clock:tick', tickListener);
          tickListener = null;
        }
        containerEl.innerHTML = '';
      }
    };
  };
})(window.Mess);
