// Ekran yönü (G-02, web utils/orientation.ts allowLandscape): telefonda yalnız soru ve akor turu yan döner, diğer
// ekranlar dikey kilitli; iPad'de her ekran her yönde. Uygulama temsilcisi izin verilen yönleri buradan okur.
import SwiftUI
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    @MainActor static var mask: UIInterfaceOrientationMask = .portrait

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .pad ? .all : AppDelegate.mask
    }
}

@MainActor
enum Orientation {
    static func allowLandscape(_ on: Bool) {
        guard UIDevice.current.userInterfaceIdiom != .pad else { return }
        AppDelegate.mask = on ? .allButUpsideDown : .portrait
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        if !on { scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { _ in } }
    }
}
