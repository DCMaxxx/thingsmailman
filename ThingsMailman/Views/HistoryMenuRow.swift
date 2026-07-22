import SwiftUI

struct HistoryMenuRow: View {
    let entry: HistoryEntry

    var body: some View {
        Label(entry.menuSubject, systemImage: entry.outcome.systemImage)
            .accessibilityLabel("\(entry.menuSubject), \(entry.outcome.title)")
    }
}
