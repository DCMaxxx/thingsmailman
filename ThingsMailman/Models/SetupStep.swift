import Foundation

enum SetupStep: Int, CaseIterable, Identifiable, Sendable {
    case thingsAndMail
    case mailboxes
    case shortcutAndLogin

    var id: Self { self }

    var title: String {
        switch self {
        case .thingsAndMail: "Things"
        case .mailboxes: "Mail"
        case .shortcutAndLogin: "Automation"
        }
    }

    var systemImage: String {
        switch self {
        case .thingsAndMail: "at"
        case .mailboxes: "envelope.badge.shield.half.filled"
        case .shortcutAndLogin: "command"
        }
    }

    var next: SetupStep? { SetupStep(rawValue: rawValue + 1) }
    var previous: SetupStep? { SetupStep(rawValue: rawValue - 1) }
}
