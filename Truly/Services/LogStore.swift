import Foundation
import Combine
final class LogStore: ObservableObject {
    @Published private(set) var logs: [ActionLog] = []

    private let key = "truly.logs.v1"
    private let milestoneKey = "milestoneOneHourShown"

    var totalMinutes: Int {
        logs.reduce(0) { $0 + $1.completedMinutes }
    }

    var milestoneOneHourShown: Bool {
        get { UserDefaults.standard.bool(forKey: milestoneKey) }
        set { UserDefaults.standard.set(newValue, forKey: milestoneKey) }
    }

    init() { load() }

    func add(_ log: ActionLog) {
        logs.insert(log, at: 0)
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ActionLog].self, from: data) else {
            logs = []
            return
        }
        logs = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(logs) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
