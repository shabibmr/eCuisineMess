/* prng.js - Mulberry32 deterministic pseudo-random number generator */

window.Mess = window.Mess || {};

(function(Mess) {
  Mess.createPRNG = function(seed) {
    var s = seed >>> 0;
    return function() {
      var t = (s += 0x6D2B79F5) >>> 0;
      t = Math.imul(t ^ (t >>> 15), t | 1) >>> 0;
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61) >>> 0;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  };
})(window.Mess);
