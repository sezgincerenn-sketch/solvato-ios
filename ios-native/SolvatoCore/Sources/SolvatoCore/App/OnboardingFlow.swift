// Tanıtımın adım sırası ve geri/ileri kuralları (docs/ozellikler/tanitim.md; web revize Onboarding.tsx). Ekran
// Solvato/Screens/OnboardingScreen.swift. "Ben öğretmenim" seçilirse öğretmen sorusundan sonra tanıtım biter ve
// öğretmen kodu ekranı (öğrenci kodu hazırlama) açılır.
import Foundation

public enum OnboardingStep: Int, CaseIterable, Sendable {
    case intro, hello, try1, try2, teacher, clef, level, reminder, done
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

    /// Öğretmen sorusunda işaretli seçenek: daha önce cevaplandıysa o, değilse "Evet, öğretmenim var"
    public static func initialRole(_ s: Settings) -> TeacherRole { s.teacherRole == .unset ? .student : s.teacherRole }

    /// Öğretmen sorusunun seçenekleri (sırasıyla)
    public static let roles: [(role: TeacherRole, title: String, sub: String)] = [
        (.student, "Evet, öğretmenim var", "Öğretmeninle birlikte çalışıyorsun"),
        (.solo, "Hayır, kendi kendime", "Anahtar ve seviyeyi birlikte seçelim"),
        (.teacher, "Ben öğretmenim", "Öğrencilerim için kullanacağım"),
    ]
}
