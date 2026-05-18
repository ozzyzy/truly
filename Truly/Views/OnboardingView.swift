import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.trulyTheme) private var theme
    @EnvironmentObject private var preferenceStore: PreferenceStore

    private let notifier = NotificationService()

    @AppStorage("nudgeHours") private var nudgeHoursString: String = "9,13,21"
    @AppStorage("screenThreshold") private var screenThreshold: Int = 30

    @State private var step = 0
    @State private var breathe = false
    @State private var selectedWindows: Set<Int> = [9, 13, 21]
    @State private var loopPhase: Int = 0  // 0=card, 1=orb, 2=sparkle
    @State private var loopTimer: Timer? = nil

    let onDone: () -> Void

    private let totalSteps = 4

    // MARK: – Data

    struct TimeWindow: Identifiable {
        let id: Int
        let icon: String
        let label: String
        let sublabel: String
    }

    private let windows: [TimeWindow] = [
        TimeWindow(id: 9,  icon: "sunrise",    label: "Утро",  sublabel: "когда день только начинается"),
        TimeWindow(id: 13, icon: "sun.max",    label: "День",  sublabel: "в середине всего"),
        TimeWindow(id: 21, icon: "moon.stars", label: "Вечер", sublabel: "перед тем как уснуть"),
    ]

    private let thresholdOptions: [(Int, String)] = [
        (15, "часто"),
        (30, "средне"),
        (60, "реже"),
    ]

    // MARK: – Body

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Mini loop preview — welcome step only
                if step == 0 {
                    loopPreview
                        .padding(.bottom, 32)
                        .onAppear { startLoopTimer() }
                        .onDisappear { loopTimer?.invalidate() }
                }

                // Step content
                Group {
                    switch step {
                    case 0:  welcomeStep
                    case 1:  timePickerStep
                    case 2:  thresholdStep
                    default: notificationStep
                    }
                }

                Spacer()

                // Step dots
                stepDots
                    .padding(.bottom, 20)

                // Bottom actions
                VStack(spacing: 12) {
                    switch step {
                    case 0:
                        TrulyButton("Начать") {
                            withAnimation { step = 1 }
                        }

                    case 1:
                        TrulyButton("Дальше") {
                            nudgeHoursString = selectedWindows.sorted()
                                .map(String.init).joined(separator: ",")
                            withAnimation { step = 2 }
                        }

                    case 2:
                        TrulyButton("Дальше") {
                            withAnimation { step = 3 }
                        }

                    default:
                        TrulyButton("Включить") {
                            Task {
                                let hours = nudgeHoursString
                                    .split(separator: ",")
                                    .compactMap { Int($0) }
                                let ok = await notifier.requestPermission()
                                if ok {
                                    await notifier.scheduleDailyNudges(hours: hours)
                                }
                                finish()
                            }
                        }
                        Button { finish() } label: {
                            Text(verbatim: "Позже")
                                .font(.dm(15, .medium))
                                .foregroundStyle(theme.textSecondary.opacity(0.55))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
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
        VStack(alignment: .leading, spacing: 16) {
            (Text("Маленькие моменты, которые возвращают ")
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
    }

    @ViewBuilder
    private var timePickerStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Когда тебя")
                    .font(.dm(30, .bold))
                    .foregroundStyle(theme.textPrimary)
                Text("найти?")
                    .font(.newsreader(30))
                    .foregroundStyle(theme.textPrimary)
            }
            .tracking(-0.3)

            Text("Выбери моменты, в которые ты чаще всего где-то не здесь.")
                .font(.dm(15))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .padding(.bottom, 4)

            VStack(spacing: 10) {
                ForEach(windows) { window in
                    let isSelected = selectedWindows.contains(window.id)
                    Button {
                        if isSelected {
                            if selectedWindows.count > 1 { selectedWindows.remove(window.id) }
                        } else {
                            selectedWindows.insert(window.id)
                        }
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
                                    .foregroundStyle(theme.textSecondary.opacity(0.6))
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
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .stroke(isSelected ? theme.accent.opacity(0.4) : theme.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(duration: 0.25), value: isSelected)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
    }

    @ViewBuilder
    private var thresholdStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Скрин-тайм:")
                    .font(.newsreader(30))
                    .foregroundStyle(theme.textPrimary)
                Text("когда напомнить?")
                    .font(.dm(30, .bold))
                    .foregroundStyle(theme.textPrimary)
            }
            .tracking(-0.3)

            Text("Truly мягко вернётся к тебе, если ты в телефоне дольше выбранного порога.")
                .font(.dm(15))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .padding(.bottom, 4)

            VStack(spacing: 10) {
                ForEach(thresholdOptions, id: \.0) { minutes, label in
                    let isSelected = screenThreshold == minutes
                    Button {
                        withAnimation(.spring(duration: 0.25)) { screenThreshold = minutes }
                    } label: {
                        HStack {
                            HStack(alignment: .firstTextBaseline, spacing: 5) {
                                Text(verbatim: "\(minutes)")
                                    .font(.dm(22, .bold))
                                    .foregroundStyle(theme.textPrimary)
                                Text(verbatim: "минут")
                                    .font(.dm(14))
                                    .foregroundStyle(theme.textSecondary.opacity(0.6))
                            }
                            Spacer()
                            Text(verbatim: label)
                                .font(.dm(13))
                                .foregroundStyle(theme.textSecondary.opacity(0.5))
                                .padding(.trailing, 8)
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundStyle(isSelected ? theme.accent : theme.border)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(isSelected ? theme.accent.opacity(0.08) : theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .stroke(isSelected ? theme.accent.opacity(0.4) : theme.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(duration: 0.25), value: isSelected)
                }
            }

            Text("Можно поменять в настройках")
                .font(.dm(12))
                .foregroundStyle(theme.textSecondary.opacity(0.4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
    }

    @ViewBuilder
    private var notificationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Bell in a border circle
            ZStack {
                Circle()
                    .stroke(theme.border, lineWidth: 1.5)
                    .frame(width: 48, height: 48)
                Image(systemName: "bell")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(theme.textPrimary)
            }
            .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 4) {
                (Text("Одно ") + Text("тихое").font(.newsreader(30)))
                    .font(.dm(30, .bold))
                    .foregroundStyle(theme.textPrimary)
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
            // Phase 0 — Mini action card
            miniCard
                .opacity(loopPhase == 0 ? 1 : 0)
                .scaleEffect(loopPhase == 0 ? 1 : (loopPhase == 1 ? 0.7 : 0.5))
                .animation(.spring(response: 0.55, dampingFraction: 0.75), value: loopPhase)

            // Phase 1 — Timer orb
            miniOrb
                .opacity(loopPhase == 1 ? 1 : 0)
                .scaleEffect(loopPhase == 1 ? 1 : (loopPhase == 0 ? 1.3 : 0.6))
                .animation(.spring(response: 0.55, dampingFraction: 0.75), value: loopPhase)

            // Phase 2 — Completion sparkle
            miniSparkle
                .opacity(loopPhase == 2 ? 1 : 0)
                .scaleEffect(loopPhase == 2 ? 1 : 0.7)
                .animation(.spring(response: 0.45, dampingFraction: 0.7), value: loopPhase)
        }
        .frame(height: 160)
    }

    private var miniCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(verbatim: "спокойствие")
                    .font(.newsreader(11))
                    .foregroundStyle(Color(hex: "29C79A"))
                Spacer()
                CategoryIcon(category: .calm, size: 13, color: Color(hex: "29C79A"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            Text(verbatim: "Закрыть глаза на 5 минут")
                .font(.dm(18, .bold))
                .foregroundStyle(Color(hex: "1A1A1A"))
                .tracking(-0.3)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .frame(width: 220)
        .background(Color.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private var miniOrb: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "29C79A").opacity(0.18))
                .frame(width: 130, height: 130)
                .scaleEffect(breathe ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: breathe)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "29C79A").opacity(0.6), Color(hex: "29C79A").opacity(0.2)],
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
            Text(verbatim: "Ты вернулась к себе")
                .font(.newsreader(13))
                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.55))
        }
    }

    private func startLoopTimer() {
        loopPhase = 0
        let durations: [Double] = [1.6, 1.2, 1.0]
        func scheduleNext() {
            let delay = durations[loopPhase % durations.count]
            loopTimer?.invalidate()
            loopTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
                withAnimation { loopPhase = (loopPhase + 1) % 3 }
                scheduleNext()
            }
        }
        scheduleNext()
    }

    // MARK: – Actions

    private func finish() {
        loopTimer?.invalidate()
        onDone()
        dismiss()
    }
}
