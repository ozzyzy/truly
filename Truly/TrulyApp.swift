import SwiftUI
import UserNotifications
import CoreText

@main
struct TrulyApp: App {

    @StateObject private var preferenceStore  = PreferenceStore()
    @StateObject private var logStore         = LogStore()

    private let notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        registerFonts()
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

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(preferenceStore)
                .environmentObject(logStore)
        }
    }
}
