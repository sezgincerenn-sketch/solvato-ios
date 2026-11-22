// Düğme: tüm ekranlarda aynı boy, köşe ve renk kuralları. Web karşılığı src/ui/Button.tsx (birebir ölçüler).
import SolvatoCore
import SwiftUI

enum ButtonVariant {
    case primary, success, secondary, ghost
}

enum ButtonSize {
    case md, lg
}

struct AppButton<Icon: View>: View {
    let title: String
    var variant: ButtonVariant = .primary
    var size: ButtonSize = .md
    /// Satırı doldur
    var block = false
    var disabled = false
    /// Verilirse düğme bu metni sistemin paylaşım menüsüyle paylaşır (web shareWithToast)
    var shareText: String?
    let icon: Icon
    let action: () -> Void

    init(
        _ title: String,
        variant: ButtonVariant = .primary,
        size: ButtonSize = .md,
        block: Bool = false,
        disabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.block = block
        self.disabled = disabled
        self.action = action
        self.icon = icon()
    }

    private var radius: Double { size == .lg ? Radius.lg : Radius.md }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: radius, style: .circular) }

    var body: some View {
        Group {
            if let shareText {
                ShareLink(item: shareText) { label }
            } else {
                Button(action: action) { label }
            }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
    }

    private var label: some View {
        HStack(spacing: Space.s2) {
            icon
            Text(title)
        }
        .font(.ui(FontSize.md, .bold))
        .foregroundStyle(foreground)
        .padding(.vertical, size == .lg ? Space.s4 : Space.s3)
        .padding(.horizontal, size == .lg ? Space.s5 : Space.s4)
        .frame(minHeight: Touch.min)
        .frame(maxWidth: block ? .infinity : nil)
        .background { fill.clipShape(shape) }
        .overlay {
            if variant == .secondary { shape.strokeBorder(ThemeColor.border.color, lineWidth: 1) }
        }
        .shadow(variant == .primary ? BoxShadow.glow(Brand.primary, strength: 0.45) : BoxShadow.none)
        .contentShape(shape)
    }

    private var foreground: Color {
        switch variant {
        case .primary: Brand.onPrimary.color
        case .success: PaletteColor.white.color
        case .secondary: ThemeColor.textSecondary.color
        case .ghost: ThemeColor.textMuted.color
        }
    }

    @ViewBuilder private var fill: some View {
        switch variant {
        case .primary: CSSLinearGradient(.primaryFlat)
        case .success: CSSLinearGradient(.success)
        case .secondary: ThemeColor.fillStrong.color
        case .ghost: Color.clear
        }
    }
}

extension AppButton where Icon == EmptyView {
    /// İkonsuz paylaşım düğmesi
    init(_ title: String, block: Bool = false, share text: String) {
        self.init(title, block: block, action: {}) { EmptyView() }
        shareText = text
    }

    /// İkonsuz düğme
    init(
        _ title: String,
        variant: ButtonVariant = .primary,
        size: ButtonSize = .md,
        block: Bool = false,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.init(title, variant: variant, size: size, block: block, disabled: disabled, action: action) { EmptyView() }
    }
}
