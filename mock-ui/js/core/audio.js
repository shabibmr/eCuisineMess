/* audio.js - Web Audio beeps (ok and error) & mute persistence */

window.Mess = window.Mess || {};

(function(Mess) {
  var STORAGE_KEY = 'mess-mock:muted';
  var muted = false;
  var audioCtx = null;

  try {
    muted = localStorage.getItem(STORAGE_KEY) === 'true';
  } catch (e) {}

  function getAudioContext() {
    if (!audioCtx) {
      var AudioContextClass = window.AudioContext || window.webkitAudioContext;
      if (AudioContextClass) {
        audioCtx = new AudioContextClass();
      }
    }
    if (audioCtx && audioCtx.state === 'suspended') {
      audioCtx.resume();
    }
    return audioCtx;
  }

  function playTone(freq, type, durationMs) {
    if (muted) return;
    try {
      var ctx = getAudioContext();
      if (!ctx) return;

      var osc = ctx.createOscillator();
      var gain = ctx.createGain();

      osc.type = type || 'sine';
      osc.frequency.setValueAtTime(freq, ctx.currentTime);

      gain.gain.setValueAtTime(0.2, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + (durationMs / 1000));

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start();
      osc.stop(ctx.currentTime + (durationMs / 1000));
    } catch (e) {
      console.warn('Audio play failure:', e);
    }
  }

  Mess.audio = {
    isMuted: function() { return muted; },

    toggleMute: function() {
      muted = !muted;
      try {
        localStorage.setItem(STORAGE_KEY, muted ? 'true' : 'false');
      } catch (e) {}
      window.dispatchEvent(new CustomEvent('mutechange', { detail: { muted: muted } }));
      return muted;
    },

    ok: function() {
      playTone(880, 'sine', 80);
    },

    error: function() {
      playTone(220, 'square', 160);
      setTimeout(function() {
        playTone(220, 'square', 160);
      }, 200);
    }
  };
})(window.Mess);
