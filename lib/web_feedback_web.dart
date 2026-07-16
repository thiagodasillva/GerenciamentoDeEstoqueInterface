// Web implementation of audio feedback using dart:js.
import 'dart:js' as js;

void playWebAudioFeedback() {
  try {
    js.context.callMethod('eval', [
      '''
      (function() {
        var context = new (window.AudioContext || window.webkitAudioContext)();
        var osc = context.createOscillator();
        var gain = context.createGain();
        
        osc.type = 'sine';
        osc.frequency.setValueAtTime(750, context.currentTime);
        osc.connect(gain);
        gain.connect(context.destination);
        
        gain.gain.setValueAtTime(0, context.currentTime);
        gain.gain.linearRampToValueAtTime(0.08, context.currentTime + 0.04);
        gain.gain.exponentialRampToValueAtTime(0.001, context.currentTime + 0.22);
        
        osc.start(context.currentTime);
        osc.stop(context.currentTime + 0.22);
      })();
      ''',
    ]);
  } catch (e) {
    // Fail-safe if Web Audio API fails
  }
}
