// Kaydırma hafızası (web utils/scrollMemory.ts): bir ekrandan ileri gidip geri dönünce ekran kalınan yerden açılır.
// Ekranların kaydırma alanları o anki konumlarını bildirir (report); ileri gidilirken bulunulan ekranın konumları
// saklanır, geri dönülünce (ve kaydırarak geri dönerken altta görünen ekranda) yeniden uygulanır. Sekmeye geçmek
// hafızayı siler. Gezinme kuralları web App.tsx setView / goBack ile aynı; AppModel.go / back çağırır.

@MainActor
public final class ScrollMemory {
    /// Saklanan konumlar: ekran → kaydırma alanı sırası → üstten uzaklık (pt)
    private var saved: [AppView: [Int: Double]] = [:]
    /// Görünen ekranın o anki konumları
    private var live: [AppView: [Int: Double]] = [:]
    /// Geri dönülen ekran: açılınca saklanan konum bir kez uygulanır
    public private(set) var restoring: AppView?

    public init() {}

    /// Kaydırma alanı konumunu bildirir (yalnız o an görünen ekran için anlamlı)
    public func report(_ v: AppView, slot: Int, y: Double) { live[v, default: [:]][slot] = y }

    /// İleri gidiliyor (ScreenStack.go'dan önce)
    func willGo(from cur: AppView, to v: AppView) {
        restoring = nil
        if v.isTab {
            saved = [:]
        } else if cur != .result && cur != .gameresult && cur != v {
            saved[cur] = live[cur] ?? [:]
        }
        live[v] = nil
    }

    /// Geri dönüldü
    func didBack(to v: AppView) {
        restoring = v
        live[v] = nil
    }

    /// Kaydırma alanı açılınca uygulanacak konum. Geri dönülen ekranda bir kez (sonra unutulur); kaydırarak geri
    /// dönerken altta görünen ekranda (şu anki ekran değil) her seferinde. Konum yoksa ya da en üstteyse nil.
    public func restore(_ v: AppView, slot: Int, current: AppView) -> Double? {
        guard restoring == v || current != v, let y = saved[v]?[slot], y > 0 else { return nil }
        if current == v { saved[v]?[slot] = nil }
        return y
    }
}
