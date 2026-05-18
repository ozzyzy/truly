import SwiftUI

struct LibraryView: View {

    @EnvironmentObject private var preferenceStore: PreferenceStore
    @Environment(\.trulyTheme) private var theme
    @Environment(\.dismiss)    private var dismiss

    var onSelect: ((ActionItem) -> Void)? = nil

    private let catalog = CatalogService().loadActions()

    private let categories: [ActionCategory] = [
        .body, .calm, .reading, .creativity, .home, .social
    ]

    @State private var tab: Tab = .all

    enum Tab { case favorites, all }

    // MARK: – Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Tab toggle ────────────────────────────────────
                tabToggle
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // ── Content ───────────────────────────────────────
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                        if tab == .favorites {
                            favoritesContent
                        } else {
                            allContent
                        }
                    }
                    .padding(.bottom, 48)
                }
            }
            .background(theme.surface.ignoresSafeArea())
            .navigationTitle("Библиотека")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(theme.surface2, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: – Tab toggle

    private var tabToggle: some View {
        HStack(spacing: 0) {
            tabButton("любимые", tab: .favorites)
            tabButton("все", tab: .all)
        }
        .background(theme.surface2, in: Capsule())
    }

    private func tabButton(_ label: String, tab t: Tab) -> some View {
        Button {
            withAnimation(.spring(duration: 0.25)) { tab = t }
        } label: {
            Text(verbatim: label)
                .font(.dm(14, tab == t ? .semibold : .medium))
                .foregroundStyle(tab == t ? theme.background : theme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(tab == t ? theme.textPrimary : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.22), value: tab)
    }

    // MARK: – Favorites

    @ViewBuilder
    private var favoritesContent: some View {
        let liked = catalog.filter { preferenceStore.likedActionIds.contains($0.id) }
        if liked.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "heart")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(theme.textSecondary.opacity(0.3))
                Text("Сохранённых пока нет")
                    .font(.system(size: 15))
                    .foregroundStyle(theme.textSecondary.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else {
            ForEach(liked) { item in
                libraryRow(item)
                Divider().opacity(0.12).padding(.leading, 52)
            }
        }
    }

    // MARK: – All by category

    @ViewBuilder
    private var allContent: some View {
        ForEach(categories, id: \.self) { category in
            let items = catalog.filter {
                $0.category == category && !preferenceStore.hiddenActionIds.contains($0.id)
            }
            if !items.isEmpty {
                // Category header — italic colored
                Text(verbatim: category.displayName)
                    .font(.newsreader(13))
                    .foregroundStyle(category.catColor)
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 8)

                ForEach(items) { item in
                    libraryRow(item)
                    if item.id != items.last?.id {
                        Divider().opacity(0.12).padding(.leading, 52)
                    }
                }
            }
        }
    }

    // MARK: – Row

    private func libraryRow(_ item: ActionItem) -> some View {
        Button {
            onSelect?(item)
            dismiss()
        } label: {
            HStack(spacing: 14) {
                CategoryIcon(category: item.category, size: 16, color: item.category.catColor)
                    .frame(width: 24, height: 24)

                Text(item.title)
                    .font(.dm(15, .medium))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text(verbatim: "\(item.minutes) мин")
                    .font(.newsreader(13))
                    .foregroundStyle(theme.textSecondary.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
