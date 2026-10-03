/* gen-bills.js - Deterministic bill generator (~4,500 bills with peak-shaped times & token sequences) */

window.Mess = window.Mess || {};

(function(Mess) {
  Mess.generateBills = function(members, menus, mealTimes, baseDate) {
    var t0 = performance.now();
    var bills = [];
    var rng = Mess.createPRNG(20261002);
    var today = baseDate ? new Date(baseDate) : new Date();

    function toISO(d) {
      return d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2);
    }

    var todayStr = toISO(today);

    // Probability map per meal
    var probMap = { 'B': 0.70, 'L': 0.85, 'D': 0.75 };
    var windowMap = {
      'B': { startH: 6, endH: 10, peakOffsetM: 45 },
      'L': { startH: 12, endH: 15, peakOffsetM: 40 },
      'D': { startH: 19, endH: 22, peakOffsetM: 50 }
    };

    // Pre-build menu lookup: date_cuisineId_meal -> boolean
    var menuExistsMap = {};
    menus.forEach(function(m) {
      menuExistsMap[m.date + '_' + m.cuisineId + '_' + m.meal] = true;
    });

    var billIdCounter = 1000;

    for (var dayOffset = -30; dayOffset <= 0; dayOffset++) {
      var d = new Date(today);
      d.setDate(d.getDate() + dayOffset);
      var dateStr = toISO(d);

      ['B', 'L', 'D'].forEach(function(meal) {
        var dailyMealBills = [];
        var win = windowMap[meal];

        members.forEach(function(m) {
          if (!m.active) return;
          if (m.validFrom && dateStr < m.validFrom) return;
          if (m.validTo && dateStr > m.validTo) return;

          // Check if menu exists for member's cuisine on this date & meal
          if (!menuExistsMap[dateStr + '_' + m.cuisineId + '_' + meal]) return;

          // M-0007 scenario member: guaranteed to have served today's current meal
          var isCurrentMealToday = (dateStr === todayStr && meal === (Mess.clock ? Mess.clock.currentMeal() : 'L'));
          var prob = isCurrentMealToday && m.code === 'M-0007' ? 1.0 : probMap[meal];

          if (rng() < prob) {
            // Generate peak-skewed time inside window
            var baseMinutes = win.startH * 60;
            var offset = Math.floor(win.peakOffsetM + (rng() - 0.5) * 60);
            if (offset < 5) offset = 5;
            var totalMinutes = baseMinutes + offset;
            var h = Math.floor(totalMinutes / 60);
            var min = totalMinutes % 60;
            var sec = Math.floor(rng() * 60);

            var timeStr = ('0' + h).slice(-2) + ':' + ('0' + min).slice(-2) + ':' + ('0' + sec).slice(-2);

            var isCancelled = rng() < 0.01;
            var isOverride = !isCancelled && (rng() < 0.005);

            billIdCounter++;
            dailyMealBills.push({
              id: 'B' + billIdCounter,
              voucherNo: 'V-' + billIdCounter,
              date: dateStr,
              time: timeStr,
              timestamp: dateStr + 'T' + timeStr,
              memberId: m.id,
              memberName: m.name,
              memberCode: m.code,
              cuisineId: m.cuisineId,
              meal: meal,
              tokenPrefix: meal,
              totalAmount: 0.00,
              cancelled: isCancelled,
              cancelReason: isCancelled ? 'Entered wrong member card' : null,
              cancelledBy: isCancelled ? 'sup.ali' : null,
              override: isOverride,
              overrideReason: isOverride ? 'Card unreadable, identity verified' : null,
              overrideBy: isOverride ? 'sup.ali' : null
            });
          }
        });

        // Sort bills for the day/meal by time string
        dailyMealBills.sort(function(a, b) { return a.time.localeCompare(b.time); });

        // Assign sequential token numbers B-0001, L-0001, D-0001...
        dailyMealBills.forEach(function(b, idx) {
          b.tokenSeq = idx + 1;
          b.tokenNo = Mess.formatToken(meal, idx + 1);
          bills.push(b);
        });
      });
    }

    var t1 = performance.now();
    console.log('Generated ' + bills.length + ' bills in ' + Math.round(t1 - t0) + ' ms.');
    return bills;
  };
})(window.Mess);
