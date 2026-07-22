import SwiftUI

struct SetupShortcutAndLoginStepView: View {
    let state: AppState
    @Bindable var preferences: PreferencesStore

    init(state: AppState) {
        self.state = state
        preferences = state.preferences
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Launch at login") {
                    Toggle("Launch at login", isOn: $preferences.launchAtLogin)
                        .labelsHidden()
                        .onChange(of: preferences.launchAtLogin) {
                            Task { await state.updateLaunchAtLogin() }
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Keyboard shortcut")
                            Text("The shortcut works only while Mail is the frontmost app.")
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        ShortcutRecorderView(shortcut: preferences.shortcut, onChange: state.updateShortcut)
                            .frame(width: 160, height: 32)
                    }

                    if state.shortcutConflict {
                        Label("That shortcut is already in use. The previous shortcut remains active.", systemImage: "exclamationmark.triangle")
                            .labelStyle(CompactLabelStyle())
                            .foregroundStyle(.orange)
                    }

                }
            }

            AutomationAboutSection()
        }
        .formStyle(.grouped)
    }
}
