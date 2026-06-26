# Flint — Plan 1: Bootstrap + Foundation + Center Crosshair

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the Flint macOS app (forked from SlackowWall), bind it to a single Minecraft window, and render a configurable, OBS-invisible center crosshair overlay — the first usable, demonstrable feature and the architectural proof for the whole port.

**Architecture:** Flint is an external macOS app — no process injection. Overlays are borderless, click-through, always-on-top `NSPanel`s with `sharingType = .none` (excluded from ScreenCaptureKit/OBS), positioned over the captured Minecraft window. This plan builds the overlay-window primitive, the anchor geometry, the crosshair config + renderer, and an instance-binding shim that reuses SlackowWall's existing capture/tracking to supply the live MC window frame.

**Tech Stack:** Swift 5, SwiftUI + AppKit, ScreenCaptureKit, XCTest. macOS 13.5 deployment target. Forked from `/Users/danmaruchi/projects/SlackowWall`.

**Reference spec:** `docs/superpowers/specs/2026-06-25-flint-toolscreen-port-design.md` (§3 bootstrap, §4 foundation, §5b crosshair).

**Scope notes:**
- This plan does **not** strip SlackowWall's wall/reset/mod features. That is a separate later cleanup plan. Plan 1 adds new code alongside the existing app.
- Subsequent plans (per spec §7): general image overlays, mode system, eye stack, input/sensitivity, Ninbot, mirrors, polish.

---

## File Structure (created/modified in this plan)

All paths are inside the new Flint repo (`~/projects/Flint`) after Task 0.

**New files (Flint feature code):**
- `Flint/Features/Overlay/OverlayAnchor.swift` — anchor enum + pure geometry (anchor + parent rect + size + offset → child rect). Unit-tested.
- `Flint/Features/Overlay/OverlayWindow.swift` — borderless/click-through/OBS-invisible `NSPanel` subclass + positioning.
- `Flint/Features/Overlay/Crosshair/CrosshairSettings.swift` — Codable crosshair config. Unit-tested.
- `Flint/Features/Overlay/Crosshair/CrosshairShape.swift` — `Shape` paths for cross/dot/circle. Geometry unit-tested.
- `Flint/Features/Overlay/Crosshair/CrosshairView.swift` — SwiftUI view composing the shape + style.
- `Flint/Features/Overlay/Crosshair/CrosshairOverlayController.swift` — owns an `OverlayWindow`, follows the MC rect, toggles via settings.
- `Flint/Features/Instance/FlintInstance.swift` — single-instance binding shim; publishes the live MC window `CGRect`.

**Modified files:**
- `Flint/Features/Settings/Models/Preferences.swift` — add `crosshair` section.
- `Flint/Info.plist` — display name → "Flint".
- Xcode project — bundle id + display name; add `FlintTests` target if absent.

**New test files:**
- `FlintTests/OverlayAnchorTests.swift`
- `FlintTests/CrosshairSettingsTests.swift`
- `FlintTests/CrosshairShapeTests.swift`

---

## Task 0: Bootstrap the Flint repo

**Files:**
- Create: `~/projects/Flint/` (forked copy)
- Archive: `~/projects/flint` → `~/projects/flint-tauri-archive`
- Modify: `~/projects/Flint/SlackowWall/Info.plist`, Xcode build settings

- [ ] **Step 1: Archive the outdated Tauri repo (rename, do NOT delete)**

```bash
mv ~/projects/flint ~/projects/flint-tauri-archive
```

Expected: `~/projects/flint` no longer exists; `~/projects/flint-tauri-archive` does. If `~/projects/flint` does not exist, skip this step.

- [ ] **Step 2: Copy SlackowWall into a fresh Flint repo (exclude build cruft)**

```bash
rsync -a --exclude '.git' --exclude 'build' --exclude 'DerivedData' \
  ~/projects/SlackowWall/ ~/projects/Flint/
cd ~/projects/Flint && git init -q && git add -A && git commit -q -m "chore: fork SlackowWall as Flint baseline"
```

Expected: `~/projects/Flint` is a new git repo with one commit. Run `cd ~/projects/Flint && git log --oneline` → one line.

- [ ] **Step 3: Rebrand display name to "Flint"**

In `~/projects/Flint/SlackowWall/Info.plist`, set `CFBundleDisplayName` to `Flint` (add the key if missing):

```xml
<key>CFBundleDisplayName</key>
<string>Flint</string>
```

- [ ] **Step 4: Set a distinct bundle identifier**

Open `~/projects/Flint/SlackowWall.xcodeproj` in Xcode → target build settings → set `PRODUCT_BUNDLE_IDENTIFIER` to `dev.danny.Flint` for all configurations. (Adjust the prefix to your preference; it just must differ from SlackowWall's so both can be installed side by side.)

- [ ] **Step 5: Create the Flint feature folder and a test target if absent**

```bash
mkdir -p ~/projects/Flint/SlackowWall/Features/Overlay/Crosshair \
         ~/projects/Flint/SlackowWall/Features/Instance
```

In Xcode, if there is no unit-test target, add one: File → New → Target → **Unit Testing Bundle**, name it `FlintTests`. (If a test target already exists, reuse it and substitute its name for `FlintTests` throughout this plan.)

> Note: The source root folder inside the project is still named `SlackowWall/` — renaming the on-disk folder and the `.xcodeproj` is cosmetic and deferred to avoid breaking project references now. New code lives under `SlackowWall/Features/Overlay/` etc.

- [ ] **Step 6: Verify the fork builds and runs as "Flint"**

In Xcode, build & run (⌘R). Expected: the app launches exactly as SlackowWall did, but the menu-bar/app name shows "Flint". Confirm in the Finder/Dock the running app is named Flint.

- [ ] **Step 7: Commit**

```bash
cd ~/projects/Flint && git add -A && git commit -m "chore: rebrand fork to Flint (display name + bundle id)"
```

---

## Task 1: Overlay anchor geometry (pure, TDD)

Anchors map a child overlay of a given size to a position inside the parent (Minecraft) rect, plus a pixel offset. This is pure math — fully unit-testable with no UI.

**Files:**
- Create: `SlackowWall/Features/Overlay/OverlayAnchor.swift`
- Test: `FlintTests/OverlayAnchorTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// FlintTests/OverlayAnchorTests.swift
import XCTest
@testable import SlackowWall

final class OverlayAnchorTests: XCTestCase {
    let parent = CGRect(x: 100, y: 200, width: 800, height: 600)
    let size = CGSize(width: 40, height: 40)

    func testCenterAnchorCentersChild() {
        let rect = OverlayAnchor.center.frame(in: parent, size: size, offset: .zero)
        // center of parent is (500, 500); child top-left = center - size/2
        XCTAssertEqual(rect.origin.x, 480, accuracy: 0.001)
        XCTAssertEqual(rect.origin.y, 480, accuracy: 0.001)
        XCTAssertEqual(rect.size, size)
    }

    func testCenterAnchorAppliesOffset() {
        let rect = OverlayAnchor.center.frame(in: parent, size: size, offset: CGPoint(x: 10, y: -5))
        XCTAssertEqual(rect.origin.x, 490, accuracy: 0.001)
        XCTAssertEqual(rect.origin.y, 475, accuracy: 0.001)
    }

    func testTopLeftAnchor() {
        let rect = OverlayAnchor.topLeft.frame(in: parent, size: size, offset: .zero)
        XCTAssertEqual(rect.origin.x, 100, accuracy: 0.001)
        XCTAssertEqual(rect.origin.y, 200, accuracy: 0.001)
    }

    func testBottomRightAnchor() {
        let rect = OverlayAnchor.bottomRight.frame(in: parent, size: size, offset: .zero)
        XCTAssertEqual(rect.origin.x, 860, accuracy: 0.001) // 100+800-40
        XCTAssertEqual(rect.origin.y, 760, accuracy: 0.001) // 200+600-40
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run in Xcode: ⌘U (or `xcodebuild test -scheme SlackowWall -only-testing:FlintTests/OverlayAnchorTests`).
Expected: FAIL — "cannot find 'OverlayAnchor' in scope".

- [ ] **Step 3: Write minimal implementation**

```swift
// SlackowWall/Features/Overlay/OverlayAnchor.swift
import CoreGraphics

/// Where an overlay is positioned relative to its parent (the Minecraft window) rect.
/// Coordinates are in the same space as the parent rect (top-left origin handled by caller).
enum OverlayAnchor: String, Codable, CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight, center

    /// Returns the child frame for an overlay of `size`, anchored within `parent`, shifted by `offset`.
    func frame(in parent: CGRect, size: CGSize, offset: CGPoint) -> CGRect {
        let origin: CGPoint
        switch self {
        case .topLeft:
            origin = CGPoint(x: parent.minX, y: parent.minY)
        case .topRight:
            origin = CGPoint(x: parent.maxX - size.width, y: parent.minY)
        case .bottomLeft:
            origin = CGPoint(x: parent.minX, y: parent.maxY - size.height)
        case .bottomRight:
            origin = CGPoint(x: parent.maxX - size.width, y: parent.maxY - size.height)
        case .center:
            origin = CGPoint(x: parent.midX - size.width / 2,
                             y: parent.midY - size.height / 2)
        }
        return CGRect(x: origin.x + offset.x, y: origin.y + offset.y,
                      width: size.width, height: size.height)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: ⌘U.
Expected: PASS (all four `OverlayAnchorTests`).

- [ ] **Step 5: Commit**

```bash
git add SlackowWall/Features/Overlay/OverlayAnchor.swift FlintTests/OverlayAnchorTests.swift
git commit -m "feat: overlay anchor geometry"
```

---

## Task 2: Crosshair settings model (Codable, TDD)

**Files:**
- Create: `SlackowWall/Features/Overlay/Crosshair/CrosshairSettings.swift`
- Test: `FlintTests/CrosshairSettingsTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// FlintTests/CrosshairSettingsTests.swift
import XCTest
@testable import SlackowWall

final class CrosshairSettingsTests: XCTestCase {
    func testDefaultsAreSensible() {
        let s = CrosshairSettings()
        XCTAssertFalse(s.enabled)               // off by default
        XCTAssertEqual(s.style, .cross)
        XCTAssertEqual(s.size, 16, accuracy: 0.001)
        XCTAssertEqual(s.thickness, 2, accuracy: 0.001)
        XCTAssertEqual(s.gap, 4, accuracy: 0.001)
        XCTAssertEqual(s.offset, .zero)
    }

    func testCodableRoundTrip() throws {
        var s = CrosshairSettings()
        s.enabled = true
        s.style = .dot
        s.size = 24
        s.offset = CGPoint(x: 1, y: -2)
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(CrosshairSettings.self, from: data)
        XCTAssertEqual(decoded, s)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: ⌘U. Expected: FAIL — "cannot find 'CrosshairSettings' in scope".

- [ ] **Step 3: Write minimal implementation**

```swift
// SlackowWall/Features/Overlay/Crosshair/CrosshairSettings.swift
import SwiftUI

enum CrosshairStyle: String, Codable, CaseIterable, Identifiable {
    case cross, dot, circle
    var id: String { rawValue }
}

/// Codable RGBA color so the crosshair color round-trips through JSON settings.
struct CodableRGBA: Codable, Hashable {
    var r: Double, g: Double, b: Double, a: Double
    init(r: Double = 1, g: Double = 0, b: Double = 0, a: Double = 1) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }
    var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: a) }
}

struct CrosshairSettings: Codable, Hashable {
    var enabled: Bool = false
    var style: CrosshairStyle = .cross
    var size: CGFloat = 16
    var thickness: CGFloat = 2
    var gap: CGFloat = 4
    var color: CodableRGBA = CodableRGBA()
    var offset: CGPoint = .zero
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: ⌘U. Expected: PASS (both `CrosshairSettingsTests`).

- [ ] **Step 5: Commit**

```bash
git add SlackowWall/Features/Overlay/Crosshair/CrosshairSettings.swift FlintTests/CrosshairSettingsTests.swift
git commit -m "feat: crosshair settings model"
```

---

## Task 3: Crosshair shape geometry (TDD) + view

The shape paths are testable geometry; the SwiftUI view that styles them is built and visually verified.

**Files:**
- Create: `SlackowWall/Features/Overlay/Crosshair/CrosshairShape.swift`
- Create: `SlackowWall/Features/Overlay/Crosshair/CrosshairView.swift`
- Test: `FlintTests/CrosshairShapeTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
// FlintTests/CrosshairShapeTests.swift
import XCTest
import SwiftUI
@testable import SlackowWall

final class CrosshairShapeTests: XCTestCase {
    let rect = CGRect(x: 0, y: 0, width: 100, height: 100)

    func testCrossPathIsNonEmptyAndWithinBounds() {
        let path = CrossPath(thickness: 4, gap: 10).path(in: rect)
        XCTAssertFalse(path.isEmpty)
        XCTAssertTrue(rect.insetBy(dx: -0.5, dy: -0.5).contains(path.boundingRect))
    }

    func testCrossPathRespectsGap() {
        // With a gap, the exact center point must NOT be filled (it's the hole).
        let path = CrossPath(thickness: 4, gap: 10).path(in: rect)
        XCTAssertFalse(path.contains(CGPoint(x: 50, y: 50)))
    }

    func testDotPathIsCenteredCircle() {
        let path = DotPath().path(in: rect)
        let bounds = path.boundingRect
        XCTAssertEqual(bounds.midX, 50, accuracy: 0.5)
        XCTAssertEqual(bounds.midY, 50, accuracy: 0.5)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: ⌘U. Expected: FAIL — "cannot find 'CrossPath' in scope".

- [ ] **Step 3: Write minimal implementation**

```swift
// SlackowWall/Features/Overlay/Crosshair/CrosshairShape.swift
import SwiftUI

/// A plus/cross with a configurable central gap. `thickness` and `gap` are in points.
struct CrossPath: Shape {
    var thickness: CGFloat
    var gap: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY
        let halfT = thickness / 2
        let halfG = gap / 2
        // Horizontal arm: left segment + right segment (leaving the gap in the middle)
        p.addRect(CGRect(x: rect.minX, y: cy - halfT, width: max(0, cx - halfG - rect.minX), height: thickness))
        p.addRect(CGRect(x: cx + halfG, y: cy - halfT, width: max(0, rect.maxX - (cx + halfG)), height: thickness))
        // Vertical arm: top segment + bottom segment
        p.addRect(CGRect(x: cx - halfT, y: rect.minY, width: thickness, height: max(0, cy - halfG - rect.minY)))
        p.addRect(CGRect(x: cx - halfT, y: cy + halfG, width: thickness, height: max(0, rect.maxY - (cy + halfG))))
        return p
    }
}

/// A small filled dot centered in the rect (diameter = min dimension / 2).
struct DotPath: Shape {
    func path(in rect: CGRect) -> Path {
        let d = min(rect.width, rect.height) / 2
        let originX = rect.midX - d / 2
        let originY = rect.midY - d / 2
        return Path(ellipseIn: CGRect(x: originX, y: originY, width: d, height: d))
    }
}

/// A ring centered in the rect, stroked by `lineWidth` at the call site.
struct CirclePath: Shape {
    func path(in rect: CGRect) -> Path {
        let d = min(rect.width, rect.height)
        let inset = (max(rect.width, rect.height) - d) / 2
        return Path(ellipseIn: CGRect(x: rect.minX + (rect.width - d) / 2,
                                      y: rect.minY + (rect.height - d) / 2,
                                      width: d, height: d).insetBy(dx: inset, dy: inset))
    }
}
```

```swift
// SlackowWall/Features/Overlay/Crosshair/CrosshairView.swift
import SwiftUI

/// Renders a crosshair per `settings`, sized to fill its container.
/// Hit-testing is disabled so it never steals clicks (overlay window is also click-through).
struct CrosshairView: View {
    let settings: CrosshairSettings

    var body: some View {
        Group {
            switch settings.style {
            case .cross:
                CrossPath(thickness: settings.thickness, gap: settings.gap)
                    .fill(settings.color.color)
            case .dot:
                DotPath()
                    .fill(settings.color.color)
            case .circle:
                CirclePath()
                    .stroke(settings.color.color, lineWidth: settings.thickness)
            }
        }
        .frame(width: settings.size, height: settings.size)
        .allowsHitTesting(false)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: ⌘U. Expected: PASS (all three `CrosshairShapeTests`).

- [ ] **Step 5: Commit**

```bash
git add SlackowWall/Features/Overlay/Crosshair/CrosshairShape.swift \
        SlackowWall/Features/Overlay/Crosshair/CrosshairView.swift \
        FlintTests/CrosshairShapeTests.swift
git commit -m "feat: crosshair shapes + view"
```

---

## Task 4: OBS-invisible overlay window primitive

A borderless, click-through, always-on-top `NSPanel` that is excluded from screen capture. Modeled on SlackowWall's `ResizeBackgroundWindow`, but configured to sit **above** the target and with `sharingType = .none`. This is AppKit window plumbing — verified by build + manual observation, not unit tests.

**Files:**
- Create: `SlackowWall/Features/Overlay/OverlayWindow.swift`

- [ ] **Step 1: Implement the overlay window**

```swift
// SlackowWall/Features/Overlay/OverlayWindow.swift
import AppKit
import SwiftUI

/// A borderless, click-through, always-on-top panel that is EXCLUDED from screen capture
/// (sharingType = .none → invisible to ScreenCaptureKit / OBS).
final class OverlayWindow: NSPanel {
    init<Content: View>(content: Content) {
        super.init(contentRect: .zero,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true          // click-through
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        canHide = false
        level = .screenSaver                // above normal app + fullscreen game windows
        sharingType = .none                 // <-- the load-bearing line: invisible to OBS/SCK
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary]
        contentView = NSHostingView(rootView: content)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Position the window using a top-left-origin rect (Core Graphics / capture space),
    /// converting to AppKit's bottom-left-origin screen coordinates.
    func setTopLeftFrame(_ rect: CGRect) {
        guard let screenHeight = NSScreen.screens.first(where: { $0.frame.contains(rect.origin) })?.frame.maxY
                ?? NSScreen.main?.frame.maxY else { return }
        let flippedY = screenHeight - rect.maxY
        setFrame(CGRect(x: rect.origin.x, y: flippedY, width: rect.width, height: rect.height),
                 display: true)
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: ⌘B. Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add SlackowWall/Features/Overlay/OverlayWindow.swift
git commit -m "feat: OBS-invisible click-through overlay window"
```

---

## Task 5: Single-instance binding shim

Flint is single-instance: it picks the one Minecraft window and publishes its live on-screen rect. This reuses SlackowWall's existing `ScreenRecorder`/tracking to find Minecraft and read its frame, exposing just the rect the overlay needs. (Full reuse details depend on the existing tracking API; this shim wraps it behind one published property.)

**Files:**
- Create: `SlackowWall/Features/Instance/FlintInstance.swift`

- [ ] **Step 1: Implement the binding shim**

```swift
// SlackowWall/Features/Instance/FlintInstance.swift
import AppKit
import Combine
import ScreenCaptureKit

/// Single-instance binding: tracks the one Minecraft window and publishes its on-screen rect
/// (top-left origin, CG/screen-capture space). Overlays observe `windowRect`.
@MainActor
final class FlintInstance: ObservableObject {
    static let shared = FlintInstance()

    /// Live Minecraft window frame in top-left-origin screen coordinates, or nil when not bound.
    @Published private(set) var windowRect: CGRect?

    private var timer: Timer?

    /// Begin polling the Minecraft window position. Uses CGWindowList to read the live frame
    /// of the window whose title matches a Minecraft version + "Minecraft".
    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        windowRect = nil
    }

    private func refresh() {
        windowRect = Self.findMinecraftWindowRect()
    }

    /// Finds the first on-screen window whose owner/title looks like Minecraft and returns its
    /// bounds in top-left-origin global coordinates (as CGWindowList reports them).
    static func findMinecraftWindowRect() -> CGRect? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        let versionRegex = try? NSRegularExpression(pattern: #"(1|2[6-9]|[34]\d)\.(\d+)(\.\d+)?"#)
        for info in infoList {
            let name = (info[kCGWindowName as String] as? String) ?? ""
            let owner = (info[kCGWindowOwnerName as String] as? String) ?? ""
            let looksLikeMC = name.contains("Minecraft")
                || owner.contains("Minecraft")
                || owner.contains("java")
            guard looksLikeMC else { continue }
            if !name.isEmpty, let rx = versionRegex {
                let range = NSRange(name.startIndex..., in: name)
                if rx.firstMatch(in: name, range: range) == nil && !name.contains("Minecraft") {
                    continue
                }
            }
            if let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
               let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) {
                return bounds
            }
        }
        return nil
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run: ⌘B. Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Manual verification**

Launch a Minecraft instance. Add a temporary debug print in `refresh()` (`print(windowRect ?? "no MC")`) behind a launch, run Flint, and confirm the console logs the Minecraft window rect and that it updates when you move/resize the Minecraft window. Remove the debug print after confirming.

- [ ] **Step 4: Commit**

```bash
git add SlackowWall/Features/Instance/FlintInstance.swift
git commit -m "feat: single-instance Minecraft window binding"
```

---

## Task 6: Add crosshair to Preferences

Wire `CrosshairSettings` into the existing settings model so it persists and binds in the UI.

**Files:**
- Modify: `SlackowWall/Features/Settings/Models/Preferences.swift`

- [ ] **Step 1: Add the crosshair property to `Preferences`**

In `Preferences`, add a stored property alongside the existing sections (`behavior`, `mode`, etc.):

```swift
    var crosshair: CrosshairSettings = .init()
```

(Place it with the other `var <section>: ... = .init()` lines inside `struct Preferences`.)

- [ ] **Step 2: Build to verify it compiles and persists**

Run: ⌘B. Expected: BUILD SUCCEEDED. The `@DefaultCodable`/Codable conformance picks up the new field automatically; existing saved settings still decode because `CrosshairSettings` has defaults for every field.

- [ ] **Step 3: Commit**

```bash
git add SlackowWall/Features/Settings/Models/Preferences.swift
git commit -m "feat: persist crosshair settings in Preferences"
```

---

## Task 7: Crosshair overlay controller (wire it all together)

Owns an `OverlayWindow` hosting `CrosshairView`, follows `FlintInstance.windowRect` using `OverlayAnchor.center`, and shows/hides per `crosshair.enabled`.

**Files:**
- Create: `SlackowWall/Features/Overlay/Crosshair/CrosshairOverlayController.swift`

- [ ] **Step 1: Implement the controller**

```swift
// SlackowWall/Features/Overlay/Crosshair/CrosshairOverlayController.swift
import AppKit
import Combine
import SwiftUI

/// Drives the center-crosshair overlay: creates/destroys the overlay window based on
/// `settings.crosshair.enabled`, and keeps it centered on the live Minecraft window rect.
@MainActor
final class CrosshairOverlayController: ObservableObject {
    private var window: OverlayWindow?
    private var cancellables = Set<AnyCancellable>()
    private let settings = Settings.shared
    private let instance = FlintInstance.shared

    func start() {
        instance.start()

        // React to settings changes.
        settings.$preferences
            .map(\.crosshair)
            .removeDuplicates()
            .sink { [weak self] cfg in self?.apply(cfg) }
            .store(in: &cancellables)

        // React to window movement.
        instance.$windowRect
            .sink { [weak self] rect in self?.reposition(rect) }
            .store(in: &cancellables)

        apply(settings.preferences.crosshair)
    }

    private func apply(_ cfg: CrosshairSettings) {
        guard cfg.enabled else {
            window?.orderOut(nil)
            window = nil
            return
        }
        let w = window ?? OverlayWindow(content: CrosshairView(settings: cfg))
        // Rebuild content so style/size/color edits take effect.
        w.contentView = NSHostingView(rootView: CrosshairView(settings: cfg))
        window = w
        reposition(instance.windowRect)
        w.orderFrontRegardless()
    }

    private func reposition(_ mcRect: CGRect?) {
        guard let window, let mcRect else { return }
        let cfg = settings.preferences.crosshair
        let size = CGSize(width: cfg.size, height: cfg.size)
        let rect = OverlayAnchor.center.frame(in: mcRect, size: size, offset: cfg.offset)
        window.setTopLeftFrame(rect)
    }
}
```

- [ ] **Step 2: Start the controller at app launch**

In the app's `AppDelegate.applicationDidFinishLaunching(_:)` (in `SlackowWallApp.swift`), instantiate and start the controller, holding a strong reference:

```swift
    let crosshairController = CrosshairOverlayController()
    // ... inside applicationDidFinishLaunching:
    crosshairController.start()
```

(Add `let crosshairController = CrosshairOverlayController()` as a stored property on `AppDelegate`, and call `crosshairController.start()` at the end of `applicationDidFinishLaunching`.)

- [ ] **Step 3: Build**

Run: ⌘B. Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Manual verification — crosshair appears centered**

Temporarily set the crosshair enabled by default for testing: in `CrosshairSettings`, change `var enabled: Bool = false` to `true`, run Flint with Minecraft open. Expected: a red cross appears at the exact center of the Minecraft window and stays centered when you move/resize the window. Revert `enabled` back to `false` after confirming.

- [ ] **Step 5: Commit**

```bash
git add SlackowWall/Features/Overlay/Crosshair/CrosshairOverlayController.swift SlackowWall/SlackowWallApp.swift
git commit -m "feat: wire center crosshair overlay to live Minecraft window"
```

---

## Task 8: Verify OBS-invisibility (the load-bearing assumption)

The whole architecture rests on `sharingType = .none` hiding overlays from ScreenCaptureKit. Verify it explicitly.

**Files:** none (verification only).

- [ ] **Step 1: Capture the screen while the crosshair is visible**

With the crosshair showing over Minecraft (from Task 7), take a ScreenCaptureKit-based screenshot. Easiest path: run OBS (or QuickTime screen recording, which also uses the capture path) and observe a preview/recording of the Minecraft window.

- [ ] **Step 2: Assert the crosshair is absent from the capture**

Expected: you see the crosshair on your physical display, but it is **absent** from the OBS/QuickTime capture of that display/window. If it appears in the capture, `sharingType = .none` is not taking effect for that capture path — investigate before building more overlays on this primitive (this is the make-or-break check called out in spec §10).

- [ ] **Step 3: Record the result**

Note the outcome (pass/fail + capture method used) in the commit message of the next change or in `docs/`. No code change if it passes.

---

## Self-Review

**Spec coverage (Plan 1 scope = spec §3 bootstrap, §4 foundation, §5b crosshair):**
- §3 bootstrap (fork-strip, archive old flint, fresh path) → Task 0. ✅ (Strip of wall features explicitly deferred — noted in scope.)
- §4a instance binding → Task 5 (`FlintInstance`). ✅
- §4b overlay window primitive (click-through, `sharingType = .none`, anchors) → Task 1 (anchors) + Task 4 (window). ✅
- §4c input layer → **deferred** to the input/sensitivity plan (not needed for the crosshair). Noted in scope.
- §4d config core → reuses existing `Settings`/`Preferences`; extended in Task 6. ✅
- §5b center crosshair (vector shapes, center anchor, per-window, OBS-invisible) → Tasks 2,3,7,8. ✅

**Placeholder scan:** No TBD/TODO; every code step has complete code; commands have expected output. The one deferred item (§4c input) is explicitly out of this plan's scope, not a placeholder.

**Type consistency:** `OverlayAnchor.frame(in:size:offset:)` used identically in Tasks 1 and 7. `CrosshairSettings` field names (`enabled/style/size/thickness/gap/color/offset`) consistent across Tasks 2,3,7. `OverlayWindow(content:)` + `setTopLeftFrame(_:)` consistent across Tasks 4 and 7. `FlintInstance.shared.windowRect` consistent across Tasks 5 and 7. `Settings.shared.preferences.crosshair` consistent across Tasks 6 and 7.

**Known assumptions to validate during execution (not placeholders, but flagged):**
- `FlintInstance` uses `CGWindowList` rather than reusing `ScreenRecorder` directly, to keep the binding self-contained and avoid pulling in multi-instance tracking. If the existing `ScreenRecorder` exposes a simpler live-rect API, prefer it.
- `AppDelegate`/`SlackowWallApp.swift` wiring (Task 7 Step 2) assumes the standard `@NSApplicationDelegateAdaptor` pattern the explorer found; adjust property placement to match the actual file.
