# Teachable Pokedex — Improvement Plan

> Full audit and improvement roadmap based on code review, security audit, performance analysis, and accessibility assessment.
> Generated: March 2026

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Phase 1 — Critical Bug Fixes](#phase-1--critical-bug-fixes)
3. [Phase 2 — Auto Camera Selection](#phase-2--auto-camera-selection)
4. [Phase 3 — Security Hardening](#phase-3--security-hardening)
5. [Phase 4 — Performance Optimization](#phase-4--performance-optimization)
6. [Phase 5 — Accessibility (WCAG 2.1 AA)](#phase-5--accessibility-wcag-21-aa)
7. [Phase 6 — UI/UX Improvements (Same Theme)](#phase-6--uiux-improvements-same-theme)
8. [Phase 7 — Code Quality & Architecture](#phase-7--code-quality--architecture)
9. [Phase 8 — PWA & Deployment](#phase-8--pwa--deployment)
10. [Phase 9 — Dependency Updates](#phase-9--dependency-updates)
11. [Appendix — File-by-File Issues Map](#appendix--file-by-file-issues-map)

---

## Executive Summary

| Category       | Critical | High | Medium | Low | Total |
| -------------- | -------- | ---- | ------ | --- | ----- |
| Bugs           | 0        | 4    | 2      | 0   | 6     |
| Security       | 2        | 4    | 6      | 4   | 16    |
| Performance    | 0        | 2    | 4      | 2   | 8     |
| Accessibility  | 0        | 8    | 8      | 6   | 22    |
| UI/UX          | 0        | 1    | 3      | 3   | 7     |
| Code Quality   | 0        | 0    | 3      | 2   | 5     |
| PWA/Deploy     | 0        | 1    | 2      | 1   | 4     |
| Dependencies   | 0        | 1    | 2      | 0   | 3     |
| **Total**      | **2**    | **21** | **30** | **18** | **71** |

---

## Phase 1 — Critical Bug Fixes

> **Priority:** Immediate | **Effort:** ~2 hours | **Branch:** `fix/critical-bugs`

### 1.1 Fix broken HTML markup in camera and VR list templates
- **File:** `index.html:41, 46`
- **Problem:** Extra `></div>` tokens break Alpine.js template rendering, causing camera and VR list items to not render correctly.
- **Current code:**
  ```html
  <div x-text="'Camera: ' + key" :class="$store.camera.isSelected(key) && 'camera-selected'"></div>></div>
  ```
- **Fix:** Remove the stray `></div>` from both template lines (41 and 46).

### 1.2 Fix VR "red" action calling undefined store
- **File:** `assets/js/alpine.js:71`
- **Problem:** Uses `Alpine.store('currentContext')` but the correct store name is `context`. Pressing Red button in VR context throws a runtime error.
- **Current code:**
  ```js
  red(){ Alpine.store('currentContext').red(); }
  ```
- **Fix:** Change to `Alpine.store('context').actions.red()` or implement proper VR red behavior (e.g., go back to camera context).

### 1.3 Fix broken audio file path
- **File:** `assets/js/pokedex_sound.js:7`
- **Problem:** Path `../assets/sounds/SFX_PRESS_AB.wav` resolves relative to the HTML document URL, not the JS file. This causes a 404.
- **Fix:** Change to `assets/sounds/SFX_PRESS_AB.wav` (relative to document root).

### 1.4 Remove orphaned `startCamera()` that leaks a stream
- **File:** `index.html:73-83`
- **Problem:** `getUserMedia` is called on page load, requests camera permission before user intent, obtains a stream that is never stored or stopped (resource leak, camera LED stays on).
- **Fix:** Remove the entire `<script>` block (lines 73-83). Camera is properly initialized via `pokedex_ml.js:init()` when user presses A button.

### 1.5 Guard `red()` camera teardown against missing DOM
- **File:** `assets/js/alpine.js:30-34`
- **Problem:** `removeChild(document.getElementById('camera'))` throws if element doesn't exist (e.g., pressing Red before starting camera).
- **Fix:** Add null check before removing element.

### 1.6 Fix implicit global variables
- **File:** `assets/js/alpine.js:24, 32, 66`
- **Problem:** `device`, `container`, and `pokemon` are assigned without `const`/`let`, creating implicit globals on `window`. This can cause subtle bugs and is exploitable via DOM clobbering.
- **Fix:** Add `const` to all three declarations.

---

## Phase 2 — Auto Camera Selection

> **Priority:** High (user-requested) | **Effort:** ~4 hours | **Branch:** `feat/auto-camera-selection`

### 2.1 Implement smart rear camera auto-detection

**Problem:** Current flow requires users to manually scroll through a camera list using Up/Down arrow buttons and press A to select. On mobile phones with 3-4 cameras this is confusing and non-discoverable.

**Solution — Multi-strategy auto-selection:**

1. **Step 1:** Request camera with `facingMode: { ideal: "environment" }` to let the browser pick the best rear camera.
2. **Step 2:** After permission is granted, call `enumerateDevices()` to get labeled device list.
3. **Step 3:** Score each device by label matching (`back`, `rear`, `environment`, `main`, `wide`) and resolution capability.
4. **Step 4:** Select the highest-scoring device automatically.
5. **Step 5:** Persist the selected `deviceId` in `localStorage` for subsequent visits.
6. **Step 6:** Keep a "Switch Camera" option accessible via Left/Right arrows during camera mode (optional, non-blocking UX).

**Auto-selection logic (conceptual):**

```js
async function selectBestCamera() {
  // First, get permission with ideal rear camera
  const stream = await navigator.mediaDevices.getUserMedia({
    video: { facingMode: { ideal: "environment" } }
  });
  // Stop the temporary stream immediately
  stream.getTracks().forEach(track => track.stop());

  // Now enumerate devices (labels available after permission)
  const devices = await navigator.mediaDevices.enumerateDevices();
  const videoInputs = devices.filter(d => d.kind === "videoinput");

  // Score devices
  const scored = videoInputs.map((device, index) => {
    let score = 0;
    const label = (device.label || "").toLowerCase();
    if (/back|rear|environment/.test(label)) score += 10;
    if (/main|wide/.test(label)) score += 5;
    if (/ultra|macro|tele|depth|front|selfie/.test(label)) score -= 5;
    if (index === videoInputs.length - 1) score += 1; // Last device is often rear on Android
    return { device, score };
  });

  scored.sort((a, b) => b.score - a.score);
  return scored[0].device;
}
```

### 2.2 Change default UX flow: skip camera selection screen

- **Current:** User sees camera list → Up/Down to select → Press A → Camera starts.
- **New:** Press A → Camera auto-starts with best rear camera → Left/Right to switch cameras if needed.
- Update `camera_actions.a()` to call `selectBestCamera()` then `init()` directly.

### 2.3 Add camera switching with Left/Right arrows

- While camera is active (`camera.busy === true`), pressing Left/Right should cycle through available cameras.
- Stop current webcam, reinitialize with next/previous device.
- Show a brief camera name overlay on switch.

### 2.4 Persist camera preference in localStorage

- After user manually switches camera, save `deviceId` to `localStorage`.
- On next visit, check saved preference first before auto-detection.
- Clear preference if saved device is no longer available.

---

## Phase 3 — Security Hardening

> **Priority:** High | **Effort:** ~3 hours | **Branch:** `fix/security-hardening`

### 3.1 [CRITICAL] Add XSS protection to VR page URL parameter
- **File:** `vr.html:22-23`
- **Problem:** `pokemon` query parameter is read from URL and injected into DOM without validation. Allows reflected XSS via crafted URLs.
- **Fix:** Validate against an allowlist of known Pokémon IDs:
  ```js
  const allowed = ['bulbasaur','charmander','squirtle','pikachu'];
  const raw = new URLSearchParams(location.search).get('pokemon');
  const pokemon = allowed.includes(raw) ? raw : 'bulbasaur';
  ```

### 3.2 [CRITICAL] Add Subresource Integrity (SRI) to all CDN scripts
- **Files:** `index.html:19-20, 25, 84` | `vr.html:7-9`
- **Problem:** 7 external scripts loaded without integrity verification. CDN compromise = full code execution.
- **Fix:** Generate SRI hashes and add `integrity` + `crossorigin="anonymous"` to each `<script>` tag.

### 3.3 Pin Alpine.js to a specific version
- **Files:** `index.html:25`, `vr.html:9`
- **Problem:** `//unpkg.com/alpinejs` resolves to latest version. Supply chain risk + unexpected breaking changes.
- **Fix:** Pin to exact version with explicit `https://` protocol: `https://unpkg.com/alpinejs@3.14.8/dist/cdn.min.js`.

### 3.4 Fix protocol-relative URLs
- **Files:** `index.html:25`, `vr.html:9`
- **Problem:** `//unpkg.com/...` allows HTTP downgrade if page is served without HTTPS.
- **Fix:** Always use explicit `https://` prefix.

### 3.5 Add Content Security Policy meta tag
- **Files:** `index.html`, `vr.html`
- **Problem:** No CSP = no defense-in-depth against XSS or injection.
- **Fix:** Add `<meta http-equiv="Content-Security-Policy">` with restrictive policy covering `script-src`, `connect-src`, `img-src`, `media-src`.

### 3.6 Pin A-Frame Inspector to specific version
- **File:** `vr.html:13`
- **Problem:** Inspector loaded from `@master` branch (unpinned).
- **Fix:** Pin to tagged release version.

### 3.7 Remove console.log of device enumeration data
- **File:** `assets/js/alpine.js:102`
- **Problem:** Logs device metadata (deviceIds) to console. Can be used for fingerprinting.
- **Fix:** Remove the `console.log` statement.

---

## Phase 4 — Performance Optimization

> **Priority:** Medium | **Effort:** ~6 hours | **Branch:** `perf/optimizations`

### 4.1 [HIGH] Fix Rive instances recreated on every resize
- **File:** `assets/js/pokedex_ui.js:10-58`
- **Problem:** `resizeCanvas()` calls `drawStuff()` which creates 4 new `rive.Rive` instances each resize event. Memory leak and performance degradation.
- **Fix:** Initialize Rive instances once outside `resizeCanvas()`. Only update canvas dimensions and layout on resize. Debounce resize handler.

### 4.2 [HIGH] Stop requestAnimationFrame loop when camera is inactive
- **File:** `assets/js/pokedex_ml.js:34-40`
- **Problem:** `loop()` runs continuously via `requestAnimationFrame` even after `webcam.stop()`. Burns CPU/GPU and battery.
- **Fix:** Store the rAF handle (`let animationId`), cancel with `cancelAnimationFrame(animationId)` when camera stops. Add `cameraActive` flag to gate the loop.

### 4.3 Cache ML model — don't reload on every camera start
- **File:** `assets/js/pokedex_ml.js:18`
- **Problem:** `tmImage.load()` is called every time `init()` runs, re-downloading and parsing the model.
- **Fix:** Load model once and cache it. Only recreate webcam on subsequent calls.

### 4.4 Defer non-critical script loading
- **File:** `index.html:19-20, 84-89`
- **Problem:** TensorFlow.js, Teachable Machine, and Rive are loaded synchronously in `<head>` or before DOM content, blocking initial paint.
- **Fix:** Add `defer` attribute to scripts or move to end of `<body>` with proper load order. Consider lazy-loading ML libraries only when camera mode starts.

### 4.5 Reuse Audio instances instead of creating new ones
- **File:** `assets/js/pokedex_sound.js:1-4`
- **Problem:** `playSound()` creates a new `Audio` object on every call. GC pressure and slower playback.
- **Fix:** Preload audio buffers and reuse instances. Use `audio.currentTime = 0; audio.play()` pattern.

### 4.6 Cancel speech synthesis queue before speaking
- **File:** `assets/js/pokedex_speech.js:10-15`
- **Problem:** Calling `speak()` multiple times queues utterances without clearing previous ones.
- **Fix:** Call `window.speechSynthesis.cancel()` before `window.speechSynthesis.speak(speech)`.

### 4.7 Debounce window resize handler
- **File:** `assets/js/pokedex_ui.js:10`
- **Problem:** Resize fires rapidly, triggering heavy work on each event.
- **Fix:** Debounce with 150-250ms delay.

### 4.8 Use modern image formats for background
- **File:** `assets/css/main.css:6`, `assets/img/background.png`
- **Problem:** PNG background may be unnecessarily large. No responsive sizes.
- **Fix:** Provide WebP/AVIF alternatives with CSS fallback. Consider responsive `image-set()`.

---

## Phase 5 — Accessibility (WCAG 2.1 AA)

> **Priority:** Medium | **Effort:** ~8 hours | **Branch:** `feat/accessibility`

### 5.1 [CRITICAL] Replace div buttons with semantic `<button>` elements
- **File:** `index.html:57-64`
- **Problem:** All 7 Pokedex controls are `<div>` elements with `@click` handlers. Keyboard-only users cannot interact with the app at all.
- **Fix:** Replace with `<button>` elements, add `aria-label` for each (e.g., "A button - Select", "Up arrow", etc.). Style buttons to maintain the same visual appearance (transparent, no border, same grid positioning).

### 5.2 [CRITICAL] Add keyboard event handlers for Pokedex controls
- **File:** `assets/js/alpine.js` or new file
- **Problem:** No `keydown` handlers exist. Arrow keys, Enter, Space, and letter keys should map to Pokedex controls.
- **Fix:** Add global `keydown` listener mapping: Arrow keys → directional controls, Enter/Space → A button, R → Red, B → Blue.

### 5.3 Add ARIA labels and roles to canvas elements
- **File:** `index.html:30, 33, 53, 68`
- **Problem:** Canvas elements have no text alternatives. Screen readers see nothing.
- **Fix:** Add `role="img"` and `aria-label` to each canvas. For the screen canvas, use `aria-live="polite"` for dynamic content.

### 5.4 Add ARIA live region for ML predictions
- **File:** `index.html` + `assets/js/pokedex_ml.js:49-53`
- **Problem:** Predictions are only announced via speech synthesis. Screen reader users with speech disabled miss results.
- **Fix:** Add a visually hidden `<div role="status" aria-live="polite">` and update its text content when a Pokémon is detected.

### 5.5 Add visible focus indicators
- **File:** `assets/css/main.css`
- **Problem:** No focus styles defined. Keyboard users cannot see which element is focused.
- **Fix:** Add `:focus-visible` styles with a gold/yellow outline that fits the Pokedex theme.

### 5.6 Add semantic landmarks
- **File:** `index.html`
- **Problem:** No `<main>`, `<section>`, or landmark roles. Screen reader landmark navigation is impossible.
- **Fix:** Wrap in `<main>`, add `<section>` for screen and controls areas.

### 5.7 Add screen-reader-only CSS utility class
- **File:** `assets/css/main.css`
- **Fix:** Add `.sr-only` class for visually hidden but screen-reader-accessible content.

### 5.8 Add `lang="en"` to VR page
- **File:** `vr.html:2`
- **Fix:** Change `<html>` to `<html lang="en">`.

### 5.9 Use proper list semantics for camera and VR selection
- **File:** `index.html:39-48`
- **Fix:** Use `<ul role="listbox">` with `<li role="option" :aria-selected="...">` for both camera device list and Pokémon list.

### 5.10 Add `prefers-reduced-motion` support
- **File:** `assets/css/main.css`
- **Fix:** Add media query to disable/reduce Rive animations when user prefers reduced motion. Also stop Rive autoplay in JS when detected.

### 5.11 Add visual feedback for button presses
- **File:** `assets/css/main.css` + `assets/js/pokedex_sound.js`
- **Problem:** Deaf users get no feedback when pressing buttons (only audio).
- **Fix:** Add brief visual pulse/scale animation on button press.

### 5.12 Add skip navigation link
- **File:** `index.html`
- **Fix:** Add a visually hidden skip link at the top of `<body>` that jumps to controls.

---

## Phase 6 — UI/UX Improvements (Same Theme)

> **Priority:** Medium | **Effort:** ~4 hours | **Branch:** `feat/ui-improvements`

### 6.1 Show loading/prediction feedback on screen
- **File:** `assets/js/pokedex_ml.js`, `index.html`
- **Problem:** No visual feedback when model is loading or predicting. User thinks app is frozen.
- **Fix:** Add status text overlay on the black screen: "Loading model...", "Scanning...", "Detected: Bulbasaur!". Use Alpine store for state.

### 6.2 Show detected Pokémon name on screen
- **File:** `assets/js/pokedex_ml.js:49-53`
- **Problem:** Prediction result is only spoken, not shown visually.
- **Fix:** Display detected Pokémon name and confidence percentage on the screen overlay. Consider showing a Pokédex entry (number, name, type).

### 6.3 Fix mobile viewport height issues
- **File:** `assets/css/main.css:6-10`
- **Problem:** `height: 100vh` on mobile causes layout jumps when browser chrome appears/disappears.
- **Fix:** Use `min-height: 100dvh` with `100vh` fallback.

### 6.4 Show device label instead of index number in camera list
- **File:** `index.html:41`
- **Problem:** Shows "Camera: 0", "Camera: 1" — meaningless to users.
- **Fix:** Show `device.label || 'Camera ' + (key + 1)`. Labels are available after permission is granted.

### 6.5 Add camera switching indicator overlay
- **Problem:** When auto-camera is implemented, user needs to know they can switch cameras.
- **Fix:** Show a small camera icon or text hint on screen when camera is active: "← → Switch Camera".

### 6.6 Add touch target minimum sizes for mobile
- **File:** `assets/css/main.css:70-96`
- **Problem:** Button hit areas may be too small on small screens.
- **Fix:** Ensure all interactive elements have minimum 44x44px touch targets.

### 6.7 Add smooth transitions between contexts
- **Problem:** Switching between camera and VR context is instant with no transition.
- **Fix:** Add a brief fade or Pokedex-themed screen transition.

---

## Phase 7 — Code Quality & Architecture

> **Priority:** Low | **Effort:** ~4 hours | **Branch:** `refactor/code-quality`

### 7.1 Add `"use strict"` to all JavaScript files
- **Files:** All JS files in `assets/js/`
- **Problem:** No strict mode. Allows silent errors and implicit globals.
- **Fix:** Add `"use strict";` at the top of each file (or within each IIFE).

### 7.2 Remove unused variables
- **File:** `assets/js/pokedex_ui.js:7-8`
- **Problem:** `_screen_ctx` and `_screen_container` are declared but never used.
- **Fix:** Remove both declarations.

### 7.3 Clean up console.log debug statements
- **Files:** `assets/js/alpine.js:58, 61, 68, 74, 93, 94, 102, 124, 127`
- **Problem:** Multiple `console.log` statements left from development.
- **Fix:** Remove or gate behind a `DEBUG` flag.

### 7.4 Consolidate Alpine store naming
- **File:** `assets/js/alpine.js`
- **Problem:** `context` vs `currentContext` mismatch (line 71). Actions split across `camera_actions` and `vr_actions` with duplicated logic.
- **Fix:** Use consistent naming. Extract shared navigation logic (up/down cycling) into reusable function.

### 7.5 Wrap all scripts in IIFE or modules
- **Files:** `alpine.js`, `pokedex_ml.js`, `pokedex_speech.js`, `pokedex_sound.js`
- **Problem:** Global scope pollution. Functions like `init()`, `predict()`, `speak()`, `playSound()` are all global.
- **Fix:** Wrap in IIFEs (like `pokedex_ui.js` already does) or migrate to ES modules.

---

## Phase 8 — PWA & Deployment

> **Priority:** Medium | **Effort:** ~4 hours | **Branch:** `feat/pwa-improvements`

### 8.1 [HIGH] Add Service Worker for offline support
- **Problem:** Manifest exists but no service worker. App doesn't work offline and fails PWA install criteria.
- **Fix:** Create `sw.js` with cache-first strategy for static assets (HTML, CSS, JS, images, sounds, Rive file, ML model). Register in `index.html`.

### 8.2 Create proper maskable icon
- **File:** `manifest.json:23-32`
- **Problem:** Same icon file used for regular and maskable purposes. Maskable icons need safe zone padding.
- **Fix:** Create a dedicated maskable icon with proper safe zone (40% padding from edges).

### 8.3 Restrict GitHub Actions to main branch
- **File:** `.github/workflows/build.yml:2`
- **Problem:** `on: push` triggers deployment on every branch push. Any feature branch overwrites production.
- **Fix:** Change to `on: push: branches: [main, html]`.

### 8.4 Update GitHub Actions versions
- **File:** `.github/workflows/build.yml:8, 10`
- **Problem:** `actions/checkout@v2` (EOL Node.js 12) and `github-pages-deploy-action@4.1.4` are outdated.
- **Fix:** Update to `actions/checkout@v4` and `JamesIves/github-pages-deploy-action@v4`. Consider pinning to commit SHAs.

---

## Phase 9 — Dependency Updates

> **Priority:** Medium | **Effort:** ~6 hours | **Branch:** `chore/update-dependencies`

### 9.1 Update TensorFlow.js (1.3.1 → 4.x)
- **File:** `index.html:19`
- **Problem:** v1.3.1 is from 2019, 5 major versions behind. Known security issues.
- **Risk:** Teachable Machine `@0.8` may need updating too for compatibility.
- **Fix:** Update both libraries together. Test model loading and prediction accuracy.

### 9.2 Update Rive runtime (0.7.30 → latest)
- **File:** `index.html:84`
- **Problem:** Rive JS v0.7.30 is significantly outdated. API may have changed.
- **Fix:** Update and adapt code to new Rive API if needed.

### 9.3 Update A-Frame (1.2.0 → latest)
- **File:** `vr.html:7-8`
- **Problem:** A-Frame 1.2.0 is outdated. Performance and WebXR improvements available.
- **Fix:** Update A-Frame and aframe-extras. Test 3D model rendering.

---

## Appendix — File-by-File Issues Map

### `index.html`
| Line | Issue | Phase | Severity |
|------|-------|-------|----------|
| 19-20 | No SRI on TF.js scripts | 3 | Critical |
| 25 | Unpinned Alpine.js, protocol-relative URL | 3 | High |
| 41 | Broken HTML `></div>` | 1 | High |
| 46 | Broken HTML `></div>` | 1 | High |
| 57-64 | Divs as buttons, no ARIA | 5 | Critical |
| 73-83 | Orphaned startCamera() leaks stream | 1 | High |
| 84 | Outdated Rive, no SRI | 3, 9 | Medium |

### `vr.html`
| Line | Issue | Phase | Severity |
|------|-------|-------|----------|
| 2 | Missing `lang="en"` | 5 | Low |
| 7-9 | No SRI, outdated A-Frame | 3, 9 | Medium |
| 9 | Unpinned Alpine.js | 3 | High |
| 13 | Inspector from `@master` | 3 | Medium |
| 22-23 | XSS via URL parameter | 3 | Critical |

### `assets/js/alpine.js`
| Line | Issue | Phase | Severity |
|------|-------|-------|----------|
| 24, 32, 66 | Implicit globals (missing const/let) | 1 | Medium |
| 30-34 | No null check on DOM removal | 1 | Medium |
| 43-62 | Manual camera selection UX | 2 | High |
| 71 | Wrong store name `currentContext` | 1 | High |
| 102 | Device data logged to console | 3 | Medium |

### `assets/js/pokedex_ml.js`
| Line | Issue | Phase | Severity |
|------|-------|-------|----------|
| 7 | Global variables `model`, `webcam`, etc. | 7 | Low |
| 18 | Model reloads on every init | 4 | Medium |
| 34-39 | rAF loop never stops | 4 | High |
| 43-54 | No visual prediction feedback | 6 | Medium |

### `assets/js/pokedex_ui.js`
| Line | Issue | Phase | Severity |
|------|-------|-------|----------|
| 7-8 | Unused variables | 7 | Low |
| 10-28 | Rive recreated on resize | 4 | High |

### `assets/js/pokedex_sound.js`
| Line | Issue | Phase | Severity |
|------|-------|-------|----------|
| 1-4 | New Audio on every play | 4 | Medium |
| 7 | Wrong relative path `../assets/` | 1 | High |

### `assets/js/pokedex_speech.js`
| Line | Issue | Phase | Severity |
|------|-------|-------|----------|
| 8 | Voice may be undefined on init | 7 | Low |
| 10-16 | No queue cancellation | 4 | Low |

### `assets/css/main.css`
| Line | Issue | Phase | Severity |
|------|-------|-------|----------|
| 6-10 | `100vh` mobile issues | 6 | Low |
| — | No focus indicators | 5 | High |
| — | No `prefers-reduced-motion` | 5 | Low |
| — | No `.sr-only` utility | 5 | Medium |

### `.github/workflows/build.yml`
| Line | Issue | Phase | Severity |
|------|-------|-------|----------|
| 2 | Deploys on all branches | 8 | High |
| 8 | `actions/checkout@v2` outdated | 8 | High |
| 10 | Deploy action outdated | 8 | Medium |

### `manifest.json`
| Line | Issue | Phase | Severity |
|------|-------|-------|----------|
| — | No service worker | 8 | High |
| 23-32 | Fake maskable icons | 8 | Low |

---

## Recommended Execution Order

```
Week 1: Phase 1 (Critical Bugs) + Phase 2 (Auto Camera)
Week 2: Phase 3 (Security) + Phase 4 (Performance)
Week 3: Phase 5 (Accessibility) + Phase 6 (UI/UX)
Week 4: Phase 7 (Code Quality) + Phase 8 (PWA) + Phase 9 (Dependencies)
```

Each phase should be implemented as a short-lived feature branch merged to `html` (trunk) via PR.
