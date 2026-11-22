// Ekran iskeleti parçaları. Web karşılıkları: src/ui/Avatar.tsx, BackButton.tsx, ScreenHeader.tsx, Toast.tsx,
// PlayChip.tsx, TopicLink.tsx, ExitConfirm.tsx, NavBar.tsx, TabletColumn.tsx. Ölçüler ve metinler web'den birebir.
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
                Text(initial).font(.ui((size * 0.44).rounded(), .heavy))
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

/// Alt ekran başlığı: geri düğmesi + başlık (+ sağda isteğe bağlı öğe)
struct ScreenHeader<Right: View>: View {
    let title: String
    var flush = false
    let onBack: () -> Void
    @ViewBuilder var right: Right

    var body: some View {
        HStack(spacing: 10) {
            BackButton(action: onBack)
            Text(title)
                .font(.ui(FontSize.xl, .heavy))
                .tracking(em: Tracking.tight, size: FontSize.xl)
                .foregroundStyle(ThemeColor.text.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            right
        }
        .padding(.top, flush ? 0 : Space.s4)
        .padding(.horizontal, flush ? 0 : Space.s4)
        .padding(.bottom, flush ? 0 : Space.s2)
    }
}

extension ScreenHeader where Right == EmptyView {
    init(title: String, flush: Bool = false, onBack: @escaping () -> Void) {
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
                if let stars { Stars(value: stars, size: 13) }
                PlayChip()
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

// MARK: - Alt menü
enum NavTab: String, CaseIterable, Sendable {
    case home, dashboard, study

    var label: String {
        switch self {
        case .home: "Pratik"
        case .dashboard: "İlerleme"
        case .study: "Çalışma"
        }
    }
}

/// Alt menü: Pratik · İlerleme · Çalışma
struct NavBar: View {
    let active: NavTab
    let onChange: (NavTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(NavTab.allCases, id: \.self) { t in
                let on = t == active
                Button {
                    onChange(t)
                } label: {
                    VStack(spacing: Space.s1) {
                        NavIcon(tab: t, active: on).frame(width: 22, height: 22)
                        Text(t.label)
                            .font(.ui(FontSize.xs, .semibold))
                            .foregroundStyle((on ? ThemeColor.violetText : ThemeColor.textMuted).color)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Space.s4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .background(alignment: .top) {
            ZStack(alignment: .top) {
                Rectangle().fill(.ultraThinMaterial)
                ThemeColor.overlay.color
                ThemeColor.border.color.frame(height: 1)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

/// Alt menü ikonları (web NavIcon, 24'lük kutu)
private struct NavIcon: View {
    let tab: NavTab
    let active: Bool

    var body: some View {
        let col = (active ? ThemeColor.violetText : ThemeColor.textMuted).color
        let sw = active ? 2.0 : 1.5
        Canvas { ctx, size in
            let s = size.width / 24
            ctx.scaleBy(x: s, y: s)
            let style = StrokeStyle(lineWidth: sw, lineCap: .round, lineJoin: .round)
            func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ r: Double) -> Path {
                Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r)
            }
            func line(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) -> Path {
                var p = Path()
                p.move(to: CGPoint(x: x1, y: y1))
                p.addLine(to: CGPoint(x: x2, y: y2))
                return p
            }
            switch tab {
            case .home:
                // Piyano klavyesi
                ctx.stroke(rect(3, 5, 18, 14, 2), with: .color(col), style: style)
                ctx.stroke(line(9, 12, 9, 19), with: .color(col), style: style)
                ctx.stroke(line(15, 12, 15, 19), with: .color(col), style: style)
                for x in [7.5, 13.5] {
                    let r = rect(x, 5, 3, 7, 0.8)
                    ctx.fill(r, with: .color(col))
                    ctx.stroke(r, with: .color(col), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                }
            case .dashboard:
                for (x, y, h) in [(3.0, 12.0, 9.0), (10, 7, 14), (17, 3, 18)] {
                    ctx.stroke(rect(x, y, 4, h, 1), with: .color(col), style: style)
                }
            case .study:
                var book = Path()
                book.move(to: CGPoint(x: 4, y: 19))
                book.addLine(to: CGPoint(x: 4, y: 6))
                book.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: 6, y: 4), radius: 2)
                book.addLine(to: CGPoint(x: 18, y: 4))
                book.addArc(tangent1End: CGPoint(x: 20, y: 4), tangent2End: CGPoint(x: 20, y: 6), radius: 2)
                book.addLine(to: CGPoint(x: 20, y: 19))
                book.move(to: CGPoint(x: 4, y: 19))
                book.addArc(tangent1End: CGPoint(x: 4, y: 21), tangent2End: CGPoint(x: 6, y: 21), radius: 2)
                book.addLine(to: CGPoint(x: 18, y: 21))
                book.addArc(tangent1End: CGPoint(x: 20, y: 21), tangent2End: CGPoint(x: 20, y: 19), radius: 2)
                ctx.stroke(book, with: .color(col), style: style)
                ctx.stroke(line(9, 9, 15, 9), with: .color(col), style: style)
                ctx.stroke(line(9, 13, 13, 13), with: .color(col), style: style)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Tablet sütunu
/// Tablette okunur genişlik: içerik ortada, en fazla `width` pt. Telefonda bir şey yapmaz.
struct TabletColumn<Content: View>: View {
    var width: Double = 680
    @ViewBuilder var content: Content
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            content.frame(maxWidth: width).frame(maxWidth: .infinity)
        } else {
            content
        }
    }
}
