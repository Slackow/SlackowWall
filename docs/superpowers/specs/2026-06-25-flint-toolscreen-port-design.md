# Flint — A macOS Port of ToolScreen (Master Design)

> **Status:** Approved design, pre-implementation
> **Date:** 2026-06-25
> **Companion doc:** [`docs/TOOLSCREEN_GAP_ANALYSIS.md`](../../TOOLSCREEN_GAP_ANALYSIS.md)

---

## 1. Summary

**Flint** is a standalone macOS app that ports [ToolScreen](https://github.com/jojoe77777/Toolscreen)'s
feature set to the Mac. Where SlackowWall is a multi-instance *wall* manager, Flint is a
**single-instance in-game overlay / mode / input engine** — the macOS answer to ToolScreen.

The name is deliberate: **Flint & Steel** is a Minecraft item, and "flint" is the spark that
starts the fire.

### What it is

A single-instance companion that binds to one Minecraft window and provides: custom overlays
(crosshair, images, EyeZoom, numbered eye, mirrors), a mode system (resize + per-mode presets),
key remapping into Minecraft, game-state hotkeys, per-mode sensitivity, custom cursors, and
Ninjabrain integration — all configured ToolScreen-style.

### What it is NOT

Not a wall tool. The entire SlackowWall wall/reset/lock/multi/world-clearing/mod-validation/
Quick-Launch/pie/Paceman stack is **out of scope** and stripped during bootstrap.

---

## 2. Architecture decision: external overlay windows, no injection

ToolScreen on Windows injects a DLL into the Minecraft process and hooks OpenGL + Win32 input.
**Flint deliberately does NOT inject.** Instead it uses external, OBS-invisible overlay windows
plus a system-level event tap.

### Rationale

- **Injection on macOS is the wrong hill.** A native `.dylib` inject is fought by SIP, hardened
  runtime, and library validation (often requires the user to disable SIP — a non-starter for
  distribution), and hooking deprecated OpenGL / Metal is fragile across macOS/Java/MC updates.
  It would prevent ever finishing a *full* port.
- **macOS gives us the two things injection seemed necessary for, for free:**
  - **OBS-invisibility** → `NSWindow.sharingType = .none` excludes a window from ScreenCaptureKit,
    which is what OBS uses on macOS. Overlays are visible to the runner, invisible in OBS/recordings.
  - **Key-remap-before-Minecraft** → a `CGEvent` tap can swallow and re-post key events
    system-wide before Minecraft's input loop sees them. SlackowWall already runs a CGEvent tap
    for mouse sensitivity, so this is proven in-stack.
- **The only real casualty** is drawing literally inside a *true-fullscreen* macOS Space. This is
  solved by running Minecraft **borderless-windowed** (standard MCSR practice), letting a floating
  overlay window sit cleanly on top.

Net: an external architecture reaches ~95% of ToolScreen's actual behavior, **legally and
shippably**, on macOS.

### Legality note

MCSR legality tracks **what a tool does**, not how it is delivered. ToolScreen-style overlays are
already accepted in MCSR. Flint is an **external screen tool** (like SlackowWall and ToolScreen
itself), **not a Fabric mod**, so it is not governed by the legal-mods list and needs no per-version
mod approval. Features that would confer an unfair advantage are out of scope by definition; the
crosshair/measure overlays mirror ToolScreen's already-accepted behavior.

---

## 3. Bootstrap

**Approach: fork & strip SlackowWall** into a new Flint project.

### Reuse (the valuable plumbing — "the best part")

- **ScreenCaptureKit capture** (`Features/Capture/`) — locating, capturing, and frame-tracking the
  MC window. Keep the engine; drop the multi-instance/wall layer.
- **CGEvent tap** (`Features/SensitivityScaling/`) — system-wide input interception. Foundation for
  key remapping and per-mode sensitivity.
- **Click-through overlay window** (`Features/ResizeBackground/`) — borderless, always-on-top,
  click-through `NSWindow` positioning. The template for every Flint overlay; add `sharingType = .none`.
- **Settings / profile infrastructure** and **Ninbot integration** (`Features/Ninbot/`).
- The **Dynamic Eye Overlay** (`Features/Projector/DynamicEyeOverlay.swift`) — already at parity with
  ToolScreen's numbered eye overlay.

### Strip (out of scope)

Wall grid, reset/lock/multi modes, world clearing, mod validation/update, Quick Launch, pie
projector, Paceman.

### Repository / path

- New Flint lives at a **fresh path** (e.g. `~/projects/Flint`), a new git repo, new Xcode project.
- The existing **`~/projects/flint`** is an unrelated, outdated **Tauri (Rust + Vite/TS)** prototype.
  It is **not reused**. It will be **archived (renamed, e.g. `~/projects/flint-tauri-archive`), not
  deleted** — preserved in case anything is worth mining later. No destructive action without
  explicit user confirmation.

---

## 4. Foundation layer

Every subsystem sits on these four primitives.

### 4a. Instance binding

Flint locks onto a single Minecraft window via ScreenCaptureKit and continuously tracks its frame
(position + size). One source of truth: the current **MC window rect**. Overlays and modes anchor
to it.

### 4b. The overlay window primitive

A reusable `OverlayWindow`: borderless, click-through, always-on-top, `sharingType = .none`
(invisible to OBS/SCK), positioned relative to the MC window rect. Every visual feature is a
**content view** hosted in an `OverlayWindow`. Anchor model (matching ToolScreen): corners, **center**,
viewport, plus pixel X/Y offset.

### 4c. The input layer

A general input engine extending the CGEvent tap to: (a) remap keys before MC sees them, (b) apply
per-mode mouse sensitivity, (c) fire hotkeys — all gated by **game-state** (title / in-world /
cursor-grabbed), using the state signal SlackowWall already detects.

### 4d. Config core

A TOML/JSON config mirroring ToolScreen's structure (`[[mode]]`, `[[image]]`, `[[mirror]]`,
`[eyezoom]`, hotkeys, profiles) so ToolScreen users feel at home — plus a SwiftUI settings UI reusing
SlackowWall's settings infrastructure.

---

## 5. Overlay subsystems

All hosted in the `OverlayWindow` primitive (4b).

### 5a. Image overlays *(parent feature)*

Drop any PNG; anchor it (corners / center / viewport / pixel offset); with scale, opacity, crop,
color-key (chroma transparency), and border. Assignable per-mode. ToolScreen's `[[image]]` system.

### 5b. Center crosshair *(headline win)*

Not a special feature — an image overlay anchored dead-center, **plus** built-in vector shapes
(cross / dot / circle, with gap) so no PNG is required. Configurable size, color, opacity, gap.
Attach to the perch/measure mode → appears exactly when measuring, invisible in OBS. Falls out of 5a.

### 5c. EyeZoom

A magnified strip of the screen center (eye-measure zoom) rendered in an `OverlayWindow`, reusing
SlackowWall's eye-projector math but composited in place over the game.

### 5d. Numbered eye overlay

Configurable columns / colors / decade markers. Port of SlackowWall's `DynamicEyeOverlay` — already
at parity with ToolScreen.

### 5e. Mirrors / capture-zones *(heaviest visual subsystem — lower priority)*

Mirror an arbitrary screen sub-region into an overlay, with mirror groups, gradients, and animated
transitions. Real-time region capture + compositing. Spec'd, but flagged highest-effort and a
candidate to slip.

### 5f. Window & browser embeds *(lowest priority / best-effort)*

ToolScreen embeds arbitrary windows and CEF/HTML overlays. macOS semantics differ:
- **Window "embed"** → position/style an existing app window (e.g. Ninbot) rather than true embedding.
- **Browser overlay** → `WKWebView` in an `OverlayWindow` with CSS injection.

Least-used features; spec'd as best-effort.

---

## 6. Modes, input & polish

### 6a. Mode system *(the spine)*

ToolScreen's `[[mode]]`. A mode = a named preset that sets MC window dimensions **and** the active
overlays / sensitivity / keymaps. Base / Wide / Thin / Tall / Reset + custom modes. Dimensions
support **math expressions** (e.g. `roundEven(screenWidth/8)`) via a small expression evaluator.
Switching a mode resizes the MC window (OS-level resize, as SlackowWall does) and swaps the active
overlay/input set instantly.

### 6b. Key rebinding / remap into MC

Per-game-state key layers (Default / CursorFree / CursorGrabbed), split trigger/type, via the CGEvent
tap (4c). The "remap before MC sees it" capability.

### 6c. Game-state hotkeys

Hotkeys that only fire in specific states (in-world, cursor-grabbed, etc.), using the same state
signal SlackowWall detects.

### 6d. Sensitivity

Per-mode mouse-sensitivity overrides + temporary sensitivity hotkeys, extending SlackowWall's
existing sensitivity scaling.

### 6e. Custom cursors

Per-game-state cursor image + optional cursor trail.

### 6f. Ninjabrain overlay

Port SlackowWall's deep Ninbot integration (auto-launch, API, auto-fix settings, green offset
overlay), rendered through Flint's overlay engine.

### 6g. Polish layer *(lowest priority)*

Config profiles with per-section overrides; themes (Catppuccin / Dracula / Nord / etc.); i18n
scaffolding (English first, structure for more).

---

## 7. Build order

The spec covers the full port; implementation layers in this order:

1. **Foundation** (4a–4d) — binding, overlay window, input engine, config.
2. **Crosshair + image overlays** (5a–5b) — first usable win.
3. **Mode system** (6a) — the spine that ties overlays/input together.
4. **Eye stack** (5c–5d) + **input/sensitivity** (6b–6d).
5. **Ninbot** (6f) + **cursors** (6e) + **game-state hotkeys** (6c).
6. **Heavy / optional**: mirrors (5e), window/browser embeds (5f).
7. **Polish**: profiles, themes, i18n (6g).

---

## 8. Testing strategy

- **Unit-testable cores** (no UI / no live MC): the math-expression evaluator (6a), anchor → frame
  geometry (4b), config parse/serialize round-trips (4d), game-state derivation (4c). These are the
  primary automated-test targets.
- **Manual / harness verification** for capture, overlay rendering, OBS-invisibility
  (`sharingType = .none` confirmed by capturing the screen and asserting the overlay is absent), and
  event-tap remapping — these depend on a live MC window and the macOS window server.
- Each subsystem ships behind its config flag so it can be exercised in isolation.

---

## 9. Out of scope (explicit)

- DLL/dylib injection into the Minecraft process; hooking OpenGL/Metal in-process.
- Fabric/Forge mod delivery.
- The entire SlackowWall wall-manager category (see §3 strip list).
- True in-buffer render-stretch (only OS-level window resize is supported).
- Any feature conferring an unfair MCSR advantage beyond ToolScreen's accepted behavior.

---

## 10. Key risks

| Risk | Mitigation |
|---|---|
| Floating overlay vs. macOS fullscreen Spaces | Require borderless-windowed MC (standard MCSR practice). |
| `sharingType = .none` not honored by some capture path | Verify early against OBS + raw SCK; it is the load-bearing assumption for "only on my screen." |
| Mirrors/capture-zones (5e) too heavy | Lowest priority; allowed to slip without blocking a "complete" port. |
| Event-tap permissions (Accessibility / Input Monitoring) | Reuse SlackowWall's existing permission-prompt flow. |
| Scope ("everything at once") stalling | Strict build order (§7); each layer ships independently usable. |
