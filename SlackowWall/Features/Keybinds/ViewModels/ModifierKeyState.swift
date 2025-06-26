import Foundation

enum ModifierKeyState {
    private static var lastF3Press: Date = .distantPast

    /// Whether F3 has been pressed in the last three seconds.
    static var f3Pressed: Bool {
        Date().timeIntervalSince(lastF3Press) < 3
    }

    /// Call when an F3 keyDown event occurs.
    static func registerF3Down() {
        lastF3Press = Date()
    }

    /// Call when an F3 keyUp event occurs.
    static func registerF3Up() {
        lastF3Press = .distantPast
    }
}
