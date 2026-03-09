(function () {
  "use strict";

  const MODEL_BASE_URL = "assets/my_model/";
  const DETECTION_THRESHOLD = 0.8;

  let model = null;
  let maxPredictions = 0;
  let webcam = null;
  let animationFrameId = null;
  let cameraActive = false;

  function updateStatus(message) {
    const status = document.getElementById("prediction-status");
    if (status) {
      status.textContent = message;
    }
  }

  async function ensureModelLoaded() {
    if (model) {
      return;
    }
    updateStatus("Loading model...");
    const modelURL = MODEL_BASE_URL + "model.json";
    const metadataURL = MODEL_BASE_URL + "metadata.json";
    model = await tmImage.load(modelURL, metadataURL);
    maxPredictions = model.getTotalClasses();
    updateStatus("Model ready. Press A to scan.");
  }

  async function init(containerId, deviceId) {
    await stopCameraFeed();
    await ensureModelLoaded();

    const container = document.getElementById(containerId);
    if (!container) {
      return;
    }

    const width = Math.max(container.offsetWidth, 320);
    const height = Math.max(container.offsetHeight - 10, 240);
    webcam = new tmImage.Webcam(width, height, false);

    const setupOptions = deviceId
      ? { deviceId: { exact: deviceId } }
      : { facingMode: { ideal: "environment" } };

    await webcam.setup(setupOptions);
    await webcam.play();

    webcam.canvas.id = "camera";
    webcam.canvas.setAttribute("role", "img");
    webcam.canvas.setAttribute(
      "aria-label",
      "Live camera feed for Pokemon recognition",
    );
    container.appendChild(webcam.canvas);

    cameraActive = true;
    updateStatus("Camera ready. Press A to identify Pokemon.");
    animationFrameId = window.requestAnimationFrame(loop);
  }

  async function loop() {
    if (!cameraActive || !webcam) {
      return;
    }

    webcam.update();
    if (window.Alpine && Alpine.store("camera").makePrediction) {
      await predict();
    }
    animationFrameId = window.requestAnimationFrame(loop);
  }

  async function predict() {
    if (!model || !webcam) {
      return;
    }

    updateStatus("Scanning...");
    const prediction = await model.predict(webcam.canvas);

    let bestMatch = null;
    for (let i = 0; i < maxPredictions; i += 1) {
      if (!bestMatch || prediction[i].probability > bestMatch.probability) {
        bestMatch = prediction[i];
      }
    }

    if (bestMatch && bestMatch.probability >= DETECTION_THRESHOLD) {
      const confidence = (bestMatch.probability * 100).toFixed(0);
      speak(bestMatch.className);
      updateStatus(`Detected ${bestMatch.className} (${confidence}%)`);
      Alpine.store("camera").makePrediction = false;
    } else {
      updateStatus("No confident match yet. Press A to try again.");
      Alpine.store("camera").makePrediction = false;
    }
  }

  async function stopCameraFeed() {
    cameraActive = false;

    if (animationFrameId !== null) {
      window.cancelAnimationFrame(animationFrameId);
      animationFrameId = null;
    }

    if (webcam) {
      webcam.stop();
      if (webcam.canvas && webcam.canvas.parentNode) {
        webcam.canvas.parentNode.removeChild(webcam.canvas);
      }
      webcam = null;
    }

    updateStatus("Camera stopped.");
  }

  function isCameraRunning() {
    return cameraActive;
  }

  window.init = init;
  window.stopCameraFeed = stopCameraFeed;
  window.isCameraRunning = isCameraRunning;
})();
