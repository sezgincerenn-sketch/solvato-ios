// Ekran iskeleti parçaları. Web karşılıkları: src/ui/Avatar.tsx, BackButton.tsx, ScreenHeader.tsx, Toast.tsx,
// PlayChip.tsx, TopicLink.tsx, ExitConfirm.tsx, TabletColumn.tsx; alt menünün sekmeleri (çubuk: UI/SystemTabs.swift). Ölçüler ve metinler web'den birebir.
import SolvatoCore
import SwiftUI

// MARK: - Profil resmi
/// Seçilen renkte daire, içinde ismin baş harfi (isim yoksa nota ikonu)
struct Avatar: View {
    /// Seçilebilir renkler: palet adı → [üst, alt] gradyan (web AVATAR_COLORS)
    static let colors: [(key: String, stops: (PaletteColor, PaletteColor))] = [
        ("violet", (.violet500, .violet800)), ("blue", (.blue500, .blue700)), ("green", (.green500, .green700)),
        ("amber", (.amber400, .amber600)), ("pink", (.pink400, .pink500)), ("cyan", (.cyan400, .teal700)),
    ]

    let name: String
    var color = "violet"
    var size: Double = 44

    var body: some View {
        let stops = Self.colors.first { $0.key == color }?.stops ?? Self.colors[0].stops
        let initial = name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1).uppercased(with: Locale(identifier: "tr"))
        ZStack {
            CSSLinearGradient([stops.0.color, stops.1.color]).clipShape(Circle())
            if initial.isEmpty {
                Icon(.note, size: (size * 0.46).rounded())
            } else {
                Text(initial).font(.uiFixed((size * 0.44).rounded(), .heavy))
            }
        }
        .foregroundStyle(PaletteColor.white.color)
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Geri düğmesi ve ekran başlığı
/// Bütün ekranlarda aynı geri düğmesi
struct BackButton: View {
    var label = "Geri"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            BackArrow()
                .stroke(ThemeColor.textSecondary.color, style: StrokeStyle(lineWidth: 2.5 * 18 / 24, lineCap: .round, lineJoin: .round))
                .frame(width: 18, height: 18)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fillStrong.color))
                .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Web: <path d="M19 12H5M12 5l-7 7 7 7" /> (24'lük kutuda)
private struct BackArrow: Shape {
    func path(in r: CGRect) -> Path {
        let s = r.width / 24
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: r.minX + x * s, y: r.minY + y * s) }
        var path = Path()
        path.move(to: p(19, 12))
        path.addLine(to: p(5, 12))
        path.move(to: p(12, 5))
        path.addLine(to: p(5, 12))
        path.addLine(to: p(12, 19))
        return path
    }
}

/// Alt ekran başlığı: geri düğmesi + başlık (+ sağda isteğe bağlı öğe). onBack yoksa (sekme ekranı) geri düğmesi yok.
struct ScreenHeader<Right: View>: View {
    let title: String
    var flush = false
    /// Sekme ekranı (Profil): başlık İlerleme ve Öğren'deki TabTitle ile aynı yükseklikte (Ceren, 27 Kasım)
    var tab = false
    let onBack: (() -> Void)?
    @ViewBuilder var right: Right

    var body: some View {
        HStack(spacing: 10) {
            if let onBack { BackButton(action: onBack) }
            Text(title)
                .font(.ui(FontSize.xl, .heavy))
                .tracking(em: Tracking.tight, size: FontSize.xl)
                .foregroundStyle(ThemeColor.text.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            right
        }
        .padding(.top, flush ? 0 : tab ? Self.tabTop : Space.s4)
        .padding(.horizontal, flush ? 0 : Space.s4)
        .padding(.bottom, flush ? 0 : Space.s2)
    }

    /// TabTitle yazısı kaydırma alanının 32 pt altında başlar; burada yazı 44 pt'lik satırda ortalı (sağdaki düğme)
    static var tabTop: Double { 32 - (Touch.min - FontSize.xl * 1.26) / 2 }
}

extension ScreenHeader where Right == EmptyView {
    init(title: String, flush: Bool = false, onBack: (() -> Void)?) {
        self.init(title: title, flush: flush, onBack: onBack) { EmptyView() }
    }
}

// MARK: - Kısa bildirim
/// Kısa bilgi balonu (web useToast): `toast.show("Kopyalandı")`, 2,2 sn sonra kaybolur
@MainActor @Observable
final class ToastModel {
    private(set) var message: String?
    private var task: Task<Void, Never>?
    let duration: Double

    init(duration: Double = 2.2) { self.duration = duration }

    func show(_ m: String) {
        message = m
        task?.cancel()
        task = Task { [weak self, duration] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.message = nil
        }
    }
}

struct ToastView: View {
    let model: ToastModel
    var body: some View {
        if let m = model.message {
            Text(m)
                .font(.ui(FontSize.sm, .semibold))
                .foregroundStyle(PaletteColor.violet100.color)
                .lineLimit(1)
                .fixedSize()
                .padding(.vertical, 10)
                .padding(.horizontal, Space.s4)
                .background(RoundedRectangle(cornerRadius: Radius.md).fill(PaletteColor.violet950.color))
                .shadow(BoxShadow.raised)
                .padding(.bottom, Space.s6)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .accessibilityAddTraits(.updatesFrequently)
        }
    }
}

// MARK: - Konu satırları
/// Konu satırlarının sağındaki küçük oynat düğmesi; her satırda aynı mor
struct PlayChip: View {
    var body: some View {
        PlayTriangle()
            .fill(ThemeColor.violetText.color)
            .frame(width: 13, height: 13)
            .frame(width: 34, height: 34)
            .background(RoundedRectangle(cornerRadius: Radius.sm).fill(PaletteColor.violet500.opacity(0.12)))
            .overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(PaletteColor.violet500.opacity(0.25), lineWidth: 1))
            .accessibilityHidden(true)
    }
}

/// Web: <path d="M5 3l14 9-14 9V3z" />
private struct PlayTriangle: Shape {
    func path(in r: CGRect) -> Path {
        let s = r.width / 24
        var p = Path()
        p.move(to: CGPoint(x: r.minX + 5 * s, y: r.minY + 3 * s))
        p.addLine(to: CGPoint(x: r.minX + 19 * s, y: r.minY + 12 * s))
        p.addLine(to: CGPoint(x: r.minX + 5 * s, y: r.minY + 21 * s))
        p.closeSubpath()
        return p
    }
}

/// Konunun hemen altındaki ek alıştırma satırı (Diyez & Bemol › Akor, Ritim & Ölçü › Ritmi Tut)
struct TopicLink: View {
    let color: CategoryColor
    let icon: IconName
    let title: String
    let sub: String
    var stars: Int?
    /// Verilirse yıldız ve oynat simgesi yerine yüzde halkası (Ana sayfa)
    var acc: Tally?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Icon(icon, size: 22)
                    .foregroundStyle(color.text.color)
                    .frame(width: 44, height: 44)
                    .background {
                        CSSLinearGradient([color.base.opacity(0.16), color.base.opacity(0.08)])
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    }
                    .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(color.base.opacity(0.2), lineWidth: 1))
                    .overlay(alignment: .top) {
                        // inset 0 1px 0 rgba(255,255,255,0.06)
                        PaletteColor.white.opacity(0.06).frame(height: 1).padding(.horizontal, Radius.md / 2)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.ui(FontSize.md, .semibold)).foregroundStyle(ThemeColor.text.color)
                    Text(sub).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let acc {
                    PercentRing(acc: acc, color: color.base)
                    // Konu kartlarındaki gibi ▶ (R40): Ana sayfadaki bütün satırlar aynı
                    PlayShape()
                        .fill(ThemeColor.textFaint.color)
                        .frame(width: 10, height: 10)
                        .accessibilityHidden(true)
                } else {
                    if let stars { Stars(value: stars, size: 13) }
                    PlayChip()
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColor.fill.color))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Turdan çıkış onayı
/// Test, akor ve Ritmi Tut ekranlarının geri düğmesi ve kenardan kaydırma bunu açar
struct ExitConfirm: View {
    var title = "Turdan çıkılsın mı?"
    var text = "Bu turdaki cevapların kaydedilmeyecek."
    let onStay: () -> Void
    let onExit: () -> Void

    var body: some View {
        ZStack {
            ThemeColor.scrim.color.ignoresSafeArea().onTapGesture {}
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color).padding(.bottom, 6)
                Text(text)
                    .font(.ui(FontSize.sm))
                    .lineSpacing(FontSize.sm * 0.5 - 4)
                    .foregroundStyle(ThemeColor.textMuted.color)
                    .padding(.bottom, 16)
                HStack(spacing: 10) {
                    Button(action: onStay) {
                        Text("Devam et")
                            .font(.ui(FontSize.sm, .bold))
                            .foregroundStyle(Brand.onPrimary.color)
                            .frame(maxWidth: .infinity)
                            .padding(13)
                            .background(CSSLinearGradient(.primaryFlat).clipShape(RoundedRectangle(cornerRadius: Radius.md)))
                    }
                    Button(action: onExit) {
                        Text("Çık")
                            .font(.ui(FontSize.sm, .bold))
                            .foregroundStyle(ThemeColor.textSecondary.color)
                            .frame(maxWidth: .infinity)
                            .padding(13)
                            .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fillStrong.color))
                            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .frame(maxWidth: 320)
            .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.surface.color))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
            .padding(24)
        }
        // Kap adlı bir grup; içindeki düğmeler ayrı ayrı erişilebilir kalır
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel("Turdan çık")
    }
}

// MARK: - Turdan çıkış düğmesi
/// Soru, akor ve Ritmi Tut turlarının sol üstündeki çarpı (R16): hep aynı görünüm; dokununca çıkış onayı
struct RoundCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Icon(.x, size: 18)
                .foregroundStyle(ThemeColor.textMuted.color)
                .frame(width: Touch.min, height: Touch.min)
                .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fillStrong.color))
                .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Turdan çık")
    }
}

// MARK: - Alt menü
/// Alt menünün dört sekmesi (gezinme.md R13). Çubuğun kendisi Apple'ın sekme çubuğu: UI/SystemTabs.swift.
enum NavTab: String, CaseIterable, Sendable {
    case home, dashboard, study, profile

    var label: String {
        switch self {
        case .home: "Ana sayfa"
        case .dashboard: "İlerleme"
        case .study: "Öğren"
        case .profile: "Profil"
        }
    }

    /// Apple simgesi (seçiliyken sistem dolu hâlini kullanır): ev, sütun grafiği, kitap, kişi
    var symbol: String {
        switch self {
        case .home: "house"
        case .dashboard: "chart.bar"
        case .study: "book"
        case .profile: "person"
        }
    }
}

// MARK: - Tablet sütunu
/// Tablette okunur genişlik: içerik ortada, en fazla `width` pt. Telefonda (ve iPad'in dar penceresinde) tam genişlik.
/// Dal yok: Split View / Stage Manager'da pencere daralıp genişleyince ekranın durumu (ör. Ritmi Tut turu) korunur.
struct TabletColumn<Content: View>: View {
    var width: Double = 680
    @ViewBuilder var content: Content
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        content.frame(maxWidth: CGFloat(sizeClass == .regular ? width : .infinity)).frame(maxWidth: .infinity)
    }
}
