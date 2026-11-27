// Dokunma alanı: her parmağın değdiği an ayrı ayrı bildirilir (web onPointerDown gibi; çoklu dokunuş açık).
// Kullanıldığı yer: Ritmi Tut'taki "Dokun" alanı (RhythmTapScreen). SwiftUI'nin DragGesture'ı tek parmağı izlediği için.
import SwiftUI
import UIKit

struct TouchDownPad: UIViewRepresentable {
    let onTouch: () -> Void

    func makeUIView(context: Context) -> PadView {
        let v = PadView()
        v.isMultipleTouchEnabled = true
        v.backgroundColor = .clear
        v.onTouch = onTouch
        return v
    }

    func updateUIView(_ uiView: PadView, context: Context) { uiView.onTouch = onTouch }

    final class PadView: UIView {
        var onTouch: (() -> Void)?
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            for _ in touches { onTouch?() }
        }
    }
}
