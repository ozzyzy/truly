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
            startHour: 8,  startMinute: 0,
            endHour:   11, endMinute:   0,
            icon: "sunrise",
            label: "Утро",
            sublabel: "между 8:00 и 11:00"
        ),
        NudgeWindow(
            timeOfDay: .afternoon,
            startHour: 12, startMinute: 0,
            endHour:   16, endMinute:   0,
            icon: "sun.max",
            label: "День",
            sublabel: "между 12:00 и 16:00"
        ),
        NudgeWindow(
            timeOfDay: .evening,
            startHour: 19, startMinute: 0,
            endHour:   22, endMinute:   0,
            icon: "moon.stars",
            label: "Вечер",
            sublabel: "между 19:00 и 22:00"
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
