import SwiftUI

struct MailboxDestinationPickerRow: View {
    @Binding var route: MailboxRoute?
    let mailboxes: [MailboxDescriptor]
    let title: String
    let needsAttention: Bool
    let onChange: (MailboxRoute?) -> Void

    var body: some View {
        HStack {
            if needsAttention {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(title)
                }
                    .foregroundStyle(.orange)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(title), needs attention")
            } else {
                Text(title)
            }

            Spacer()

            Picker(title, selection: $route) {
                Text("Choose a mailbox…").tag(Optional<MailboxRoute>.none)
                ForEach(mailboxes) { mailbox in
                    Text(mailbox.displayName).tag(Optional(mailbox.route))
                }
            }
            .labelsHidden()
            .fixedSize()
            .frame(width: 260, alignment: .trailing)
            .onChange(of: route) { _, newValue in onChange(newValue) }
        }
        .frame(maxWidth: .infinity)
    }
}
