// Native Solvato'nun girişi. Tema tercihini (sistem / koyu / açık) web'le aynı anahtarda saklar ve uygular.
// UI testleri `-UITestTheme dark|light` başlatma argümanıyla temayı zorlar (kayıtlı tercihi değiştirmeden).
// Kök görünüm AppRoot (Pratik ile açılır). UI test senaryosu (SOLVATO_SENARYO_* ortam değişkenleri, TestScenario)
// verilirse uygulama o veriyle bellekte ve sabit tarihle açılır; `-UITestDesignSystem` tasarım sistemi önizlemesini açar.
import SolvatoCore
import SwiftUI
import UIKit

@main
struct SolvatoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    /// UI test senaryosu varsa o veriyle bellekte; yoksa gerçek kayıtlarla
    @State private var model: AppModel = TestScenario(environment: ProcessInfo.processInfo.environment)?.makeModel() ?? AppModel()

    /// Tema tercihi uygulama durumunda (Persistence, `pianote_theme_v1`)
    private var themeMode: Binding<ThemeMode> {
        Binding(get: { model.themeMode }, set: { model.themeMode = $0 })
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
            // Koyu/Açık'tan Sistem'e dönünce bazı iOS sürümlerinde preferredColorScheme(nil) uygulamayı yeniden
            // açana kadar etkisiz kalır; pencerenin kendi ayarı da güncellenir (G-04: Sistem anında değişir)
            .onChange(of: effectiveMode, initial: true) { _, m in
                let style: UIUserInterfaceStyle = m == .dark ? .dark : m == .light ? .light : .unspecified
                for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
                    for w in scene.windows { w.overrideUserInterfaceStyle = style }
                }
            }
        }
    }
}
