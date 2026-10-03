/* rfid-capture.js - RFID Card Capture component with 15s timeout ring & duplicate check */

window.Mess = window.Mess || {};

(function(Mess) {
  Mess.createRfidCapture = function(containerEl, options) {
    options = options || {};
    var currentValue = options.value || '';
    var currentCustomerId = options.currentCustomerId || null;
    var onChange = options.onChange || null;

    var isListening = false;
    var timerId = null;
    var secondsLeft = 15;
    var rfidListener = null;

    var html = `
      <div class="rfid-capture-widget flex-col gap-xs" style="width: 100%;">
        <div class="flex-row gap-xs align-center">
          <div class="field-with-icon" style="flex: 1; position: relative;">
            <i data-lucide="nfc" class="field-icon color-ink-3" style="position: absolute; left: 10px; top: 50%; transform: translateY(-50%); width: 16px; height: 16px;"></i>
            <input type="text" class="field-input rfid-input-display font-mono" readonly 
                   value="${currentValue}" placeholder="No card assigned" 
                   style="padding-left: 34px; letter-spacing: 0.05em; font-weight: 500;">
          </div>
          <button type="button" class="btn btn--secondary capture-btn" title="Capture RFID card">
            <span class="btn-text">Capture</span>
          </button>
          <button type="button" class="btn btn--quiet btn--icon clear-btn" title="Clear RFID card">
            <i data-lucide="x"></i>
          </button>
        </div>

        <!-- Listening Countdown Banner -->
        <div class="rfid-listening-banner card-inset flex-row align-center gap-sm" 
             style="display: none; padding: 8px 12px; border-radius: var(--radius-sm); background: var(--surface); border: 1px solid var(--primary);">
          <div class="rfid-timer-ring-wrapper" style="position: relative; width: 28px; height: 28px; flex-shrink: 0;">
            <svg class="timer-ring-svg" width="28" height="28" viewBox="0 0 36 36">
              <path class="ring-bg" stroke="var(--separator)" stroke-width="3" fill="none"
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" />
              <path class="ring-progress" stroke="var(--primary)" stroke-width="3" stroke-dasharray="100, 100" stroke-linecap="round" fill="none"
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" />
            </svg>
            <span class="timer-countdown-text text-xs font-mono font-bold" 
                  style="position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; font-size: 10px;">15</span>
          </div>

          <div class="flex-col" style="flex: 1;">
            <span class="text-xs font-semibold color-ink animate-pulse">Tap card on reader now…</span>
            <span class="text-xs color-ink-3">Or use Demo Panel (Ctrl+Shift+D)</span>
          </div>

          <button type="button" class="btn btn--quiet btn--xs cancel-listen-btn">Cancel</button>
        </div>

        <!-- Error / Warning message -->
        <div class="rfid-error-msg text-xs color-danger font-medium" style="display: none;"></div>
      </div>
    `;

    containerEl.innerHTML = html;

    var inputDisplay = containerEl.querySelector('.rfid-input-display');
    var captureBtn = containerEl.querySelector('.capture-btn');
    var clearBtn = containerEl.querySelector('.clear-btn');
    var listeningBanner = containerEl.querySelector('.rfid-listening-banner');
    var ringProgress = containerEl.querySelector('.ring-progress');
    var countdownText = containerEl.querySelector('.timer-countdown-text');
    var cancelListenBtn = containerEl.querySelector('.cancel-listen-btn');
    var errorMsg = containerEl.querySelector('.rfid-error-msg');

    function showError(msg) {
      errorMsg.textContent = msg;
      errorMsg.style.display = 'block';
    }

    function clearError() {
      errorMsg.textContent = '';
      errorMsg.style.display = 'none';
    }

    function updateTimerRing() {
      countdownText.textContent = secondsLeft;
      var percent = (secondsLeft / 15) * 100;
      ringProgress.setAttribute('stroke-dasharray', `${percent}, 100`);
    }

    function startListening() {
      if (isListening) return;
      isListening = true;
      clearError();
      secondsLeft = 15;
      updateTimerRing();
      listeningBanner.style.display = 'flex';
      captureBtn.disabled = true;

      // Register RFID read listener
      rfidListener = function(e) {
        var cardCode = e.detail && e.detail.code ? e.detail.code : (typeof e.detail === 'string' ? e.detail : null);
        if (!cardCode) return;
        onCardTapped(cardCode);
      };

      window.addEventListener('rfid:read', rfidListener);

      timerId = setInterval(function() {
        secondsLeft--;
        updateTimerRing();
        if (secondsLeft <= 0) {
          stopListening();
          showError('Listening timed out (15s). Tap Capture to try again.');
        }
      }, 1000);
    }

    function stopListening() {
      if (!isListening) return;
      isListening = false;
      if (timerId) {
        clearInterval(timerId);
        timerId = null;
      }
      if (rfidListener) {
        window.removeEventListener('rfid:read', rfidListener);
        rfidListener = null;
      }
      listeningBanner.style.display = 'none';
      captureBtn.disabled = false;
    }

    function onCardTapped(cardCode) {
      stopListening();

      // Check if card is duplicate
      var existingCustomer = null;
      if (Mess.store) {
        var customers = Mess.store.list('customers') || [];
        existingCustomer = customers.find(function(c) {
          return c.rfid && c.rfid.trim().toLowerCase() === cardCode.trim().toLowerCase() && c.id !== currentCustomerId;
        });
      }

      if (existingCustomer) {
        if (Mess.audio && Mess.audio.error) Mess.audio.error();
        showError(`Card linked to ${existingCustomer.name} (${existingCustomer.code})`);
        return;
      }

      // Valid card!
      if (Mess.audio && Mess.audio.ok) Mess.audio.ok();
      setValue(cardCode);
      if (typeof onChange === 'function') {
        onChange(cardCode);
      }
    }

    function setValue(val) {
      currentValue = val || '';
      inputDisplay.value = currentValue;
      clearError();
    }

    captureBtn.addEventListener('click', function() {
      if (isListening) {
        stopListening();
      } else {
        startListening();
      }
    });

    cancelListenBtn.addEventListener('click', function() {
      stopListening();
    });

    clearBtn.addEventListener('click', function() {
      stopListening();
      setValue('');
      if (typeof onChange === 'function') {
        onChange('');
      }
    });

    if (window.lucide && window.lucide.createIcons) {
      window.lucide.createIcons({ root: containerEl });
    }

    return {
      getValue: function() {
        return currentValue;
      },
      setValue: setValue,
      startListening: startListening,
      stopListening: stopListening,
      clear: function() {
        setValue('');
      },
      destroy: function() {
        stopListening();
        containerEl.innerHTML = '';
      }
    };
  };
})(window.Mess);
