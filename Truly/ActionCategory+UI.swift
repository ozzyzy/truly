import SwiftUI

extension ActionCategory {

    var displayName: String {
        switch self {
        case .reading:    return "чтение"
        case .calm:       return "спокойствие"
        case .body:       return "тело"
        case .home:       return "дом"
        case .creativity: return "творчество"
        case .social:     return "связь"
        }
    }

    /// Per-category color used for card tint, blobs, timer ring, pills
    var catColor: Color {
        switch self {
        case .body:       return Color(hex: "FF9173")
        case .calm:       return Color(hex: "29C79A")
        case .reading:    return Color(hex: "5B9EF4")
        case .creativity: return Color(hex: "AB8EF4")
        case .home:       return Color(hex: "F5BC4A")
        case .social:     return Color(hex: "F472AA")
        }
    }

    /// Category-aware phrase for the Done screen (gender-neutral Russian)
    var reclaimedPhrase: String {
        switch self {
        case .body:       return "Движение для тела"
        case .calm:       return "Тихий момент для себя"
        case .reading:    return "Время за книгой"
        case .creativity: return "Момент творчества"
        case .home:       return "Забота о пространстве"
        case .social:     return "Связь с близкими"
        }
    }

}

// MARK: – Category icon as SwiftUI Shape

struct CategoryIcon: View {
    let category: ActionCategory
    var size: CGFloat = 20
    var color: Color? = nil

    var body: some View {
        Canvas { ctx, canvasSize in
            let s = canvasSize.width / 20   // scale from 20×20 viewBox
            ctx.translateBy(x: 0, y: 0)

            var path = Path()
            switch category {
            case .body:
                // Running figure
                path.addEllipse(in: CGRect(x: 11*s, y: 1*s, width: 2.5*s, height: 2.5*s))
                path.move(to: CGPoint(x: 12.25*s, y: 3.5*s))
                path.addLine(to: CGPoint(x: 10*s, y: 8*s))
                path.addLine(to: CGPoint(x: 7*s, y: 6*s))
                path.addLine(to: CGPoint(x: 9*s, y: 11*s))
                path.addLine(to: CGPoint(x: 7*s, y: 16*s))
                path.move(to: CGPoint(x: 9*s, y: 11*s))
                path.addLine(to: CGPoint(x: 13*s, y: 13*s))
                path.addLine(to: CGPoint(x: 15*s, y: 16*s))
                path.move(to: CGPoint(x: 10*s, y: 8*s))
                path.addLine(to: CGPoint(x: 14*s, y: 7*s))

            case .calm:
                // Moon + 2 stars
                path.move(to: CGPoint(x: 12*s, y: 3*s))
                path.addCurve(
                    to: CGPoint(x: 5*s, y: 10*s),
                    control1: CGPoint(x: 8*s, y: 3*s),
                    control2: CGPoint(x: 5*s, y: 6*s)
                )
                path.addCurve(
                    to: CGPoint(x: 12*s, y: 17*s),
                    control1: CGPoint(x: 5*s, y: 14*s),
                    control2: CGPoint(x: 8*s, y: 17*s)
                )
                path.addCurve(
                    to: CGPoint(x: 12*s, y: 3*s),
                    control1: CGPoint(x: 16*s, y: 17*s),
                    control2: CGPoint(x: 16*s, y: 3*s)
                )
                // stars
                let starCtx = ctx
                var star1 = Path(); star1.move(to: CGPoint(x: 15*s, y: 6*s)); star1.addLine(to: CGPoint(x: 15.3*s, y: 6.8*s)); star1.addLine(to: CGPoint(x: 16*s, y: 6*s)); star1.addLine(to: CGPoint(x: 15.3*s, y: 5.2*s)); star1.closeSubpath()
                starCtx.fill(star1, with: .foreground)
                var star2 = Path(); star2.move(to: CGPoint(x: 16*s, y: 9.5*s)); star2.addLine(to: CGPoint(x: 16.2*s, y: 10*s)); star2.addLine(to: CGPoint(x: 16.8*s, y: 9.5*s)); star2.addLine(to: CGPoint(x: 16.2*s, y: 9*s)); star2.closeSubpath()
                starCtx.fill(star2, with: .foreground)

            case .reading:
                // Open book
                path.move(to: CGPoint(x: 10*s, y: 6*s))
                path.addLine(to: CGPoint(x: 10*s, y: 17*s))
                path.move(to: CGPoint(x: 10*s, y: 6*s))
                path.addCurve(to: CGPoint(x: 4*s, y: 4*s), control1: CGPoint(x: 8*s, y: 5*s), control2: CGPoint(x: 6*s, y: 4*s))
                path.addLine(to: CGPoint(x: 4*s, y: 16*s))
                path.addCurve(to: CGPoint(x: 10*s, y: 17*s), control1: CGPoint(x: 6*s, y: 15.5*s), control2: CGPoint(x: 8*s, y: 17*s))
                path.move(to: CGPoint(x: 10*s, y: 6*s))
                path.addCurve(to: CGPoint(x: 16*s, y: 4*s), control1: CGPoint(x: 12*s, y: 5*s), control2: CGPoint(x: 14*s, y: 4*s))
                path.addLine(to: CGPoint(x: 16*s, y: 16*s))
                path.addCurve(to: CGPoint(x: 10*s, y: 17*s), control1: CGPoint(x: 14*s, y: 15.5*s), control2: CGPoint(x: 12*s, y: 17*s))

            case .creativity:
                // Pencil
                path.move(to: CGPoint(x: 14*s, y: 3*s))
                path.addLine(to: CGPoint(x: 17*s, y: 6*s))
                path.addLine(to: CGPoint(x: 8*s, y: 15*s))
                path.addLine(to: CGPoint(x: 4*s, y: 16*s))
                path.addLine(to: CGPoint(x: 5*s, y: 12*s))
                path.closeSubpath()
                path.move(to: CGPoint(x: 14*s, y: 3*s))
                path.addLine(to: CGPoint(x: 17*s, y: 6*s))
                // tip
                path.move(to: CGPoint(x: 5*s, y: 12*s))
                path.addLine(to: CGPoint(x: 8*s, y: 15*s))

            case .home:
                // House
                path.move(to: CGPoint(x: 3*s, y: 9*s))
                path.addLine(to: CGPoint(x: 10*s, y: 3*s))
                path.addLine(to: CGPoint(x: 17*s, y: 9*s))
                path.addLine(to: CGPoint(x: 17*s, y: 17*s))
                path.addLine(to: CGPoint(x: 3*s, y: 17*s))
                path.closeSubpath()
                // door
                path.move(to: CGPoint(x: 8*s, y: 17*s))
                path.addLine(to: CGPoint(x: 8*s, y: 12*s))
                path.addLine(to: CGPoint(x: 12*s, y: 12*s))
                path.addLine(to: CGPoint(x: 12*s, y: 17*s))

            case .social:
                // Two speech bubbles
                path.addRoundedRect(
                    in: CGRect(x: 2*s, y: 3*s, width: 11*s, height: 9*s),
                    cornerSize: CGSize(width: 3*s, height: 3*s)
                )
                path.move(to: CGPoint(x: 5*s, y: 12*s))
                path.addLine(to: CGPoint(x: 3*s, y: 15*s))
                path.addLine(to: CGPoint(x: 7*s, y: 12*s))
                path.addRoundedRect(
                    in: CGRect(x: 8*s, y: 9*s, width: 10*s, height: 8*s),
                    cornerSize: CGSize(width: 3*s, height: 3*s)
                )
                path.move(to: CGPoint(x: 15*s, y: 17*s))
                path.addLine(to: CGPoint(x: 17*s, y: 19*s))
                path.addLine(to: CGPoint(x: 13*s, y: 17*s))
            }

            let iconColor = color ?? .primary
            ctx.stroke(path, with: .color(iconColor), style: StrokeStyle(lineWidth: 1.5*s, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}
