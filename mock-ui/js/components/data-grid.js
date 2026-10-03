/* data-grid.js - High-performance Tabulator wrapper with keyboard nav, virtual DOM & exports */

window.Mess = window.Mess || {};

(function(Mess) {
  Mess.createDataGrid = function(containerSelector, options) {
    if (!window.Tabulator) {
      console.error('Tabulator is not loaded.');
      return null;
    }

    var el = typeof containerSelector === 'string' ? document.querySelector(containerSelector) : containerSelector;
    if (!el) {
      console.warn('Grid container not found:', containerSelector);
      return null;
    }

    var opt = options || {};
    var onRowOpen = opt.onRowOpen || null;
    var fileName = opt.downloadFileName || 'export';

    var defaultTabulatorConfig = {
      data: opt.data || [],
      columns: opt.columns || [],
      layout: opt.layout || 'fitColumns',
      height: opt.height || '100%',
      renderVertical: 'virtual',
      renderHorizontal: 'virtual',
      pagination: opt.pagination !== false,
      paginationSize: opt.paginationSize || 50,
      paginationSizeSelector: [25, 50, 100, 200],
      selectableRows: 1,
      groupBy: opt.groupBy || false,
      groupHeader: opt.groupHeader || null,
      rowFormatter: opt.rowFormatter || null,
      placeholder: opt.placeholder || 'No records found'
    };

    var table = new Tabulator(el, defaultTabulatorConfig);

    // Enter & Double-click row opening
    table.on('rowDblClick', function(e, row) {
      var data = row.getData();
      if (typeof onRowOpen === 'function') onRowOpen(data);
      window.dispatchEvent(new CustomEvent('grid:row-open', { detail: { data: data } }));
    });

    el.addEventListener('keydown', function(e) {
      if (e.key === 'Enter') {
        var selected = table.getSelectedRows();
        if (selected && selected.length > 0) {
          var data = selected[0].getData();
          if (typeof onRowOpen === 'function') onRowOpen(data);
          window.dispatchEvent(new CustomEvent('grid:row-open', { detail: { data: data } }));
        }
      }
    });

    // Theme change listener
    var onThemeChange = function() {
      if (table) {
        try { table.redraw(true); } catch (e) {}
      }
    };
    window.addEventListener('themechange', onThemeChange);

    return {
      table: table,

      setData: function(newData) {
        return table.setData(newData);
      },

      getData: function() {
        return table.getData();
      },

      setFilter: function(field, type, value) {
        table.setFilter(field, type, value);
      },

      clearFilter: function() {
        table.clearFilter();
      },

      downloadCSV: function(customName) {
        // Enforce user rule: Always use '|' as a separator when creating CSV files
        table.download('csv', (customName || fileName) + '.csv', {
          delimiter: '|'
        });
      },

      downloadXLSX: function(customName) {
        table.download('xlsx', (customName || fileName) + '.xlsx', {
          sheetName: 'Sheet1'
        });
      },

      downloadPDF: function(customName) {
        table.download('pdf', (customName || fileName) + '.pdf', {
          orientation: 'landscape',
          title: opt.title || 'Report'
        });
      },

      print: function() {
        table.print(false, true);
      },

      destroy: function() {
        window.removeEventListener('themechange', onThemeChange);
        if (table) {
          table.destroy();
          table = null;
        }
      }
    };
  };
})(window.Mess);
