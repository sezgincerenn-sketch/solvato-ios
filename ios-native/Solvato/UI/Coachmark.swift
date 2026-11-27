// Ana sayfa ilk kullanım ipuçları (web src/ui/Coachmark.tsx + App.tsx COACH_STEPS): ekrandaki öğeleri sırayla
// aydınlatır (çevresi kararır, mor çerçeve), altında ya da üstünde açıklama balonu; "Atla" / "Sıradaki" / "Anladım".
// Hedefler `.coachTarget("today")` ile işaretlenir; konumlar SwiftUI anchor tercihleriyle toplanır.
import SolvatoCore
import SwiftUI

struct CoachStep {
    let target: String
    let title: String
    let text: String

    /// Sayfadaki sırayla, yukarıdan aşağı (R29, Ceren 26 Kasım): sayfa hep aşağı iner, bitince en üste döner
    static let home: [CoachStep] = [
        .init(target: "level", title: "Seviyen", text: "Bu seviyede 50 soru çözüp %80 doğru yapınca bir üst seviyenin soruları açılır."),
        .init(target: "today", title: "Buradan başla", text: "Her gün karışık 10 soru. Günlük hedefini tamamlayınca serin bir gün artar."),
        .init(target: "games", title: "Oyunlar", text: "Günün meydan okumasını oyna ya da arkadaşına meydan oku."),
        .init(target: "categories", title: "Bir konuya odaklan", text: "Sadece Sol anahtarı, ritim ya da terim çalışmak istersen bir karta dokun."),
        .init(
            target: "nav", title: "İlerleme, Öğren ve Profil",
            text: "Gelişimini İlerleme'de gör, notaları Öğren'de çalış; öğretmen kodu ve ayarlar Profil'de."),
    ]
}

struct CoachTargets: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    /// Tanıtımda aydınlatılacak öğe
    func coachTarget(_ name: String) -> some View {
        anchorPreference(key: CoachTargets.self, value: .bounds) { [name: $0] }
    }
}

struct CoachmarkView: View {
    let steps: [CoachStep]
    let index: Int
    let rect: CGRect?
    let onNext: () -> Void
    let onDone: () -> Void
    /// VoiceOver: balon açılınca ve her adımda odak balonun yazısına gelir
    @AccessibilityFocusState private var focused: Bool

    var body: some View {
        GeometryReader { geo in
            let H = geo.size.height
            let pad = 6.0
            let hole = rect.map { $0.insetBy(dx: -pad, dy: -pad) }
            let below = rect.map { $0.midY < H / 2 } ?? true
            let step = steps[index]
            ZStack(alignment: .topLeading) {
                // Karartma ve aydınlatılan alan (çift-tek dolgu ile delik)
                Path { p in
                    p.addRect(CGRect(origin: .zero, size: geo.size).insetBy(dx: -2000, dy: -2000))
                    if let hole { p.addRoundedRect(in: hole, cornerSize: CGSize(width: Radius.lg, height: Radius.lg)) }
                }
                .fill(PaletteColor.slate950.opacity(0.72), style: FillStyle(eoFill: true))
                // Web'deki tam ekran katman gibi bütün dokunuşları tutar: aydınlatılan alana dokunulup turdan çıkılamaz
                .contentShape(Rectangle())
                .onTapGesture {}
                .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.22), value: hole)
                if let hole {
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .stroke(PaletteColor.violet400.color, lineWidth: 2)
                        .frame(width: hole.width + 2, height: hole.height + 2)
                        .offset(x: hole.minX - 1, y: hole.minY - 1)
                        .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.22), value: hole)
                }
                bubble(step)
                    .popInOnAppear()
                    .frame(maxWidth: 420)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Space.s4)
                    .frame(maxHeight: .infinity, alignment: rect == nil ? .center : below ? .top : .bottom)
                    .padding(.top, rect != nil && below ? (hole!.maxY + 12) : 0)
                    .padding(.bottom, rect != nil && !below ? (H - hole!.minY + 12) : 0)
                    .id(index)
            }
        }
        .ignoresSafeArea(.keyboard)
        // Kap adlı bir grup; içindeki düğmeler ayrı ayrı erişilebilir kalır
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel("Kısa tanıtım")
    }

    private func bubble(_ step: CoachStep) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // "1/5", başlık ve metin tek öğe; Atla / Sıradaki ayrı düğmeler
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "\(index + 1)/\(steps.count)")
                    .font(.ui(FontSize.xs, .bold))
                    .tracking(em: Tracking.label, size: FontSize.xs)
                    .foregroundStyle(ThemeColor.textSubtle.color)
                Text(step.title).font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color).padding(.top, 2)
                Text(step.text).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color).lineHeight(1.5, size: FontSize.sm).padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityFocused($focused)
            .onAppear {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    focused = true
                }
            }
            HStack {
                AppButton("Atla", variant: .ghost, action: onDone)
                Spacer()
                AppButton(index == steps.count - 1 ? "Anladım" : "Sıradaki", action: index == steps.count - 1 ? onDone : onNext)
            }
            .padding(.top, Space.s3)
        }
        .padding(Space.s4)
        .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.surface.color))
        .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
        .shadow(BoxShadow.raised)
    }
}
