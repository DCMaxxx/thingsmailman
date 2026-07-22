import SwiftUI

struct SetupStatusView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @Bindable var state: AppState
    @State private var step: SetupStep
    @State private var mode: SetupPresentationMode

    init(state: AppState) {
        self.state = state
        _step = State(initialValue: state.requestedSetupStep ?? .thingsAndMail)
        _mode = State(initialValue: state.preferences.isSetupComplete ? .editing : .onboarding)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if mode == .onboarding {
                SetupHeaderView(mode: mode)
                SetupProgressView(step: step)
            } else {
                SetupSectionPicker(selection: $step)
            }
            Divider()

            Group {
                switch step {
                case .thingsAndMail:
                    SetupThingsAndMailStepView(state: state)
                case .mailboxes:
                    SetupMailboxStepView(state: state)
                case .shortcutAndLogin:
                    SetupShortcutAndLoginStepView(state: state)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if mode == .onboarding {
                SetupNavigationView(
                    step: step,
                    isSetupComplete: state.preferences.isSetupComplete,
                    canContinue: canContinue,
                    canFinish: canFinish,
                    goBack: goBack,
                    goForward: goForward
                )
            }
        }
        .scenePadding()
        .frame(width: 620, height: 600)
        .task(id: step) { await prepareStep() }
        .onChange(of: state.requestedSetupStep) { _, requestedStep in
            guard let requestedStep else { return }
            step = requestedStep
            state.requestedSetupStep = nil
        }
    }

    private var canFinish: Bool {
        state.isAddressValid
            && state.mailAuthorization == .authorized
            && !state.mappingHealth.needsAttention
    }

    private var canContinue: Bool {
        switch step {
        case .thingsAndMail:
            state.isAddressValid
        case .mailboxes:
            state.mailAuthorization == .authorized && !state.mappingHealth.needsAttention
        case .shortcutAndLogin:
            canFinish
        }
    }

    private func goBack() {
        if let previous = step.previous { step = previous }
    }

    private func goForward() {
        if let next = step.next {
            step = next
        } else {
            Task {
                await state.saveSetup()
                if state.preferences.isSetupComplete { dismissWindow(id: "setup") }
            }
        }
    }

    private func prepareStep() async {
        if state.requestedSetupStep == step { state.requestedSetupStep = nil }
        guard step == .mailboxes else { return }
        await state.refreshMailSetup()
    }
}
