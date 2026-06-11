import SwiftUI
import UserNotifications

struct TimerFlowView: View {

    let action: ActionItem
    let onFinished: (Int) -> Void

    @Environment(\.trulyTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase

    // MARK: – State

    /// Nil when paused — source of truth for time remaining.
    @State private var endDate:  Date?
    /// Snapshot of seconds left, used while paused and to compute elapsed.
    @State private var remaining: Int
    /// Display ticker (fires every 0.5 s, just reads from endDate).
    @State private var ticker: Timer?

    @State private var isPaused        = false
    @State private var breathe         = false
    @State private var timeUpPending   = false
    @State private var flashOpacity: Double = 0

    private let total: Int
    private var catColor: Color { action.category.catColor }

    init(action: ActionItem, onFinished: @escaping (Int) -> Void) {
        self.action     = action
        self.onFinished = onFinished
        let secs        = action.minutes * 60
        _remaining      = State(initialValue: secs)
        self.total      = secs
    }

    // MARK: – Body

    var body: some View {
        ZStack {
            ZStack {
                theme.background.ignoresSafeArea()
                RadialGradient(
                    colors: [catColor.opacity(0.09), theme.background],
                    center: UnitPoint(x: 0.5, y: 0.35),
                    startRadius: 60, endRadius: 420
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 0) {

                // ── Header ────────────────────────────────────────────
                HStack {
                    Button { cancel() } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(theme.textSecondary)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(action.title)
                        .font(.dm(13, .medium))
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)

                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // ── Breathing circles ─────────────────────────────────
                ZStack {
                    Circle()
                        .fill(catColor.opacity(breathe ? 0.10 : 0.18))
                        .frame(width: 290, height: 290)
                        .scaleEffect(breathe ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breathe)

                    Circle()
                        .fill(RadialGradient(
                            colors: [catColor.opacity(0.60), catColor.opacity(0.22)],
                            center: .center, startRadius: 10, endRadius: 100
                        ))
                        .frame(width: 195, height: 195)
                        .scaleEffect(breathe ? 1.06 : 0.94)
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breathe)
                }

                Spacer()

                // ── Timer label ───────────────────────────────────────
                VStack(spacing: 6) {
                    Text(verbatim: timeString(remaining))
                        .font(.dm(40, .medium))
                        .monospacedDigit()
                        .tracking(-0.5)
                        .foregroundStyle(theme.textPrimary)

                    if isPaused {
                        Text(verbatim: "пауза")
                            .font(.dm(11, .medium))
                            .tracking(0.4)
                            .foregroundStyle(theme.textSecondary.opacity(0.5))
                    }
                }

                Spacer()

                // ── Controls ──────────────────────────────────────────
                VStack(spacing: 18) {
                    HStack(spacing: 20) {
                        circleButton(systemName: isPaused ? "play.fill" : "pause.fill") {
                            togglePause()
                        }
                        circleButton(systemName: "xmark") {
                            cancel()
                        }
                    }

                    Button { finish() } label: {
                        Text(verbatim: "закончить раньше")
                            .font(.newsreader(13, medium: false))
                            .foregroundStyle(theme.textSecondary.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 52)
            }
            .opacity(timeUpPending ? 0.2 : 1)
            .animation(.easeInOut(duration: 0.5), value: timeUpPending)

            // ── Time's up flash ───────────────────────────────────────
            if timeUpPending {
                ZStack {
                    RadialGradient(
                        colors: [catColor.opacity(0.18), theme.background.opacity(0.95)],
                        center: .center, startRadius: 20, endRadius: 300
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48, weight: .ultraLight))
                            .foregroundStyle(catColor)
                        Text(verbatim: "Время вышло")
                            .font(.dm(20, .bold))
                            .foregroundStyle(theme.textPrimary)
                    }
                    .scaleEffect(flashOpacity > 0 ? 1 : 0.92)
                }
                .opacity(flashOpacity)
                .animation(.easeInOut(duration: 0.4), value: flashOpacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startTimer()
            breathe = true
        }
        .onDisappear {
            ticker?.invalidate()
            cancelTimerNotification()
        }
        // Background-aware: when app becomes active after being backgrounded
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            if let end = endDate {
                let left = Int(end.timeIntervalSinceNow.rounded())
                if left <= 0 {
                    // Time expired while in background
                    ticker?.invalidate()
                    remaining = 0
                    triggerTimeUpFlash()
                } else {
                    remaining = left
                }
            }
        }
    }

    // MARK: – Circle button

    private func circleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(theme.textSecondary)
                .frame(width: 58, height: 58)
                .background(theme.surface, in: Circle())
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: – Timer logic

    private func startTimer() {
        ticker?.invalidate()
        endDate  = Date().addingTimeInterval(Double(remaining))
        isPaused = false
        scheduleTimerNotification()

        let t = Timer(timeInterval: 0.5, repeats: true) { _ in
            guard let end = endDate else { return }
            let left = Int(end.timeIntervalSinceNow.rounded())
            if left > 0 {
                remaining = left
            } else {
                ticker?.invalidate()
                remaining = 0
                triggerTimeUpFlash()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func togglePause() {
        if isPaused {
            // Resume
            endDate  = Date().addingTimeInterval(Double(remaining))
            isPaused = false
            scheduleTimerNotification()
        } else {
            // Pause — snapshot remaining, stop endDate
            remaining = endDate.map { max(0, Int($0.timeIntervalSinceNow.rounded())) } ?? remaining
            endDate   = nil
            isPaused  = true
            cancelTimerNotification()
        }
    }

    private func triggerTimeUpFlash() {
        cancelTimerNotification()
        timeUpPending = true
        withAnimation(.easeIn(duration: 0.3)) { flashOpacity = 1 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) { flashOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                let elapsed = max(0, total - remaining)
                let minutes = max(1, Int(ceil(Double(elapsed) / 60.0)))
                onFinished(minutes)
            }
        }
    }

    private func cancel() {
        ticker?.invalidate()
        cancelTimerNotification()
        onFinished(0)
    }

    private func finish() {
        ticker?.invalidate()
        cancelTimerNotification()
        let elapsed = max(0, total - remaining)
        let minutes = max(1, Int(ceil(Double(elapsed) / 60.0)))
        onFinished(minutes)
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: – Timer done notification

    private func scheduleTimerNotification() {
        guard let end = endDate else { return }
        let content       = UNMutableNotificationContent()
        content.body      = "Готово. Эти минуты — твои."
        content.sound     = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, end.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "truly.timer.done",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func cancelTimerNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["truly.timer.done"])
    }
}
