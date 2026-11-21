// Tema tercihi: sistem / koyu / açık. Web karşılığı src/state/theme.ts; aynı depolama anahtarı ve aynı varsayılan (sistem).

public enum ThemeMode: String, CaseIterable, Sendable {
    case system, dark, light

    /// Depolama anahtarı (web ile aynı ad; eski adlar bilerek korunuyor)
    public static let storageKey = "pianote_theme_v1"

    /// Kayıtlı değer okunamaz ya da tanınmazsa "sistem"
    public init(stored: String?) {
        self = stored.flatMap(ThemeMode.init(rawValue:)) ?? .system
    }

    /// Ekranda kullanılacak görünüm
    public func resolve(system: Appearance) -> Appearance {
        switch self {
        case .system: system
        case .dark: .dark
        case .light: .light
        }
    }
}
