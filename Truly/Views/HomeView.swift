import SwiftUI

struct HomeView: View {

    private let catalog = CatalogService().loadActions()
    private let engine  = SuggestionEngine()

    @Environment(\.trulyTheme) private var theme
    @EnvironmentObject private var preferenceStore: PreferenceStore
    @EnvironmentObject private var logStore: LogStore

    @State private var path          = NavigationPath()
    @State private var current:        ActionItem? = nil
    @State private var cardVisible   = true
    @State private var showLibrary   = false
    @State private var showSettings  = false
    @State private var showHistory   = false

    @State private var isUserPicked  = false
    @State private var shuffleCount  = 0
    @State private var showAlts      = false
    @State private var altActions:     [ActionItem] = []

    // Category filter chips
    @State private var selectedMood: ActionCategory? = nil

    // Drag gesture
    @State private var dragOffset    = CGSize.zero

    // Zoom morph transition
    @Namespace private var cardNamespace

    // First launch gift
    @AppStorage("hasSeenFirstCard") private var hasSeenFirstCard = false

    // MARK: – Stats

    private var todayMinutes: Int {
        logStore.logs
            .filter { Calendar.current.isDateInToday($0.completedAt) }
            .reduce(0) { $0 + $1.completedMinutes }
    }

    private var totalMinutes: Int {
        logStore.logs.reduce(0) { $0 + $1.completedMinutes }
    }

    // MARK: – Helpers

    private func nextSuggestion() -> ActionItem? {
        if let mood = selectedMood {
            let pool = catalog.filter {
                $0.category == mood && !preferenceStore.hiddenActionIds.contains($0.id)
            }
            if !pool.isEmpty {
                return pool.filter { $0.id != current?.id }.shuffled().first ?? pool.shuffled().first
            }
        }
        return engine.suggest(
            catalog: catalog,
            likedIds: preferenceStore.likedActionIds,
            hiddenIds: preferenceStore.hiddenActionIds,
            logs: logStore.logs
        )
    }

    private func formatMinutes(_ m: Int) -> String {
        if m < 60 { return "\(m) мин" }
        let h = m / 60, r = m % 60
        return r > 0 ? "\(h) ч \(r) мин" : "\(h) ч"
    }

    private var currentCatColor: Color {
        current?.category.catColor ?? Color(hex: "28B87C")
    }

    private func loadAlternatives() {
        guard let cur = current else { return }
        altActions = catalog
            .filter { $0.id != cur.id && !preferenceStore.hiddenActionIds.contains($0.id) }
            .shuffled()
            .prefix(3)
            .map { $0 }
    }

    // MARK: – Body

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                theme.background.ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── Nav bar ──────────────────────────────────────
                    HStack(spacing: 10) {
                        Text(verbatim: "truly")
                            .font(Font.custom("Newsreader-MediumItalic", size: 26))
                            .foregroundStyle(theme.textPrimary)
                            .tracking(-1)

                        Spacer()

                        Button { showHistory = true } label: {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(theme.textSecondary)
                                .frame(width: 34, height: 34)
                                .background(theme.surface2, in: Circle())
                        }
                        .buttonStyle(.plain)

                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(theme.textSecondary)
                                .frame(width: 34, height: 34)
                                .background(theme.surface2, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 4)

                    // ── Stats line ───────────────────────────────────
                    statsLine
                        .padding(.horizontal, 22)
                        .padding(.bottom, 6)

                    // ── Mood chips ───────────────────────────────────
                    MoodChips(selected: $selectedMood, theme: theme)
                        .onChange(of: selectedMood) { _, _ in
                            withAnimation(.easeOut(duration: 0.15)) { cardVisible = false }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                if let next = nextSuggestion() { current = next }
                                isUserPicked = false
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    cardVisible = true
                                }
                            }
                        }

                    Spacer()

                    // ── First-launch gift label ──────────────────────
                    if !hasSeenFirstCard {
                        HStack(spacing: 6) {
                            Text(verbatim: "✦")
                                .foregroundStyle(theme.accent)
                            Text(verbatim: "Вот первое предложение для тебя")
                                .font(.newsreader(14))
                                .foregroundStyle(theme.textSecondary.opacity(0.75))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 10)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // ── Card ────────────────────────────────────────
                    if let action = current {
                        cardContent(action)
                    } else {
                        emptyState
                    }

                    // ── Gesture hint / nudge ─────────────────────────
                    gestureHintView
                        .padding(.top, 6)

                    // ── Alternatives panel ───────────────────────────
                    if showAlts && !altActions.isEmpty {
                        altsPanel
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.top, 10)
                    }

                    Spacer()

                    // ── CTA buttons ──────────────────────────────────
                    if current != nil {
                        VStack(spacing: 4) {
                            TrulyButton("Начать") {
                                if let action = current {
                                    shuffleCount = 0
                                    dismissSwipeHint()
                                    withAnimation { hasSeenFirstCard = true }
                                    path.append(HomeRoute.timer(action))
                                }
                            }

                            Button { showLibrary = true } label: {
                                Text(verbatim: "другое")
                                    .font(.dm(14, .medium))
                                    .foregroundStyle(theme.textSecondary.opacity(0.55))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }

            }

            // MARK: Navigation

            .navigationDestination(for: HomeRoute.self) { route in
                switch route {

                case .timer(let action):
                    TimerFlowView(action: action) { minutes in
                        guard minutes > 0 else {
                            path.removeLast()
                            return
                        }
                        logStore.add(ActionLog(
                            id: UUID().uuidString,
                            actionId: action.id,
                            titleSnapshot: action.title,
                            category: action.category,
                            plannedMinutes: action.minutes,
                            completedMinutes: minutes,
                            completedAt: Date()
                        ))
                        let isMilestone = logStore.totalMinutes >= 60 && !logStore.milestoneOneHourShown
                        path.append(HomeRoute.done(minutes, isMilestone))
                    }
                    .navigationTransition(.zoom(sourceID: "actionCard", in: cardNamespace))

                case .done(let minutes, let isMilestone):
                    DoneView(
                        minutes: minutes,
                        isMilestone: isMilestone,
                        category: current?.category ?? .calm
                    ) {
                        let total = logStore.totalMinutes
                        path.append(HomeRoute.between(minutes, total))
                    }

                case .between(let lastMin, let totalMin):
                    BetweenView(lastMin: lastMin, totalMin: totalMin) {
                        path = NavigationPath()
                        current = nextSuggestion()
                        isUserPicked = false
                    }
                }
            }
        }

        // ── Sheets ──────────────────────────────────────────────────
        .sheet(isPresented: $showLibrary) {
            LibraryView { selected in
                current = selected
                isUserPicked = true
                showAlts = false
                shuffleCount = 0
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
        }
        .sheet(isPresented: $showHistory) {
            NavigationStack { StatsView() }
        }

        // ── Lifecycle ────────────────────────────────────────────────
        .onAppear {
            if current == nil { current = nextSuggestion() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .trulyOpenSuggestion)) { _ in
            path = NavigationPath()
            current = nextSuggestion()
            isUserPicked = false
            shuffleCount = 0
        }
    }

    // MARK: – Stats line

    @ViewBuilder
    private var statsLine: some View {
        VStack(alignment: .leading, spacing: 2) {
            if todayMinutes > 0 {
                HStack(spacing: 5) {
                    Text(verbatim: "✦")
                        .foregroundStyle(theme.accent)
                    Text(verbatim: "Сегодня вернула себе \(formatMinutes(todayMinutes))")
                        .foregroundStyle(theme.textPrimary)
                }
                .font(.dm(13, .medium))
            } else {
                Text(verbatim: "первый момент сегодня")
                    .font(.newsreader(13))
                    .foregroundStyle(theme.textSecondary.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 18)
    }

    // MARK: – Gesture hint / nudge

    @ViewBuilder
    private var gestureHintView: some View {
        if shuffleCount >= 3 && !showAlts {
            Text("может, всё-таки попробуешь?")
                .font(.newsreader(12))
                .foregroundStyle(theme.textSecondary.opacity(0.7))
        } else if showSwipeHint {
            HStack(spacing: 18) {
                Label("другое", systemImage: "arrow.left")
                Label("варианты", systemImage: "arrow.up")
            }
            .font(.dm(10, .medium))
            .foregroundStyle(theme.textSecondary.opacity(0.32))
            .labelStyle(.titleAndIcon)
        }
    }

    private var showSwipeHint: Bool { !preferenceStore.hasSeenSwipeHint }

    private func dismissSwipeHint() {
        if !preferenceStore.hasSeenSwipeHint {
            preferenceStore.hasSeenSwipeHint = true
        }
    }

    // MARK: – Float card

    @ViewBuilder
    private func cardContent(_ action: ActionItem) -> some View {
        let catCol = action.category.catColor

        VStack(spacing: 0) {

            // ── Top row: category italic left, icon right ────────
            HStack(alignment: .top) {
                Text(verbatim: action.category.displayName)
                    .font(.newsreader(13))
                    .foregroundStyle(catCol)
                Spacer()
                CategoryIcon(category: action.category, size: 18, color: catCol)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 12)

            // ── Title ────────────────────────────────────────────
            Text(action.title)
                .font(.dm(32, .bold))
                .tracking(-0.5)
                .foregroundStyle(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 0)

            Spacer().frame(height: 20)

            // ── Divider ─────────────────────────────────────────
            Divider()
                .opacity(0.08)

            // ── Bottom row: time left, heart right ───────────────
            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(verbatim: "\(action.minutes)")
                        .font(.dm(17, .bold))
                        .foregroundStyle(catCol)
                    Text(verbatim: "минут")
                        .font(.dm(13))
                        .foregroundStyle(theme.textSecondary.opacity(0.6))
                }
                Spacer()
                Button {
                    preferenceStore.toggleLike(action.id)
                } label: {
                    Image(systemName: preferenceStore.isLiked(action.id) ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            preferenceStore.isLiked(action.id) ? Color(hex: "E05C5C") : theme.textSecondary.opacity(0.35)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(theme.border, lineWidth: 1)
        )
        .matchedTransitionSource(id: "actionCard", in: cardNamespace)
        .opacity(cardVisible ? 1 : 0)
        .scaleEffect(cardVisible ? 1 : 0.94)
        .offset(x: dragOffset.width * 0.55, y: dragOffset.height * 0.3)
        .rotationEffect(.degrees(Double(dragOffset.width) * 0.01))
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: cardVisible)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height

                    if dx < -65 {
                        shuffle()
                        dismissSwipeHint()
                    } else if dy < -50 {
                        loadAlternatives()
                        withAnimation(.easeOut(duration: 0.32)) {
                            showAlts = true
                        }
                        dismissSwipeHint()
                    }

                    withAnimation(.spring(response: 0.38, dampingFraction: 0.7)) {
                        dragOffset = .zero
                    }
                }
        )
        .padding(.horizontal, 24)
    }

    // MARK: – Alternatives panel

    private var altsPanel: some View {
        VStack(spacing: 8) {
            HStack {
                Text(verbatim: "другие варианты")
                    .font(.dm(11, .semibold))
                    .foregroundStyle(theme.textSecondary.opacity(0.6))
                    .tracking(0.3)
                Spacer()
                Button { withAnimation { showAlts = false } } label: {
                    Text("✕")
                        .font(.system(size: 14))
                        .foregroundStyle(theme.textSecondary.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)

            HStack(spacing: 8) {
                ForEach(altActions) { alt in
                    Button {
                        current = alt
                        isUserPicked = true
                        withAnimation { showAlts = false }
                    } label: {
                        VStack(spacing: 4) {
                            CategoryIcon(category: alt.category, size: 20, color: alt.category.catColor)
                            Text(alt.title)
                                .font(.dm(11, .bold))
                                .foregroundStyle(theme.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                            Text(verbatim: "\(alt.minutes) мин")
                                .font(.newsreader(11))
                                .foregroundStyle(alt.category.catColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 6)
                        .background(theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(theme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: – Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(theme.accent)
            Text("Все действия скрыты")
                .font(.system(.title3).weight(.semibold))
                .foregroundStyle(theme.textPrimary)
            Button { showLibrary = true } label: {
                Text("Открыть библиотеку")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(40)
    }

    // MARK: – Card swap

    private func shuffle() {
        shuffleCount += 1
        showAlts = false
        withAnimation(.easeOut(duration: 0.15)) { cardVisible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            if let next = nextSuggestion() { current = next }
            isUserPicked = false
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                cardVisible = true
            }
        }
    }
}

// MARK: – Mood chips

struct MoodChips: View {
    @Binding var selected: ActionCategory?
    let theme: TrulyTheme

    private struct Chip {
        let category: ActionCategory?
        let label: String
    }

    private let chips: [Chip] = [
        Chip(category: nil,         label: "все"),
        Chip(category: .calm,       label: "спокойствие"),
        Chip(category: .body,       label: "тело"),
        Chip(category: .creativity, label: "творчество"),
        Chip(category: .reading,    label: "чтение"),
        Chip(category: .home,       label: "дом"),
        Chip(category: .social,     label: "связь"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(chips, id: \.label) { chip in
                    let active = selected == chip.category
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            selected = chip.category
                        }
                    } label: {
                        Text(verbatim: chip.label)
                            .font(.dm(12, .medium))
                            .foregroundStyle(active ? theme.background : theme.textSecondary)
                            .padding(.horizontal, 14)
                            .frame(height: 32)
                            .background(
                                active ? theme.textPrimary : Color.clear,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().stroke(
                                    active ? Color.clear : theme.border,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.spring(duration: 0.2), value: active)
                }
            }
            .padding(.horizontal, 18)
            .padding(.trailing, 18)
        }
        .padding(.bottom, 6)
    }
}
