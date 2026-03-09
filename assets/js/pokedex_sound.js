(function () {
  "use strict";

  const pressASound = new Audio("assets/sounds/SFX_PRESS_AB.wav");

  function flashButton() {
    const button = document.querySelector(".button_a");
    if (!button) {
      return;
    }
    button.classList.add("button-pressed");
    window.setTimeout(() => button.classList.remove("button-pressed"), 120);
  }

  window.playPressA = function playPressA() {
    flashButton();
    pressASound.currentTime = 0;
    pressASound.play().catch(() => {});
  };
})();
