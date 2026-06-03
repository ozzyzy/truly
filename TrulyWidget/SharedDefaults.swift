import Foundation

enum SharedDefaults {
    static let suiteName = "group.com.truly.shared"

    static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    enum Keys {
        static let totalMinutes   = "shared.totalMinutes"
        static let weeklyMinutes  = "shared.weeklyMinutes"
        static let weekStartDate  = "shared.weekStartDate"
    }
}
