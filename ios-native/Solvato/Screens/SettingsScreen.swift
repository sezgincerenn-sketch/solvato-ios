// Ayarlar (docs/ozellikler/ayarlar.md, Taslak 1): dört kart — Çalışma (hedef, seviye, anahtar, çalışılacak notalar),
// Sorular (cevap yöntemi, tuş isimleri, zaman yarışı), Ses ve bildirim (ses, titreşim, hatırlatma ve saati), Diğer (tema,
// tanıtım, gizlilik, lisanslar); en altta İlerlemeyi sıfırla ve sürüm. Değerli satıra dokununca seçim penceresi açılır.
// Parçalar UI/SettingsRows.swift; yazılar SolvatoCore SettingsText'te. Öğretmen kodu Profil'de (gezinme.md).
import SolvatoCore
import SwiftUI

struct SettingsScreen: View {
    let model: AppModel
    @State private var reminderMsg = ""
    @State private var confirmReset = false

    var body: some View {
        let s = model.settings
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SettingsGroup(title: "Çalışma") {
                    ChoiceRow(
                        title: "Günlük hedef", value: s.dailyGoal,
                        options: SettingsText.goalOptions.map { o -> (value: Int, label: String, sub: String?) in
                            (o.value, SettingsText.goalValue(o.value), o.sub)
                        }
                    ) { model.settings.dailyGoal = $0 }
                    SettingsDivider()
                    ChoiceRow(
                        title: "Seviye", sub: SettingsText.levelSub(s), value: s.level,
                        options: SettingsText.levelOptions.map { o -> (value: Int, label: String, sub: String?) in (o.value, o.label, nil) }
                    ) { l in
                        var next = model.settings
                        SettingsText.setLevel(l, in: &next)
                        model.settings = next
                    }
                    SettingsDivider()
                    ChoiceRow(
                        title: "Anahtar", value: s.clef,
                        options: SettingsText.clefOptions.map { o -> (value: ClefChoice, label: String, sub: String?) in (o.value, o.label, nil) }
                    ) { model.settings.clef = $0 }
                    SettingsDivider()
                    LinkRow(title: "Çalışılacak notalar", value: SettingsText.notesValue(s.notes)) { model.go(.notes) }
                }

                SettingsGroup(title: "Sorular") {
                    ChoiceRow(
                        title: "Cevap yöntemi", value: s.inputMode,
                        options: SettingsText.inputOptions.map { o -> (value: InputMode, label: String, sub: String?) in (o.value, o.label, nil) }
                    ) { model.settings.inputMode = $0 }
                    SettingsDivider()
                    ToggleRow(title: "Tuş isimlerini göster", on: s.keyLabels) { model.settings.keyLabels.toggle() }
                    SettingsDivider()
                    ToggleRow(title: "Zaman yarışı", on: s.timer) { model.settings.timer.toggle() }
                }

                SettingsGroup(title: "Ses ve bildirim") {
                    ToggleRow(title: "Ses", on: s.soundKeys) { model.settings.soundKeys.toggle() }
                    SettingsDivider()
                    ToggleRow(title: "Titreşim", on: s.haptics) { model.settings.haptics.toggle() }
                    SettingsDivider()
                    ToggleRow(title: "Günlük hatırlatma", on: s.reminder) { toggleReminder() }
                    if s.reminder {
                        SettingsDivider()
                        // Saat değişince bildirim yeni saate taşınır
                        TimeRow(title: "Hatırlatma saati", hour: s.reminderHour, minute: s.reminderMinute) { h, m in
                            model.settings.reminderHour = h
                            model.settings.reminderMinute = m
                            Task { _ = await Reminder.enable(hour: h, minute: m) }
                        }
                    }
                }
                if !reminderMsg.isEmpty {
                    Text(reminderMsg)
                        .font(.ui(FontSize.sm))
                        .foregroundStyle(ThemeColor.redText.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                }

                SettingsGroup(title: "Diğer") {
                    ChoiceRow(
                        title: "Tema", value: model.themeMode,
                        options: SettingsText.themeOptions.map { o -> (value: ThemeMode, label: String, sub: String?) in (o.value, o.label, nil) }
                    ) { model.themeMode = $0 }
                    SettingsDivider()
                    LinkRow(title: "Tanıtımı tekrar göster") { model.showTutorial() }
                    SettingsDivider()
                    LinkRow(title: HelpContent.title) { model.go(.help) }
                    SettingsDivider()
                    LinkRow(title: "Gizlilik") { model.go(.privacy) }
                    SettingsDivider()
                    LinkRow(title: "Lisanslar") { model.go(.licenses) }
                }

                resetArea.padding(.top, 18)
                Text("Sürüm 1.0")
                    .font(.ui(FontSize.sm))
                    .foregroundStyle(ThemeColor.textSubtle.color)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .padding(.top, Space.s2)
            .remembersScroll(model, .settings)
        }
        .scrollIndicators(.hidden)
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
        let m = model.settings.reminderMinute
        Task { @MainActor in
            if await Reminder.enable(hour: h, minute: m) {
                model.settings.reminder = true
                reminderMsg = ""
            } else {
                reminderMsg = "Bildirim izni verilmedi. iPhone Ayarlar → Solfado → Bildirimler bölümünden açabilirsin."
            }
        }
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
                    .contentShape(Rectangle())
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
