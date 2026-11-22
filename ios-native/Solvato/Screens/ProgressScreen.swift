// İlerleme sekmesi: Doğruluk · Bu hafta · Öğrenme yolu · Konular · Zorlandığın notalar · Son turlar. Telefonda tek
// sütun, iPad'de iki bağımsız sütun. Web src/screens/ProgressScreen.tsx (+ PathCard, WeeklyReportCard, RoundHistory).
// Yazılar ve kurallar SolvatoCore ProgressContent'ten (web'le 50 durumda aynı).
import SolvatoCore
import SwiftUI

struct ProgressScreen: View {
    let model: AppModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var period: AccuracyPeriod?
    @State private var allRounds = false

    var body: some View {
        let c = ProgressContent(stats: model.stats, settings: model.settings, now: model.now)
        ScrollView {
            if !c.hasAnswers {
                VStack(spacing: 16) {
                    PathCardView(c: c, model: model)
                    EmptyProgress { model.go(.home) }
                }
                .padding(.horizontal, 16)
                .padding(.top, 32)
            } else if sizeClass == .regular {
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 16) {
                        accuracy(c)
                        PathCardView(c: c, model: model)
                        weak(c)
                    }
                    VStack(spacing: 16) {
                        WeekCard(c: c, text: c.report.text)
                        topics(c)
                        rounds(c)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 32)
                .padding(.bottom, 28)
            } else {
                VStack(spacing: 16) {
                    accuracy(c)
                    WeekCard(c: c, text: c.report.text)
                    PathCardView(c: c, model: model)
                    topics(c)
                    weak(c)
                    rounds(c)
                }
                .padding(.horizontal, 16)
                .padding(.top, 32)
                .padding(.bottom, 28)
            }
        }
        .scrollIndicators(.hidden)
        .background(ThemeColor.bg.color)
    }

    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.surface.color))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
    }

    private func cardTitle(_ s: String) -> some View {
        Text(s).font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color)
    }

    // MARK: Doğruluk
    private func accuracy(_ c: ProgressContent) -> some View {
        let p = period ?? c.defaultPeriod
        let a = c.accuracy(p)
        return card {
            HStack(spacing: 8) {
                cardTitle("Doğruluk")
                Spacer()
                HStack(spacing: 4) {
                    ForEach(AccuracyPeriod.allCases, id: \.self) { x in
                        Button { period = x } label: {
                            Text(x.label)
                                .font(.ui(FontSize.xs, .semibold))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .frame(minHeight: 32)
                                .choiceStyle(p == x, radius: Radius.pill)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.bottom, 12)
            if a.pct == nil {
                Text(a.empty).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
            } else {
                HStack(spacing: 16) {
                    ScoreRing(value: a.correct, max: a.total, size: 88, label: "%\(a.pct!)", color: .violet500)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(a.summary).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
                        if let d = a.delta { Text(d).font(.ui(FontSize.sm, .semibold)).foregroundStyle(ThemeColor.greenText.color) }
                        if let n = a.lowNote { Text(n).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textFaint.color) }
                    }
                }
            }
        }
    }

    // MARK: Konular
    private func topics(_ c: ProgressContent) -> some View {
        card {
            cardTitle("Konular")
            ForEach(c.topics, id: \.key) { t in
                Button { t.key == "chords" ? model.go(.chordquiz) : model.startQuiz(FilterCategory(rawValue: t.key) ?? .all) } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(t.label).font(.ui(FontSize.sm, .semibold)).foregroundStyle(ThemeColor.text.color)
                            if let n = t.note { Text(n).font(.ui(FontSize.xs)).foregroundStyle(ThemeColor.textMuted.color) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(ThemeColor.fill.color)
                                if let p = t.pct { t.color.bar.frame(width: g.size.width * Double(p) / 100).clipShape(Capsule()) }
                            }
                        }
                        .frame(width: 72, height: 6)
                        Text(verbatim: t.pct.map { "%\($0)" } ?? "—")
                            .font(.mono(FontSize.sm, .bold))
                            .foregroundStyle(t.pct == nil ? ThemeColor.textFaint.color : t.color.text.color)
                            .frame(width: 40, alignment: .trailing)
                        Text("›").foregroundStyle(ThemeColor.textMuted.color).frame(width: 12)
                    }
                    .frame(minHeight: 44)
                    .padding(.vertical, 6)
                    .overlay(alignment: .top) { ThemeColor.border.color.frame(height: 1) }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(t.accessibility)
            }
        }
    }

    // MARK: Zorlandığın notalar
    @ViewBuilder
    private func weak(_ c: ProgressContent) -> some View {
        if !c.weak.isEmpty {
            card {
                cardTitle("Zorlandığın notalar")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(c.weak, id: \.key) { n in
                        VStack(alignment: .leading, spacing: 2) {
                            MusicalStaffView(clef: n.clef, noteY: n.noteY, ledgerLines: n.ledgerLines, accidental: n.accidental, maxHeight: 72)
                            (Text(n.note).bold().foregroundStyle(ThemeColor.text.color) + Text(verbatim: " %\(n.pct)"))
                                .font(.ui(FontSize.sm))
                                .foregroundStyle(ThemeColor.textMuted.color)
                        }
                        .padding(.top, 6)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fill.color))
                        .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(n.clef == .treble ? "Sol" : "Fa") anahtarında \(n.note), yüzde \(n.pct)")
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 14)
                AppButton("Bu notaları çalış", block: true) { model.startWeakPractice(c.weak.map(\.key)) }
            }
        }
    }

    // MARK: Son turlar
    @ViewBuilder
    private func rounds(_ c: ProgressContent) -> some View {
        if !c.rounds.isEmpty {
            card {
                HStack {
                    cardTitle("Son turlar")
                    Spacer()
                    if c.rounds.count > 3 {
                        Button(allRounds ? "Daha az" : "Tümünü göster") { allRounds.toggle() }
                            .font(.ui(FontSize.sm, .semibold))
                            .foregroundStyle(ThemeColor.violetText.color)
                            .padding(6)
                    }
                }
                .padding(.bottom, 4)
                ForEach(Array(c.rounds.prefix(allRounds ? 30 : 3).enumerated()), id: \.offset) { i, r in
                    HStack(spacing: Space.s3) {
                        Stars(value: r.stars, size: 11)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(r.label).font(.ui(FontSize.sm, .semibold)).foregroundStyle(ThemeColor.text.color)
                            Text(r.when).font(.ui(FontSize.xs)).foregroundStyle(ThemeColor.textSubtle.color)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(r.score).font(.mono(FontSize.sm, .bold)).foregroundStyle(ThemeColor.text.color)
                            if let t = r.time { Text(t).font(.mono(FontSize.xs)).foregroundStyle(ThemeColor.textSubtle.color) }
                        }
                    }
                    .padding(.vertical, Space.s2)
                    .overlay(alignment: .top) { if i > 0 { ThemeColor.border.color.frame(height: 1) } }
                }
            }
        }
    }
}

/// Öğrenme yolu (web PathCard): aşama daireleri, "Sıradaki: …" ve ilerleme
struct PathCardView: View {
    let c: ProgressContent
    let model: AppModel

    private func go(_ s: ProgressContent.Stage) {
        if let cat = s.category { model.startQuiz(cat) } else { model.go(.chordquiz) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Öğrenme yolu").font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.textSoft.color)
                Spacer()
                Text(c.pathDone).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
            }
            .padding(.bottom, 12)
            HStack(spacing: 0) {
                ForEach(Array(c.stages.enumerated()), id: \.offset) { i, st in
                    Button { go(st) } label: {
                        Group {
                            if st.done {
                                Icon(.check, size: 15, strokeWidth: 3).foregroundStyle(PaletteColor.white.color)
                            } else {
                                Text(st.short).font(.ui(FontSize.sm, .heavy))
                                    .foregroundStyle(st.isCurrent ? PaletteColor.white.color : ThemeColor.textMuted.color)
                            }
                        }
                        .frame(width: 34, height: 34)
                        .background {
                            if st.done {
                                CSSLinearGradient([PaletteColor.green500.color, PaletteColor.green600.color]).clipShape(Circle())
                            } else if st.isCurrent {
                                CSSLinearGradient(.primaryFlat).clipShape(Circle())
                            } else {
                                Circle().fill(ThemeColor.fillStrong.color)
                            }
                        }
                        .overlay(
                            Circle().strokeBorder(
                                st.isCurrent ? PaletteColor.violet300.color : ThemeColor.borderStrong.color, lineWidth: st.isCurrent ? 2 : 1)
                        )
                        .shadow(color: st.isCurrent ? PaletteColor.violet500.opacity(0.55) : .clear, radius: 7)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(st.accessibility)
                    if i < c.stages.count - 1 {
                        RoundedRectangle(cornerRadius: Radius.xs)
                            .fill(st.done ? PaletteColor.green500.color : ThemeColor.fillStronger.color)
                            .frame(height: 3)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.bottom, 8)
            Button { go(c.nextStage) } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.nextTitle).font(.ui(FontSize.sm, .bold)).foregroundStyle(ThemeColor.highlightTitle.color)
                        Text(c.nextSub).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.highlightBody.color)
                        if let p = c.nextPct {
                            GeometryReader { g in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: Radius.xs).fill(ThemeColor.fillStronger.color)
                                    RoundedRectangle(cornerRadius: Radius.xs).fill(PaletteColor.violet400.color).frame(width: g.size.width * Double(p) / 100)
                                }
                            }
                            .frame(height: 4)
                            .padding(.top, 6)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(ThemeColor.violetTextSoft.color)
                }
                .padding(.vertical, 11)
                .padding(.horizontal, 12)
                .background(RoundedRectangle(cornerRadius: Radius.md).fill(PaletteColor.violet500.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(PaletteColor.violet500.opacity(0.28), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(.top, 14)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColor.fill.color))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(ThemeColor.border.color, lineWidth: 1))
    }
}

/// Bu hafta: seri ve bugünkü dürtme, 7 günlük şerit, özet, "Öğretmenine haftalık rapor gönder" (paylaşım menüsü)
private struct WeekCard: View {
    let c: ProgressContent
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            HStack(alignment: .firstTextBaseline) {
                Text("Bu hafta").font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color)
                Spacer()
                Text(c.report.range).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
            }
            HStack(spacing: Space.s3) {
                Icon(.flame, size: 22, fill: c.report.streak > 0)
                    .foregroundStyle(ThemeColor.orangeText.color)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(PaletteColor.orange500.opacity(c.report.streak > 0 ? 0.16 : 0.08)))
                VStack(alignment: .leading, spacing: 0) {
                    Text(c.streakTitle).font(.ui(FontSize.lg, .heavy)).foregroundStyle(ThemeColor.text.color)
                    Text(c.streakNudge).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
                }
            }
            HStack(spacing: 6) {
                ForEach(Array(c.weekDays.enumerated()), id: \.offset) { _, d in
                    VStack(spacing: 4) {
                        ZStack {
                            if d.goalMet {
                                Circle().fill(PaletteColor.green500.color)
                                Icon(.check, size: 16, strokeWidth: 3).foregroundStyle(PaletteColor.white.color)
                            } else if d.worked {
                                Circle().fill(PaletteColor.green500.opacity(0.15))
                                Circle().strokeBorder(PaletteColor.green500.color, lineWidth: 2)
                            } else if d.isToday {
                                Circle().fill(ThemeColor.fillStrong.color)
                                Circle().strokeBorder(PaletteColor.green500.color, style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                            } else {
                                Circle().fill(ThemeColor.fillStrong.color)
                                Circle().strokeBorder(ThemeColor.border.color, style: StrokeStyle(lineWidth: 1, dash: d.future ? [3, 3] : []))
                            }
                        }
                        .frame(width: 30, height: 30)
                        .opacity(d.future ? 0.5 : 1)
                        Text(d.label)
                            .font(.ui(FontSize.xs, d.isToday ? .bold : .regular))
                            .foregroundStyle((d.isToday ? ThemeColor.text : ThemeColor.textSubtle).color)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(c.weekLabel)
            Text(c.weekSummary).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
            ShareLink(item: text) {
                Text("Öğretmenine haftalık rapor gönder")
                    .font(.ui(FontSize.md, .bold))
                    .foregroundStyle(ThemeColor.text.color)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fillStrong.color))
                    .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            }
        }
        .padding(Space.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.fill.color))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
    }
}

/// Hiç tur yokken: çizim, "İstatistiklerin burada görünecek", "İlk tura başla"
private struct EmptyProgress: View {
    let onStart: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            Canvas { ctx, size in
                let s = size.width / 168
                ctx.scaleBy(x: s, y: s)
                let line = ThemeColor.textDisabled.color
                let v = ThemeColor.violetText.color
                for y in [30.0, 42, 54, 66, 78] {
                    var p = Path()
                    p.move(to: CGPoint(x: 8, y: y))
                    p.addLine(to: CGPoint(x: 160, y: y))
                    ctx.stroke(p, with: .color(line), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                }
                for (x, y, h) in [(26.0, 62.0, 34.0), (58, 44, 52), (90, 28, 68)] {
                    ctx.stroke(Path(roundedRect: CGRect(x: x, y: y, width: 20, height: h), cornerRadius: 5), with: .color(v), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                }
                var head = Path(ellipseIn: CGRect(x: -9, y: -6.4, width: 18, height: 12.8))
                head = head.applying(CGAffineTransform(rotationAngle: -20 * .pi / 180).concatenating(CGAffineTransform(translationX: 132, y: 66)))
                ctx.fill(head, with: .color(v))
                var stem = Path()
                stem.move(to: CGPoint(x: 140, y: 64))
                stem.addLine(to: CGPoint(x: 140, y: 28))
                stem.move(to: CGPoint(x: 140, y: 28))
                stem.addCurve(to: CGPoint(x: 148, y: 46), control1: CGPoint(x: 150, y: 32), control2: CGPoint(x: 152, y: 40))
                ctx.stroke(stem, with: .color(v), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
            }
            .frame(width: 168, height: 120)
            .padding(.bottom, 18)
            .accessibilityHidden(true)
            Text("İstatistiklerin burada görünecek")
                .font(.ui(FontSize.xl, .heavy))
                .foregroundStyle(ThemeColor.text.color)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            Text("İlk turunu çöz; doğruluğun, serin ve zorlandığın notalar burada görünsün.")
                .font(.ui(FontSize.md))
                .foregroundStyle(ThemeColor.textMuted.color)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
                .padding(.bottom, 22)
            Button(action: onStart) {
                Text("İlk tura başla")
                    .font(.ui(FontSize.md, .bold))
                    .foregroundStyle(Brand.onPrimary.color)
                    .padding(.vertical, 15)
                    .padding(.horizontal, 28)
                    .background(CSSLinearGradient(.primaryFlat).clipShape(RoundedRectangle(cornerRadius: Radius.lg)))
                    .shadow(color: PaletteColor.violet600.opacity(0.45), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}
