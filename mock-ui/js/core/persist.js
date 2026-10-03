/* persist.js - Change-log persistence per collection & Reset functionality */

window.Mess = window.Mess || {};

(function(Mess) {
  var STORAGE_KEY = 'mess-mock:v1';

  var changeLog = {
    upserts: {},
    deletes: {}
  };

  function loadLog() {
    try {
      var raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        var parsed = JSON.parse(raw);
        changeLog.upserts = parsed.upserts || {};
        changeLog.deletes = parsed.deletes || {};
      }
    } catch (e) {
      console.warn('Failed to load change-log from localStorage:', e);
    }
  }

  function saveLog() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(changeLog));
    } catch (e) {
      console.warn('Failed to save change-log to localStorage:', e);
    }
  }

  Mess.persist = {
    init: function() {
      loadLog();

      window.addEventListener('store:change', function(e) {
        if (!e.detail) return;
        var kind = e.detail.kind;
        var action = e.detail.action;
        var record = e.detail.record;

        if (!kind || !record) return;

        changeLog.upserts[kind] = changeLog.upserts[kind] || [];
        changeLog.deletes[kind] = changeLog.deletes[kind] || [];

        if (action === 'save') {
          // Remove from deletes if previously marked deleted
          changeLog.deletes[kind] = changeLog.deletes[kind].filter(function(id) { return id !== record.id; });
          
          // Upsert record
          var idx = changeLog.upserts[kind].findIndex(function(r) { return r.id === record.id; });
          if (idx !== -1) {
            changeLog.upserts[kind][idx] = record;
          } else {
            changeLog.upserts[kind].push(record);
          }
        } else if (action === 'remove') {
          // Remove from upserts if previously upserted
          changeLog.upserts[kind] = changeLog.upserts[kind].filter(function(r) { return r.id !== record.id; });
          
          // Add to deletes if not already there
          if (changeLog.deletes[kind].indexOf(record.id) === -1) {
            changeLog.deletes[kind].push(record.id);
          }
        }

        saveLog();
      });
    },

    apply: function(seedData) {
      loadLog();
      if (!seedData) return seedData;

      Object.keys(changeLog.deletes).forEach(function(kind) {
        if (seedData[kind] && Array.isArray(seedData[kind])) {
          var delIds = changeLog.deletes[kind];
          seedData[kind] = seedData[kind].filter(function(item) {
            return delIds.indexOf(item.id) === -1;
          });
        }
      });

      Object.keys(changeLog.upserts).forEach(function(kind) {
        if (!seedData[kind]) seedData[kind] = [];
        var upserts = changeLog.upserts[kind];
        upserts.forEach(function(rec) {
          var idx = seedData[kind].findIndex(function(item) { return item.id === rec.id; });
          if (idx !== -1) {
            seedData[kind][idx] = rec;
          } else {
            seedData[kind].push(rec);
          }
        });
      });

      return seedData;
    },

    reset: function() {
      try {
        localStorage.removeItem(STORAGE_KEY);
      } catch (e) {}
      window.location.reload();
    }
  };

  Mess.persist.init();

})(window.Mess);
