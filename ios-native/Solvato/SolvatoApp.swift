// Native Solvato'nun girişi. Tema tercihini (sistem / koyu / açık) web'le aynı anahtarda saklar ve uygular.
// UI testleri `-UITestTheme dark|light` başlatma argümanıyla temayı zorlar (kayıtlı tercihi değiştirmeden).
// Kök görünüm AppRoot (Pratik ile açılır). UI test senaryosu (SOLVATO_SENARYO_* ortam değişkenleri, TestScenario)
// verilirse uygulama o veriyle bellekte ve sabit tarihle açılır; `-UITestDesignSystem` tasarım sistemi önizlemesini açar.
import SolvatoCore
import SwiftUI

@main
struct SolvatoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(ThemeMode.storageKey) private var storedTheme = ThemeMode.system.rawValue
    /// UI test senaryosu varsa o veriyle bellekte; yoksa gerçek kayıtlarla
    @State private var model: AppModel = TestScenario(environment: ProcessInfo.processInfo.environment)?.makeModel() ?? AppModel()

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
                // Tasarım sistemi önizlemesi yalnız UI testinde (-UITestDesignSystem)
                if ProcessInfo.processInfo.arguments.contains("-UITestDesignSystem") {
                    DesignSystemScreen(themeMode: themeMode)
                } else {
                    AppRoot(model: model)
                }
            }
            .preferredColorScheme(effectiveMode.colorScheme)
        }
    }
}
