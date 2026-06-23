# SlackowWall vs. ToolScreen — Gap Analysis

> **Purpose:** Catalog what ToolScreen (the dominant Windows MCSR utility) does that SlackowWall does not, then decide whether a fresh macOS port of ToolScreen or continued investment in SlackowWall is the better path.
>
> **Sources:** ToolScreen — [`jojoe77777/Toolscreen`](https://github.com/jojoe77777/Toolscreen) (Windows, C++, cloned & read at `/tmp/Toolscreen`). SlackowWall — this repo.
>
> **Date:** 2026-06-22

---

## 0. TL;DR

ToolScreen and SlackowWall solve overlapping problems with **fundamentally different architectures**, and that architecture is the source of almost every feature gap:

- **ToolScreen injects a DLL into the Minecraft process** and hooks OpenGL + Win32 input. It renders *inside the game window*, resizes the game instantly, remaps keys before the game sees them, and mirrors arbitrary screen regions — all on one screen, no OBS projectors, never leaving fullscreen.
- **SlackowWall is an external macOS app.** It captures instances via ScreenCaptureKit and shows them in **separate projector/wall windows**. It cannot draw inside Minecraft, cannot inject input, and cannot resize the game's render buffer the way ToolScreen does.

The practical result: SlackowWall is a strong **multi-instance wall + measurement-projector + Ninjabrain glue** tool. ToolScreen is a strong **single-instance in-game overlay/mode/mirror engine**. They are *not* the same product, and the gaps below are mostly things macOS's sandbox makes hard, not things nobody got around to.

**The specific feature you asked about — a custom crosshair at screen-center in eye-measure mode for the damageless dragon perch — is a real gap.** ToolScreen gets it for free from its general "image overlay anchored to screen center, assigned per-mode" system. SlackowWall has no equivalent (see §3).

---

## 1. Architecture: the root of most gaps

| | **ToolScreen (Windows)** | **SlackowWall (macOS)** |
|---|---|---|
| Model | DLL injected into MC process | External app, no injection |
| Rendering | Hooks OpenGL (`glFlush`/`SwapBuffers`), draws **in the game window** | ScreenCaptureKit → draws in **separate windows** |
| Resizing | Calls MC's `setGameWindowSize()` (1.13+), instant | Resizes the OS window only; cannot restretch render buffer the same way |
| Input | Hooks Win32 messages → remap keys **before MC sees them** | CGEvent tap for **mouse sensitivity only**; no key remap into MC |
| Streaming | Renders into OBS Game Capture; OBS Virtual Camera output | OBS Lua script switches scenes; capture is window-mirroring |
| "Only on my screen" overlays | Yes — overlay visible to runner but not OBS | N/A (overlays are separate windows) |
| Install friction | DLL injection → Defender exclusions, AV false positives | Screen Recording permission prompt |

**Why it matters:** "draw a crosshair on the game," "remap keys per game-state," "instant fullscreen↔thin resize," and "one-screen no-OBS workflow" all fall out of injection. On macOS, injecting into a Java process and hooking Metal/OpenGL is the hard, fragile part — and it's exactly what SlackowWall deliberately avoids.

---

## 2. Feature-by-feature gap table

Legend: ✅ has it · ⚠️ partial/different · ❌ missing

| Capability | ToolScreen | SlackowWall | Notes |
|---|:---:|:---:|---|
| **In-game overlays (drawn on MC window)** | ✅ | ❌ | SlackowWall draws in separate windows only |
| **Image overlays, free position/anchor, per-mode** | ✅ | ❌ | Anchors: corners, **center**, viewport, pie regions; opacity, crop, color-key, border |
| **Custom center crosshair for measure/perch** | ✅ (via center image overlay) | ❌ | See §3 — your specific ask |
| **Window overlays (embed any window in-game)** | ✅ | ⚠️ | SW shows Ninbot/Paceman as their own windows, not embedded |
| **Browser/HTML overlays (CEF) w/ CSS injection** | ✅ | ❌ | |
| **Mode system / presets w/ instant resize** | ✅ | ⚠️ | SW has Base/Wide/Thin/Tall/Reset modes + resize, but no in-buffer stretch, no math-expression dims |
| **Mode dimensions via math expressions** | ✅ | ❌ | e.g. `roundEven(screenWidth/8)` |
| **Screen mirroring / capture zones (arbitrary regions)** | ✅ | ⚠️ | SW mirrors whole instance windows; no sub-region capture-zone compositor |
| **Mirror groups, gradients, animated transitions** | ✅ | ❌ | |
| **EyeZoom (magnified crosshair strip)** | ✅ | ⚠️ | SW Eye Projector + new Dynamic Overlay is the analog; ToolScreen's is in-game |
| **Numbered eye overlay (configurable cols/colors/decades)** | ✅ | ✅ | **SW's new Dynamic Eye Overlay is at parity here** |
| **Key rebinding / remap into MC (per game-state layers)** | ✅ | ❌ | Default/CursorFree/CursorGrabbed layouts, split trigger/type |
| **Hotkey system w/ game-state conditions** | ✅ | ⚠️ | SW has keybinds + modifier blocking, but no game-state-conditional hotkeys |
| **Per-mode mouse sensitivity override** | ✅ | ⚠️ | SW has tall-mode + BoatEye sensitivity scaling; not arbitrary per-mode |
| **Sensitivity hotkeys (temp override)** | ✅ | ❌ | |
| **Custom cursors per game-state + cursor trail** | ✅ | ❌ | SW has lock-icon customization, not cursors |
| **Ninjabrain Bot — rich in-overlay rendering (API)** | ✅ | ⚠️ | SW integrates Ninbot deeply (auto-launch, API, **auto-fix settings**, green offset overlay) but renders Ninbot's own window, not a styled in-game panel |
| **Config profiles w/ per-section overrides + sharing** | ✅ | ⚠️ | SW has profiles; no per-section override / debug-upload share link |
| **Themes / appearance customization** | ✅ | ❌ | Catppuccin/Dracula/Nord/etc. |
| **Multi-language** | ✅ (en/zh/pt) | ❌ | |
| **Multi-instance wall (grid of many instances)** | ❌ | ✅ | **SlackowWall's core strength — ToolScreen is single-instance** |
| **Reset-style management (Wall/Lock/Multi modes)** | ❌ | ✅ | SW exclusive |
| **Auto world clearing** | ❌ | ✅ | SW exclusive |
| **Mod detection / legal-mod validation & update** | ❌ | ✅ | SW exclusive (mcsr-meta) |
| **Quick Launch (Prism instances)** | ❌ | ✅ | SW exclusive |
| **Pie projector + E-count + flatten** | ❌ | ✅ | SW exclusive |
| **Paceman integration** | ❌ | ✅ | SW exclusive |

### What ToolScreen has that SlackowWall lacks (the gap list)
1. **In-game overlays of any kind** (image / window / browser) — the biggest single gap, and the parent of #2.
2. **Free-anchored image overlays assigned per mode** → custom center crosshair, custom Ninbot image, decorative UI.
3. **Key rebinding/remapping into Minecraft**, with per-game-state layers.
4. **Game-state-conditional hotkeys** (only fire on title/wall/in-world/cursor-grabbed, via Hermes/State Output).
5. **Arbitrary capture-zone mirroring** (sub-regions, mirror groups, gradients, transitions).
6. **Browser/HTML + window-embed overlays.**
7. **Per-mode sensitivity overrides + sensitivity hotkeys.**
8. **Custom cursors + cursor trails.**
9. **Math-expression mode dimensions + in-buffer stretch.**
10. **Polish layer:** themes, i18n, per-section config profiles, debug-share upload.

### What SlackowWall has that ToolScreen lacks
The entire **wall manager** category: multi-instance grid, reset/lock/multi modes, world clearing, mod validation/update, Quick Launch, pie projector, Paceman. ToolScreen is not a wall tool at all.

---

## 3. Deep dive: the center crosshair for the damageless dragon perch

**What you described:** a custom crosshair fixed at the exact center of the screen during eye-measure mode, used as an aim reference for the damageless / one-cycle dragon perch.

**How ToolScreen does it:** there is **no feature literally called "crosshair"** (the only `crosshair` string in the codebase is a *cursor shape* option in `tab_inputs.inl` / `tab_mouse.inl`). Instead it falls out of two general systems:

1. **Image overlays** (`src/gui/tabs/tab_images.inl`) support a `relative-to` **anchor including "screen center"**, plus pixel X/Y offset, scale, opacity, color-keying, and an **"only on my screen"** flag.
2. **Overlays are assigned per mode** (`[[mode]]` in `src/config/default.toml`). So a runner drops a small crosshair/dot PNG, anchors it dead-center, and attaches it only to the EyeZoom (or a custom "perch") mode.

Result: a pixel-perfect, always-centered reticle that appears exactly when measuring/perching and is invisible in OBS. ToolScreen didn't build a "dragon crosshair" — it built a generic center-anchored overlay engine, and the community uses it for that.

**SlackowWall today:** no center-anchored custom-image overlay. The closest primitives:
- Eye Projector **center line** (the vertical divider in the Dynamic Eye Overlay) — but that's a thin line inside the *projector window*, not a free crosshair over the game at screen center.
- Ninbot **green offset overlay** rectangle — positional, but Ninbot-driven, not a static aim reticle.

**Smallest path to parity *within* SlackowWall's architecture:** because SW can't draw on the MC window, a "crosshair" would be a **borderless, click-through, always-on-top NSWindow** centered on the Minecraft window (the Resize Background feature at `Features/ResizeBackground/` already does click-through always-on-top window positioning — it's a near-perfect template). Add a "Center Crosshair" utility: custom image or built-in shapes (cross/dot/circle), size, color, opacity, optional gap, shown only in Tall/measure mode. This is genuinely achievable on macOS and is the highest-value, lowest-architecture-risk item in this whole document.

---

## 4. Recommendation — port vs. improve

### The core tension
The ToolScreen gaps cluster into two buckets:
- **Bucket A — needs in-game injection** (in-game overlays, key remap into MC, capture-zone mirroring, in-buffer stretch). On macOS this means injecting into the Java process and hooking Metal/OpenGL + Quartz event taps. High effort, fragile across MC/macOS/Java updates, code-signing/notarization headaches, and a permanent maintenance tax.
- **Bucket B — does NOT need injection** (center crosshair via overlay window, themes, per-mode sensitivity, more hotkey conditions, profile polish, i18n). These are normal app features SlackowWall can add incrementally.

### Honest read
- A **from-scratch macOS port of ToolScreen** would be a *new, hard, injection-based project* (rough order-of-magnitude: **1–2+ months** for an experienced macOS/Metal/C++ dev just to reach a fragile MVP, then ongoing breakage maintenance). It would also **throw away** SlackowWall's genuinely-unique and working wall/reset/mod/world-clearing stack, which ToolScreen does not have and Mac runners still need.
- **Most of what makes ToolScreen feel "so far ahead" to a Mac user is Bucket B + the in-game *feel*.** The single most-requested concrete item here (center crosshair) is Bucket B and is days, not months, of work.

### Recommended path: **improve SlackowWall, don't port (yet)**
1. **Now / quick wins (Bucket B):**
   - Center Crosshair overlay window (§3) — highest value, lowest risk.
   - Per-mode sensitivity overrides + a sensitivity hotkey.
   - Game-state-conditional hotkeys (State Output mod is already detected).
   - Generic **center/anchor image-overlay window** (generalize the crosshair work → also covers custom Ninbot image, decorative overlays).
2. **Medium term:** themes, profile per-section overrides, polish.
3. **Only consider an injection layer (Bucket A) if** Mac runners specifically demand true in-game overlays / key-remap-into-MC and the overlay-window approach proves insufficient. Treat that as a **separate spike/prototype** (can MC's Metal context be hooked safely & legally for MCSR?) **before** committing — it's the make-or-break risk, and it's the only thing that actually requires "a new app."

### One-line answer
Don't scrap SlackowWall to port ToolScreen. **Close the Bucket-B gaps inside SlackowWall (starting with the center crosshair), and gate any injection-based "new app" decision behind a small, dedicated feasibility spike** — because that injection layer, not the feature list, is the real cost.

---

## Appendix — file pointers

**ToolScreen (`/tmp/Toolscreen`):** `README.md`; `src/config/default.toml` (`[eyezoom]`, `[[mode]]`, `[[mirror]]`, `[[image]]`); `src/gui/tabs/` (`tab_images.inl`, `tab_modes.inl`, `tab_mirrors.inl`, `tab_inputs.inl`, `tab_hotkeys.inl`, `tab_ninjabrain_overlay.inl`); `src/hooks/`, `src/render/`, `src/bootstrap/dllmain.cpp`; `lang/en.json`.

**SlackowWall (this repo):** `Features/Capture/` (wall, grid, ScreenCaptureKit engine), `Features/Projector/` (eye/pie, `DynamicEyeOverlay.swift`), `Features/Settings/Models/Sections/` (Behavior/Instance/Mode/Utility/Keybind/Personalize), `Features/Keybinds/`, `Features/SensitivityScaling/`, `Features/Ninbot/`, `Features/ResizeBackground/` (click-through overlay-window template), `Features/ModCheck/`, `Features/InstanceFunctions/WorldClearing.swift`, `Features/QuickLaunch/`, `Features/Paceman/`, `Features/OBS/`.
