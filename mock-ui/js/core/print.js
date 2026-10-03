/* print.js - Hidden iframe printer & print-to-device toggle */

window.Mess = window.Mess || {};

(function(Mess) {
  var STORAGE_KEY = 'mess-mock:print-device';
  var printToDevice = false;

  try {
    printToDevice = localStorage.getItem(STORAGE_KEY) === 'true';
  } catch (e) {}

  Mess.print = {
    isPrintToDevice: function() { return printToDevice; },

    togglePrintToDevice: function() {
      printToDevice = !printToDevice;
      try {
        localStorage.setItem(STORAGE_KEY, printToDevice ? 'true' : 'false');
      } catch (e) {}
      window.dispatchEvent(new CustomEvent('printdevicechange', { detail: { printToDevice: printToDevice } }));
      return printToDevice;
    },

    setPrintToDevice: function(val) {
      printToDevice = !!val;
      try {
        localStorage.setItem(STORAGE_KEY, printToDevice ? 'true' : 'false');
      } catch (e) {}
      window.dispatchEvent(new CustomEvent('printdevicechange', { detail: { printToDevice: printToDevice } }));
    },

    printHtml: function(htmlContent, cssFile) {
      var frame = document.getElementById('print-frame');
      if (!frame) return;

      var doc = frame.contentDocument || frame.contentWindow.document;
      doc.open();
      doc.write('<!DOCTYPE html><html><head><title>Print</title>');
      if (cssFile) {
        doc.write('<link rel="stylesheet" href="' + cssFile + '">');
      }
      doc.write('</head><body>');
      doc.write(htmlContent);
      doc.write('</body></html>');
      doc.close();

      if (printToDevice) {
        setTimeout(function() {
          frame.contentWindow.focus();
          frame.contentWindow.print();
        }, 250);
      } else {
        // Fallback preview dialog if print to device is disabled
        if (Mess.dialog && Mess.dialog.alert) {
          Mess.dialog.alert('Token Print Preview (Print-to-Device Off)', htmlContent);
        }
      }
    }
  };
})(window.Mess);
