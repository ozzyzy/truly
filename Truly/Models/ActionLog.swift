import Foundation

struct ActionLog: Identifiable, Codable, Hashable {
    let id: String
    let actionId: String
    let titleSnapshot: String
    let category: ActionCategory
    let plannedMinutes: Int
    let completedMinutes: Int
    let completedAt: Date
}
