// Native Solvato'nun girişi. Tema tercihini (sistem / koyu / açık) web'le aynı anahtarda saklar ve uygular.
// UI testleri `-UITestTheme dark|light` başlatma argümanıyla temayı zorlar (kayıtlı tercihi değiştirmeden).
// UI test senaryosu (SOLVATO_SENARYO_* ortam değişkenleri, TestScenario) verilirse uygulama o veriyle bellekte açılır
// ve kök görünüm (AppRoot) gösterilir; yoksa şimdilik tasarım sistemi ekranı (ekranlar 0.5'te tamamlanınca kök AppRoot).
import SolvatoCore
import SwiftUI

@main
struct SolvatoApp: App {
    @AppStorage(ThemeMode.storageKey) private var storedTheme = ThemeMode.system.rawValue
    @State private var scenarioModel: AppModel? = TestScenario(environment: ProcessInfo.processInfo.environment)?.makeModel()

    private var themeMode: Binding<ThemeMode> {
        Binding(get: { ThemeMode(stored: storedTheme) }, set: { storedTheme = $0.rawValue })
    }

    /// Test argümanı varsa o tema; yoksa kullanıcının tercihi
    private var effectiveMode: ThemeMode {
        ThemeMode(rawValue: UserDefaults.standard.string(forKey: "UITestTheme") ?? "") ?? themeMode.wrappedValue
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let scenarioModel {
                    AppRoot(model: scenarioModel)
                } else {
                    DesignSystemScreen(themeMode: themeMode)
                }
            }
            .preferredColorScheme(effectiveMode.colorScheme)
        }
    }
}
