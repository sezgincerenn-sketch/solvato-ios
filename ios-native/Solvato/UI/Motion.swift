// Ortak animasyonlar (G-06, web src/index.css): sallanma (yanlış, 0,44 sn), doğru nabzı (0,52 sn), aşağıdan kayarak
// belirme (0,38 sn), büyüyerek belirme (0,3 sn), seri alevi (0,7 sn), nota zıplaması (0,55 sn) ve titremesi (0,45 sn).
// Anahtar kareler ve eğriler CSS'teki gibi: eğri (animation-timing-function) her iki kare arasına ayrı uygulanır.
// Hareketi azalt açıksa hiçbiri oynamaz, son hâl görünür. Soru turu, akor turu, düello ve "yan çevir" ipucunda.
import SolvatoCore
import SwiftUI

/// CSS cubic-bezier
private func bezier(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) -> UnitCurve {
    .bezier(startControlPoint: UnitPoint(x: x1, y: y1), endControlPoint: UnitPoint(x: x2, y: y2))
}

private struct ShakeValue {
    var x = 0.0
    var r = 0.0
}

/// Yanlış cevapta sallanma (web .animate-shake): `active` true olunca bir kez
private struct Shake: ViewModifier {
    let active: Bool
    @State private var runs = 0
    @Environment(\.accessibilityReduceMotion) private var reduce

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: ShakeValue(), trigger: runs) { c, v in
                c.rotationEffect(.degrees(v.r)).offset(x: v.x)
            } keyframes: { _ in
                let c = bezier(0.36, 0.07, 0.19, 0.97)
                let d = 0.44 * 0.15
                KeyframeTrack(\.x) {
                    LinearKeyframe(-9, duration: d, timingCurve: c)
                    LinearKeyframe(8, duration: d, timingCurve: c)
                    LinearKeyframe(-7, duration: d, timingCurve: c)
                    LinearKeyframe(6, duration: d, timingCurve: c)
                    LinearKeyframe(-4, duration: d, timingCurve: c)
                    LinearKeyframe(0, duration: 0.44 * 0.25, timingCurve: c)
                }
                KeyframeTrack(\.r) {
                    LinearKeyframe(-1, duration: d, timingCurve: c)
                    LinearKeyframe(1, duration: d, timingCurve: c)
                    LinearKeyframe(-0.8, duration: d, timingCurve: c)
                    LinearKeyframe(0.5, duration: d, timingCurve: c)
                    LinearKeyframe(0, duration: d, timingCurve: c)
                    LinearKeyframe(0, duration: 0.44 * 0.25, timingCurve: c)
                }
            }
            .onChange(of: active, initial: true) { _, a in if a && !reduce { runs += 1 } }
    }
}

/// Doğru cevapta yeşil halka dışa yayılıp kaybolur (web .animate-correct-pulse: box-shadow 0 → 22 px, %55'te biter)
private struct CorrectPulse: ViewModifier {
    let active: Bool
    let cornerRadius: Double
    @State private var runs = 0
    @Environment(\.accessibilityReduceMotion) private var reduce

    func body(content: Content) -> some View {
        content.overlay {
            if runs > 0 {
                KeyframeAnimator(initialValue: 0.0, trigger: runs) { p in
                    // p: 0 → 1 halka büyür, saydamlaşır; sonra görünmez
                    let s = 22 * p
                    RoundedRectangle(cornerRadius: cornerRadius + s / 2)
                        .stroke(PaletteColor.green500.opacity(0.75 * (1 - p)), lineWidth: s)
                        .padding(-s / 2)
                        .opacity(p >= 1 ? 0 : 1)
                        .allowsHitTesting(false)
                } keyframes: { _ in
                    KeyframeTrack {
                        LinearKeyframe(1.0, duration: 0.52 * 0.55, timingCurve: .easeOut)
                        LinearKeyframe(1.0, duration: 0.52 * 0.45)
                    }
                }
            }
        }
        .onChange(of: active, initial: true) { _, a in if a && !reduce { runs += 1 } }
    }
}

/// Görünürken aşağıdan kayarak belirir (web .animate-slide-up: 44 pt aşağıdan, saydamdan)
private struct SlideUp: ViewModifier {
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduce

    func body(content: Content) -> some View {
        content
            .opacity(shown || reduce ? 1 : 0)
            .offset(y: shown || reduce ? 0 : 44)
            .onAppear { withAnimation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.38)) { shown = true } }
    }
}

/// Görünürken büyüyerek belirir (web .animate-pop-in / @keyframes popIn: 0,82 → %65'te 1,05 → 1, saydamdan).
/// Varsayılan 0,3 sn ease-out; yıldızlarda 0,45 sn yaylı eğri ve gecikme (CSS animation-delay, "both": önce görünmez).
private struct PopIn: ViewModifier {
    var duration = 0.3
    var curve: UnitCurve = .easeOut
    var delay = 0.0
    @State private var runs = 0
    @Environment(\.accessibilityReduceMotion) private var reduce

    private struct V {
        var scale = 0.82
        var opacity = 0.0
    }

    func body(content: Content) -> some View {
        if reduce {
            content
        } else {
            content
                .keyframeAnimator(initialValue: V(), trigger: runs) { c, v in
                    c.scaleEffect(v.scale).opacity(v.opacity)
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        LinearKeyframe(0.82, duration: delay)
                        LinearKeyframe(1.05, duration: duration * 0.65, timingCurve: curve)
                        LinearKeyframe(1, duration: duration * 0.35, timingCurve: curve)
                    }
                    // opaklık 0 → 1 tüm süre boyunca (65 %'te ara kare yok)
                    KeyframeTrack(\.opacity) {
                        LinearKeyframe(0, duration: delay)
                        LinearKeyframe(1, duration: duration, timingCurve: curve)
                    }
                }
                .onAppear { runs += 1 }
        }
    }
}

/// Görünürken 16 pt aşağıdan belirir (web .animate-fade-in-up: 0,32 sn ease-out; tur sonucu ekranı)
private struct FadeInUp: ViewModifier {
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduce

    func body(content: Content) -> some View {
        content
            .opacity(shown || reduce ? 1 : 0)
            .offset(y: shown || reduce ? 0 : 16)
            .onAppear { withAnimation(.easeOut(duration: 0.32)) { shown = true } }
    }
}

/// Seri alevi titrer (web .flame-live: 1,1 sn, ölçek 1 → 1,12, dönüş −2° → 3°, alt-orta eksende, sürekli)
private struct FlameFlicker: ViewModifier {
    let on: Bool
    @Environment(\.accessibilityReduceMotion) private var reduce

    private struct V {
        var scale = 1.0
        var r = -2.0
    }

    func body(content: Content) -> some View {
        if on && !reduce {
            content.keyframeAnimator(initialValue: V(), repeating: true) { c, v in
                c.scaleEffect(v.scale, anchor: UnitPoint(x: 0.5, y: 0.9)).rotationEffect(.degrees(v.r), anchor: UnitPoint(x: 0.5, y: 0.9))
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    LinearKeyframe(1.12, duration: 0.55, timingCurve: .easeInOut)
                    LinearKeyframe(1, duration: 0.55, timingCurve: .easeInOut)
                }
                KeyframeTrack(\.r) {
                    LinearKeyframe(3, duration: 0.55, timingCurve: .easeInOut)
                    LinearKeyframe(-2, duration: 0.55, timingCurve: .easeInOut)
                }
            }
        } else {
            content
        }
    }
}

extension View {
    /// Yanlış cevapta sallanma
    func shake(_ active: Bool) -> some View { modifier(Shake(active: active)) }
    /// Doğru cevapta yeşil nabız
    func correctPulse(_ active: Bool, cornerRadius: Double) -> some View { modifier(CorrectPulse(active: active, cornerRadius: cornerRadius)) }
    /// Aşağıdan kayarak belirme
    func slideUpOnAppear() -> some View { modifier(SlideUp()) }
    /// Büyüyerek belirme
    func popInOnAppear() -> some View { modifier(PopIn()) }
    /// Yıldızların belirmesi (web Stars animate: 0,45 sn, yaylı eğri, `delay` sn sonra)
    func starPopIn(delay: Double) -> some View {
        modifier(PopIn(duration: 0.45, curve: bezier(0.34, 1.56, 0.64, 1), delay: delay))
    }
    /// Ekranın aşağıdan belirmesi
    func fadeInUpOnAppear() -> some View { modifier(FadeInUp()) }
    /// Seri alevinin titremesi (seri > 0)
    func flameFlicker(_ on: Bool) -> some View { modifier(FlameFlicker(on: on)) }
}

/// Üç doğruda skorun üstünde yükselip kaybolan alev (web .animate-streak-flare)
struct StreakFlare<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.accessibilityReduceMotion) private var reduce
    @State private var runs = 0

    private struct V {
        var opacity = 0.0
        var scale = 0.5
        var y = 0.0
    }

    var body: some View {
        if reduce {
            content.opacity(0)
        } else {
            content.keyframeAnimator(initialValue: V(), trigger: runs) { c, v in
                c.scaleEffect(v.scale).offset(y: v.y).opacity(v.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.opacity) {
                    LinearKeyframe(1, duration: 0.42, timingCurve: .easeOut)
                    LinearKeyframe(0, duration: 0.28, timingCurve: .easeOut)
                }
                KeyframeTrack(\.scale) {
                    LinearKeyframe(1.3, duration: 0.42, timingCurve: .easeOut)
                    LinearKeyframe(1, duration: 0.28, timingCurve: .easeOut)
                }
                KeyframeTrack(\.y) {
                    LinearKeyframe(-12, duration: 0.42, timingCurve: .easeOut)
                    LinearKeyframe(-24, duration: 0.28, timingCurve: .easeOut)
                }
            }
            .onAppear { runs += 1 }
        }
    }
}

/// Portedeki nota grubunun hareketi (web .note-bounce / .note-wobble): ölçek, x, y (çizim birimi)
struct GroupMotion: Equatable {
    var scale = 1.0
    var x = 0.0
    var y = 0.0
}

/// Cevaptan sonra nota zıplar (doğru) ya da titrer (yanlış); `content` hareket değeriyle çizimi kurar
struct NoteMotion<Content: View>: View {
    let feedback: Bool?
    @ViewBuilder let content: (GroupMotion) -> Content
    @State private var runs = 0
    @State private var correct = true
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        KeyframeAnimator(initialValue: GroupMotion(), trigger: runs) { v in
            content(v)
        } keyframes: { _ in
            // Doğru: zıplama (ölçek + y, 0,55 sn); yanlış: titreme (x, 0,45 sn). Kullanılmayan izler yerinde durur.
            let c = bezier(0.34, 1.56, 0.64, 1)
            let b = correct ? 1.0 : 0
            let w = correct ? 0.0 : 1
            KeyframeTrack(\.scale) {
                LinearKeyframe(1 + 0.28 * b, duration: 0.55 * 0.35, timingCurve: c)
                LinearKeyframe(1 - 0.04 * b, duration: 0.55 * 0.3, timingCurve: c)
                LinearKeyframe(1, duration: 0.55 * 0.35, timingCurve: c)
            }
            KeyframeTrack(\.y) {
                LinearKeyframe(-6 * b, duration: 0.55 * 0.35, timingCurve: c)
                LinearKeyframe(1 * b, duration: 0.55 * 0.3, timingCurve: c)
                LinearKeyframe(0, duration: 0.55 * 0.35, timingCurve: c)
            }
            KeyframeTrack(\.x) {
                LinearKeyframe(-4 * w, duration: 0.09, timingCurve: .easeInOut)
                LinearKeyframe(4 * w, duration: 0.09, timingCurve: .easeInOut)
                LinearKeyframe(-3 * w, duration: 0.09, timingCurve: .easeInOut)
                LinearKeyframe(2 * w, duration: 0.09, timingCurve: .easeInOut)
                LinearKeyframe(0, duration: 0.09, timingCurve: .easeInOut)
            }
        }
        .onChange(of: feedback, initial: true) { _, f in
            guard let f, !reduce else { return }
            correct = f
            runs += 1
        }
    }
}

/// "Telefonu yan çevir, klavye büyüsün" ipucu (web components/RotateHint.tsx): telefon simgesi 2,4 sn'de bir yana
/// döner; dokununca kapanır.
struct RotateHintView: View {
    let onClose: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        Button(action: onClose) {
            HStack(spacing: 12) {
                ZStack {
                    phone
                        .keyframeAnimator(initialValue: 0.0, repeating: !reduce) { c, r in
                            c.rotationEffect(.degrees(reduce ? 0 : r))
                        } keyframes: { _ in
                            // 0–%15 dik, %45–70 yan, %100 dik; her aralık ease-in-out
                            KeyframeTrack {
                                LinearKeyframe(0, duration: 2.4 * 0.15, timingCurve: .easeInOut)
                                LinearKeyframe(-90, duration: 2.4 * 0.3, timingCurve: .easeInOut)
                                LinearKeyframe(-90, duration: 2.4 * 0.25, timingCurve: .easeInOut)
                                LinearKeyframe(0, duration: 2.4 * 0.3, timingCurve: .easeInOut)
                            }
                        }
                    arrow
                }
                .frame(width: 34, height: 34)
                Text("Telefonu yan çevir, klavye büyüsün")
                    .font(.ui(FontSize.sm, .semibold))
                    .foregroundStyle(ThemeColor.violetTextSoft.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("✕").font(.ui(FontSize.md)).foregroundStyle(ThemeColor.textMuted.color).accessibilityHidden(true)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: Radius.md).fill(PaletteColor.violet500.opacity(0.12)))
            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(PaletteColor.violet500.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .accessibilityLabel("Telefonu yan çevirirsen klavye büyür. Kapatmak için dokun.")
        .slideUpOnAppear()
    }

    /// 34×34 SVG: telefon gövdesi ve ekranda küçük klavye (döndürme merkezi 17, 17)
    private var phone: some View {
        Canvas { ctx, _ in
            ctx.stroke(
                Path(roundedRect: CGRect(x: 10, y: 3, width: 14, height: 28), cornerRadius: 3), with: .color(PaletteColor.violet400.color),
                lineWidth: 2)
            ctx.fill(
                Path(roundedRect: CGRect(x: 12, y: 20, width: 10, height: 7), cornerRadius: 1), with: .color(PaletteColor.violet400.opacity(0.35)))
            for x in [14.5, 17, 19.5] {
                var p = Path()
                p.move(to: CGPoint(x: x, y: 20))
                p.addLine(to: CGPoint(x: x, y: 27))
                ctx.stroke(p, with: .color(PaletteColor.slate900.color), lineWidth: 0.8)
            }
        }
        .frame(width: 34, height: 34)
    }

    /// Sağ üstte amber dönüş oku (web'deki yollar, SVGPath ile)
    private var arrow: some View {
        Canvas { ctx, _ in
            let style = StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            for d in ["M27 9 A 12 12 0 0 1 30 17", "M30.5 13.5 L 30 17.2 L 26.6 15.8"] {
                let p = DrawingRenderer.path((try? SVGPath.parse(d)) ?? [])
                ctx.stroke(p, with: .color(PaletteColor.amber400.color), style: style)
            }
        }
        .frame(width: 34, height: 34)
    }
}
