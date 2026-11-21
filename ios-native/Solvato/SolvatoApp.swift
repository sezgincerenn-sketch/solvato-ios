// Native Solvato'nun girişi. Tema tercihini (sistem / koyu / açık) web'le aynı anahtarda saklar ve uygular.
// UI testleri `-UITestTheme dark|light` başlatma argümanıyla temayı zorlar (kayıtlı tercihi değiştirmeden).
import SolvatoCore
import SwiftUI

@main
struct SolvatoApp: App {
    @AppStorage(ThemeMode.storageKey) private var storedTheme = ThemeMode.system.rawValue

    private var themeMode: Binding<ThemeMode> {
        Binding(get: { ThemeMode(stored: storedTheme) }, set: { storedTheme = $0.rawValue })
    }

    /// Test argümanı varsa o tema; yoksa kullanıcının tercihi
    private var effectiveMode: ThemeMode {
        ThemeMode(rawValue: UserDefaults.standard.string(forKey: "UITestTheme") ?? "") ?? themeMode.wrappedValue
    }

    var body: some Scene {
        WindowGroup {
            DesignSystemScreen(themeMode: themeMode)
                .preferredColorScheme(effectiveMode.colorScheme)
        }
    }
}
