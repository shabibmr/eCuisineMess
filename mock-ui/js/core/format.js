/* format.js - Formatting utilities (dates, times, RFID masks, quantities, tokens, currency) */

window.Mess = window.Mess || {};

(function(Mess) {
  function pad2(n) {
    return (n < 10 ? '0' : '') + n;
  }

  function pad4(n) {
    return ('0000' + n).slice(-4);
  }

  Mess.formatDate = function(dateInput) {
    var d = dateInput ? new Date(dateInput) : new Date();
    if (isNaN(d.getTime())) return '';
    return pad2(d.getDate()) + '-' + pad2(d.getMonth() + 1) + '-' + d.getFullYear();
  };

  Mess.formatTime = function(dateInput) {
    var d = dateInput ? new Date(dateInput) : new Date();
    if (isNaN(d.getTime())) return '';
    return pad2(d.getHours()) + ':' + pad2(d.getMinutes());
  };

  Mess.formatDateTime = function(dateInput) {
    var d = dateInput ? new Date(dateInput) : new Date();
    if (isNaN(d.getTime())) return '';
    return Mess.formatDate(d) + ' ' + Mess.formatTime(d) + ':' + pad2(d.getSeconds());
  };

  Mess.maskRFID = function(rfidStr) {
    if (!rfidStr) return '••••••••••••';
    var clean = String(rfidStr).replace(/\s+/g, '');
    if (clean.length <= 4) return clean;
    var last4 = clean.slice(-4);
    return '••••••' + last4;
  };

  Mess.formatQty = function(qty) {
    var num = parseFloat(qty);
    if (isNaN(num)) return '0';
    return num % 1 === 0 ? num.toString() : num.toFixed(1);
  };

  Mess.formatToken = function(prefix, seqNum) {
    var p = (prefix || 'L').toUpperCase();
    return p + '-' + pad4(seqNum);
  };

  Mess.formatCurrency = function(val) {
    var num = parseFloat(val) || 0;
    return num.toFixed(2);
  };

  Mess.format = {
    date: Mess.formatDate,
    time: Mess.formatTime,
    dateTime: Mess.formatDateTime,
    maskRfid: Mess.maskRFID,
    maskRFID: Mess.maskRFID,
    qty: Mess.formatQty,
    token: Mess.formatToken,
    currency: Mess.formatCurrency
  };

  // Unit assertions
  (function runAsserts() {
    try {
      console.assert(Mess.maskRFID('0004772398') === '••••••2398', 'RFID Mask test failed');
      console.assert(Mess.formatToken('L', 188) === 'L-0188', 'Token format test failed');
      console.assert(Mess.formatToken('b', 1) === 'B-0001', 'Token format test failed');
      console.assert(Mess.formatQty(1.5) === '1.5', 'Qty format test failed');
      console.assert(Mess.formatQty(2.0) === '2', 'Qty format test failed');
      console.assert(Mess.formatCurrency(0) === '0.00', 'Currency format test failed');
      
      var rng = Mess.createPRNG(20261002);
      var r1 = rng();
      var r2 = rng();
      console.assert(typeof r1 === 'number' && r1 !== r2, 'PRNG test failed');

      console.log('T-020 Format & PRNG unit asserts passed.');
    } catch (e) {
      console.error('T-020 Unit asserts failed:', e);
    }
  })();
})(window.Mess);
