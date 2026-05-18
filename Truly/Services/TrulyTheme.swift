import SwiftUI

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b)
    }
}

struct TrulyTheme {
    let background:    Color
    let surface:       Color
    let surface2:      Color
    let textPrimary:   Color
    let textSecondary: Color
    let accent:        Color
    let border:        Color

    static let mint = TrulyTheme(
        background:    Color(hex: "FAFCFB"),
        surface:       Color(hex: "FFFFFF"),
        surface2:      Color(hex: "F3F7F5"),
        textPrimary:   Color(hex: "0F1815"),
        textSecondary: Color(hex: "5A655F"),
        accent:        Color(hex: "1FAE7B"),
        border:        Color(hex: "EBF0ED")
    )

    static let paper = TrulyTheme(
        background:    Color(hex: "FCFCFC"),
        surface:       Color(hex: "FFFFFF"),
        surface2:      Color(hex: "F4F4F4"),
        textPrimary:   Color(hex: "161616"),
        textSecondary: Color(hex: "6D6D6D"),
        accent:        Color(hex: "1FAE7B"),
        border:        Color(hex: "EEEEEE")
    )

    static let night = TrulyTheme(
        background:    Color(hex: "0A0B11"),
        surface:       Color(hex: "14151E"),
        surface2:      Color(hex: "1C1D28"),
        textPrimary:   Color(hex: "F0EDFF"),
        textSecondary: Color(hex: "8B8AAB"),
        accent:        Color(hex: "9F95F0"),
        border:        Color(hex: "1E1F2C")
    )
}

extension EnvironmentValues {
    @Entry var trulyTheme: TrulyTheme = .mint
}
