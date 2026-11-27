// Tur sonucu: yıldızlar, "Tur bitti · …", Solfie'nin ipucu ya da rekor haberi, doğruluk halkası, XP ve ortalama süre,
// ünvan kartı, "Hatalarını tekrar et" / "Yeni tur" ve "Bitir". Web karşılığı src/screens/ResultScreen.tsx. Yazılar
// SolvatoCore ResultContent'ten (testli). Kutlama penceresi (CelebrationView) aynı dosyada.
import SolvatoCore
import SwiftUI

struct ResultScreen: View {
    let model: AppModel
    /// R8 "Serini koru" kartı bu ekranda görünüyor mu; izin verilmezse karttaki uyarı
    @State private var offer = false
    @State private var offerMsg = ""

    private var content: ResultContent {
        ResultContent(
            answers: model.lastResults, key: model.lastSpecial?.rawValue ?? model.currentCategory.rawValue, points: model.lastPoints,
            stars: model.lastStars.stars, previousBest: model.lastStars.best, totalXp: model.stats.totalPoints,
            questions: model.sessionQuestions)
    }

    var body: some View {
        let c = content
        ScrollView {
            VStack(spacing: 0) {
                // VoiceOver: başlık, doğruluk, yıldız ve XP başlıkta tek seferde okunur (erisilebilirlik-ipad.md)
                Stars(value: c.stars, size: 52, animate: true).padding(.bottom, 14).accessibilityHidden(true)
                Text(c.title)
                    .font(.ui(FontSize.xl, .heavy))
                    .tracking(em: -0.03, size: FontSize.xl)
                    .foregroundStyle(ThemeColor.text.color)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 4)
                    .accessibilityLabel(
                        AccessibilityText.join([c.title, "%\(c.pct) doğru", AccessibilityText.stars(c.stars), c.points > 0 ? "+\(c.points) XP" : nil]))
                    .accessibilityAddTraits(.isHeader)
                Text(c.categoryLabel)
                    .font(.ui(FontSize.sm, .medium))
                    .foregroundStyle(ThemeColor.textSubtle.color)
                    .padding(.bottom, 6)
                SolfieSays(text: c.solfieText, amber: c.newBest, pose: c.newBest ? .cheer : .idle)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                if offer { reminderOffer.padding(.bottom, 20) }
                ScoreRing(value: c.correct, max: c.total, label: "%\(c.pct)", caption: "Doğruluk", detail: "\(c.correct)/\(c.total) doğru")
                    .background {
                        // web: inset −10 daire, radial-gradient(circle, violet .4 0%, saydam 65%); yarıçap en uzak köşe 80·√2
                        RadialGradient(colors: [PaletteColor.violet500.opacity(0.4), .clear], center: .center, startRadius: 0, endRadius: 80 * 2.0.squareRoot() * 0.65)
                            .clipShape(Circle())
                            .padding(-10)
                            .allowsHitTesting(false)
                    }
                    .padding(.bottom, 28)
                HStack(spacing: 10) {
                    statBox(
                        icon: AnyView(Icon(.sparkles, size: 20)), value: "+\(c.points)", label: "XP", text: .amberText, tint: .amber500)
                    statBox(icon: AnyView(ClockIcon().frame(width: 20, height: 20)), value: c.timeValue, label: c.timeLabel, text: .blueText, tint: .blue400)
                }
                .padding(.bottom, 16)
                RankCardView(xp: c.totalXp, gained: c.points).padding(.bottom, 16)
                VStack(spacing: 10) {
                    Button { c.hasWrong ? model.retryWrong() : model.retry() } label: {
                        HStack(spacing: 8) {
                            PlayShape().fill(PaletteColor.violet100.color).frame(width: 16, height: 16)
                            Text(c.primaryTitle).font(.ui(FontSize.md, .bold)).tracking(em: -0.01, size: FontSize.md)
                        }
                        .foregroundStyle(Brand.onPrimary.color)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 56)
                        .background(CSSLinearGradient(.primaryFlat).clipShape(RoundedRectangle(cornerRadius: Radius.lg)))
                        .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(PaletteColor.violet500.opacity(0.3), lineWidth: 1))
                        .shadow(color: PaletteColor.violet600.opacity(0.5), radius: 14, y: 6)
                    }
                    .buttonStyle(.plain)
                    Button { model.back() } label: {
                        Text("Bitir")
                            .font(.ui(FontSize.sm, .semibold))
                            .foregroundStyle(ThemeColor.textSubtle.color)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 46)
                            .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fill.color))
                            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 28)
            }
            .padding(.top, 36)
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        // Web: ekran 16 pt aşağıdan belirir (.animate-fade-in-up)
        .fadeInUpOnAppear()
        .background(alignment: .top) {
            RadialGradient(colors: [PaletteColor.violet500.opacity(0.3), .clear], center: .center, startRadius: 0, endRadius: 160 * 0.7)
                .frame(width: 320, height: 220)
                .scaleEffect(x: 1, y: 220.0 / 320.0)
                .allowsHitTesting(false)
        }
        .background(ThemeColor.bg.color)
        .onAppear {
            // Bir kez: gösterildiği an işaretlenir (kutlama açıksa kart altında bekler)
            guard ReminderOffer.shouldOffer(model.settings, streak: model.stats.streak) else { return }
            offer = true
            model.settings.reminderOffered = true
        }
    }

    /// R8: hatırlatma kapalıyken ilk seri gününde "Serini koru" teklifi
    private var reminderOffer: some View {
        AppCard(tone: .violet500) {
            VStack(alignment: .leading, spacing: Space.s3) {
                HStack(spacing: Space.s2) {
                    Icon(.flame, size: 18, fill: true).foregroundStyle(ThemeColor.orangeText.color)
                    Text(ReminderOffer.title).font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color)
                }
                Text(ReminderOffer.text).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
                if offerMsg.isEmpty {
                    HStack(spacing: Space.s2) {
                        AppButton(ReminderOffer.decline, variant: .secondary, block: true) { withAnimation { offer = false } }
                        AppButton(ReminderOffer.accept, block: true, action: acceptReminder)
                    }
                } else {
                    Text(offerMsg)
                        .font(.ui(FontSize.sm))
                        .foregroundStyle(ThemeColor.redText.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .transition(.opacity)
    }

    /// İzin istenir, hatırlatma şimdiki saate kurulur; izin yoksa hatırlatma kapalı kalır ve kartta uyarı
    private func acceptReminder() {
        let c = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let h = c.hour ?? model.settings.reminderHour
        let m = c.minute ?? model.settings.reminderMinute
        Task { @MainActor in
            if await Reminder.enable(hour: h, minute: m) {
                model.settings.reminder = true
                model.settings.reminderHour = h
                model.settings.reminderMinute = m
                withAnimation { offer = false }
            } else {
                offerMsg = "Bildirim izni verilmedi. iPhone Ayarlar → Solvato → Bildirimler bölümünden açabilirsin."
            }
        }
    }

    private func statBox(icon: AnyView, value: String, label: String, text: ThemeColor, tint: PaletteColor) -> some View {
        VStack(spacing: 4) {
            icon.foregroundStyle(text.color)
            Text(value).font(.mono(FontSize.md, .heavy)).foregroundStyle(text.color)
            Text(label.uppercased(with: Locale(identifier: "tr")))
                .font(.ui(FontSize.xs, .semibold))
                .tracking(em: 0.05, size: FontSize.xs)
                .foregroundStyle(ThemeColor.textSubtle.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: Radius.lg).fill(tint.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(tint.opacity(0.2), lineWidth: 1))
    }
}

/// Saat ikonu (web: circle r10 + polyline 12 6 12 12 16 14)
private struct ClockIcon: View {
    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 24
            ctx.scaleBy(x: s, y: s)
            var p = Path(ellipseIn: CGRect(x: 2, y: 2, width: 20, height: 20))
            p.move(to: CGPoint(x: 12, y: 6))
            p.addLine(to: CGPoint(x: 12, y: 12))
            p.addLine(to: CGPoint(x: 16, y: 14))
            ctx.stroke(p, with: .foreground, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}

/// Ünvan kartı (web RankCard): rozet, "Ünvan · 5/15", ad, XP, ilerleme ve kalan XP; profilde ünvan listesiyle (detailed)
struct RankCardView: View {
    let xp: Int
    var gained = 0
    var detailed = false

    var body: some View {
        let r = Ranks.from(xp: xp)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Space.s3) {
                Text(verbatim: String(r.rank))
                    .font(.uiFixed(FontSize.lg, .heavy))
                    .foregroundStyle(PaletteColor.black.color)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(PaletteColor.amber400.color))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: "ÜNVAN · \(r.rank)/\(Ranks.all.count)")
                        .font(.ui(FontSize.xs, .bold))
                        .tracking(em: Tracking.label, size: FontSize.xs)
                        .foregroundStyle(ThemeColor.textSubtle.color)
                    Text(r.label).font(.ui(FontSize.lg, .heavy)).foregroundStyle(ThemeColor.text.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(verbatim: "\(xp) XP").font(.mono(FontSize.sm, .bold)).foregroundStyle(ThemeColor.amberText.color).lineLimit(1)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(ThemeColor.fillStrong.color)
                    Capsule()
                        .fill(LinearGradient(colors: [PaletteColor.amber500.color, PaletteColor.amber300.color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: g.size.width * Double(r.pct) / 100)
                }
            }
            .frame(height: 6)
            .padding(.top, Space.s3)
            Text(
                (gained > 0 ? "Bu turda +\(gained) XP. " : "")
                    + (r.nextLabel.map { "\($0) ünvanına \(r.toNext) XP kaldı." } ?? "En üst ünvandasın.")
            )
            .font(.ui(FontSize.sm))
            .foregroundStyle(ThemeColor.textMuted.color)
            .padding(.top, Space.s2)
            if detailed { list(r) }
        }
        .padding(Space.s4)
        .background(RoundedRectangle(cornerRadius: Radius.lg).fill(PaletteColor.amber500.opacity(0.07)))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(PaletteColor.amber500.opacity(0.25), lineWidth: 1))
    }

    private func list(_ r: RankInfo) -> some View {
        let vis = ProfileText.visibleRanks(r.rank)
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(vis.enumerated()), id: \.offset) { k, i in
                if k > 0 && i - vis[k - 1] > 1 {
                    Text("⋮").foregroundStyle(ThemeColor.textFaint.color).padding(.leading, 5).accessibilityHidden(true)
                }
                let done = i + 1 < r.rank
                let cur = i + 1 == r.rank
                HStack(spacing: Space.s2) {
                    Text(verbatim: done ? "✓" : String(i + 1))
                        .font(.uiFixed(11, .bold))
                        .foregroundStyle(cur ? PaletteColor.black.color : ThemeColor.amberText.color)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(cur ? PaletteColor.amber400.color : done ? PaletteColor.amber500.opacity(0.25) : ThemeColor.fillStrong.color))
                        .accessibilityHidden(true)
                    Text(Ranks.all[i].label).frame(maxWidth: .infinity, alignment: .leading)
                    Text(verbatim: "\(trNumber(Double(Ranks.all[i].min))) XP").font(.mono(FontSize.xs)).foregroundStyle(ThemeColor.textSubtle.color)
                }
                .font(.ui(FontSize.sm, cur ? .bold : .medium))
                .foregroundStyle((cur ? ThemeColor.text : done ? ThemeColor.textMuted : ThemeColor.textSubtle).color)
            }
        }
        .padding(.top, Space.s3)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(Ranks.all.count) ünvandan \(r.rank).")
    }
}

/// Kutlama penceresi (web Celebration): yeni ünvan, yeni seviye, günlük hedef, seri; konfeti; 6,5 sn sonra kapanır
struct CelebrationView: View {
    let data: Celebration
    let onClose: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        ZStack {
            PaletteColor.slate950.opacity(0.72).ignoresSafeArea().onTapGesture(perform: onClose)
            if !reduceMotion { ConfettiView() }
            VStack(spacing: 0) {
                Solfie(size: 88, pose: .cheer).padding(.bottom, 8)
                Text("Harika iş!").font(.ui(FontSize.lg, .heavy)).foregroundStyle(ThemeColor.text.color).padding(.bottom, 14)
                VStack(spacing: 8) {
                    ForEach(data.rows, id: \.title) { r in
                        HStack(spacing: 12) {
                            Icon(r.icon, size: 28, fill: r.filled).foregroundStyle(r.color.color)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(r.title).font(.ui(FontSize.md, .bold)).foregroundStyle(r.color.color)
                                Text(r.sub).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fill.color))
                        .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(r.color.color.opacity(0x44 / 255), lineWidth: 1))
                        // VoiceOver: kazanılan her şey tek öğe ("Seri 5 gün, …")
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.bottom, 18)
                Button(action: onClose) {
                    Text("Devam")
                        .font(.ui(FontSize.md, .bold))
                        .foregroundStyle(Brand.onPrimary.color)
                        .frame(maxWidth: .infinity)
                        .padding(13)
                        .background(CSSLinearGradient(.primaryFlat).clipShape(RoundedRectangle(cornerRadius: Radius.md)))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 26)
            .padding([.horizontal, .bottom], 20)
            .frame(maxWidth: 340)
            .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.surface.color))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(PaletteColor.violet500.opacity(0.35), lineWidth: 1))
            .shadow(color: .black.opacity(0.5), radius: 30, y: 20)
            .padding(24)
            // celebratePop: 0.8 → 1.03 → 1, aşağıdan
            .scaleEffect(shown || reduceMotion ? 1 : 0.8)
            .offset(y: shown || reduceMotion ? 0 : 14)
            .opacity(shown || reduceMotion ? 1 : 0)
        }
        // Kap adlı bir grup; içindeki düğmeler ayrı ayrı erişilebilir kalır
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel("Kutlama")
        .onAppear {
            Sound.play(data.sound)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { shown = true }
        }
        .task {
            try? await Task.sleep(for: .seconds(Celebration.autoClose))
            onClose()
        }
    }
}

/// Konfeti: 46 parça, renkler sırayla, yukarıdan düşer ve döner (web confettiFall)
private struct ConfettiView: View {
    private struct Piece {
        let left, dx, rot, dur, delay, size: Double
        let color: Color
        let round: Bool
    }
    private static let colors: [PaletteColor] = [.violet500, .violet400, .amber300, .green400, .pink400, .blue400]
    @State private var pieces: [Piece] = (0..<46).map { i in
        Piece(
            left: .random(in: 0..<1), dx: (Double.random(in: 0..<1) - 0.5) * 160, rot: 360 + .random(in: 0..<720),
            dur: 2.2 + .random(in: 0..<1.6), delay: .random(in: 0..<0.5), size: 6 + .random(in: 0..<7),
            color: ConfettiView.colors[i % ConfettiView.colors.count].color, round: i % 3 == 0)
    }
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSince(start)
                for p in pieces {
                    let k = min(1, max(0, (t - p.delay) / p.dur))
                    // cubic-bezier(0.25, 0.6, 0.4, 1) yaklaşık: hızlı başlar, yavaşlar
                    let e = 1 - pow(1 - k, 2.2)
                    let x = p.left * size.width + p.dx * e
                    let y = -20 + (size.height * 1.05 + 20) * e
                    var c = ctx
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .degrees(p.rot * e))
                    let h = p.round ? p.size : p.size * 1.6
                    let r = CGRect(x: -p.size / 2, y: -h / 2, width: p.size, height: h)
                    c.fill(p.round ? Path(ellipseIn: r) : Path(roundedRect: r, cornerRadius: 2), with: .color(p.color))
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
