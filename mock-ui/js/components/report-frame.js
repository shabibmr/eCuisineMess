/* report-frame.js - Configurable Report Screen Frame with Drill-down Drawer */

window.Mess = window.Mess || {};

(function(Mess) {
  Mess.createReportFrame = function(config) {
    var title = config.title || 'Report';
    var subtitle = config.subtitle || '';
    var views = config.views || []; // e.g. [{ id: 'summary', label: 'Summary' }, { id: 'detail', label: 'Detail' }]
    var currentViewId = views.length > 0 ? views[0].id : null;
    var extraFiltersHtml = config.extraFiltersHtml || '';
    var onGenerate = config.onGenerate || function() { return []; };
    var columns = config.columns || []; // Or function(viewId, filterValues)
    var gridOptions = config.gridOptions || {};
    var onRowDblClick = config.onRowDblClick || null; // function(e, row, drawer)

    var grid = null;
    var drawerStack = []; // [{ title, render, data }]
    var drawerEl = null;
    var backdropEl = null;
    var rootElement = null;

    function getTodayIso() {
      if (Mess.clock && Mess.clock.now) {
        var d = Mess.clock.now();
        var yyyy = d.getFullYear();
        var mm = String(d.getMonth() + 1).padStart(2, '0');
        var dd = String(d.getDate()).padStart(2, '0');
        return yyyy + '-' + mm + '-' + dd;
      }
      var now = new Date();
      return now.toISOString().slice(0, 10);
    }

    function readFilters(rootEl) {
      var fromDate = rootEl.querySelector('.filter-from-date') ? rootEl.querySelector('.filter-from-date').value : getTodayIso();
      var toDate = rootEl.querySelector('.filter-to-date') ? rootEl.querySelector('.filter-to-date').value : getTodayIso();
      var cuisineId = rootEl.querySelector('.filter-cuisine') ? rootEl.querySelector('.filter-cuisine').value : 'all';
      
      var mealSegment = rootEl.querySelector('.filter-meal.active');
      var mealType = mealSegment ? mealSegment.getAttribute('data-meal') : 'all';

      var values = {
        fromDate: fromDate,
        toDate: toDate,
        cuisineId: cuisineId,
        mealType: mealType,
        viewId: currentViewId
      };

      if (typeof config.readExtraFilters === 'function') {
        Object.assign(values, config.readExtraFilters(rootEl));
      }

      return values;
    }

    function initDrawer(rootEl) {
      if (rootEl.querySelector('.report-drawer-container')) return;

      var drawerHtml = `
        <div class="report-drawer-backdrop" style="display:none; position:fixed; inset:0; background:rgba(0,0,0,0.35); z-index:calc(var(--z-drawer) - 1);"></div>
        <div class="side-sheet report-drill-drawer" style="width: 580px; max-width: 90vw; z-index:var(--z-drawer);">
          <div class="sheet-header flex-row justify-between align-center">
            <div class="flex-col gap-xs">
              <nav class="drawer-breadcrumb flex-row align-center gap-xs text-xs color-ink-2" aria-label="Drilldown breadcrumbs"></nav>
              <h3 class="drawer-title" style="margin:0; font-size:16px;">Details</h3>
            </div>
            <div class="flex-row gap-xs align-center">
              <button type="button" class="btn btn--quiet drawer-back-btn" style="display:none;" title="Back">
                <i data-lucide="arrow-left"></i>
              </button>
              <button type="button" class="btn btn--quiet drawer-close-btn" title="Close drawer">
                <i data-lucide="x"></i>
              </button>
            </div>
          </div>
          <div class="sheet-body drawer-content flex-col gap-md" style="flex:1; overflow-y:auto; padding:16px;"></div>
          <div class="sheet-footer drawer-footer flex-row justify-between align-center">
            <span class="drawer-footer-count text-xs color-ink-2"></span>
            <button type="button" class="btn btn--secondary drawer-done-btn">Close</button>
          </div>
        </div>
      `;

      var container = document.createElement('div');
      container.className = 'report-drawer-container';
      container.innerHTML = drawerHtml;
      rootEl.appendChild(container);

      drawerEl = container.querySelector('.report-drill-drawer');
      backdropEl = container.querySelector('.report-drawer-backdrop');

      var closeBtn = container.querySelector('.drawer-close-btn');
      var doneBtn = container.querySelector('.drawer-done-btn');
      var backBtn = container.querySelector('.drawer-back-btn');

      function closeDrawer() {
        drawerStack = [];
        drawerEl.classList.remove('open');
        backdropEl.style.display = 'none';
      }

      closeBtn.addEventListener('click', closeDrawer);
      doneBtn.addEventListener('click', closeDrawer);
      backdropEl.addEventListener('click', closeDrawer);

      backBtn.addEventListener('click', function() {
        if (drawerStack.length > 1) {
          drawerStack.pop();
          renderTopDrawer();
        } else {
          closeDrawer();
        }
      });
    }

    function renderTopDrawer() {
      if (!drawerEl || drawerStack.length === 0) return;
      var current = drawerStack[drawerStack.length - 1];

      var breadcrumbEl = drawerEl.querySelector('.drawer-breadcrumb');
      var titleEl = drawerEl.querySelector('.drawer-title');
      var backBtn = drawerEl.querySelector('.drawer-back-btn');
      var contentEl = drawerEl.querySelector('.drawer-content');
      var footerCountEl = drawerEl.querySelector('.drawer-footer-count');

      // Update breadcrumbs
      var crumbs = ['Report'];
      for (var i = 0; i < drawerStack.length; i++) {
        crumbs.push(drawerStack[i].breadcrumbTitle || drawerStack[i].title);
      }
      breadcrumbEl.innerHTML = crumbs.map(function(c, idx) {
        if (idx === crumbs.length - 1) {
          return `<span class="color-ink font-semibold">${c}</span>`;
        }
        return `<span>${c}</span> <span class="color-ink-3">/</span>`;
      }).join(' ');

      titleEl.textContent = current.title;
      backBtn.style.display = drawerStack.length > 1 ? 'inline-flex' : 'none';
      contentEl.innerHTML = '';
      footerCountEl.textContent = current.countText || '';

      if (typeof current.render === 'function') {
        current.render(contentEl, drawerApi);
      }

      if (window.lucide && window.lucide.createIcons) {
        window.lucide.createIcons({ root: drawerEl });
      }
    }

    var drawerApi = {
      push: function(drawerLevelConfig) {
        // Limit to 2 levels maximum as required by spec
        if (drawerStack.length >= 2) {
          drawerStack.pop();
        }
        drawerStack.push(drawerLevelConfig);
        drawerEl.classList.add('open');
        backdropEl.style.display = 'block';
        renderTopDrawer();
      },
      pop: function() {
        if (drawerStack.length > 1) {
          drawerStack.pop();
          renderTopDrawer();
        } else {
          this.close();
        }
      },
      close: function() {
        drawerStack = [];
        if (drawerEl) drawerEl.classList.remove('open');
        if (backdropEl) backdropEl.style.display = 'none';
      },
      isOpen: function() {
        return drawerEl && drawerEl.classList.contains('open');
      }
    };

    return {
      template: function() {
        var today = getTodayIso();
        var cuisines = (Mess.store && Mess.store.list('cuisines')) || [];

        var viewSwitcherHtml = '';
        if (views.length > 1) {
          viewSwitcherHtml = `
            <div class="segmented-control report-view-switcher" role="radiogroup" aria-label="Report view selection">
              ${views.map(function(v) {
                var activeClass = v.id === currentViewId ? 'active' : '';
                var ariaChecked = v.id === currentViewId ? 'true' : 'false';
                var iconHtml = v.icon ? `<i data-lucide="${v.icon}"></i> ` : '';
                return `<button type="button" class="${activeClass}" data-view="${v.id}" role="radio" aria-checked="${ariaChecked}">${iconHtml}${v.label}</button>`;
              }).join('')}
            </div>
          `;
        }

        return /* html */ `
          <div class="report-frame flex-col gap-md" style="height: 100%; position: relative;">
            <!-- Header -->
            <div class="toolbar flex-row justify-between align-center">
              <div class="toolbar-left flex-col gap-xs">
                <h2 style="margin: 0;">${title}</h2>
                ${subtitle ? `<span class="text-sm color-ink-2">${subtitle}</span>` : ''}
              </div>
              <div class="toolbar-right flex-row gap-sm align-center">
                ${viewSwitcherHtml}
                <button type="button" class="btn btn--secondary report-print-btn">
                  <i data-lucide="printer"></i> Print
                </button>
                <div class="dropdown-export-wrapper" style="position: relative;">
                  <button type="button" class="btn btn--secondary report-export-btn">
                    <i data-lucide="download"></i> Export ▾
                  </button>
                  <div class="dropdown-menu export-dropdown-menu" style="display:none; position:absolute; right:0; top:calc(100% + 4px); background:var(--surface-strong); border:1px solid var(--separator); border-radius:var(--radius-menu); box-shadow:var(--elev-pop); min-width:140px; z-index:100; padding:4px 0;">
                    <button type="button" class="menu-item export-xlsx" style="width:100%; text-align:left; padding:8px 12px; background:none; border:none; cursor:pointer; color:var(--ink); font-size:13px; display:flex; align-items:center; gap:8px;">
                      <i data-lucide="file-spreadsheet"></i> Excel (.xlsx)
                    </button>
                    <button type="button" class="menu-item export-pdf" style="width:100%; text-align:left; padding:8px 12px; background:none; border:none; cursor:pointer; color:var(--ink); font-size:13px; display:flex; align-items:center; gap:8px;">
                      <i data-lucide="file-text"></i> PDF document
                    </button>
                    <button type="button" class="menu-item export-csv" style="width:100%; text-align:left; padding:8px 12px; background:none; border:none; cursor:pointer; color:var(--ink); font-size:13px; display:flex; align-items:center; gap:8px;">
                      <i data-lucide="file-code"></i> CSV (| delimited)
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <!-- Filter Bar -->
            <div class="toolbar-filters card-inset flex-row gap-md wrap align-center" style="padding: 12px 16px; border-radius: var(--radius-panel); background: var(--surface);">
              <div class="flex-row gap-xs align-center">
                <label class="text-xs font-semibold color-ink-2">From</label>
                <input type="date" class="field-input filter-from-date" value="${today}" style="width: 140px;">
              </div>

              <div class="flex-row gap-xs align-center">
                <label class="text-xs font-semibold color-ink-2">To</label>
                <input type="date" class="field-input filter-to-date" value="${today}" style="width: 140px;">
              </div>

              <div class="flex-row gap-xs align-center">
                <label class="text-xs font-semibold color-ink-2">Cuisine</label>
                <select class="field-select filter-cuisine" style="min-width: 130px;">
                  <option value="all">All Cuisines</option>
                  ${cuisines.map(function(c) {
                    return `<option value="${c.id}">${c.name}</option>`;
                  }).join('')}
                </select>
              </div>

              <div class="flex-row gap-xs align-center">
                <label class="text-xs font-semibold color-ink-2">Meal</label>
                <div class="segmented-control meal-segmented" role="radiogroup" aria-label="Meal type filter">
                  <button type="button" class="filter-meal active" data-meal="all" role="radio" aria-checked="true">All</button>
                  <button type="button" class="filter-meal" data-meal="B" role="radio" aria-checked="false">B</button>
                  <button type="button" class="filter-meal" data-meal="L" role="radio" aria-checked="false">L</button>
                  <button type="button" class="filter-meal" data-meal="D" role="radio" aria-checked="false">D</button>
                </div>
              </div>

              ${extraFiltersHtml}

              <div style="margin-left: auto;">
                <button type="button" class="btn btn--primary report-generate-btn">
                  <i data-lucide="play"></i> Generate
                </button>
              </div>
            </div>

            <!-- Report Results View -->
            <div class="report-content-well flex-col table-well" style="flex: 1; min-height: 380px; position: relative; border-radius: var(--radius-panel); background: var(--surface); border: 1px solid var(--separator); overflow: hidden;">
              <!-- Initial ungenerated empty state -->
              <div class="report-empty-state empty-state flex-col align-center justify-center gap-sm" style="height: 100%; min-height: 320px; padding: 40px; text-align: center;">
                <div class="empty-state-icon" style="color: var(--ink-3);">
                  <i data-lucide="filter" style="width: 48px; height: 48px;"></i>
                </div>
                <h3 style="margin: 0; font-size: 16px;">Report Ready to Generate</h3>
                <p class="text-sm color-ink-2" style="max-width: 420px; margin: 0;">
                  Set your desired date range and filters above, then click <strong>Generate</strong> to calculate report metrics.
                </p>
                <button type="button" class="btn btn--primary btn--sm report-generate-trigger">
                  <i data-lucide="play"></i> Run Report
                </button>
              </div>

              <!-- Grid / Custom container -->
              <div class="report-result-container" style="display:none; height: 100%; width: 100%;"></div>
            </div>

            <!-- Footer Stats / Status -->
            <div class="report-footer flex-row justify-between align-center text-sm color-ink-2 pt-xs">
              <span class="report-summary-text">Click Generate to run report</span>
              <span class="report-timestamp text-xs color-ink-3"></span>
            </div>
          </div>
        `;
      },

      init: function(rootEl) {
        rootElement = rootEl;
        initDrawer(rootEl);

        var generateBtn = rootEl.querySelector('.report-generate-btn');
        var generateTrigger = rootEl.querySelector('.report-generate-trigger');
        var printBtn = rootEl.querySelector('.report-print-btn');
        var exportBtn = rootEl.querySelector('.report-export-btn');
        var exportMenu = rootEl.querySelector('.export-dropdown-menu');
        var emptyState = rootEl.querySelector('.report-empty-state');
        var resultContainer = rootEl.querySelector('.report-result-container');
        var summaryText = rootEl.querySelector('.report-summary-text');
        var timestampEl = rootEl.querySelector('.report-timestamp');

        // Meal segmented buttons
        var mealButtons = rootEl.querySelectorAll('.filter-meal');
        mealButtons.forEach(function(btn) {
          btn.addEventListener('click', function() {
            mealButtons.forEach(function(b) {
              b.classList.remove('active');
              b.setAttribute('aria-checked', 'false');
            });
            btn.classList.add('active');
            btn.setAttribute('aria-checked', 'true');
          });
        });

        // View switcher
        var viewButtons = rootEl.querySelectorAll('.report-view-switcher button');
        viewButtons.forEach(function(btn) {
          btn.addEventListener('click', function() {
            var vId = btn.getAttribute('data-view');
            if (vId === currentViewId) return;
            currentViewId = vId;
            viewButtons.forEach(function(b) {
              b.classList.remove('active');
              b.setAttribute('aria-checked', 'false');
            });
            btn.classList.add('active');
            btn.setAttribute('aria-checked', 'true');

            if (typeof config.onViewChange === 'function') {
              config.onViewChange(currentViewId, readFilters(rootEl));
            }
            // If already generated, re-run with new view
            if (emptyState.style.display === 'none') {
              runGenerate();
            }
          });
        });

        // Export dropdown menu
        exportBtn.addEventListener('click', function(e) {
          e.stopPropagation();
          var isShown = exportMenu.style.display === 'block';
          exportMenu.style.display = isShown ? 'none' : 'block';
        });

        document.addEventListener('click', function(e) {
          if (exportMenu && !exportMenu.contains(e.target) && e.target !== exportBtn) {
            exportMenu.style.display = 'none';
          }
        });

        var exportXlsx = rootEl.querySelector('.export-xlsx');
        var exportPdf = rootEl.querySelector('.export-pdf');
        var exportCsv = rootEl.querySelector('.export-csv');

        function getExportFilename(ext) {
          var cleanTitle = title.toLowerCase().replace(/[^a-z0-9]+/g, '-');
          var date = getTodayIso();
          return `${cleanTitle}-${date}.${ext}`;
        }

        if (exportXlsx) {
          exportXlsx.addEventListener('click', function() {
            exportMenu.style.display = 'none';
            if (grid && grid.download) {
              grid.download('xlsx', getExportFilename('xlsx'));
            } else if (typeof config.onExport === 'function') {
              config.onExport('xlsx', getExportFilename('xlsx'));
            }
          });
        }

        if (exportPdf) {
          exportPdf.addEventListener('click', function() {
            exportMenu.style.display = 'none';
            if (grid && grid.download) {
              grid.download('pdf', getExportFilename('pdf'), { title: title });
            } else if (typeof config.onExport === 'function') {
              config.onExport('pdf', getExportFilename('pdf'));
            }
          });
        }

        if (exportCsv) {
          exportCsv.addEventListener('click', function() {
            exportMenu.style.display = 'none';
            if (grid && grid.download) {
              // Always enforce '|' delimiter as per project rules!
              grid.download('csv', getExportFilename('csv'), { delimiter: '|' });
            } else if (typeof config.onExport === 'function') {
              config.onExport('csv', getExportFilename('csv'));
            }
          });
        }

        // Print handler
        printBtn.addEventListener('click', function() {
          if (typeof config.onPrint === 'function') {
            config.onPrint(readFilters(rootEl), currentViewId);
          } else if (Mess.print && Mess.print.report) {
            Mess.print.report({
              title: title,
              subtitle: summaryText.textContent,
              container: resultContainer
            });
          } else {
            window.print();
          }
        });

        function runGenerate() {
          var filters = readFilters(rootEl);
          emptyState.style.display = 'none';
          resultContainer.style.display = 'block';

          // Call onGenerate
          var res = onGenerate(filters, currentViewId, drawerApi);

          Promise.resolve(res).then(function(data) {
            var recordCount = Array.isArray(data) ? data.length : 0;
            summaryText.textContent = `Generated ${recordCount} record${recordCount === 1 ? '' : 's'}`;
            var timeStr = Mess.format ? Mess.format.time(new Date()) : new Date().toLocaleTimeString();
            timestampEl.textContent = `As of ${timeStr}`;

            // Render custom result or build Tabulator grid
            if (typeof config.renderResults === 'function') {
              config.renderResults(resultContainer, data, filters, currentViewId, drawerApi);
            } else {
              // Standard Tabulator Grid
              var cols = typeof columns === 'function' ? columns(currentViewId, filters) : columns;
              if (grid) {
                grid.destroy();
                grid = null;
              }

              resultContainer.innerHTML = '';
              var opts = Object.assign({
                data: data,
                columns: cols,
                layout: 'fitColumns',
                pagination: true,
                paginationSize: 50
              }, gridOptions);

              if (Mess.createDataGrid) {
                grid = Mess.createDataGrid(resultContainer, opts);
              } else if (window.Tabulator) {
                grid = new Tabulator(resultContainer, opts);
              }

              if (grid && onRowDblClick) {
                grid.on('rowDblClick', function(e, row) {
                  onRowDblClick(e, row.getData(), drawerApi);
                });
              }
            }

            if (window.lucide && window.lucide.createIcons) {
              window.lucide.createIcons({ root: rootEl });
            }
          }).catch(function(err) {
            console.error('Error generating report:', err);
            summaryText.textContent = 'Error generating report: ' + err.message;
          });
        }

        generateBtn.addEventListener('click', runGenerate);
        if (generateTrigger) generateTrigger.addEventListener('click', runGenerate);

        if (window.lucide && window.lucide.createIcons) {
          window.lucide.createIcons({ root: rootEl });
        }
      },

      drawer: drawerApi,

      getGrid: function() {
        return grid;
      },

      refresh: function() {
        if (rootElement) {
          var generateBtn = rootElement.querySelector('.report-generate-btn');
          if (generateBtn) generateBtn.click();
        }
      },

      destroy: function() {
        if (grid) {
          if (typeof grid.destroy === 'function') grid.destroy();
          grid = null;
        }
        if (drawerApi) {
          drawerApi.close();
        }
        rootElement = null;
      }
    };
  };

  // Common Report Data Helpers (Task T-080)
  Mess.reportHelpers = {
    getValidBills: function(filters) {
      filters = filters || {};
      var allBills = (Mess.store && Mess.store.list('bills')) || [];
      var fromDate = filters.fromDate;
      var toDate = filters.toDate;
      var cuisineId = filters.cuisineId;
      var mealType = filters.mealType;

      return allBills.filter(function(b) {
        if (b.cancelled) return false;
        if (fromDate && b.date < fromDate) return false;
        if (toDate && b.date > toDate) return false;

        if (cuisineId && cuisineId !== 'all') {
          var cId = b.cuisine_id || b.cuisineId;
          if (cId !== cuisineId) return false;
        }

        if (mealType && mealType !== 'all') {
          var mCode = (b.meal_code || b.meal || b.meal_type || '').toUpperCase();
          if (mCode !== mealType.toUpperCase()) return false;
        }

        return true;
      });
    },

    getDerivedItemLines: function(bills) {
      var lines = [];
      var menus = (Mess.store && Mess.store.list('menus')) || [];
      var items = (Mess.store && Mess.store.list('items')) || [];
      var menuMap = {};
      menus.forEach(function(m) {
        menuMap[m.date + '_' + m.cuisineId + '_' + m.meal] = m.items || [];
      });
      var itemMap = {};
      items.forEach(function(it) {
        itemMap[it.id] = it;
      });

      bills.forEach(function(b) {
        var cId = b.cuisine_id || b.cuisineId;
        var meal = b.meal_code || b.meal || b.meal_type || 'L';
        var menuItems = b.items;
        if (!menuItems || menuItems.length === 0) {
          menuItems = menuMap[b.date + '_' + cId + '_' + meal] || [];
        }
        menuItems.forEach(function(it) {
          var itId = it.itemId || it.item_id || it.id;
          var itObj = itemMap[itId];
          lines.push({
            billId: b.id,
            voucherNo: b.voucherNo || b.voucher_no || b.token_number || b.tokenNo,
            tokenNo: b.token_no || b.token_number || b.tokenNo,
            date: b.date,
            time: b.time,
            memberId: b.customer_id || b.memberId,
            memberName: b.customer_name || b.memberName,
            cuisineId: cId,
            cuisineName: b.cuisine_name || (Mess.store && Mess.store.get('cuisines', cId) ? Mess.store.get('cuisines', cId).name : cId),
            mealCode: meal,
            itemId: itId,
            name: it.name || it.item_name || (itObj ? itObj.name : itId),
            category: itObj ? itObj.category : '',
            unit: itObj ? itObj.unit : 'Plate',
            qty: Number(it.qty || it.quantity || (itObj ? itObj.defaultQty : 1))
          });
        });
      });
      return lines;
    }
  };
})(window.Mess);
