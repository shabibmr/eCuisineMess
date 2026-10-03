/* integrity.js - Data integrity validator & data bootstrapper */

window.Mess = window.Mess || {};

(function(Mess) {
  Mess.data = {
    build: function(customDate) {
      var baseDate = customDate ? new Date(customDate) : new Date();

      var items = Mess.seed.items ? Mess.seed.items.slice() : [];
      var cuisines = Mess.seed.cuisines ? Mess.seed.cuisines.slice() : [];
      var cuisineItems = Mess.seed.cuisineItems ? Mess.seed.cuisineItems.slice() : [];
      var customers = Mess.seed.customers ? Mess.seed.customers.slice() : [];
      var mealTimes = Mess.seed.mealTimes ? Mess.seed.mealTimes.slice() : [];

      var menus = Mess.generateMenus ? Mess.generateMenus(cuisines, cuisineItems, items, baseDate) : [];
      var bills = Mess.generateBills ? Mess.generateBills(customers, menus, mealTimes, baseDate) : [];

      var rawData = {
        items: items,
        cuisines: cuisines,
        cuisineItems: cuisineItems,
        customers: customers,
        mealTimes: mealTimes,
        menus: menus,
        bills: bills
      };

      // Apply compact change log from persistence
      if (Mess.persist && Mess.persist.apply) {
        rawData = Mess.persist.apply(rawData);
      }

      // Initialize store
      if (Mess.store && Mess.store.init) {
        Mess.store.init(rawData);
      }

      // Run integrity check
      Mess.data.checkIntegrity();
    },

    checkIntegrity: function() {
      var items = Mess.store.list('items');
      var cuisines = Mess.store.list('cuisines');
      var customers = Mess.store.list('customers');
      var menus = Mess.store.list('menus');
      var bills = Mess.store.list('bills');

      var results = [
        { Check: 'Items Total', Status: items.length === 48 ? 'PASS' : 'WARN', Detail: items.length + ' items (46 active)' },
        { Check: 'Cuisines Total', Status: cuisines.length === 7 ? 'PASS' : 'WARN', Detail: cuisines.length + ' cuisines (1 inactive/unmapped)' },
        { Check: 'Members Total', Status: customers.length === 64 ? 'PASS' : 'WARN', Detail: customers.length + ' members' },
        { Check: 'Menus Generated', Status: menus.length > 0 ? 'PASS' : 'FAIL', Detail: menus.length + ' menu records' },
        { Check: 'Bills Generated', Status: bills.length > 0 ? 'PASS' : 'FAIL', Detail: bills.length + ' bills' }
      ];

      // Unique token check
      var tokenKeySet = {};
      var dupTokens = 0;
      bills.forEach(function(b) {
        var key = b.date + '_' + b.meal + '_' + b.tokenNo;
        if (tokenKeySet[key]) dupTokens++;
        else tokenKeySet[key] = true;
      });
      results.push({
        Check: 'Token Uniqueness',
        Status: dupTokens === 0 ? 'PASS' : 'FAIL',
        Detail: dupTokens === 0 ? 'All tokens unique per date/meal' : dupTokens + ' duplicate tokens'
      });

      // Member reference validity
      var invalidMemberRefs = 0;
      var memberIdMap = {};
      customers.forEach(function(c) { memberIdMap[c.id] = true; });
      bills.forEach(function(b) {
        if (!memberIdMap[b.memberId]) invalidMemberRefs++;
      });
      results.push({
        Check: 'Member Reference Integrity',
        Status: invalidMemberRefs === 0 ? 'PASS' : 'FAIL',
        Detail: invalidMemberRefs === 0 ? 'All bill members exist' : invalidMemberRefs + ' missing member refs'
      });

      console.table(results);
      return results;
    }
  };
})(window.Mess);
