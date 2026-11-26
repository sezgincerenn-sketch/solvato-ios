// Ayarlar: Çalışma (günlük hedef, seviye, anahtar, çalışılacak notalar), Soru ekranı (cevap yöntemi, tuş
// isimleri, zaman yarışı), Ses ve görünüm (ses, titreşim, tema), Hatırlatma, tanıtımı tekrar göster, ilerlemeyi sıfırla,
// Hakkında (gizlilik, lisanslar, sürüm). Öğretmen kodu Profil'de (gezinme.md). Web src/screens/SettingsScreen.tsx; yazılar SolvatoCore SettingsText'ten.
import SolvatoCore
import SwiftUI

struct SettingsScreen: View {
    let model: AppModel
    @State private var reminderMsg = ""
    @State private var confirmReset = false

    var body: some View {
        let s = model.settings
        VStack(spacing: 0) {
            ScreenHeader(title: "Ayarlar") { model.back() }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    section("Çalışma")
                    block("Günlük hedef", SettingsText.goalText[s.dailyGoal] ?? "") {
                        Segmented(value: s.dailyGoal, options: [10, 20, 30, 50].map { ($0, "\($0)") }) { model.settings.dailyGoal = $0 }
                    }
                    block("Seviye", SettingsText.levelSub(s)) {
                        Segmented(value: s.level, options: [(1, "Başlangıç"), (2, "Orta"), (3, "İleri")]) {
                            model.settings.level = $0
                            model.settings.levelProgress = LevelProgress(n: 0, c: 0)
                        }
                    }
                    block("Anahtar") {
                        Segmented(value: s.clef, options: [(ClefChoice.treble, "Sol"), (.bass, "Fa"), (.both, "İkisi de")]) { model.settings.clef = $0 }
                    }
                    block("Çalışılacak notalar", SettingsText.notesSummary(s.notes)) {
                        NotesPicker(value: s.notes) { model.settings.notes = $0 }
                    }

                    section("Soru ekranı")
                    block("Cevap yöntemi") {
                        Segmented(value: s.inputMode, options: [(InputMode.piano, "Klavye"), (.choice, "Şıklar")]) { model.settings.inputMode = $0 }
                    }
                    toggleRow("Tuş isimlerini göster", nil, s.keyLabels) { model.settings.keyLabels.toggle() }
                    toggleRow("Zaman yarışı", "Her soru için süre verilir.", s.timer) { model.settings.timer.toggle() }

                    section("Ses ve görünüm")
                    toggleRow("Ses", "Telefon sessiz moddayken de çalar.", s.soundKeys) { model.settings.soundKeys.toggle() }
                    toggleRow("Titreşim", nil, s.haptics) { model.settings.haptics.toggle() }
                    block("Tema") {
                        Segmented(value: model.themeMode, options: [(ThemeMode.system, "Sistem"), (.dark, "Koyu"), (.light, "Açık")]) { model.themeMode = $0 }
                    }

                    section("Hatırlatma")
                    toggleRow("Günlük hatırlatma", SettingsText.reminderSub(s), s.reminder) { toggleReminder() }
                    if !reminderMsg.isEmpty {
                        Text(reminderMsg).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.redText.color).padding(.vertical, 8)
                    }
                    if s.reminder {
                        HStack(spacing: 8) {
                            ForEach(SettingsText.reminderHours, id: \.self) { h in
                                Chip(String(format: "%02d:00", h), selected: s.reminderHour == h) {
                                    model.settings.reminderHour = h
                                    Task { _ = await Reminder.enable(hour: h) }
                                }
                            }
                        }
                        .padding(.vertical, 12)
                    }

                    plainButton("Tanıtımı tekrar göster") { model.showTutorial() }.padding(.top, 20)
                    resetArea.padding(.top, 14)

                    section("Hakkında")
                    linkRow("Gizlilik", "Veri toplanmaz, her şey bu cihazda") { model.go(.privacy) }
                    linkRow("Lisanslar", "Kullanılan yazı tipleri ve açık kaynak yazılımlar") { model.go(.licenses) }
                    Text("Sürüm 1.0")
                        .font(.ui(FontSize.sm))
                        .foregroundStyle(ThemeColor.textSubtle.color)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .remembersScroll(model, .settings)
            }
            .scrollIndicators(.hidden)
        }
        .background(ThemeColor.bg.color)
    }

    private func toggleReminder() {
        if model.settings.reminder {
            Reminder.disable()
            model.settings.reminder = false
            reminderMsg = ""
            return
        }
        let h = model.settings.reminderHour
        Task { @MainActor in
            if await Reminder.enable(hour: h) {
                model.settings.reminder = true
                reminderMsg = ""
            } else {
                reminderMsg = "Bildirim izni verilmedi. iPhone Ayarlar → Solvato → Bildirimler bölümünden açabilirsin."
            }
        }
    }

    // MARK: Parçalar
    private func section(_ t: String) -> some View {
        Text(t.uppercased(with: Locale(identifier: "tr")))
            .font(.ui(FontSize.xs, .bold))
            .tracking(em: 0.08, size: FontSize.xs)
            .foregroundStyle(ThemeColor.violetText.color)
            .padding(.top, 26)
            .padding(.bottom, 2)
    }

    private func titleSub(_ title: String, _ sub: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.ui(FontSize.md, .semibold)).foregroundStyle(ThemeColor.text.color)
            if let sub { Text(sub).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color).fixedSize(horizontal: false, vertical: true) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func block<C: View>(_ title: String, _ sub: String? = nil, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            titleSub(title, sub)
            content()
        }
        .padding(.top, 14)
        .padding(.bottom, 16)
        .overlay(alignment: .bottom) { ThemeColor.border.color.frame(height: 1) }
    }

    private func toggleRow(_ title: String, _ sub: String?, _ on: Bool, _ action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            titleSub(title, sub)
            Button(action: action) {
                ZStack(alignment: on ? .trailing : .leading) {
                    Capsule().fill(on ? PaletteColor.violet600.color : ThemeColor.fillStronger.color)
                    Circle().fill(PaletteColor.white.color).frame(width: 26, height: 26).padding(3)
                }
                .frame(width: 52, height: 32)
                .animation(.easeOut(duration: 0.18), value: on)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(on ? "Açık" : "Kapalı")
            .accessibilityAddTraits(.isToggle)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) { ThemeColor.border.color.frame(height: 1) }
    }

    private func linkRow(_ title: String, _ sub: String?, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                titleSub(title, sub)
                Text("›").font(.ui(FontSize.lg)).foregroundStyle(ThemeColor.textMuted.color).accessibilityHidden(true)
            }
            .padding(.vertical, 14)
            .overlay(alignment: .bottom) { ThemeColor.border.color.frame(height: 1) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func plainButton(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.ui(FontSize.md, .semibold))
                .foregroundStyle(ThemeColor.textSecondary.color)
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fill.color))
                .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var resetArea: some View {
        if !confirmReset {
            Button { confirmReset = true } label: {
                Text("İlerlemeyi sıfırla")
                    .font(.ui(FontSize.md, .semibold))
                    .foregroundStyle(ThemeColor.redText.color)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(PaletteColor.red500.opacity(0.1)))
                    .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(PaletteColor.red500.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(.plain)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("XP, seri ve tüm istatistiklerin silinecek. Bu geri alınamaz.").font(.ui(FontSize.md)).foregroundStyle(ThemeColor.redText.color)
                HStack(spacing: 10) {
                    Button { confirmReset = false } label: {
                        Text("Vazgeç").font(.ui(FontSize.sm, .bold)).foregroundStyle(ThemeColor.textSecondary.color)
                            .frame(maxWidth: .infinity).padding(12)
                            .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fillStrong.color))
                            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
                    }
                    Button {
                        confirmReset = false
                        model.resetProgress()
                    } label: {
                        Text("Sıfırla").font(.ui(FontSize.sm, .bold)).foregroundStyle(PaletteColor.white.color)
                            .frame(maxWidth: .infinity).padding(12)
                            .background(RoundedRectangle(cornerRadius: Radius.md).fill(PaletteColor.red600.color))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: Radius.md).fill(PaletteColor.red500.opacity(0.08)))
            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(PaletteColor.red500.opacity(0.25), lineWidth: 1))
        }
    }
}

/// Çalışılacak notalar: 7 nota düğmesi (en az 3 seçili) ve hazır seçimler (web NotesPicker)
struct NotesPicker: View {
    let value: [String]
    let onChange: ([String]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Segmented(options: allNotes.map { ($0, $0) }, isSelected: { value.contains($0) }, columns: 7, size: .sm) {
                onChange(SettingsText.toggleNote($0, in: value))
            }
            HStack(spacing: 8) {
                ForEach(SettingsText.notePresets, id: \.label) { p in
                    Chip(p.label, selected: value == p.notes) { onChange(p.notes) }
                }
            }
        }
    }
}
