import SwiftUI

extension Font {
    static func dm(_ size: CGFloat, _ weight: Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .medium:   name = "DMSans-Medium"
        case .semibold: name = "DMSans-SemiBold"
        case .bold:     name = "DMSans-Bold"
        default:        name = "DMSans-Regular"
        }
        return .custom(name, size: size)
    }

    static func newsreader(_ size: CGFloat, medium: Bool = true) -> Font {
        .custom(medium ? "Newsreader-MediumItalic" : "Newsreader-Italic", size: size)
    }
}
