/* styleguide.js - Styleguide QA page showcase screen */

window.Mess = window.Mess || {};

(function(Mess) {
  Mess.screens.register({
    id: 'styleguide',
    route: '/styleguide',
    title: 'Styleguide & Component Gallery',
    nav: { group: 'Bottom', icon: 'palette', order: 90 },
    roles: ['admin', 'supervisor', 'counter'],
    template: function() {
      return /* html */ `
        <div class="styleguide-page flex-col gap-lg">
          <header class="flex-row justify-between align-center">
            <div>
              <h1>Styleguide & Component Gallery</h1>
              <p class="text-sm color-ink-2">QA source for typography, palettes, meal colors, components, grid, chart & token slip.</p>
            </div>
          </header>

          <!-- Typography Section -->
          <section class="card flex-col gap-md">
            <h2>1. Typography & Numerals</h2>
            <div class="flex-col gap-xs">
              <span class="text-2xl">2XL Title (32px / 750)</span>
              <span class="text-xl">XL Heading (27px / 750)</span>
              <span class="text-lg">LG Subheading (22px / 750)</span>
              <span class="text-md">MD Section Label (18px / 600)</span>
              <span class="text-base">Base Body Text (15px / 400) - Sample Arabic Name: <span lang="ar">محمد أحمد السويدي</span></span>
              <span class="text-sm color-ink-2">SM Meta Text (13px / 400)</span>
              <span class="text-xs color-ink-2">XS Caption (12px / 400)</span>
            </div>
            <div class="flex-row gap-md align-center">
              <span class="tabular-nums font-semibold text-lg">Tabular Nums: 0123456789 (Qty: 4,500 · Token: L-0188)</span>
            </div>
          </section>

          <!-- Meal & Status Color Tokens -->
          <section class="card flex-col gap-md">
            <h2>2. Meal & Status Color Palette</h2>
            <div class="grid-2col">
              <div class="flex-row gap-sm align-center">
                <span class="badge badge--b"><i data-lucide="sunrise"></i> Breakfast (Saffron)</span>
                <span class="text-sm">--meal-b (#E08A1E)</span>
              </div>
              <div class="flex-row gap-sm align-center">
                <span class="badge badge--l"><i data-lucide="sun"></i> Lunch (Curry leaf)</span>
                <span class="text-sm">--meal-l (#1F9D6B)</span>
              </div>
              <div class="flex-row gap-sm align-center">
                <span class="badge badge--d"><i data-lucide="moon-star"></i> Dinner (Night violet)</span>
                <span class="text-sm">--meal-d (#6A4BD1)</span>
              </div>
              <div class="flex-row gap-sm align-center">
                <span class="badge badge--inactive" style="border-color: var(--danger); color: var(--danger);"><i data-lucide="octagon-alert"></i> Danger / Error</span>
                <span class="text-sm">--danger (#D7263D)</span>
              </div>
            </div>
            <div class="flex-row gap-md">
              <span class="badge badge--active">Active</span>
              <span class="badge badge--expiring">Expiring in 4 days</span>
              <span class="badge badge--inactive">Inactive</span>
            </div>
          </section>

          <!-- Component Gallery -->
          <section class="card flex-col gap-md">
            <h2>3. Core Components</h2>
            
            <div class="flex-row gap-md wrap">
              <button type="button" class="btn btn--primary">Primary Action</button>
              <button type="button" class="btn btn--secondary">Secondary</button>
              <button type="button" class="btn btn--quiet">Quiet Ghost</button>
              <button type="button" class="btn btn--danger">Danger Action</button>
              <button type="button" class="btn btn--icon" aria-label="Settings"><i data-lucide="settings"></i></button>
              <button type="button" class="btn btn--primary" disabled>Disabled</button>
            </div>

            <div class="grid-2col">
              <div class="field-group">
                <label class="field-label">Sample Field</label>
                <input type="text" class="field-input" placeholder="Enter text..." value="Rahul K">
              </div>
              <div class="field-group">
                <label class="field-label">Invalid Field</label>
                <input type="text" class="field-input invalid" value="Invalid entry">
                <span class="field-error-msg">This field is required.</span>
              </div>
            </div>

            <div class="flex-row gap-xl align-center">
              <label class="checkbox-label">
                <input type="checkbox" class="checkbox" checked>
                <span>Show inactive records</span>
              </label>

              <label class="switch-label">
                <input type="checkbox" class="switch-input" checked>
                <span class="switch"><span class="switch-slider"></span></span>
                <span>Print to device</span>
              </label>

              <div class="stepper">
                <button type="button" class="stepper-btn">-</button>
                <input type="text" class="stepper-input" value="1.0">
                <button type="button" class="stepper-btn">+</button>
              </div>
            </div>
          </section>

          <!-- Sample Grid -->
          <section class="card flex-col gap-md">
            <h2>4. Sample Data Grid (Tabulator)</h2>
            <div id="styleguide-grid" style="height: 180px;"></div>
          </section>

          <!-- Sample Chart & Token Slip -->
          <div class="grid-2col">
            <section class="card flex-col gap-md">
              <h2>5. Sample ApexChart</h2>
              <div id="styleguide-chart" style="height: 200px;"></div>
            </section>

            <section class="card flex-col gap-md align-center">
              <h2>6. Thermal Token Slip</h2>
              <div class="token-slip">
                <div class="slip-header-title">Sample Camp Mess</div>
                <div class="text-xs">Jebel Ali, Dubai, UAE</div>
                <hr style="margin: 8px 0; border: none; border-top: 1px dashed #000;">
                <div class="text-sm">LUNCH TOKEN</div>
                <div class="slip-token-number" style="color: var(--meal-l);">L-0188</div>
                <div class="text-xs">Member: M-0042 (Rahul K)</div>
                <div class="text-xs">Cuisine: South Indian</div>
                <div class="text-xs">Date: 02-10-2026 12:45:10</div>
              </div>
            </section>
          </div>
        </div>
      `;
    },
    component: function() {
      var gridInstance = null;
      var chartInstance = null;

      return {
        init: function() {
          if (window.Tabulator) {
            gridInstance = new Tabulator("#styleguide-grid", {
              data: [
                { id: "I001", name: "Idli", category: "Breakfast", unit: "Nos", active: true },
                { id: "I002", name: "Plain Dosa", category: "Breakfast", unit: "Nos", active: true },
                { id: "I003", name: "Sambar", category: "Curries", unit: "Bowl", active: true },
                { id: "I004", name: "Halwa Puri", category: "Breakfast", unit: "Plate", active: false }
              ],
              layout: "fitColumns",
              columns: [
                { title: "Code", field: "id", width: 90 },
                { title: "Item Name", field: "name" },
                { title: "Category", field: "category" },
                { title: "Unit", field: "unit", width: 90 },
                { title: "Active", field: "active", formatter: "tickCross", width: 80 }
              ]
            });
          }

          if (window.ApexCharts) {
            chartInstance = new ApexCharts(document.querySelector("#styleguide-chart"), {
              chart: { type: 'bar', height: 180, toolbar: { show: false } },
              series: [{ name: 'Tokens Issued', data: [45, 120, 85] }],
              xaxis: { categories: ['Breakfast', 'Lunch', 'Dinner'] },
              colors: ['#1F9D6B']
            });
            chartInstance.render();
          }
        },
        destroy: function() {
          if (gridInstance) gridInstance.destroy();
          if (chartInstance) chartInstance.destroy();
        }
      };
    }
  });
})(window.Mess);
