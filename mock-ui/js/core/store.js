/* store.js - Core Data Store with referential checks, CRUD, and delete blocking */

window.Mess = window.Mess || {};

(function(Mess) {
  var collections = {
    items: [],
    cuisines: [],
    cuisineItems: [],
    customers: [],
    mealTimes: [],
    menus: [],
    bills: []
  };

  function resolveKind(kind) {
    if (kind === 'cuisine_items' || kind === 'cuisineItems') return 'cuisineItems';
    if (kind === 'meal_times' || kind === 'mealTimes') return 'mealTimes';
    return kind;
  }

  Mess.store = {
    init: function(seedData) {
      if (seedData) {
        collections.items = seedData.items || [];
        collections.cuisines = seedData.cuisines || [];
        collections.cuisineItems = seedData.cuisineItems || seedData.cuisine_items || [];
        collections.customers = seedData.customers || [];
        collections.mealTimes = seedData.mealTimes || seedData.meal_times || [];
        collections.menus = seedData.menus || [];
        collections.bills = seedData.bills || [];
      }
    },

    getRaw: function(kind) {
      return collections[resolveKind(kind)] || [];
    },

    list: function(kind, filterFn) {
      var arr = collections[resolveKind(kind)] || [];
      if (typeof filterFn === 'function') {
        return arr.filter(filterFn);
      }
      return arr.slice();
    },

    get: function(kind, id) {
      var arr = collections[resolveKind(kind)] || [];
      for (var i = 0; i < arr.length; i++) {
        if (arr[i].id === id || arr[i].code === id) {
          return arr[i];
        }
      }
      return null;
    },

    save: function(kind, record) {
      var k = resolveKind(kind);
      if (!collections[k]) collections[k] = [];
      var arr = collections[k];

      // Uniqueness check for code field
      if (record.code) {
        for (var j = 0; j < arr.length; j++) {
          if (arr[j].code === record.code && arr[j].id !== record.id) {
            return { success: false, error: 'Code ' + record.code + ' is already used.' };
          }
        }
      }

      var existingIdx = -1;
      for (var i = 0; i < arr.length; i++) {
        if (arr[i].id === record.id) {
          existingIdx = i;
          break;
        }
      }

      if (existingIdx !== -1) {
        arr[existingIdx] = record;
      } else {
        arr.push(record);
      }

      window.dispatchEvent(new CustomEvent('store:change', { detail: { kind: k, action: 'save', record: record } }));
      return { success: true, record: record };
    },

    refsOf: function(kind, id) {
      var refs = {};
      var total = 0;

      if (kind === 'items') {
        var ciCount = (collections.cuisineItems || []).filter(function(ci) { 
          return ci.itemId === id || ci.item_id === id; 
        }).length;
        if (ciCount > 0) { refs.cuisines = ciCount; total += ciCount; }

        var billCount = 0;
        (collections.bills || []).forEach(function(b) {
          if (b.items && Array.isArray(b.items)) {
            if (b.items.some(function(it) { return it.itemId === id || it.item_id === id; })) billCount++;
          }
        });
        if (billCount > 0) { refs.bills = billCount; total += billCount; }
      }

      if (kind === 'cuisines') {
        var memberCount = (collections.customers || []).filter(function(c) { 
          return c.cuisineId === id || c.cuisine_id === id; 
        }).length;
        if (memberCount > 0) { refs.members = memberCount; total += memberCount; }

        var menuCount = (collections.menus || []).filter(function(m) { 
          return m.cuisineId === id || m.cuisine_id === id; 
        }).length;
        if (menuCount > 0) { refs.menus = menuCount; total += menuCount; }
      }

      if (kind === 'customers') {
        var custBillCount = (collections.bills || []).filter(function(b) { 
          return b.memberId === id || b.customer_id === id; 
        }).length;
        if (custBillCount > 0) { refs.bills = custBillCount; total += custBillCount; }
      }

      return { refCounts: refs, total: total };
    },

    remove: function(kind, id) {
      var check = Mess.store.refsOf(kind, id);
      if (check.total > 0) {
        return {
          success: false,
          blocked: true,
          refCounts: check.refCounts,
          total: check.total,
          message: 'Record cannot be deleted because it is referenced in other records.'
        };
      }

      var arr = collections[kind] || [];
      var idx = arr.findIndex(function(item) { return item.id === id; });
      if (idx !== -1) {
        var removed = arr.splice(idx, 1)[0];
        window.dispatchEvent(new CustomEvent('store:change', { detail: { kind: kind, action: 'remove', record: removed } }));
        return { success: true, record: removed };
      }
      return { success: false, error: 'Record not found.' };
    },

    markInactive: function(kind, id) {
      var record = Mess.store.get(kind, id);
      if (record) {
        record.active = false;
        Mess.store.save(kind, record);
        return { success: true, record: record };
      }
      return { success: false, error: 'Record not found.' };
    }
  };

  // Register Alpine store if Alpine is available
  if (window.Alpine) {
    window.Alpine.store('data', Mess.store);
  } else {
    document.addEventListener('alpine:init', function() {
      window.Alpine.store('data', Mess.store);
    });
  }

})(window.Mess);
