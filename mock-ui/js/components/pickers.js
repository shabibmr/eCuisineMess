/* pickers.js - Presets for Item, Cuisine, and Customer Pickers with F2 dialogs & RFID tap selection */

window.Mess = window.Mess || {};

(function(Mess) {
  Mess.pickers = {
    createItemPicker: function(containerEl, options) {
      var opt = options || {};
      var currentCuisineId = opt.cuisineId || null;

      function getItems() {
        var allItems = Mess.store ? Mess.store.list('items') : [];
        if (!currentCuisineId) return allItems;

        var mapped = (Mess.store.list('cuisineItems') || []).filter(function(ci) {
          return ci.cuisineId === currentCuisineId;
        }).map(function(ci) { return ci.itemId; });

        return allItems.filter(function(it) {
          return mapped.indexOf(it.id) !== -1;
        });
      }

      function openF2Dialog(pickerInstance) {
        var items = getItems();
        var content = document.createElement('div');
        content.style.height = '420px';

        Mess.dialog.sheet('Select Item (F2)', '<div id="f2-item-grid" style="height: 380px;"></div>', function(sheetEl, closeSheet) {
          var grid = Mess.createDataGrid(sheetEl.querySelector('#f2-item-grid'), {
            data: items,
            columns: [
              { title: 'Code', field: 'code', width: 90 },
              { title: 'Item Name', field: 'name' },
              { title: 'Category', field: 'category' },
              { title: 'Unit', field: 'unit', width: 80 }
            ],
            onRowOpen: function(row) {
              pickerInstance.setCurrentId(row.id);
              closeSheet();
            }
          });
        });
      }

      var picker = Mess.createSearchPicker(containerEl, {
        placeholder: opt.placeholder || 'Select item...',
        keys: ['code', 'name', 'category'],
        data: getItems(),
        hasNewAction: opt.allowNew !== false,
        formatRow: function(item) {
          return '<span><strong>' + item.code + '</strong> – ' + item.name + ' (' + item.unit + ')</span>';
        },
        formatDisplay: function(item) {
          return item.code + ' – ' + item.name + ' (' + item.unit + ')';
        },
        onF2: function() {
          openF2Dialog(picker);
        },
        onNew: function() {
          // Open Item Editor in sheet
          if (Mess.screens && Mess.screens.get('item-editor')) {
            var scr = Mess.screens.get('item-editor');
            Mess.dialog.sheet('New Item', scr.template('new'), function(sheetEl, closeSheet) {
              scr.component().init(sheetEl, 'new', function(newRecord) {
                picker.setData(getItems());
                picker.setCurrentId(newRecord.id);
                closeSheet();
              });
            });
          }
        },
        onSelect: opt.onSelect
      });

      picker.setCuisine = function(cuisineId) {
        currentCuisineId = cuisineId;
        picker.setData(getItems());
      };

      return picker;
    },

    createCuisinePicker: function(containerEl, options) {
      var opt = options || {};

      function getCuisines() {
        var all = Mess.store ? Mess.store.list('cuisines') : [];
        if (opt.activeOnly !== false) {
          return all.filter(function(c) { return c.active; });
        }
        return all;
      }

      var picker = Mess.createSearchPicker(containerEl, {
        placeholder: opt.placeholder || 'Select cuisine...',
        keys: ['code', 'name'],
        data: getCuisines(),
        formatRow: function(c) {
          return '<span><strong>' + c.code + '</strong> – ' + c.name + '</span>';
        },
        formatDisplay: function(c) {
          return c.code + ' – ' + c.name;
        },
        onSelect: opt.onSelect
      });

      return picker;
    },

    createCustomerPicker: function(containerEl, options) {
      var opt = options || {};

      function getCustomers() {
        var all = Mess.store ? Mess.store.list('customers') : [];
        if (opt.activeOnly !== false) {
          return all.filter(function(c) { return c.active; });
        }
        return all;
      }

      var picker = Mess.createSearchPicker(containerEl, {
        placeholder: opt.placeholder || 'Search member code, name, phone or tap RFID...',
        keys: ['code', 'name', 'phone', 'rfid'],
        data: getCustomers(),
        formatRow: function(m) {
          return '<div class="flex-row gap-sm align-center">' +
                 '<img src="' + m.photo + '" class="avatar" style="width:28px;height:28px;">' +
                 '<span><strong>' + m.code + '</strong> – ' + m.name + ' (' + m.cuisineId + ') · ' + m.validTo + '</span>' +
                 '</div>';
        },
        formatDisplay: function(m) {
          return m.code + ' – ' + m.name + ' (' + m.cuisineId + ')';
        },
        onSelect: opt.onSelect
      });

      // RFID tap auto-select listener
      var rfidHandler = function(e) {
        if (!e.detail || !e.detail.rfid) return;
        var rfid = e.detail.rfid;
        var member = getCustomers().find(function(c) { return c.rfid === rfid; });
        if (member) {
          picker.setCurrentId(member.id);
        }
      };

      window.addEventListener('rfid:read', rfidHandler);

      return picker;
    }
  };
})(window.Mess);
