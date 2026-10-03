/* clock.js - Time service, demo clock override, meal detection & data-meal sync */

window.Mess = window.Mess || {};

(function(Mess) {
  var overrideDate = null;
  var currentMealCode = 'none';

  // Default meal times (can be updated by store/settings)
  var mealTimes = [
    { code: 'B', name: 'Breakfast', from: '06:00', to: '10:00', active: true },
    { code: 'L', name: 'Lunch',     from: '12:00', to: '15:00', active: true },
    { code: 'D', name: 'Dinner',    from: '19:00', to: '22:30', active: true }
  ];

  function parseHHMM(str) {
    var parts = (str || '00:00').split(':');
    return parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
  }

  function getNowDate() {
    return overrideDate ? new Date(overrideDate) : new Date();
  }

  function calculateMeal(d) {
    var nowMinutes = d.getHours() * 60 + d.getMinutes();
    
    for (var i = 0; i < mealTimes.length; i++) {
      var mt = mealTimes[i];
      if (!mt.active) continue;
      var fromM = parseHHMM(mt.from);
      var toM = parseHHMM(mt.to);
      if (nowMinutes >= fromM && nowMinutes < toM) {
        return mt.code;
      }
    }
    return 'none';
  }

  function getNextMeal(d) {
    var nowMinutes = d.getHours() * 60 + d.getMinutes();
    
    for (var i = 0; i < mealTimes.length; i++) {
      var mt = mealTimes[i];
      if (!mt.active) continue;
      var fromM = parseHHMM(mt.from);
      if (nowMinutes < fromM) {
        return mt;
      }
    }
    // If past dinner, next is tomorrow's Breakfast
    return mealTimes[0];
  }

  function updateClockState() {
    var now = getNowDate();
    var meal = calculateMeal(now);

    if (meal !== currentMealCode) {
      currentMealCode = meal;
      if (Mess.theme && Mess.theme.setMeal) {
        Mess.theme.setMeal(meal);
      }
      window.dispatchEvent(new CustomEvent('mealchange', {
        detail: { meal: meal, now: now }
      }));
    }

    window.dispatchEvent(new CustomEvent('clock:tick', {
      detail: { now: now, meal: meal }
    }));
  }

  Mess.clock = {
    now: getNowDate,

    setOverride: function(dateOrTimeStr) {
      if (!dateOrTimeStr) {
        overrideDate = null;
      } else if (typeof dateOrTimeStr === 'string' && dateOrTimeStr.indexOf(':') !== -1 && dateOrTimeStr.length <= 5) {
        // HH:mm string override for today
        var d = new Date();
        var parts = dateOrTimeStr.split(':');
        d.setHours(parseInt(parts[0], 10), parseInt(parts[1], 10), 0, 0);
        overrideDate = d;
      } else {
        overrideDate = new Date(dateOrTimeStr);
      }
      updateClockState();
    },

    clearOverride: function() {
      overrideDate = null;
      updateClockState();
    },

    isOverridden: function() {
      return overrideDate !== null;
    },

    setMealTimes: function(newMealTimes) {
      if (Array.isArray(newMealTimes)) {
        mealTimes = newMealTimes;
        updateClockState();
      }
    },

    getMealTimes: function() {
      return mealTimes;
    },

    currentMeal: function() {
      return calculateMeal(getNowDate());
    },

    nextMeal: function() {
      return getNextMeal(getNowDate());
    }
  };

  // Start 1-second interval
  setInterval(updateClockState, 1000);
  
  // Run initial state update
  setTimeout(updateClockState, 50);

})(window.Mess);
