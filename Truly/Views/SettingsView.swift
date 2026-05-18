import SwiftUI

struct SettingsView: View {

    @Environment(\.trulyTheme) private var theme
    @EnvironmentObject private var preferenceStore: PreferenceStore

    @AppStorage("nudgeHours")      private var nudgeHoursString: String = "9,13,21"
    @AppStorage("screenThreshold") private var screenThreshold: Int = 30

    private let notifier = NotificationService()

    private let windows: [(id: Int, icon: String, label: String, sublabel: String)] = [
        (9,  "sunrise",    "Утро",  "когда день только начинается"),
        (13, "sun.max",    "День",  "в середине всего"),
        (21, "moon.stars", "Вечер", "перед тем как уснуть"),
    ]

    private let thresholdOptions: [(Int, String)] = [
        (15, "минут"),
        (30, "минут"),
        (60, "минут"),
    ]

    private var selectedHours: Set<Int> {
        Set(nudgeHoursString.split(separator: ",").compactMap { Int($0) })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                // ── КОГДА НАПОМНИТЬ ───────────────────────────────
                sectionBlock("КОГДА НАПОМНИТЬ") {
                    VStack(spacing: 10) {
                        ForEach(windows, id: \.id) { w in
                            let isSelected = selectedHours.contains(w.id)
                            Button {
                                var hours = selectedHours
                                if isSelected {
                                    if hours.count > 1 { hours.remove(w.id) }
                                } else {
                                    hours.insert(w.id)
                                }
                                nudgeHoursString = hours.sorted().map(String.init).joined(separator: ",")
                                Task {
                                    let ok = await notifier.requestPermission()
                                    if ok {
                                        await notifier.scheduleDailyNudges(hours: Array(hours))
                                    }
                                }
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
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(isSelected ? theme.accent.opacity(0.35) : theme.border, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .animation(.spring(duration: 0.22), value: isSelected)
                        }
                    }
                }

                // ── СКРИН-ТАЙМ ПОРОГ ──────────────────────────────
                sectionBlock("СКРИН-ТАЙМ ПОРОГ") {
                    HStack(spacing: 10) {
                        ForEach(thresholdOptions, id: \.0) { minutes, label in
                            let isSelected = screenThreshold == minutes
                            Button {
                                withAnimation(.spring(duration: 0.22)) { screenThreshold = minutes }
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(minutes)")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(isSelected ? theme.accent : theme.textPrimary)
                                    Text(label.uppercased())
                                        .font(.system(size: 9, weight: .semibold))
                                        .tracking(0.5)
                                        .foregroundStyle(theme.textSecondary.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isSelected ? theme.accent.opacity(0.08) : theme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(isSelected ? theme.accent.opacity(0.35) : theme.border, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .animation(.spring(duration: 0.22), value: isSelected)
                        }
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
                            Text("Любимые и скрытые")
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

    private let catalog = CatalogService().loadActions()

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
                            Text("Вернуть")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(theme.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if likedItems.isEmpty && hiddenItems.isEmpty {
                    Text("Пока пусто")
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
