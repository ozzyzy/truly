import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var logStore: LogStore
    @Environment(\.trulyTheme) private var theme
    @Environment(\.dismiss)    private var dismiss

    // MARK: – Computed

    private var todayMinutes: Int { minutes(from: Calendar.current.startOfDay(for: Date())) }
    private var weekMinutes: Int  { minutes(from: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()) }
    private var totalMinutes: Int { logStore.totalMinutes }

    // MARK: – Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // ── 3 stat boxes ─────────────────────────────────
                    HStack(spacing: 10) {
                        statBox(value: fmt(todayMinutes), label: "сегодня", highlight: false)
                        statBox(value: fmt(weekMinutes),  label: "за неделю", highlight: false)
                        statBox(value: fmt(totalMinutes), label: "всего", highlight: true)
                    }
                    .padding(.top, 4)

                    // ── Recent sessions ───────────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        Text("ПОСЛЕДНИЕ СЕССИИ")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.4)
                            .foregroundStyle(theme.textSecondary.opacity(0.45))

                        if logStore.logs.isEmpty {
                            Text("Пока ничего — начни свой первый момент")
                                .font(.system(size: 14))
                                .foregroundStyle(theme.textSecondary.opacity(0.5))
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(logStore.logs.prefix(20)) { log in
                                    recentRow(log)
                                    if log.id != logStore.logs.prefix(20).last?.id {
                                        Divider()
                                            .opacity(0.12)
                                            .padding(.leading, 48)
                                    }
                                }
                            }
                            .background(theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("История")
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

    // MARK: – Stat box

    private func statBox(value: String, label: String, highlight: Bool) -> some View {
        VStack(spacing: 6) {
            Text(verbatim: value)
                .font(.dm(22, .bold))
                .tracking(-0.5)
                .foregroundStyle(highlight ? theme.background : theme.textPrimary)
            Text(verbatim: label)
                .font(.dm(11))
                .foregroundStyle(highlight ? theme.background.opacity(0.65) : theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(highlight ? theme.textPrimary : theme.surface)
        )
    }

    // MARK: – Recent row

    private func recentRow(_ log: ActionLog) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(log.category.catColor.opacity(0.08))
                    .frame(width: 28, height: 28)
                CategoryIcon(category: log.category, size: 14, color: log.category.catColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(log.titleSnapshot)
                    .font(.dm(15, .semibold))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)
                Text(shortDate(log.completedAt))
                    .font(.dm(11))
                    .foregroundStyle(theme.textSecondary.opacity(0.5))
            }

            Spacer()

            Text(verbatim: "\(log.completedMinutes) мин")
                .font(.newsreader(13))
                .foregroundStyle(theme.textSecondary.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: – Helpers

    private func minutes(from date: Date) -> Int {
        logStore.logs
            .filter { $0.completedAt >= date }
            .reduce(0) { $0 + $1.completedMinutes }
    }

    private func fmt(_ total: Int) -> String {
        if total == 0 { return "0м" }
        if total < 60 { return "\(total)м" }
        let h = total / 60, m = total % 60
        return m > 0 ? "\(h)ч\(m)м" : "\(h)ч"
    }

    private func shortDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Сегодня" }
        if cal.isDateInYesterday(date) { return "Вчера" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.dateFormat = "d MMM"
        return fmt.string(from: date)
    }
}
