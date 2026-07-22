import SwiftUI

struct SetupThingsAndMailStepView: View {
    @Bindable var state: AppState
    @FocusState private var isAddressFieldFocused: Bool
    @State private var hasValidatedAddress = false

    init(state: AppState) {
        self.state = state
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    LabeledContent("Things Mailman address") {
                        HStack {
                            TextField(
                                "Things Mailman address",
                                text: $state.thingsAddress,
                                prompt: Text("example@things.email")
                            )
                            .labelsHidden()
                            .textContentType(.emailAddress)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 230)
                            .focused($isAddressFieldFocused)
                            .onSubmit(validateAddress)
                            .accessibilityLabel("Things Mailman address")

                            PasteButton(payloadType: String.self, onPaste: pasteAddress)
                        }
                    }

                    if hasValidatedAddress && !isAddressFieldFocused && !state.isAddressValid {
                        Label("Enter an address ending in @things.email.", systemImage: "exclamationmark.circle")
                            .labelStyle(CompactLabelStyle())
                            .foregroundStyle(.red)
                    }

                    Text("In Things, open **Settings → Things Cloud → Mail to Things → Manage**, enable Mail to Things, then copy your private address and paste it above. [More info](https://culturedcode.com/things/support/articles/2908262/)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: isAddressFieldFocused) { wasFocused, isFocused in
            if wasFocused && !isFocused { hasValidatedAddress = true }
        }
        .task(id: state.thingsAddress) {
            guard state.preferences.isSetupComplete else { return }
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await state.saveAddress()
        }
    }

    private func validateAddress() {
        hasValidatedAddress = true
        isAddressFieldFocused = false
    }

    private func pasteAddress(_ values: [String]) {
        guard let value = values.first else { return }
        state.thingsAddress = value.trimmingCharacters(in: .whitespacesAndNewlines)
        hasValidatedAddress = true
        isAddressFieldFocused = false
    }
}
