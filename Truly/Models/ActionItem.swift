import Foundation

enum ActionCategory: String, Codable {
    case reading, body, home, calm, creativity, social
}

struct ActionItem: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let category: ActionCategory
    let minutes: Int
}
