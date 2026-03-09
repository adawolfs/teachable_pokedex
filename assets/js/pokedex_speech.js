(function () {
  "use strict";

  const speech = new SpeechSynthesisUtterance();
  speech.lang = "en";

  function assignVoice() {
    const voices = window.speechSynthesis.getVoices();
    if (voices.length > 0) {
      speech.voice = voices[0];
    }
  }

  assignVoice();
  window.speechSynthesis.onvoiceschanged = assignVoice;

  window.speak = function speak(text) {
    speech.text = text;
    speech.rate = 1;
    speech.pitch = 1;
    speech.volume = 1;
    window.speechSynthesis.cancel();
    window.speechSynthesis.speak(speech);
  };
})();
