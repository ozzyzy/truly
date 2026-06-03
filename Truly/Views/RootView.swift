import SwiftUI

struct RootView: View {

    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        HomeView()
            .environment(\.trulyTheme, .mint)
            .fullScreenCover(isPresented: .constant(!hasOnboarded)) {
                OnboardingView {
                    hasOnboarded = true
                }
                .environment(\.trulyTheme, .mint)
            }
            .onOpenURL { url in
                guard url.scheme == "truly", url.host == "shuffle" else { return }
                NotificationCenter.default.post(name: .trulyOpenSuggestion, object: nil)
            }
    }
}
