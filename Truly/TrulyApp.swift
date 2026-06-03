import SwiftUI
import UserNotifications
import CoreText

@main
struct TrulyApp: App {

    @StateObject private var preferenceStore  = PreferenceStore()
    @StateObject private var logStore         = LogStore()

    private let notificationDelegate = NotificationDelegate()
    private let notifier             = NotificationService()

    @AppStorage("nudgeWindowIds") private var nudgeWindowIds: String = "morning,afternoon,evening"

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        registerFonts()
        migrateNudgeSettings()
    }

    // MARK: – Nudge settings migration (v1 fixed hours → v2 windows)

    private func migrateNudgeSettings() {
        let defaults = UserDefaults.standard
        let newKey   = "nudgeWindowIds"
        let oldKey   = "nudgeHours"

        guard defaults.string(forKey: newKey) == nil else { return }  // already migrated

        if let old = defaults.string(forKey: oldKey), !old.isEmpty {
            let hours = old.split(separator: ",").compactMap { Int($0) }
            var windows: Set<NudgeWindow.TimeOfDay> = []
            for h in hours {
                switch h {
                case 0..<11:  windows.insert(.morning)
                case 11..<17: windows.insert(.afternoon)
                default:      windows.insert(.evening)
                }
            }
            defaults.set(NudgeWindow.TimeOfDay.toString(windows), forKey: newKey)
        } else {
            // Fresh install — all three windows on
            defaults.set("morning,afternoon,evening", forKey: newKey)
        }
    }

    private func registerFonts() {
        let fontNames = [
            "DMSans-Regular", "DMSans-Medium", "DMSans-SemiBold", "DMSans-Bold",
            "Newsreader-Italic", "Newsreader-MediumItalic"
        ]
        for name in fontNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    // MARK: – Nudge reschedule

    func rescheduleNudges() async {
        let selected = NudgeWindow.TimeOfDay.from(string: nudgeWindowIds)
        let windows  = NudgeWindow.defaults.filter { selected.contains($0.timeOfDay) }
        await notifier.scheduleDailyNudges(windows: windows,
                                           lastSessionAt: logStore.logs.first?.completedAt)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(preferenceStore)
                .environmentObject(logStore)
                .onAppear { logStore.syncSharedTotal() }
                .task { await rescheduleNudges() }
        }
    }
}
