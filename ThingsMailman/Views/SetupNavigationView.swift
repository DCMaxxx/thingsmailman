import SwiftUI

struct SetupNavigationView: View {
    let step: SetupStep
    let isSetupComplete: Bool
    let canContinue: Bool
    let canFinish: Bool
    let goBack: () -> Void
    let goForward: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button("Back", action: goBack)
                .disabled(step.previous == nil)
            Button(forwardTitle, action: goForward)
                .buttonStyle(.borderedProminent)
                .disabled(step.next == nil ? !canFinish : !canContinue)
        }
    }

    private var forwardTitle: String {
        if step.next != nil { return "Continue" }
        return isSetupComplete ? "Save" : "Finish Setup"
    }
}
