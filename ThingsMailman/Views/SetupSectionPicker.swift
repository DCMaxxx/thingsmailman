import SwiftUI

struct SetupSectionPicker: View {
    @Binding var selection: SetupStep

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SetupStep.allCases) { step in
                Button {
                    selection = step
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: step.systemImage)
                            .font(.title2)
                            .frame(height: 26)
                        Text(step.title)
                    }
                    .foregroundStyle(selection == step ? Color.accentColor : Color.secondary)
                    .frame(width: 104, height: 64)
                    .background(
                        selection == step ? Color.secondary.opacity(0.12) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(step.title)
                .accessibilityAddTraits(selection == step ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Setup section")
    }
}
