import AppIntents
import Foundation

struct StartShuffleIntent: AppIntent {
    static var title: LocalizedStringResource = "Открыть Truly"
    static var description = IntentDescription("Запускает случайный момент в Truly.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .trulyOpenSuggestion, object: nil)
        return .result()
    }
}
