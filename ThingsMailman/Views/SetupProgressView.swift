import SwiftUI

struct SetupProgressView: View {
    let step: SetupStep

    var body: some View {
        HStack(spacing: 10) {
            ForEach(SetupStep.allCases) { item in
                Label(item.title, systemImage: symbol(for: item))
                    .labelStyle(CompactLabelStyle())
                    .font(.headline)
                    .foregroundStyle(color(for: item))
                    .lineLimit(1)

                if item != SetupStep.allCases.last {
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                    Spacer(minLength: 0)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(step.rawValue + 1) of \(SetupStep.allCases.count): \(step.title)")
    }

    private func symbol(for item: SetupStep) -> String {
        if item.rawValue < step.rawValue { return "checkmark.circle.fill" }
        return "\(item.rawValue + 1).circle.fill"
    }

    private func color(for item: SetupStep) -> Color {
        if item == step { return .accentColor }
        if item.rawValue < step.rawValue { return .primary }
        return .secondary
    }
}
