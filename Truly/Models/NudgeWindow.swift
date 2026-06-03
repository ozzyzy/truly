import Foundation

struct NudgeWindow: Codable, Identifiable, Hashable {

    enum TimeOfDay: String, Codable, CaseIterable {
        case morning, afternoon, evening
    }

    var id: TimeOfDay { timeOfDay }
    let timeOfDay: TimeOfDay
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let icon: String
    let label: String
    let sublabel: String

    static let defaults: [NudgeWindow] = [
        NudgeWindow(
            timeOfDay: .morning,
            startHour: 7,  startMinute: 30,
            endHour:   10, endMinute:   30,
            icon: "sunrise",
            label: "Утро",
            sublabel: "где-то между 7:30 и 10:30"
        ),
        NudgeWindow(
            timeOfDay: .afternoon,
            startHour: 12, startMinute: 0,
            endHour:   15, endMinute:   0,
            icon: "sun.max",
            label: "День",
            sublabel: "где-то между 12:00 и 15:00"
        ),
        NudgeWindow(
            timeOfDay: .evening,
            startHour: 19, startMinute: 0,
            endHour:   22, endMinute:   30,
            icon: "moon.stars",
            label: "Вечер",
            sublabel: "где-то между 19:00 и 22:30"
        ),
    ]

    /// Случайная дата внутри окна для указанного дня.
    func randomDateWithin(referenceDate: Date = Date(),
                          calendar: Calendar = .current) -> Date? {
        let startSec = startHour * 3600 + startMinute * 60
        let endSec   = endHour   * 3600 + endMinute   * 60
        guard endSec > startSec else { return nil }
        let randomSec = Int.random(in: startSec...endSec)
        var c = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        c.hour   = randomSec / 3600
        c.minute = (randomSec % 3600) / 60
        c.second = 0
        return calendar.date(from: c)
    }
}

// MARK: – Persistence helpers

extension NudgeWindow.TimeOfDay {
    static func from(string: String) -> Set<NudgeWindow.TimeOfDay> {
        Set(string.split(separator: ",").compactMap { Self(rawValue: String($0)) })
    }

    static func toString(_ set: Set<NudgeWindow.TimeOfDay>) -> String {
        set.map(\.rawValue).sorted().joined(separator: ",")
    }
}
