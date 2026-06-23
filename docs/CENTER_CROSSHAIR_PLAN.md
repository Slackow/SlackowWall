# Feature Plan — Center Crosshair Overlay (eye-measure / dragon perch)

> **Goal:** A customizable crosshair pinned to the center of the Minecraft window, shown during eye-measure (Tall) mode, as an aim reference for the damageless / one-cycle dragon perch. ToolScreen achieves this with a center-anchored in-game image overlay; SlackowWall will achieve the same effect with a click-through always-on-top overlay window floated over the game.
>
> **Date:** 2026-06-22 · **Status:** proposed

---

## 1. Is this possible on macOS? — Yes (the easy way), with one caveat

There are two ways to put a crosshair "on" Minecraft. Be clear about which:

### Approach A — Overlay window floated over the game ✅ **(recommended, fully possible)**
A borderless, non-activating, click-through `NSPanel` positioned at the center of the Minecraft window and ordered just above it. **This is already proven in this codebase** — `ResizeBackgroundManager` does exactly this (a borderless `NSPanel`, `ignoresMouseEvents = true`, ordered relative to the MC window via CGWindow z-order). The only differences for a crosshair are: order **above** the game instead of below, and center on the **window frame** instead of filling the screen.

- **Pros:** 100% native, no entitlements beyond what SlackowWall already uses, no injection, survives MC/macOS updates, MCSR-legal (it's an external overlay, same class as OBS/Ninbot windows).
- **Cons / caveats:**
  - **It will appear in OBS / screen capture** unless excluded — there is no macOS "only on my screen" equivalent to ToolScreen's flag. Mitigations: set `window.sharingType = .none` (hides it from ScreenCaptureKit/most capture paths), and/or document an OBS window-capture exclusion. For a *perch aim reference* this is usually fine (you want it only on your screen, and `.sharingType = .none` gives that).
  - It floats **above** the game, so if the runner alt-tabs the panel must hide/reorder (the ResizeBackground code already tracks target PID + window presence and handles teardown — reuse it).
  - Pixel-exact centering depends on the AX-reported window frame (already used via `WindowController.getWindowPosition/Size`). Fine for an aim dot; we also add manual X/Y offset for calibration (perch reference is often a few px off true center).

### Approach B — True in-game overlay via injection ❌ **(not worth it here)**
Drawing *inside* MC's render pass (like ToolScreen's DLL+OpenGL hook) would require injecting into the Java process and hooking Metal/OpenGL on macOS. Possible in theory, but fragile, notarization-hostile, and massive overkill for a crosshair. **Do not do this for this feature.** (It's the Bucket-A decision discussed in `TOOLSCREEN_GAP_ANALYSIS.md` §4 and should stay gated behind its own spike.)

**Conclusion:** Approach A is straightforward and is what this plan implements.

---

## 2. Reused building blocks (already in the repo)

| Need | Existing symbol | File |
|---|---|---|
| Click-through borderless overlay panel | `ResizeBackgroundManager` / `ResizeBackgroundWindow` | `Features/ResizeBackground/ResizeBackgroundManager.swift` |
| MC window position & size (AX) | `WindowController.getWindowPosition(pid:)`, `getWindowSize(pid:)` | `WindowController` |
| Enter/exit eye-measure mode hook | `ShortcutManager.resizeTall()` and the "exiting tall" branch in `resize(...)` (`eyeProjectorOpen` toggling) | `Features/Keybinds/ViewModels/ShortcutManager.swift` |
| Window-id registry | `SWWindowID`, `NSApp.getWindow(_:)` | `Utils/Extensions/NSApplication+Ext.swift` |
| Persisted RGB color | `CodableColor` (added on this branch) | `Utils/CodableColor.swift` |
| Color binding helper for SwiftUI | `colorBinding(_:)` (added on this branch) | `UtilitySettings.swift` |
| Settings card UI patterns | `SettingsToggleView`, `SettingsLabel`, `SettingsSliderView`, `ColorPicker` | `UtilitySettings.swift` |

The crosshair is essentially **"ResizeBackground, but centered and ordered above, with a shape view instead of an image."**

---

## 3. Settings to add (`Preferences.UtilitySection`)

Add to `Features/Settings/Models/Sections/UtilitySection.swift` (defaults chosen for a typical perch reference):

```swift
// Center crosshair overlay (eye-measure / dragon perch)
var eyeCrosshairEnabled: Bool = false
var eyeCrosshairStyle: CrosshairStyle = .cross      // cross | dot | circle | crossDot | customImage
var eyeCrosshairImage: URL? = nil                    // used when style == .customImage
var eyeCrosshairColor: CodableColor = CodableColor(r: 0, g: 1, b: 0)   // green
var eyeCrosshairSize: Double = 20        // px (overall extent)
var eyeCrosshairThickness: Double = 2    // px (line width for cross/circle)
var eyeCrosshairGap: Double = 4          // px (center gap for cross)
var eyeCrosshairOpacity: Double = 1.0
var eyeCrosshairOffsetX: Double = 0      // px fine-calibration from true center
var eyeCrosshairOffsetY: Double = 0
var eyeCrosshairOnlyInTallMode: Bool = true   // show only in eye-measure mode
var eyeCrosshairHideFromCapture: Bool = true  // window.sharingType = .none
```

New enum (next to the section, mirror existing enum style):

```swift
enum CrosshairStyle: String, Codable, CaseIterable, Identifiable {
    case cross, dot, circle, crossDot, customImage
    var id: String { rawValue }
    var label: String { … }   // "Cross", "Dot", "Circle", "Cross + Dot", "Custom Image"
}
```

> Reusing `CodableColor` here is the payoff from this branch's dynamic-overlay work — no new persistence code.

---

## 4. New files

### `Features/Crosshair/CrosshairOverlayView.swift`
A pure SwiftUI `Canvas` (or `ZStack` of `Path`s) that draws the selected style. Stateless — driven by the settings values passed in. Sketch:

```swift
struct CrosshairOverlayView: View {
    let style: CrosshairStyle
    let color: Color
    let size: CGFloat
    let thickness: CGFloat
    let gap: CGFloat
    let opacity: Double
    let image: NSImage?

    var body: some View {
        Canvas { ctx, canvasSize in
            let c = CGPoint(x: canvasSize.width/2, y: canvasSize.height/2)
            switch style {
                case .cross, .crossDot: drawCross(ctx, center: c)   // 4 arms with center gap
                case .dot:              drawDot(ctx, center: c)
                case .circle:           drawCircle(ctx, center: c)
                case .customImage:      break // image drawn via overlay Image()
            }
            if style == .crossDot { drawDot(ctx, center: c) }
        }
        .frame(width: size, height: size)
        .opacity(opacity)
        .allowsHitTesting(false)
    }
}
```

### `Features/Crosshair/CrosshairManager.swift`
A singleton modeled almost line-for-line on `ResizeBackgroundManager`, with these deltas:

- **Window:** borderless `.nonactivatingPanel`, `ignoresMouseEvents = true`, `level = .floating` (or `.statusBar`), `collectionBehavior` same as ResizeBackground, `hasShadow = false`, `backgroundColor = .clear`, `isOpaque = false`. Identifier: add `case crosshair = "crosshair-window"` to `SWWindowID`.
- **`sharingType`:** if `eyeCrosshairHideFromCapture`, set `window.sharingType = .none`.
- **Frame:** center on the MC window, not the screen:

  ```swift
  guard let pos = WindowController.getWindowPosition(pid: pid),   // AX top-left origin
        let mcSize = WindowController.getWindowSize(pid: pid) else { … }
  let s = CGSize(width: settings.eyeCrosshairSize, height: settings.eyeCrosshairSize)
  // AX → Cocoa Y flip against the screen that contains the window
  let screen = NSScreen.screens.first { $0.frame.contains(centerPointAX) } ?? .primary
  let centerAX = CGPoint(x: pos.x + mcSize.width/2, y: pos.y + mcSize.height/2)
  let centerCocoa = CGPoint(x: centerAX.x + offsetX,
                            y: (screen.frame.maxY - centerAX.y) + offsetY)
  window.setFrame(CGRect(x: centerCocoa.x - s.width/2,
                         y: centerCocoa.y - s.height/2,
                         width: s.width, height: s.height), display: true)
  ```

  (Reuse whatever flip helper `WindowController`/ResizeBackground already use so AX↔Cocoa conversion stays consistent — don't invent a second convention.)
- **Z-order:** above the game window — `window.orderFrontRegardless()` then `window.order(.above, relativeTo: Int(targetWindowID))`.
- **Lifecycle:** copy `hideIfTargetRemoved(pid:)` / `hideIfTargetRemoved(_ removedPIDs:)` and the "MC window is gone" guard verbatim.
- **API:** `show(over instance:)`, `showAutomatically(over:)`, `hide()`, `hideAutomatically()`, plus a `refreshAppearance()` to live-update while the user tweaks settings.

---

## 5. Wiring it up

1. **`SWWindowID`** — add `case crosshair = "crosshair-window"`.
2. **Show on entering eye-measure mode** — in `ShortcutManager.resizeTall()`, right where it sets `eyeProjectorOpen = true` / opens the eye projector, also call `CrosshairManager.shared.showAutomatically(over: instance)` (gated on `eyeCrosshairEnabled` && (`!eyeCrosshairOnlyInTallMode || in tall`)).
3. **Hide on exit** — in the `resize(...)` "exiting tall" branch (where `eyeProjectorOpen = false`), call `CrosshairManager.shared.hideAutomatically()`. Also hide on `resizeBase/resizeReset`.
4. **Teardown** — wherever ResizeBackground gets `hideIfTargetRemoved` on instance loss (TrackingManager removal), call the crosshair equivalent so a closed MC window kills the overlay.
5. **Optional manual toggle** — add a `KeyAction`/global keybind `toggleCrosshair` (mirror `resizeBackgroundToggleGKey` in `KeybindSection`) for runners who want it outside tall mode.

---

## 6. Settings UI (`UtilitySettings.swift`, Eye Projector section)

Add a block near the Dynamic Overlay controls (reuse `colorBinding`, `SettingsSliderView`, etc.):

```
Toggle  "Center Crosshair"                         → eyeCrosshairEnabled
  Picker "Style" (Cross/Dot/Circle/Cross+Dot/Custom Image)
  if .customImage: file importer  (reuse the overlay-image importer pattern)
  ColorPicker "Color"      → colorBinding(\.eyeCrosshairColor)
  Slider  "Size"           → eyeCrosshairSize     (4...80)
  Slider  "Thickness"      → eyeCrosshairThickness (1...10)   [cross/circle only]
  Slider  "Center Gap"     → eyeCrosshairGap       (0...30)   [cross only]
  Slider  "Opacity"        → eyeCrosshairOpacity   (0...1)
  Stepper/TextField "Offset X / Offset Y"          → calibration
  Toggle  "Only in Tall Mode"   → eyeCrosshairOnlyInTallMode
  Toggle  "Hide from Screen Capture/OBS"           → eyeCrosshairHideFromCapture
```

Each `.onChange` calls `CrosshairManager.shared.refreshAppearance()` so it updates live while the eye projector is open (same pattern as `restartEyeProjectorIfNeeded()`).

---

## 7. Edge cases & acceptance

- **Multi-monitor:** pick the `NSScreen` containing the MC window center for the Y-flip (don't assume primary).
- **MC moved/resized while shown:** crosshair re-centers on next mode change; for live tracking, optionally poll AX frame on a timer while visible (cheap, only while open) — keep out of v1 unless needed.
- **Capture visibility:** verify `sharingType = .none` actually drops it from the SlackowWall ScreenCaptureKit capture and from OBS; document the fallback (OBS source filter) if a given capture path still sees it.
- **Boundless / retino instances:** confirm AX frame is still correct (boundless uses `sendResizeCommand`); test both.
- **Done when:** crosshair appears dead-center (± offset) over the game on Tall, hides on exit/instance-close, is click-through, styles/colors/size/opacity all live-update, and (if enabled) is absent from capture.

**Rough size:** ~2 new files (~150–250 LOC), ~10 settings fields + 1 enum, ~5 wiring touch-points, ~1 UI block. Small, self-contained, no architectural risk — it's a specialization of an overlay-window pattern the app already ships.
