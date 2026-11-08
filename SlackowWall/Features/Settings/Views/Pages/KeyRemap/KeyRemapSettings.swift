//
//  KeyRemapSettings.swift
//  SlackowWall
//

import SwiftUI

struct KeyRemapSettings: View {
    @AppSettings(\.remap) private var settings

    var body: some View {
        SettingsPageView(title: "Key Remapping", shouldDisableFocus: false) {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                VStack(spacing: 12) {
                    if !AXIsProcessTrusted() {
                        permissionCard(
                            title: "Accessibility Permission Needed",
                            pane: "Privacy_Accessibility",
                            description:
                                "Allow SlackowWall under Privacy & Security → Accessibility. If it's already on there, remove it with − and add it again."
                        )
                    }
                    if !CGPreflightListenEventAccess() {
                        permissionCard(
                            title: "Input Monitoring Permission Needed",
                            pane: "Privacy_ListenEvent",
                            description:
                                "macOS also requires SlackowWall to be allowed under Privacy & Security → Input Monitoring to remap keys. If it's already on there, remove it with − and add it again."
                        )
                    }
                }
            }

            SettingsCardView {
                VStack {
                    SettingsToggleView(
                        title: "Enable Key Remapping",
                        description:
                            "While SlackowWall is open, pressing a key on the left sends the key on the right instead.",
                        option: $settings.enabled)

                    Divider()

                    SettingsToggleView(
                        title: "Only in Minecraft",
                        description:
                            "Only remap keys while a Minecraft instance is the focused window, so typing elsewhere is unaffected.",
                        option: $settings.onlyInMinecraft)
                }
            }

            SettingsLabel(
                title: "Remaps",
                description:
                    "Click a box and press a key to set it. Modifier keys (Shift, Control, Option, Command, left or right) can be remapped to other modifiers, and only take effect in Minecraft."
            )
            .padding(.top, 5)

            SettingsCardView {
                VStack {
                    if settings.remaps.isEmpty {
                        Text("No remaps yet.")
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach($settings.remaps) { $remap in
                        if remap.id != settings.remaps.first?.id {
                            Divider()
                        }
                        HStack {
                            Toggle("", isOn: $remap.enabled)
                                .labelsHidden()
                                .controlSize(.small)

                            KeybindingView(keybinding: keyBinding($remap.from))

                            Image(systemName: "arrow.right")
                                .foregroundStyle(.gray)

                            KeybindingView(keybinding: keyBinding($remap.to))

                            Spacer()

                            if remap.from != nil && remap.from == remap.to {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                    .popoverLabel("A key can't be remapped to itself")
                            } else if remap.mixesModifierAndKey {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.yellow)
                                    .popoverLabel("Modifier keys can only be remapped to other modifier keys")
                            }

                            Button(action: { delete(remap) }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            SettingsCardView {
                SettingsButtonView(
                    title: "Add Remap", buttonText: "Add",
                    action: { settings.remaps.append(KeyRemap()) })
            }

            SettingsLabel(title: "Minecraft")
                .padding(.top, 5)

            SettingsCardView {
                SettingsToggleView(
                    title: "Don't let ⌘Q quit Minecraft",
                    description:
                        "Pressing Q while holding Command no longer quits Minecraft, but Minecraft still sees Command held, so ⌘Q drops a whole stack. Works even when key remapping is turned off.",
                    option: $settings.blockCommandQInMinecraft)
            }
        }
    }

    private func permissionCard(title: String, pane: String, description: String) -> some View {
        SettingsCardView {
            SettingsButtonView(
                title: title, description: description, buttonText: "Open Settings",
                action: {
                    if let url = URL(
                        string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")
                    {
                        NSWorkspace.shared.open(url)
                    }
                })
        }
    }

    /// Bridges a single optional key to `KeybindingView`, dropping modifiers.
    private func keyBinding(_ key: Binding<KeyCode?>) -> Binding<Keybinding> {
        Binding {
            key.wrappedValue.map { Keybinding($0) } ?? .none
        } set: { newValue in
            guard let primary = newValue.primaryKey else {
                key.wrappedValue = nil
                return
            }
            // Caps Lock and Fn can't be remapped; the other modifiers can.
            if KeyCode.modifierFlags(code: primary) == nil || ModifierKey.isRemappable(primary) {
                key.wrappedValue = primary
            }
        }
    }

    private func delete(_ remap: KeyRemap) {
        settings.remaps.removeAll { $0.id == remap.id }
    }
}

#Preview {
    KeyRemapSettings()
        .frame(width: 500, height: 500)
}
