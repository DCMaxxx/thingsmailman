import SwiftUI

struct SetupMailboxStepView: View {
    let state: AppState

    var body: some View {
        Form {
            Section {
                SetupMailAccessRow(state: state)
            }

            if state.mailAuthorization == .authorized {
                SetupMailboxRoutesSection(state: state)
            }
        }
        .formStyle(.grouped)
    }
}
