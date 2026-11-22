// Öğretmen kodu (Ayarlar › Öğretmen kodu): 1) öğrenci öğretmeninin gönderdiği kodu girer, ayarlar kurulur; 2) öğretmen
// öğrencisi için seçim yapar, kodu paylaşım menüsüyle gönderir. Web src/screens/TeacherScreen.tsx; kurallar
// SolvatoCore TeacherFlow / TeacherCode'da.
import SolvatoCore
import SwiftUI

struct TeacherScreen: View {
    let model: AppModel
    @State private var code = ""
    @State private var err = ""
    @State private var applied: (code: String, setup: TeacherSetup)?
    @State private var setup: TeacherSetup

    init(model: AppModel) {
        self.model = model
        _setup = State(initialValue: TeacherFlow.initialSetup(model.settings))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Öğretmen kodu") { model.back() }
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s3) {
                    muted("Öğretmenin hangi notaları ve hangi seviyede çalışacağını bir kodla gönderir. Kodu girince uygulaman o ayarlarla kurulur.")
                    AppCard { student }
                    AppCard { teacher }
                }
                .padding(.horizontal, Space.s4)
                .padding(.top, Space.s2)
                .padding(.bottom, Space.s6)
                .remembersScroll(model, .teacher)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(ThemeColor.bg.color)
    }

    // MARK: 1) Öğrenci
    @ViewBuilder private var student: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            title("Öğretmeninden kod mu geldi?")
            if let applied {
                muted("Ayarların güncellendi (\(applied.code))", color: ThemeColor.greenText.color, weight: .semibold)
                setupList(applied.setup)
                muted("İstediğin zaman Ayarlar'dan değiştirebilirsin.")
            } else {
                CodeField(
                    code: $code, error: $err, placeholder: "ABC-DEF", label: "Öğretmen kodu", button: "Uygula",
                    sanitize: TeacherFlow.sanitize, onSubmit: apply)
                if !model.settings.teacherCode.isEmpty {
                    muted("Son uygulanan kod: \(model.settings.teacherCode)", size: FontSize.xs)
                }
            }
        }
    }

    private func apply() {
        var s = model.settings
        guard let r = TeacherFlow.apply(code, to: &s) else {
            err = TeacherFlow.invalidMessage
            return
        }
        model.settings = s
        applied = r
        code = ""
    }

    // MARK: 2) Öğretmen
    @ViewBuilder private var teacher: some View {
        let teacherCode = TeacherCode.encode(setup)
        VStack(alignment: .leading, spacing: Space.s3) {
            title("Öğretmensen: öğrencine kod hazırla")
            muted("Seçimlerini yap, kodu öğrencine gönder. Her öğrenciye ya da her döneme ayrı kod verebilirsin.")

            label("Konular")
            FlowLayout(spacing: 8) {
                Chip("Hepsi", selected: TeacherCode.allTopics(setup.topics)) { setup.topics = [] }
                ForEach(TeacherCode.topics, id: \.key) { t in
                    Chip(t.label, selected: TeacherFlow.topicSelected(t.key, in: setup.topics)) {
                        setup.topics = TeacherFlow.toggleTopic(t.key, in: setup.topics)
                    }
                }
            }
            muted("Seçilen konular öğrencinin ana sayfasında en üstte çıkar, günlük karışık tur da bunlardan gelir.", size: FontSize.xs)
                .padding(.top, -4)

            label("Anahtar")
            Segmented(value: setup.clef, options: [(ClefChoice.treble, "Sol"), (.bass, "Fa"), (.both, "İkisi de")], size: .sm) { setup.clef = $0 }
            label("Seviye")
            Segmented(value: setup.level, options: [1, 2, 3].map { ($0, QuestionLevel.label($0)) }, size: .sm) { setup.level = $0 }
            label("Çalışılacak notalar")
            NotesPicker(value: setup.notes) { setup.notes = $0 }
            label("Günlük hedef")
            Segmented(value: setup.dailyGoal, options: TeacherCode.goals.map { ($0, "\($0) soru") }, size: .sm) { setup.dailyGoal = $0 }
            label("Tuşlarda nota adları")
            Segmented(value: setup.keyLabels, options: [(false, "Gizli"), (true, "Görünür")], size: .sm) { setup.keyLabels = $0 }

            VStack(spacing: 4) {
                muted("Öğrencinin gireceği kod", size: FontSize.xs)
                Text(teacherCode)
                    .font(.mono(FontSize.xxl, .heavy))
                    .lineHeight(1.5, size: FontSize.xxl, natural: 1.32)
                    .tracking(4)
                    .foregroundStyle(ThemeColor.text.color)
                    .accessibilityLabel("Öğrencinin gireceği kod \(teacherCode)")
            }
            .frame(maxWidth: .infinity)
            .padding(Space.s4)
            .background(RoundedRectangle(cornerRadius: Radius.lg).fill(ThemeColor.fillStrong.color))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(ThemeColor.borderStrong.color, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
            .padding(.top, Space.s2)

            AppButton("Kodu gönder", block: true, share: TeacherCode.shareText(code: teacherCode, setup))
        }
    }

    // MARK: Parçalar
    private func setupList(_ s: TeacherSetup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Web <ul>: madde işareti yok (Tailwind sıfırlaması), soldan 18 boşluk
            ForEach(TeacherCode.describe(s), id: \.self) { line in
                Text(line)
                    .font(.ui(FontSize.sm))
                    .foregroundStyle(ThemeColor.textMuted.color)
                    .lineHeight(1.5, size: FontSize.sm)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.leading, 18)
    }

    private func title(_ t: String) -> some View {
        Text(t).font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color)
    }

    private func label(_ t: String) -> some View {
        Text(t).font(.ui(FontSize.sm, .semibold)).foregroundStyle(ThemeColor.textSecondary.color)
    }

    private func muted(_ t: String, size: Double = FontSize.sm, color: Color? = nil, weight: FontWeight = .regular) -> some View {
        Text(t)
            .font(.ui(size, weight))
            .foregroundStyle(color ?? ThemeColor.textMuted.color)
            .lineHeight(1.5, size: size)
            .fixedSize(horizontal: false, vertical: true)
    }
}
