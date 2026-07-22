import Foundation

enum SendDisposition: Sendable, Equatable {
    case accepted
    case rejected(code: Int)
    case indeterminate(code: Int)
}
