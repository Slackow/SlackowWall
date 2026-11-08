//
//  KeyRemapManager.swift
//  SlackowWall
//

import AppKit
import Combine
import CoreGraphics

/// Rewrites key presses system-wide (or only in Minecraft) using a CGEvent tap,
/// so pressing one key sends another, e.g. A → O. Modifier keys can be remapped to
/// other modifiers (e.g. Left Control → Right Command), but only inside Minecraft.
final class KeyRemapManager {
    static let shared = KeyRemapManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var settingsObserver: AnyCancellable?
    private var activationObserver: NSObjectProtocol?
    private var retryTimer: Timer?
    private var loggedTapFailure = false
    private var requestedInputMonitoring = false

    /// Keyboard event taps need both Accessibility and Input Monitoring.
    static var hasPermissions: Bool {
        AXIsProcessTrusted() && CGPreflightListenEventAccess()
    }

    /// from-key → to-key, rebuilt whenever settings change.
    private var mapping: [KeyCode: KeyCode] = [:]
    /// Same, for modifier keys (Shift/Control/Option/Command). Only applied in Minecraft.
    private var modifierMapping: [KeyCode: KeyCode] = [:]
    private var onlyInMinecraft = true
    private var blockCommandQ = false

    /// Keys currently held down and the key they were sent as, so the key-up
    /// always matches the key-down even if settings or focus change mid-press.
    private var heldKeys: [KeyCode: KeyCode] = [:]
    /// Modifiers currently held down and the modifier they were sent as.
    private var heldModifiers: [KeyCode: KeyCode] = [:]

    private var minecraftPIDs: [pid_t: Bool] = [:]
    private var frontmostIsMinecraft = false

    private init() {}

    func start() {
        settingsObserver = Settings.shared.$preferences
            .map(\.remap)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.apply($0) }

        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            self?.updateFrontmost(app)
        }
        updateFrontmost(NSWorkspace.shared.frontmostApplication)
    }

    private func apply(_ section: Preferences.RemapSection) {
        mapping = [:]
        modifierMapping = [:]
        if section.enabled {
            for remap in section.remaps where remap.isValid {
                guard let from = remap.from, let to = remap.to else { continue }
                if ModifierKey.isRemappable(from) {
                    if modifierMapping[from] == nil { modifierMapping[from] = to }
                } else if mapping[from] == nil {
                    mapping[from] = to
                }
            }
        }
        onlyInMinecraft = section.onlyInMinecraft
        blockCommandQ = section.blockCommandQInMinecraft

        let wanted = !mapping.isEmpty || !modifierMapping.isEmpty || blockCommandQ
        if wanted {
            startTap()
        } else {
            stopTap()
        }
        updateRetryTimer(wanted: wanted)
    }

    /// If the tap couldn't be created (usually Accessibility permission not granted yet),
    /// keep trying so remapping starts as soon as permission is given, without a restart.
    private func updateRetryTimer(wanted: Bool) {
        guard wanted && eventTap == nil else {
            retryTimer?.invalidate()
            retryTimer = nil
            return
        }
        guard retryTimer == nil else { return }
        retryTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let self, Self.hasPermissions else { return }
            startTap()
            updateRetryTimer(wanted: true)
        }
    }

    private func updateFrontmost(_ app: NSRunningApplication?) {
        guard let pid = app?.processIdentifier else {
            frontmostIsMinecraft = false
            return
        }
        if let cached = minecraftPIDs[pid] {
            frontmostIsMinecraft = cached
            return
        }
        let args = Utilities.processArguments(pid: pid) ?? []
        let isMinecraft = ["net.minecraft.client.main.Main", "-Djava.library.path="]
            .contains { marker in args.contains { $0.contains(marker) } }
        minecraftPIDs[pid] = isMinecraft
        frontmostIsMinecraft = isMinecraft
    }

    // MARK: - Event tap

    private func startTap() {
        guard eventTap == nil else { return }

        let eventTypes: [CGEventType] = [
            .keyDown, .keyUp, .flagsChanged,
            // Clicks carry modifier flags too, so they're rewritten while a modifier is remapped.
            .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown,
            .otherMouseUp,
        ]
        let eventMask = eventTypes.reduce(0) { $0 | (1 << $1.rawValue) }

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<KeyRemapManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handle(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        guard let eventTap else {
            if !loggedTapFailure {
                loggedTapFailure = true
                LogManager.shared.appendLog(
                    "Key Remap: failed to create event tap. Accessibility:", AXIsProcessTrusted(),
                    "Input Monitoring:", CGPreflightListenEventAccess())
            }
            // Shows the system prompt and adds SlackowWall to the Input Monitoring list.
            if !CGPreflightListenEventAccess() && !requestedInputMonitoring {
                requestedInputMonitoring = true
                CGRequestListenEventAccess()
            }
            return
        }
        loggedTapFailure = false

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        LogManager.shared.appendLog(
            "Key Remap: enabled with \(mapping.count + modifierMapping.count) remap(s),",
            "block ⌘Q:", blockCommandQ)
    }

    private func stopTap() {
        guard let eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: false)
        CFMachPortInvalidate(eventTap)
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        self.eventTap = nil
        self.runLoopSource = nil
        heldKeys = [:]
        heldModifiers = [:]
        LogManager.shared.appendLog("Key Remap: disabled")
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // macOS turns off taps that are slow or interrupted; turn it back on.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        switch type {
            case .flagsChanged:
                handleModifierChange(event)
                return Unmanaged.passUnretained(event)
            case .keyDown, .keyUp:
                return handleKey(type: type, event: event)
            default:
                rewriteModifierFlags(event)
                return Unmanaged.passUnretained(event)
        }
    }

    private func handleKey(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = KeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let isDown = type == .keyDown

        let target: KeyCode?
        if isDown {
            target = shouldRemap ? mapping[keyCode] : nil
            if let target {
                heldKeys[keyCode] = target
            }
        } else {
            target = heldKeys.removeValue(forKey: keyCode)
        }

        var output = event
        var created = false
        if let target,
            let remapped = CGEvent(
                keyboardEventSource: CGEventSource(event: event), virtualKey: target,
                keyDown: isDown)
        {
            remapped.flags = event.flags
            remapped.setIntegerValueField(
                .keyboardEventAutorepeat,
                value: event.getIntegerValueField(.keyboardEventAutorepeat))
            output = remapped
            created = true
        }

        rewriteModifierFlags(output)

        // Minecraft drops a stack when it sees a Command key held while Q is pressed.
        // Taking Command off the Q press itself stops macOS from treating it as "Quit",
        // while Minecraft still sees Command held from the earlier modifier press.
        if blockCommandQ && frontmostIsMinecraft && (target ?? keyCode) == .q
            && output.flags.contains(.maskCommand)
        {
            output.flags = CGEventFlags(
                rawValue: output.flags.rawValue
                    & ~(CGEventFlags.maskCommand.rawValue | ModifierKey.commandDeviceBits))
        }

        return created ? Unmanaged.passRetained(output) : Unmanaged.passUnretained(output)
    }

    /// Handles a modifier key going down or up, sending it as its remapped modifier.
    private func handleModifierChange(_ event: CGEvent) {
        let keyCode = KeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        guard let key = ModifierKey.all[keyCode] else { return }

        let isDown = event.flags.rawValue & key.deviceBit != 0
        let output: KeyCode
        if isDown {
            output = (shouldRemapModifiers ? modifierMapping[keyCode] : nil) ?? keyCode
            heldModifiers[keyCode] = output
        } else {
            output = heldModifiers.removeValue(forKey: keyCode) ?? keyCode
        }

        if output != keyCode {
            event.setIntegerValueField(.keyboardEventKeycode, value: Int64(output))
        }
        rewriteModifierFlags(event, force: output != keyCode)
    }

    /// Replaces the modifier flags on an event so held remapped modifiers show up as
    /// the modifier they were remapped to.
    private func rewriteModifierFlags(_ event: CGEvent, force: Bool = false) {
        guard force || heldModifiers.contains(where: { $0.key != $0.value }) else { return }
        let original = event.flags.rawValue
        var raw = original & ~ModifierKey.allBits
        for (code, key) in ModifierKey.all where original & key.deviceBit != 0 {
            let sentAs = heldModifiers[code] ?? code
            if let out = ModifierKey.all[sentAs] {
                raw |= out.deviceBit | out.familyBit
            }
        }
        event.flags = CGEventFlags(rawValue: raw)
    }

    private var shouldRemapModifiers: Bool {
        // Swapping modifiers outside Minecraft would break normal shortcuts, so never do it.
        frontmostIsMinecraft && shouldRemap
    }

    private var shouldRemap: Bool {
        // Never remap while typing in SlackowWall's own settings, so keys can be recorded.
        if NSApp.isActive,
            NSApp.keyWindow?.identifier?.rawValue.hasPrefix(SWWindowID.settings.rawValue) == true
        {
            return false
        }
        return !onlyInMinecraft || frontmostIsMinecraft
    }
}

/// The modifier keys that can be remapped, with the left/right-specific flag bit macOS
/// sets while each one is held and the general Shift/Control/Option/Command flag.
struct ModifierKey {
    let deviceBit: UInt64
    let familyBit: UInt64

    static let all: [KeyCode: ModifierKey] = [
        .control: .init(deviceBit: 0x0001, familyBit: CGEventFlags.maskControl.rawValue),
        .rightControl: .init(deviceBit: 0x2000, familyBit: CGEventFlags.maskControl.rawValue),
        .shift: .init(deviceBit: 0x0002, familyBit: CGEventFlags.maskShift.rawValue),
        .rightShift: .init(deviceBit: 0x0004, familyBit: CGEventFlags.maskShift.rawValue),
        .command: .init(deviceBit: 0x0008, familyBit: CGEventFlags.maskCommand.rawValue),
        .rightCommand: .init(deviceBit: 0x0010, familyBit: CGEventFlags.maskCommand.rawValue),
        .option: .init(deviceBit: 0x0020, familyBit: CGEventFlags.maskAlternate.rawValue),
        .rightOption: .init(deviceBit: 0x0040, familyBit: CGEventFlags.maskAlternate.rawValue),
    ]

    static let allBits: UInt64 = all.values.reduce(0) { $0 | $1.deviceBit | $1.familyBit }
    static let commandDeviceBits: UInt64 = 0x0008 | 0x0010

    static func isRemappable(_ code: KeyCode) -> Bool {
        all[code] != nil
    }
}
