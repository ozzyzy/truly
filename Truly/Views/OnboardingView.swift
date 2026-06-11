import SwiftUI

private let windowPickerRadius = DesignConstants.windowPickerRadius

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.trulyTheme) private var theme

    private let notifier = NotificationService()

    @AppStorage("nudgeWindowIds") private var nudgeWindowIdsString: String = "morning,afternoon,evening"

    @State private var step = 0
    @State private var breathe = false
    @State private var selectedWindows: Set<NudgeWindow.TimeOfDay> = [.morning, .afternoon, .evening]
    @State private var loopPhase: Int = 0       // 0=card, 1=orb, 2=sparkle
    @State private var loopTimer: Timer? = nil
    @State private var wiggleWindow: NudgeWindow.TimeOfDay? = nil  // for shake feedback

    let onDone: () -> Void

    private let totalSteps = 3
    private let windows = NudgeWindow.defaults

    // MARK: – Body

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button — visible only on step 2
                HStack {
                    if step == 2 {
                        Button {
                            withAnimation(.spring(duration: 0.3)) { step = 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(theme.textSecondary.opacity(0.6))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .frame(height: 44)

                Spacer()

                // Step content
                Group {
                    switch step {
                    case 0:  welcomeStep
                    case 1:  timePickerStep
                    default: notificationStep
                    }
                }

                Spacer()

                // Step dots
                stepDots
                    .padding(.bottom, 20)

                // Bottom actions
                VStack(spacing: 0) {
                    switch step {
                    case 0:
                        TrulyButton("Начать") {
                            withAnimation { step = 1 }
                        }

                    case 1:
                        TrulyButton("Дальше") {
                            nudgeWindowIdsString = NudgeWindow.TimeOfDay.toString(selectedWindows)
                            withAnimation { step = 2 }
                        }

                    default:
                        TrulyButton("Включить") {
                            Task {
                                let ok = await notifier.requestPermission()
                                if ok {
                                    let ws = NudgeWindow.defaults.filter { selectedWindows.contains($0.timeOfDay) }
                                    await notifier.scheduleDailyNudges(windows: ws)
                                }
                                finish()
                            }
                        }
                        // "Позже" — compact, clearly secondary
                        Button { finish() } label: {
                            Text(verbatim: "Позже")
                                .font(.dm(15, .medium))
                                .foregroundStyle(theme.textSecondary.opacity(0.45))
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: – Step dots

    private var stepDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i == step ? theme.textPrimary : theme.border)
                    .frame(width: i == step ? 22 : 6, height: 5)
                    .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
    }

    // MARK: – Steps

    @ViewBuilder
    private var welcomeStep: some View {
        // Preview and headline share the same left-aligned column
        VStack(alignment: .leading, spacing: 28) {
            // Loop preview — decorative, clearly not tappable
            loopPreview
                .padding(.leading, 28)
                .onAppear { startLoopTimer() }
                .onDisappear { loopTimer?.invalidate() }

            VStack(alignment: .leading, spacing: 16) {
                (Text("Маленькие моменты,\nкоторые возвращают ")
                 + Text("тебя").font(.newsreader(34))
                 + Text(" себе."))
                    .font(.dm(34, .bold))
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                    .tracking(-0.5)

                Text("Truly помогает превратить короткие окна времени в что-то настоящее.")
                    .font(.dm(15))
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var timePickerStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Both lines get explicit tracking
            VStack(alignment: .leading, spacing: 4) {
                Text("Когда тебя")
                    .font(.dm(30, .bold))
                    .foregroundStyle(theme.textPrimary)
                    .tracking(-0.3)
                Text("найти?")
                    .font(.newsreader(30))
                    .foregroundStyle(theme.textPrimary)
                    .tracking(-0.3)
            }

            Text("Выбери моменты, в которые ты чаще всего где-то не здесь.")
                .font(.dm(15))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .padding(.bottom, 4)

            VStack(spacing: 10) {
                ForEach(windows) { window in
                    let isSelected = selectedWindows.contains(window.timeOfDay)
                    let isWiggling = wiggleWindow == window.timeOfDay
                    Button {
                        toggleWindow(window.timeOfDay)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: window.icon)
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(isSelected ? theme.accent : theme.textSecondary.opacity(0.5))
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(window.label)
                                    .font(.dm(16, .semibold))
                                    .foregroundStyle(theme.textPrimary)
                                Text(window.sublabel)
                                    .font(.dm(13))
                                    .foregroundStyle(theme.textSecondary.opacity(0.55))
                            }
                            Spacer()
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundStyle(isSelected ? theme.accent : theme.border)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(isSelected ? theme.accent.opacity(0.08) : theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: windowPickerRadius, style: .continuous)
                                .stroke(isSelected ? theme.accent.opacity(0.4) : theme.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: windowPickerRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(duration: 0.25), value: isSelected)
                    .modifier(WiggleModifier(trigger: isWiggling))
                }

                Text("Truly появится где-то внутри окна — каждый день в разное время")
                    .font(.dm(13))
                    .foregroundStyle(theme.textSecondary.opacity(0.4))
                    .multilineTextAlignment(.leading)
                    .padding(.top, 2)
                    .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
    }

    @ViewBuilder
    private var notificationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Simple bell — no heavy border circle
            Image(systemName: "bell")
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundStyle(theme.textPrimary.opacity(0.7))
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 4) {
                (Text("Одно ") + Text("тихое").font(.newsreader(30)))
                    .font(.dm(30, .bold))
                    .foregroundStyle(theme.textPrimary)
                    .tracking(-0.3)
                Text("напоминание.")
                    .font(.dm(30, .bold))
                    .foregroundStyle(theme.textPrimary)
                    .tracking(-0.3)
            }

            Text("И минутка для себя не потеряется в потоке дня.")
                .font(.dm(15))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
    }

    // MARK: – Loop preview (step 0 animation)

    @ViewBuilder
    private var loopPreview: some View {
        ZStack {
            miniCard
                .opacity(loopPhase == 0 ? 1 : 0)
                .scaleEffect(loopPhase == 0 ? 1 : (loopPhase == 1 ? 0.7 : 0.5))
                .animation(.spring(response: 0.55, dampingFraction: 0.75), value: loopPhase)

            miniOrb
                .opacity(loopPhase == 1 ? 1 : 0)
                .scaleEffect(loopPhase == 1 ? 1 : (loopPhase == 0 ? 1.3 : 0.6))
                .animation(.spring(response: 0.55, dampingFraction: 0.75), value: loopPhase)

            miniSparkle
                .opacity(loopPhase == 2 ? 1 : 0)
                .scaleEffect(loopPhase == 2 ? 1 : 0.7)
                .animation(.spring(response: 0.45, dampingFraction: 0.7), value: loopPhase)
        }
        .frame(height: 140)
        .allowsHitTesting(false)  // явно декоративная, не перехватывает тапы
    }

    private var miniCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(verbatim: "спокойствие")
                    .font(.newsreader(11))
                    .foregroundStyle(theme.accent)
                Spacer()
                CategoryIcon(category: .calm, size: 13, color: theme.accent)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            Text(verbatim: "Закрыть глаза на 5 минут")
                .font(.dm(18, .bold))
                .foregroundStyle(theme.textPrimary)
                .tracking(-0.3)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .frame(width: 220)
        // Theme-aware surface, no hard-coded white
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
        )
        // Reduced shadow — clearly decorative, not interactive
        .shadow(color: theme.textPrimary.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    private var miniOrb: some View {
        ZStack {
            Circle()
                .fill(theme.accent.opacity(0.18))
                .frame(width: 130, height: 130)
                .scaleEffect(breathe ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: breathe)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.accent.opacity(0.6), theme.accent.opacity(0.2)],
                        center: .center, startRadius: 5, endRadius: 45
                    )
                )
                .frame(width: 88, height: 88)
                .scaleEffect(breathe ? 1.04 : 0.96)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: breathe)
            Text(verbatim: "05:00")
                .font(.dm(20, .medium))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .onAppear { breathe = true }
    }

    private var miniSparkle: some View {
        VStack(spacing: 8) {
            Text(verbatim: "✦")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(theme.accent)
            // Гендерно-нейтральный текст
            Text(verbatim: "Момент для себя")
                .font(.newsreader(13))
                .foregroundStyle(theme.textSecondary.opacity(0.55))
        }
    }

    // MARK: – Timer (RunLoop.common — не замерзает при скролле)

    private func startLoopTimer() {
        loopPhase = 0
        scheduleNextLoop()
    }

    private func scheduleNextLoop() {
        let durations: [Double] = [1.6, 1.2, 1.0]
        let delay = durations[loopPhase % durations.count]
        loopTimer?.invalidate()
        let t = Timer(timeInterval: delay, repeats: false) { _ in
            withAnimation { loopPhase = (loopPhase + 1) % 3 }
            scheduleNextLoop()
        }
        RunLoop.main.add(t, forMode: .common)
        loopTimer = t
    }

    // MARK: – Actions

    private func toggleWindow(_ tod: NudgeWindow.TimeOfDay) {
        if selectedWindows.contains(tod) {
            guard selectedWindows.count > 1 else {
                // Нельзя убрать последнее — тряхнуть
                wiggleWindow = tod
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { wiggleWindow = nil }
                return
            }
            selectedWindows.remove(tod)
        } else {
            selectedWindows.insert(tod)
        }
    }

    private func finish() {
        loopTimer?.invalidate()
        onDone()
        dismiss()
    }
}

// MARK: – Wiggle modifier

private struct WiggleModifier: ViewModifier {
    let trigger: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: trigger ? 6 : 0)
            .animation(
                trigger
                    ? .spring(response: 0.15, dampingFraction: 0.2).repeatCount(4, autoreverses: true)
                    : .default,
                value: trigger
            )
    }
}
