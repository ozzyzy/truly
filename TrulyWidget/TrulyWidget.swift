import WidgetKit
import SwiftUI

// MARK: – Formatting

enum MinutesFormatter {

    struct Part { let number: String; let unit: String }

    static func weeklyParts(_ minutes: Int) -> [Part] {
        if minutes < 60 { return [Part(number: "\(minutes)", unit: "мин")] }
        let h = minutes / 60, r = minutes % 60
        if h < 10 && r > 0 {
            return [Part(number: "\(h)", unit: "ч"), Part(number: "\(r)", unit: "мин")]
        }
        return [Part(number: "\(h)", unit: "ч")]
    }

    static func compact(_ minutes: Int) -> (number: String, unit: String) {
        if minutes < 60 { return ("\(minutes)", "мин") }
        let h = minutes / 60, r = minutes % 60
        if h < 10 && r > 0 { return ("\(h) ч \(r)", "мин") }
        return ("\(h)", "ч")
    }
}

// MARK: – Timeline

struct SimpleEntry: TimelineEntry {
    let date: Date
    let weeklyMinutes: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), weeklyMinutes: 0)
    }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), weeklyMinutes: currentWeeklyMinutes()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let now = Date()
        let cal = Calendar.current

        // Entry for right now
        let entry = SimpleEntry(date: now, weeklyMinutes: currentWeeklyMinutes())

        // Next Monday 00:00 — schedule a zero-reset entry so the widget
        // clears even if the app hasn't been opened across the week boundary.
        let nextMonday = nextMondayMidnight(after: now, cal: cal)
        let resetEntry = SimpleEntry(date: nextMonday, weeklyMinutes: 0)

        // Also refresh at next midnight (picks up any app-written changes
        // that didn't trigger reloadAllTimelines, e.g. background updates).
        let nextMidnight = cal.startOfDay(for: now.addingTimeInterval(86_400))

        let refreshDate = min(nextMidnight, nextMonday)
        completion(Timeline(entries: [entry, resetEntry], policy: .after(refreshDate)))
    }

    // MARK: – Helpers

    /// Reads weeklyMinutes from SharedDefaults and returns 0 if the stored
    /// week start no longer matches the current calendar week.
    private func currentWeeklyMinutes() -> Int {
        let defaults = SharedDefaults.shared
        let stored   = defaults.integer(forKey: SharedDefaults.Keys.weeklyMinutes)
        guard stored > 0 else { return 0 }

        let cal       = Calendar.current
        let thisWeek  = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let savedWeek = defaults.object(forKey: SharedDefaults.Keys.weekStartDate) as? Date

        // If the app has never written weekStartDate, trust the stored value.
        guard let savedWeek else { return stored }

        // Different week → treat as reset (app will write the correct value on next open).
        return cal.isDate(savedWeek, equalTo: thisWeek, toGranularity: .weekOfYear) ? stored : 0
    }

    private func nextMondayMidnight(after date: Date, cal: Calendar) -> Date {
        var components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekOfYear = (components.weekOfYear ?? 1) + 1
        components.weekday    = 2  // Monday
        return cal.date(from: components) ?? date.addingTimeInterval(7 * 86_400)
    }
}

// MARK: – Background
// containerBackground must carry the paper gradient for systemSmall so the system
// clips it to the correct squircle shape. Clear is used for accessory families.

private struct WidgetBackground: View {
    @Environment(\.widgetFamily) private var family
    var body: some View {
        if family == .systemSmall {
            LinearGradient(
                colors: [
                    Color(red: 242/255, green: 247/255, blue: 242/255),
                    Color(red: 230/255, green: 239/255, blue: 232/255),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.clear
        }
    }
}

// MARK: – Widget

struct TrulyWidget: Widget {
    let kind = "TrulyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TrulyWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBackground()
                }
        }
        .configurationDisplayName("Truly")
        .description("Один тап — и у тебя момент для себя.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .systemSmall,
        ])
    }
}

// MARK: – Entry view

struct TrulyWidgetEntryView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:    circularView
            case .accessoryRectangular: rectangularView
            case .accessoryInline:      inlineView
            case .systemSmall:          homeSmallView
            default:                    circularView
            }
        }
        .widgetURL(URL(string: "truly://shuffle"))
    }

    // ── Circular ──────────────────────────────────────────────────────

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 3) {
                Text(verbatim: "✦")
                    .font(.system(size: 17, weight: .light))
                Text(verbatim: "truly")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(-0.3)
            }
        }
    }

    // ── Rectangular ───────────────────────────────────────────────────

    private var rectangularView: some View {
        HStack(spacing: 10) {
            Text(verbatim: "✦")
                .font(.system(size: 20, weight: .ultraLight))

            VStack(alignment: .leading, spacing: 1) {
                if entry.weeklyMinutes == 0 {
                    Text(verbatim: "truly")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(-0.3)
                    Text(verbatim: "момент для тебя")
                        .font(.system(size: 11, weight: .regular))
                        .opacity(0.65)
                } else {
                    let fmt = MinutesFormatter.compact(entry.weeklyMinutes)
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(verbatim: fmt.number)
                            .font(.system(size: 16, weight: .bold))
                        Text(verbatim: fmt.unit)
                            .font(.system(size: 11, weight: .regular))
                            .opacity(0.8)
                    }
                    Text(verbatim: "за эту неделю")
                        .font(.system(size: 10, weight: .regular))
                        .opacity(0.65)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // ── Inline ────────────────────────────────────────────────────────

    private var inlineView: some View {
        Text(verbatim: "✦ truly · момент")
            .font(.system(size: 12, weight: .medium))
    }

    // ── systemSmall — paper almanac ───────────────────────────────────
    // Background comes from containerBackground (WidgetBackground above),
    // which the system clips to the correct squircle. No manual clipShape needed.

    private var homeSmallView: some View {
        GeometryReader { geo in
            let k = min(geo.size.width, geo.size.height) / 200

            ZStack(alignment: .topLeading) {

                // Watermark
                Canvas { ctx, size in
                    let ws  = size.width
                    let mark = returnMarkPath(
                        cx: ws * 0.86, cy: ws * 0.92,
                        R: ws * 0.42,  rEnd: ws * 0.42 * 0.32,
                        wStart: ws * 0.12, wEnd: ws * 0.02,
                        a0: 145, sweep: 330
                    )
                    let c = CGPoint(x: size.width / 2, y: size.height / 2)
                    let rotated = mark.applying(
                        CGAffineTransform.identity
                            .translatedBy(x: c.x, y: c.y)
                            .rotated(by: -6 * .pi / 180)
                            .translatedBy(x: -c.x, y: -c.y)
                    )
                    ctx.fill(rotated, with: .color(
                        Color(red: 1/255, green: 92/255, blue: 66/255).opacity(0.07)
                    ))
                }

                // Content
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: "truly")
                        .font(.custom("Newsreader-MediumItalic", size: 24 * k))
                        .foregroundStyle(Color(red: 2/255, green: 105/255, blue: 76/255))
                        .tracking(-0.5)

                    Spacer()

                    if entry.weeklyMinutes == 0 {
                        emptyContent(k: k)
                    } else {
                        counterContent(k: k)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(20 * k)
            }
        }
    }

    @ViewBuilder
    private func emptyContent(k: CGFloat) -> some View {
        Text("минута\nдля себя?")
            .font(.custom("Newsreader-MediumItalic", size: 19 * k))
            .foregroundStyle(Color(red: 1/255, green: 92/255, blue: 66/255).opacity(0.55))
            .tracking(-0.2)
            .lineSpacing(2 * k)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func counterContent(k: CGFloat) -> some View {
        let parts = MinutesFormatter.weeklyParts(entry.weeklyMinutes)

        HStack(alignment: .lastTextBaseline, spacing: 7 * k) {
            ForEach(parts.indices, id: \.self) { i in
                HStack(alignment: .lastTextBaseline, spacing: 3 * k) {
                    Text(verbatim: parts[i].number)
                        .font(.custom("Newsreader-MediumItalic", size: 56 * k))
                        .foregroundStyle(Color(red: 1/255, green: 92/255, blue: 66/255))
                        .tracking(-1.1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(verbatim: parts[i].unit)
                        .font(.custom("Newsreader-MediumItalic", size: 20 * k))
                        .foregroundStyle(Color(red: 1/255, green: 92/255, blue: 66/255).opacity(0.7))
                        .lineLimit(1)
                }
            }
        }

        Text(verbatim: "за эту неделю")
            .font(.system(size: 13 * k, weight: .medium))
            .foregroundStyle(Color(red: 1/255, green: 92/255, blue: 66/255).opacity(0.55))
            .tracking(0.26)
            .padding(.top, 4 * k)
    }

    // MARK: – Watermark path

    private func returnMarkPath(
        cx: CGFloat, cy: CGFloat,
        R: CGFloat,  rEnd: CGFloat,
        wStart: CGFloat, wEnd: CGFloat,
        a0: CGFloat, sweep: CGFloat,
        steps: Int = 90
    ) -> Path {
        func ease(_ t: CGFloat) -> CGFloat { t * t * (3 - 2 * t) }
        var outer: [CGPoint] = []
        var inner: [CGPoint] = []
        for i in 0...steps {
            let t   = CGFloat(i) / CGFloat(steps)
            let rad = R + (rEnd - R) * ease(t)
            let w   = wStart + (wEnd - wStart) * t
            let ang = (a0 + sweep * t) * .pi / 180
            outer.append(CGPoint(x: cx + rad * cos(ang),       y: cy + rad * sin(ang)))
            inner.append(CGPoint(x: cx + (rad - w) * cos(ang), y: cy + (rad - w) * sin(ang)))
        }
        var path = Path()
        path.move(to: outer[0])
        outer.dropFirst().forEach { path.addLine(to: $0) }
        inner.reversed().forEach  { path.addLine(to: $0) }
        path.closeSubpath()
        return path
    }
}
