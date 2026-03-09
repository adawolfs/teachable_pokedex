"use strict";

const PREFERRED_CAMERA_KEY = "pokedex-preferred-camera-id";

function updateStatus(message) {
  const status = document.getElementById("prediction-status");
  if (status) {
    status.textContent = message;
  }
}

function cycleSelection(current, total, direction) {
  if (total === 0) {
    return 0;
  }
  return (current + direction + total) % total;
}

async function loadVideoDevices() {
  if (!navigator.mediaDevices || !navigator.mediaDevices.enumerateDevices) {
    return [];
  }
  const devices = await navigator.mediaDevices.enumerateDevices();
  return devices.filter((device) => device.kind === "videoinput");
}

function scoreCamera(device, index, total) {
  const label = (device.label || "").toLowerCase();
  let score = 0;

  if (/back|rear|environment/.test(label)) score += 10;
  if (/main|wide/.test(label)) score += 6;
  if (/front|selfie|depth|tele|macro/.test(label)) score -= 5;
  if (index === total - 1) score += 1;

  return score;
}

function pickBestCamera(devices) {
  if (devices.length === 0) {
    return null;
  }

  const preferredCameraId = window.localStorage.getItem(PREFERRED_CAMERA_KEY);
  const preferredCamera = devices.find(
    (device) => device.deviceId === preferredCameraId,
  );
  if (preferredCamera) {
    return preferredCamera;
  }

  const sorted = devices
    .map((device, index) => ({
      device,
      score: scoreCamera(device, index, devices.length),
    }))
    .sort((left, right) => right.score - left.score);

  return sorted[0].device;
}

async function refreshDevices() {
  const cameraStore = Alpine.store("camera");
  const devices = await loadVideoDevices();
  Alpine.store("devices", devices);

  if (devices.length > 0) {
    const currentSelected = Math.min(cameraStore.selected, devices.length - 1);
    cameraStore.selected = Math.max(currentSelected, 0);
  } else {
    cameraStore.selected = 0;
  }
}

function installKeyboardControls() {
  document.addEventListener("keydown", (event) => {
    if (
      event.target instanceof HTMLInputElement ||
      event.target instanceof HTMLTextAreaElement
    ) {
      return;
    }

    const controls = Alpine.store("controls");
    switch (event.key) {
      case "ArrowUp":
        event.preventDefault();
        controls.up();
        break;
      case "ArrowDown":
        event.preventDefault();
        controls.down();
        break;
      case "ArrowLeft":
        event.preventDefault();
        controls.left();
        break;
      case "ArrowRight":
        event.preventDefault();
        controls.right();
        break;
      case "Enter":
      case " ":
        event.preventDefault();
        controls.a();
        break;
      case "r":
      case "R":
        event.preventDefault();
        controls.red();
        break;
      case "b":
      case "B":
        event.preventDefault();
        controls.blue();
        break;
      default:
        break;
    }
  });
}

document.addEventListener("alpine:init", () => {
  Alpine.store("devices", []);

  Alpine.store("camera", {
    selected: 0,
    makePrediction: false,
    busy: false,
    isSelected(key) {
      return key === this.selected;
    },
  });

  Alpine.store("vr", {
    selected: 0,
    pokemon: ["bulbasaur", "charmander", "squirtle", "pikachu"],
    isSelected(key) {
      return key === this.selected;
    },
  });

  Alpine.store("camera_actions", {
    async a() {
      const camera = Alpine.store("camera");
      if (camera.busy) {
        camera.makePrediction = true;
        updateStatus("Scanning...");
        return;
      }

      await refreshDevices();
      const devices = Alpine.store("devices");
      const selectedDevice = pickBestCamera(devices);

      if (!selectedDevice) {
        updateStatus("No camera found on this device.");
        return;
      }

      camera.selected = devices.findIndex(
        (device) => device.deviceId === selectedDevice.deviceId,
      );
      await init("black_screen", selectedDevice.deviceId);
      camera.busy = true;
      camera.makePrediction = false;
      window.localStorage.setItem(
        PREFERRED_CAMERA_KEY,
        selectedDevice.deviceId,
      );
    },

    async red() {
      const camera = Alpine.store("camera");
      if (!camera.busy) {
        return;
      }

      await stopCameraFeed();
      camera.busy = false;
      camera.makePrediction = false;
    },

    async blue() {
      await this.red();
      Alpine.store("context", {
        actions: Alpine.store("vr_actions"),
        name: "vr",
      });
      updateStatus("VR mode. Use Up/Down to choose Pokemon, then press A.");
    },

    up() {
      const camera = Alpine.store("camera");
      const devices = Alpine.store("devices");
      camera.selected = cycleSelection(camera.selected, devices.length, -1);
    },

    down() {
      const camera = Alpine.store("camera");
      const devices = Alpine.store("devices");
      camera.selected = cycleSelection(camera.selected, devices.length, 1);
    },

    async left() {
      const camera = Alpine.store("camera");
      if (!camera.busy) {
        return;
      }

      const devices = Alpine.store("devices");
      camera.selected = cycleSelection(camera.selected, devices.length, -1);
      const selectedDevice = devices[camera.selected];
      if (!selectedDevice) {
        return;
      }
      await init("black_screen", selectedDevice.deviceId);
      window.localStorage.setItem(
        PREFERRED_CAMERA_KEY,
        selectedDevice.deviceId,
      );
      updateStatus(`Switched to ${selectedDevice.label || "camera"}.`);
    },

    async right() {
      const camera = Alpine.store("camera");
      if (!camera.busy) {
        return;
      }

      const devices = Alpine.store("devices");
      camera.selected = cycleSelection(camera.selected, devices.length, 1);
      const selectedDevice = devices[camera.selected];
      if (!selectedDevice) {
        return;
      }
      await init("black_screen", selectedDevice.deviceId);
      window.localStorage.setItem(
        PREFERRED_CAMERA_KEY,
        selectedDevice.deviceId,
      );
      updateStatus(`Switched to ${selectedDevice.label || "camera"}.`);
    },
  });

  Alpine.store("vr_actions", {
    a() {
      const pokemon = Alpine.store("vr").pokemon[Alpine.store("vr").selected];
      updateStatus(`Loading AR view for ${pokemon}...`);
      window.location.href = `vr.html?pokemon=${pokemon}`;
    },

    red() {
      Alpine.store("context", {
        actions: Alpine.store("camera_actions"),
        name: "camera",
      });
      updateStatus("Camera mode selected. Press A to start.");
    },

    blue() {
      Alpine.store("context", {
        actions: Alpine.store("camera_actions"),
        name: "camera",
      });
      updateStatus("Camera mode selected. Press A to start.");
    },

    up() {
      const vr = Alpine.store("vr");
      vr.selected = cycleSelection(vr.selected, vr.pokemon.length, -1);
    },

    down() {
      const vr = Alpine.store("vr");
      vr.selected = cycleSelection(vr.selected, vr.pokemon.length, 1);
    },

    left() {},
    right() {},
  });

  Alpine.store("context", {
    actions: Alpine.store("camera_actions"),
    name: "camera",
  });

  Alpine.store("controls", {
    a() {
      playPressA();
      Alpine.store("context").actions.a();
    },
    red() {
      Alpine.store("context").actions.red();
    },
    blue() {
      Alpine.store("context").actions.blue();
    },
    up() {
      Alpine.store("context").actions.up();
    },
    down() {
      Alpine.store("context").actions.down();
    },
    left() {
      Alpine.store("context").actions.left();
    },
    right() {
      Alpine.store("context").actions.right();
    },
  });

  if (navigator.mediaDevices && navigator.mediaDevices.addEventListener) {
    navigator.mediaDevices.addEventListener("devicechange", refreshDevices);
  }
  refreshDevices().catch(() => {
    updateStatus("Unable to read camera list until permission is granted.");
  });
  installKeyboardControls();
  updateStatus("Press A to start camera detection.");
});
