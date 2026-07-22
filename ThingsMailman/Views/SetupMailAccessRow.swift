import SwiftUI

struct SetupMailAccessRow: View {
    let state: AppState

    var body: some View {
        LabeledContent("Mail access") {
            switch state.mailAuthorization {
            case .authorized:
                Label("Authorized", systemImage: "checkmark.circle.fill")
                    .labelStyle(CompactLabelStyle())
                    .foregroundStyle(.green)
            case .denied:
                HStack {
                    Label("Denied", systemImage: "xmark.circle.fill")
                        .labelStyle(CompactLabelStyle())
                        .foregroundStyle(.red)
                    Button("Open System Settings…", action: state.openMailPrivacySettings)
                }
            case .notDetermined:
                Button("Request Access…", action: requestAccess)
            case .mailNotRunning:
                HStack {
                    Label("Mail isn’t open", systemImage: "exclamationmark.circle")
                        .labelStyle(CompactLabelStyle())
                        .foregroundStyle(.secondary)
                    Button("Open Mail", action: state.openMail)
                }
            }
        }
    }

    private func requestAccess() {
        Task {
            await state.requestMailAuthorization()
        }
    }
}
