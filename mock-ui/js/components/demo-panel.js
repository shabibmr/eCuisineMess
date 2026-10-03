/* demo-panel.js - Docked Demo Control Panel (Ctrl+Shift+D) */

window.Mess = window.Mess || {};

(function(Mess) {
  var isVisible = false;

  function initDemoPanel() {
    var container = document.getElementById('demo-panel-container');
    if (!container) return;

    container.innerHTML = /* html */ `
      <div id="demo-panel" class="demo-panel" x-data="MessDemoPanel" x-show="open" style="display: none;">
        <div class="demo-panel-header">
          <span class="font-bold text-sm">Demo Controls (Ctrl+Shift+D)</span>
          <button type="button" class="btn btn--icon" @click="open = false"><i data-lucide="x"></i></button>
        </div>
        <div class="demo-panel-body flex-col gap-md">
          <!-- Scenario Quick Taps -->
          <div class="flex-col gap-xs">
            <span class="text-xs font-semibold color-ink-2">Tap Scenario Cards (RFID)</span>
            <div class="grid-2col gap-xs">
              <button type="button" class="btn btn--secondary text-xs" @click="tap('0004772398')">M-0042 Rahul K (Happy)</button>
              <button type="button" class="btn btn--secondary text-xs" @click="tap('0004770007')">M-0007 Maria (Already served)</button>
              <button type="button" class="btn btn--secondary text-xs" @click="tap('0004770013')">M-0013 Imran (Expired)</button>
              <button type="button" class="btn btn--secondary text-xs" @click="tap('0004770021')">M-0021 Sunil (Expiring)</button>
              <button type="button" class="btn btn--secondary text-xs" @click="tap('0004770030')">M-0030 Ahmed (Inactive)</button>
              <button type="button" class="btn btn--secondary text-xs" @click="tap('0004770055')">M-0055 Arjun (No Menu)</button>
              <button type="button" class="btn btn--secondary text-xs" @click="tap('0009999999')">Unregistered Card</button>
              <button type="button" class="btn btn--secondary text-xs" @click="tap('0004777001')">Unassigned Capture Card</button>
            </div>
          </div>

          <!-- Clock Override -->
          <div class="flex-col gap-xs">
            <span class="text-xs font-semibold color-ink-2">Clock Override</span>
            <div class="flex-row gap-xs wrap">
              <button type="button" class="btn btn--quiet text-xs" @click="setClock('08:00')">Breakfast (08:00)</button>
              <button type="button" class="btn btn--quiet text-xs" @click="setClock('13:00')">Lunch (13:00)</button>
              <button type="button" class="btn btn--quiet text-xs" @click="setClock('20:00')">Dinner (20:00)</button>
              <button type="button" class="btn btn--quiet text-xs" @click="setClock('16:00')">Closed (16:00)</button>
              <button type="button" class="btn btn--quiet text-xs" @click="resetClock()">Reset Clock</button>
            </div>
          </div>

          <!-- Quick Role Switch -->
          <div class="flex-col gap-xs">
            <span class="text-xs font-semibold color-ink-2">Role Switch</span>
            <div class="flex-row gap-xs">
              <button type="button" class="btn btn--secondary text-xs" @click="setRole('admin')">Admin</button>
              <button type="button" class="btn btn--secondary text-xs" @click="setRole('supervisor')">Supervisor</button>
              <button type="button" class="btn btn--secondary text-xs" @click="setRole('counter')">Counter</button>
            </div>
          </div>

          <!-- Reset Data -->
          <div class="flex-row justify-between align-center pt-xs">
            <button type="button" class="btn btn--danger text-xs" @click="resetData()">Reset Sample Data</button>
          </div>
        </div>
      </div>
    `;

    if (window.Alpine) {
      Alpine.data('MessDemoPanel', function() {
        return {
          open: false,
          init: function() {
            var self = this;
            window.addEventListener('keydown', function(e) {
              if (e.ctrlKey && e.shiftKey && (e.key === 'D' || e.key === 'd')) {
                e.preventDefault();
                self.open = !self.open;
              }
            });
          },
          tap: function(cardNo) {
            if (Mess.rfid) Mess.rfid.simulate(cardNo);
          },
          setClock: function(timeStr) {
            if (Mess.clock) Mess.clock.setOverride(timeStr);
          },
          resetClock: function() {
            if (Mess.clock) Mess.clock.clearOverride();
          },
          setRole: function(role) {
            if (Mess.roles) Mess.roles.setRole(role);
          },
          resetData: function() {
            if (confirm('Reset all sample data to default seed?')) {
              if (Mess.persist) Mess.persist.reset();
            }
          }
        };
      });
    }
  }

  Mess.demoPanel = {
    toggle: function() {
      isVisible = !isVisible;
    }
  };

  document.addEventListener('DOMContentLoaded', initDemoPanel);

})(window.Mess);
