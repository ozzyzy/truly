import WidgetKit
import SwiftUI
import CoreText

@main
struct TrulyWidgetBundle: WidgetBundle {

    init() {
        registerFonts()
    }

    var body: some Widget {
        TrulyWidget()
    }

    // Widget lives at: Truly.app/PlugIns/TrulyWidgetExtension.appex/
    // Fonts live at:   Truly.app/Fonts/
    private func registerFonts() {
        let appBundle = Bundle.main.bundleURL
            .deletingLastPathComponent() // drop TrulyWidgetExtension.appex
            .deletingLastPathComponent() // drop PlugIns → now at Truly.app/
        let fontURL = appBundle.appendingPathComponent("Fonts/Newsreader-MediumItalic.ttf")
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
}
