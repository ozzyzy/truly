import SwiftUI

struct SettingsView: View {

    @Environment(\.trulyTheme) private var theme
    @EnvironmentObject private var preferenceStore: PreferenceStore

    @AppStorage("nudgeWindowIds") private var nudgeWindowIdsString: String = "morning,afternoon,evening"

    @EnvironmentObject private var logStore: LogStore

    private let notifier = NotificationService()
    private let windows  = NudgeWindow.defaults

    private var selectedWindows: Set<NudgeWindow.TimeOfDay> {
        NudgeWindow.TimeOfDay.from(string: nudgeWindowIdsString)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                // ── КОГДА НАПОМНИТЬ ───────────────────────────────
                sectionBlock("КОГДА НАПОМНИТЬ") {
                    VStack(spacing: 10) {
                        ForEach(windows) { w in
                            let isSelected = selectedWindows.contains(w.timeOfDay)
                            Button {
                                toggleWindow(w.timeOfDay)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: w.icon)
                                        .font(.system(size: 15, weight: .light))
                                        .foregroundStyle(isSelected ? theme.accent : theme.textSecondary.opacity(0.4))
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(w.label)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(theme.textPrimary)
                                        Text(w.sublabel)
                                            .font(.system(size: 12))
                                            .foregroundStyle(theme.textSecondary.opacity(0.55))
                                    }

                                    Spacer()

                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20))
                                        .foregroundStyle(isSelected ? theme.accent : theme.border)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(isSelected ? theme.accent.opacity(0.07) : theme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignConstants.windowPickerRadius, style: .continuous)
                                        .stroke(isSelected ? theme.accent.opacity(0.35) : theme.border, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: DesignConstants.windowPickerRadius, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .animation(.spring(duration: 0.22), value: isSelected)
                        }

                        Text(verbatim: "Truly появится где-то внутри окна — каждый день в разное время")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.textSecondary.opacity(0.45))
                            .multilineTextAlignment(.leading)
                            .padding(.top, 2)
                    }
                }

                // ── ДЕЙСТВИЯ ──────────────────────────────────────
                sectionBlock("ДЕЙСТВИЯ") {
                    NavigationLink {
                        FavoritesAndHiddenView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "heart")
                                .font(.system(size: 14))
                                .foregroundStyle(theme.textSecondary)
                                .frame(width: 24)
                            Text(verbatim: "Любимые и скрытые")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(theme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(theme.textSecondary.opacity(0.35))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(theme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: – Actions

    private func toggleWindow(_ tod: NudgeWindow.TimeOfDay) {
        var current = selectedWindows
        if current.contains(tod) {
            guard current.count > 1 else { return }  // нельзя убрать всё
            current.remove(tod)
        } else {
            current.insert(tod)
        }
        nudgeWindowIdsString = NudgeWindow.TimeOfDay.toString(current)
        Task {
            let ok = await notifier.requestPermission()
            if ok {
                let ws = NudgeWindow.defaults.filter { current.contains($0.timeOfDay) }
                await notifier.scheduleDailyNudges(windows: ws,
                                                   lastSessionAt: logStore.logs.first?.completedAt)
            }
        }
    }

    // MARK: – Section block

    private func sectionBlock<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(theme.textSecondary.opacity(0.45))

            content()
        }
    }
}

// MARK: – Favorites & Hidden (sub-page)

struct FavoritesAndHiddenView: View {
    @Environment(\.trulyTheme) private var theme
    @EnvironmentObject private var preferenceStore: PreferenceStore

    private let catalog = CatalogService.shared.actions

    private var likedItems: [ActionItem] {
        catalog.filter { preferenceStore.likedActionIds.contains($0.id) }
    }

    private var hiddenItems: [ActionItem] {
        catalog.filter { preferenceStore.hiddenActionIds.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !likedItems.isEmpty {
                    actionSection("ЛЮБИМЫЕ", items: likedItems) { item in
                        Button { preferenceStore.toggleLike(item.id) } label: {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 13))
                                .foregroundStyle(theme.textSecondary.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !hiddenItems.isEmpty {
                    actionSection("СКРЫТЫЕ", items: hiddenItems) { item in
                        Button { preferenceStore.unhide(item.id) } label: {
                            Text(verbatim: "Вернуть")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(theme.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if likedItems.isEmpty && hiddenItems.isEmpty {
                    Text(verbatim: "Пока пусто")
                        .font(.system(size: 15))
                        .foregroundStyle(theme.textSecondary.opacity(0.4))
                        .padding(.top, 60)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Любимые и скрытые")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func actionSection<T: View>(
        _ title: String,
        items: [ActionItem],
        @ViewBuilder trailing: @escaping (ActionItem) -> T
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(theme.textSecondary.opacity(0.45))

            VStack(spacing: 0) {
                ForEach(items) { item in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(item.category.catColor.opacity(0.08))
                                .frame(width: 24, height: 24)
                            CategoryIcon(category: item.category, size: 13, color: item.category.catColor)
                        }

                        Text(item.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(theme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        trailing(item)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)

                    if item.id != items.last?.id {
                        Divider().opacity(0.12).padding(.leading, 52)
                    }
                }
            }
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
