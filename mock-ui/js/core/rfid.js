/* rfid.js - Keyboard-wedge RFID reader detector & event emitter */

window.Mess = window.Mess || {};

(function(Mess) {
  var buffer = '';
  var lastKeyTime = 0;
  var MAX_KEY_INTERVAL_MS = 35;
  var MIN_CARD_LENGTH = 8;

  function handleKeyDown(e) {
    var now = Date.now();
    var timeDiff = now - lastKeyTime;
    lastKeyTime = now;

    if (e.key === 'Enter') {
      if (buffer.length >= MIN_CARD_LENGTH && timeDiff < MAX_KEY_INTERVAL_MS * 2) {
        var cardNo = buffer;
        buffer = '';
        e.preventDefault();
        e.stopPropagation();
        Mess.rfid.emit(cardNo);
        return;
      }
      buffer = '';
      return;
    }

    if (e.key.length === 1) {
      if (timeDiff < MAX_KEY_INTERVAL_MS || buffer.length === 0) {
        buffer += e.key;
      } else {
        // Reset buffer if delay is too long (human typing)
        buffer = e.key;
      }
    }
  }

  Mess.rfid = {
    init: function() {
      document.addEventListener('keydown', handleKeyDown, true);
    },

    emit: function(cardNo) {
      var clean = String(cardNo || '').trim();
      window.dispatchEvent(new CustomEvent('rfid:read', {
        detail: { rfid: clean, timestamp: new Date() }
      }));
    },

    simulate: function(cardNo) {
      Mess.rfid.emit(cardNo);
    }
  };

  Mess.rfid.init();

})(window.Mess);
