(function () {
  "use strict";

  const lightsCanvas = document.getElementById("lights");
  const baseCanvas = document.getElementById("base");
  const controlsCanvas = document.getElementById("controls");
  const screenCanvas = document.getElementById("screen");
  const reduceMotion = window.matchMedia(
    "(prefers-reduced-motion: reduce)",
  ).matches;
  const riveFile = "assets/rive/pokedex.riv";

  let resizeTimer = null;
  let lights = null;
  let base = null;

  function resizeCanvas() {
    lightsCanvas.width = 1000;
    lightsCanvas.height = 1500;
    baseCanvas.width = 1000;
    baseCanvas.height = 1500;
    controlsCanvas.width = 1000;
    controlsCanvas.height = 500;
    screenCanvas.width = 1000;
    screenCanvas.height = 1000;

    if (lights) {
      lights.layout = new rive.Layout({
        fit: rive.Fit.FitWidth,
        alignment: rive.Alignment.TopCenter,
      });
    }
    if (base) {
      base.layout = new rive.Layout({
        fit: rive.Fit.FitWidth,
        alignment: rive.Alignment.BottomCenter,
      });
    }
  }

  function initRive() {
    lights = new rive.Rive({
      src: riveFile,
      canvas: lightsCanvas,
      artboard: "lights",
      autoplay: !reduceMotion,
    });

    base = new rive.Rive({
      src: riveFile,
      canvas: baseCanvas,
      artboard: "base",
      autoplay: !reduceMotion,
    });

    new rive.Rive({
      src: riveFile,
      canvas: screenCanvas,
      artboard: "screen",
      autoplay: !reduceMotion,
    });

    new rive.Rive({
      src: riveFile,
      canvas: controlsCanvas,
      artboard: "controls",
      autoplay: !reduceMotion,
    });
  }

  window.addEventListener("resize", () => {
    if (resizeTimer) {
      window.clearTimeout(resizeTimer);
    }
    resizeTimer = window.setTimeout(resizeCanvas, 180);
  });

  resizeCanvas();
  initRive();
})();
