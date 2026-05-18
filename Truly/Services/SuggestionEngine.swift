import Foundation

final class SuggestionEngine {

    func suggest(
        catalog: [ActionItem],
        likedIds: Set<String>,
        hiddenIds: Set<String>,
        logs: [ActionLog]
    ) -> ActionItem? {

        let hour = Calendar.current.component(.hour, from: Date())
        let isEvening = (hour >= 20 || hour < 6)

        let visible = catalog.filter { !hiddenIds.contains($0.id) }
        guard !visible.isEmpty else { return nil }

        let recentIds = Set(logs.prefix(3).map { $0.actionId })
        let nonRecent = visible.filter { !recentIds.contains($0.id) }
        let base = nonRecent.isEmpty ? visible : nonRecent

        let liked = base.filter { likedIds.contains($0.id) }

        let eveningPool = base.filter { item in
            switch item.category {
            case .calm, .reading: return true
            case .body:           return item.minutes <= 5
            case .home:           return item.minutes <= 10
            case .creativity:     return item.minutes <= 5
            case .social:         return item.minutes <= 3
            }
        }

        let roll = Int.random(in: 1...100)
        let pool: [ActionItem]

        if isEvening, !eveningPool.isEmpty {
            if roll <= 45      { pool = eveningPool }
            else if roll <= 70, !liked.isEmpty { pool = liked }
            else               { pool = base }
        } else {
            if roll <= 40, !liked.isEmpty { pool = liked }
            else                          { pool = base }
        }

        return pool.randomElement()
    }
}
