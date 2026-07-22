import Foundation

enum PostSendAction: String, CaseIterable, Codable, Identifiable, Sendable {
    case leave
    case archive
    case trash
    case move

    var id: Self { self }

    var title: String {
        switch self {
        case .leave: "Keep in Inbox"
        case .archive: "Archive"
        case .trash: "Trash"
        case .move: "Move to folder"
        }
    }

    var needsMailboxMapping: Bool { self == .archive || self == .move }
}
