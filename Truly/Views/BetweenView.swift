import SwiftUI

struct BetweenView: View {

    let lastMin: Int
    let totalMin: Int
    let onDone: () -> Void

    @Environment(\.trulyTheme) private var theme
    @State private var visible = false
    @State private var breathe = false

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 64) {
                // Just-completed contribution
                VStack(spacing: 6) {
                    Text(verbatim: "+\(lastMin)м")
                        .font(.dm(38, .medium))
                        .tracking(-1.2)
                        .foregroundStyle(theme.textPrimary)
                    Text(verbatim: "только что")
                        .font(.newsreader(13))
                        .foregroundStyle(theme.textSecondary.opacity(0.55))
                }

                // Cumulative total — breathing
                VStack(spacing: 14) {
                    Text(verbatim: fmtMin(totalMin))
                        .font(.dm(72, .medium))
                        .tracking(-3)
                        .foregroundStyle(theme.textPrimary)
                        .scaleEffect(breathe ? 1.04 : 0.96)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breathe)
                    Text(verbatim: "всего вернула себе")
                        .font(.newsreader(13))
                        .foregroundStyle(theme.textSecondary.opacity(0.55))
                }
            }
        }
        .opacity(visible ? 1 : 0)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9)) { visible = true }
            breathe = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { onDone() }
        }
        .onTapGesture { onDone() }
    }

    private func fmtMin(_ m: Int) -> String {
        if m == 0 { return "0м" }
        if m < 60 { return "\(m)м" }
        let h = m / 60, r = m % 60
        return r > 0 ? "\(h)ч \(r)м" : "\(h)ч"
    }
}
