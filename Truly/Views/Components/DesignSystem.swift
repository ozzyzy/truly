import SwiftUI

// MARK: – Button

struct TrulyButton: View {
    @Environment(\.trulyTheme) private var theme

    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(.dm(15, .semibold))
                .tracking(-0.2)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(theme.textPrimary)
                .foregroundStyle(theme.background)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
