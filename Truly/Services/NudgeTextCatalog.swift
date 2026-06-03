import Foundation

struct NudgeText: Codable {
    let title: String
    let body: String?
}

final class NudgeTextCatalog {

    static let shared = NudgeTextCatalog()

    private struct Payload: Codable {
        let morning:   [NudgeText]
        let afternoon: [NudgeText]
        let evening:   [NudgeText]
    }

    private let payload: Payload?

    private init() {
        guard let url  = Bundle.main.url(forResource: "nudgeTexts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(Payload.self, from: data) else {
            payload = nil
            return
        }
        payload = decoded
    }

    func randomText(for timeOfDay: NudgeWindow.TimeOfDay) -> NudgeText {
        let pool: [NudgeText]
        switch timeOfDay {
        case .morning:   pool = payload?.morning   ?? []
        case .afternoon: pool = payload?.afternoon ?? []
        case .evening:   pool = payload?.evening   ?? []
        }
        return pool.randomElement() ?? NudgeText(title: "Truly", body: "момент для себя")
    }
}
