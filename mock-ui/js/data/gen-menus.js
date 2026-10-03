/* gen-menus.js - Deterministic daily menu generator with intentional gaps */

window.Mess = window.Mess || {};

(function(Mess) {
  Mess.generateMenus = function(cuisines, cuisineItems, items, baseDate) {
    var menus = [];
    var rng = Mess.createPRNG(20261002);
    var today = baseDate ? new Date(baseDate) : new Date();

    var activeCuisines = cuisines.filter(function(c) { return c.active; });

    // Helper to format date key YYYY-MM-DD
    function toISO(d) {
      return d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2);
    }

    var todayStr = toISO(today);

    var dPlus2 = new Date(today);
    dPlus2.setDate(dPlus2.getDate() + 2);
    var dPlus2Str = toISO(dPlus2);

    var dPlus3 = new Date(today);
    dPlus3.setDate(dPlus3.getDate() + 3);
    var dPlus3Str = toISO(dPlus3);

    var mealsList = ['B', 'L', 'D'];

    for (var dayOffset = -30; dayOffset <= 3; dayOffset++) {
      var d = new Date(today);
      d.setDate(d.getDate() + dayOffset);
      var dateStr = toISO(d);

      activeCuisines.forEach(function(c) {
        var mapped = cuisineItems.filter(function(ci) { return ci.cuisineId === c.id; }).map(function(ci) { return ci.itemId; });
        if (mapped.length === 0) return;

        mealsList.forEach(function(meal) {
          // Intentional Gap 1: Kerala (KR) Dinner today is empty
          if (c.id === 'KR' && meal === 'D' && dateStr === todayStr) {
            return;
          }

          // Intentional Gap 2: today + 3 days has only Breakfast
          if (dateStr === dPlus3Str && meal !== 'B') {
            return;
          }

          // Intentional Gap 3: today + 2 days has Filipino (FL) empty across all meals
          if (c.id === 'FL' && dateStr === dPlus2Str) {
            return;
          }

          // Select 3 to 5 items from mapped list deterministically
          var itemCount = 3 + Math.floor(rng() * 3);
          var selectedItems = [];
          
          for (var k = 0; k < itemCount; k++) {
            var itemIdx = Math.floor(rng() * mapped.length);
            var itemId = mapped[itemIdx];
            if (!selectedItems.some(function(it) { return it.itemId === itemId; })) {
              var itemObj = items.find(function(it) { return it.id === itemId; });
              selectedItems.push({
                itemId: itemId,
                qty: itemObj ? itemObj.defaultQty : 1
              });
            }
          }

          var savedBy = (dayOffset % 2 === 0) ? 'admin' : 'chef.ravi';
          var prevDay = new Date(d);
          prevDay.setDate(prevDay.getDate() - 1);
          var savedAt = toISO(prevDay) + ' 20:00:00';

          menus.push({
            id: dateStr + '_' + c.id + '_' + meal,
            date: dateStr,
            cuisineId: c.id,
            meal: meal,
            items: selectedItems,
            savedBy: savedBy,
            savedAt: savedAt
          });
        });
      });
    }

    return menus;
  };
})(window.Mess);
