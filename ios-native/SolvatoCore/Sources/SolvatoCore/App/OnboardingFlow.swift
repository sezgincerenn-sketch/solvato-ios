// Tanıtımın adım sırası, geri/ileri kuralları ve giriş metinleri (docs/ozellikler/tanitim.md, kullanici-testi-revize.md
// madde 2). Ekran Solvato/Screens/OnboardingScreen.swift. Altı adım: giriş + ad → Do → Sol → öğretmen sorusu → Ayarların
// (anahtar, seviye, hedef, hatırlatma) → hazırsın. "Ben öğretmenim" seçilirse öğretmen sorusundan sonra tanıtım biter
// ve öğretmen kodu ekranı (öğrenci kodu hazırlama) açılır.
import Foundation

public enum OnboardingStep: Int, CaseIterable, Sendable {
    case intro, try1, try2, teacher, setup, done
}

public enum OnboardingFlow {
    /// Sonraki adım; nil ise tanıtım biter (öğretmen yolu: soru cevaplandı, rol öğretmen)
    public static func next(after step: OnboardingStep, role: TeacherRole) -> OnboardingStep? {
        if step == .teacher && role == .teacher { return nil }
        return OnboardingStep(rawValue: step.rawValue + 1)
    }

    /// Geri oku: bir önceki adım (ilk adımda yerinde kalır)
    public static func back(from step: OnboardingStep) -> OnboardingStep {
        OnboardingStep(rawValue: max(0, step.rawValue - 1)) ?? .intro
    }

    /// Geri oku görünür mü (ilk adımda yeri boş kalır)
    public static func showsBack(_ step: OnboardingStep) -> Bool { step != .intro }

    /// Giriş başlığı
    public static let introTitle = "Her gün birkaç dakikayla nota okumak kolaylaşsın."
    /// Girişteki simgeli listenin satırları (simge ekranda; ad)
    public static let features = ["Nota okuma", "Ritim", "Akor", "Kulak"]
    /// Liste VoiceOver'da tek öğe
    public static let featuresLabel = "Nota okuma, ritim, akor ve kulak çalışmaları"
    /// Denemede doğru tuştan sonra sonraki adıma geçmeden önceki bekleme (sn)
    public static let autoAdvanceDelay = 1.0

    /// Öğretmen sorusunda işaretli seçenek: daha önce cevaplandıysa o, değilse "Evet, öğretmenim var"
    public static func initialRole(_ s: Settings) -> TeacherRole { s.teacherRole == .unset ? .student : s.teacherRole }

    /// Öğretmen sorusunun seçenekleri (sırasıyla)
    public static let roles: [(role: TeacherRole, title: String, sub: String)] = [
        (.student, "Evet, öğretmenim var", "Öğretmeninle birlikte çalışıyorsun"),
        (.solo, "Hayır, kendi kendime", "Anahtar ve seviyeyi birlikte seçelim"),
        (.teacher, "Ben öğretmenim", "Öğrencilerim için kullanacağım"),
    ]
}
