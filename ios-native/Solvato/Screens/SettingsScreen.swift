// Ayarlar (docs/ozellikler/ayarlar.md, Taslak 1): dört kart — Çalışma (günlük hedef, seviye, anahtar, çalışılacak
// notalar), Sorular (cevap yöntemi, tuş isimleri, zaman yarışı), Ses ve bildirim (ses, titreşim, hatırlatma ve saati),
// Diğer (tema, tanıtım, gizlilik, lisanslar); en altta "İlerlemeyi sıfırla" ve sürüm. Değerli satırlar seçim penceresi
// açar (UI/SettingsRows). Öğretmen kodu Profil'de (gezinme.md). Yazılar SolvatoCore SettingsText'ten.
import SolvatoCore
import SwiftUI

struct SettingsScreen: View {
    let model: AppModel
    @State private var reminderMsg = ""
    @State private var confirmReset = false
    @State private var timeOpen = false

    var body: some View {
        let s = model.settings
        VStack(spacing: 0) {
            ScreenHeader(title: "Ayarlar") { model.back() }
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s6) {
                    SettingsGroup(title: "Çalışma") {
                        SettingsPickerRow(
                            title: "Günlük hedef",
                            options: SettingsText.goalOptions.map { OptionItem(value: $0.goal, label: SettingsText.goalValue($0.goal), note: $0.note) },
                            selected: s.dailyGoal
                        ) { model.settings.dailyGoal = $0 }
                        SettingsPickerRow(
                            title: "Seviye", sub: SettingsText.levelSub(s),
                            options: SettingsText.levelOptions.map { OptionItem(value: $0.level, label: $0.label) },
                            selected: s.level
                        ) { model.settings.setLevel($0) }
                        SettingsPickerRow(
                            title: "Anahtar", options: SettingsText.clefOptions.map { OptionItem(value: $0.clef, label: $0.label) },
                            selected: s.clef
                        ) { model.settings.clef = $0 }
                        SettingsValueRow(title: "Çalışılacak notalar", value: SettingsText.notesValue(s.notes)) { model.go(.notes) }
                    }

                    SettingsGroup(title: "Sorular") {
                        SettingsPickerRow(
                            title: "Cevap yöntemi", options: SettingsText.inputOptions.map { OptionItem(value: $0.mode, label: $0.label) },
                            selected: s.inputMode
                        ) { model.settings.inputMode = $0 }
                        SettingsToggleRow(title: "Tuş isimlerini göster", isOn: s.keyLabels) { model.settings.keyLabels.toggle() }
                        SettingsToggleRow(title: "Zaman yarışı", isOn: s.timer) { model.settings.timer.toggle() }
                    }

                    VStack(alignment: .leading, spacing: Space.s2) {
                        SettingsGroup(title: "Ses ve bildirim") {
                            SettingsToggleRow(title: "Ses", isOn: s.soundKeys) { model.settings.soundKeys.toggle() }
                            SettingsToggleRow(title: "Titreşim", isOn: s.haptics) { model.settings.haptics.toggle() }
                            SettingsToggleRow(title: "Günlük hatırlatma", isOn: s.reminder) { toggleReminder() }
                            if s.reminder {
                                SettingsValueRow(title: "Hatırlatma saati", value: SettingsText.clock(hour: s.reminderHour, minute: s.reminderMinute)) {
                                    timeOpen = true
                                }
                                // Saat değişince bildirim yeni saate taşınır
                                .timeWheel(isPresented: $timeOpen, hour: s.reminderHour, minute: s.reminderMinute, label: "Hatırlatma saati") { h, m in
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
                                .padding(.horizontal, Space.s1)
                        }
                    }

                    SettingsGroup(title: "Diğer") {
                        SettingsPickerRow(
                            title: "Tema", options: SettingsText.themeOptions.map { OptionItem(value: $0.mode, label: $0.label) },
                            selected: model.themeMode
                        ) { model.themeMode = $0 }
                        SettingsLinkRow(title: "Tanıtımı tekrar göster") { model.showTutorial() }
                        SettingsLinkRow(title: "Gizlilik") { model.go(.privacy) }
                        SettingsLinkRow(title: "Lisanslar") { model.go(.licenses) }
                    }

                    VStack(spacing: Space.s2) {
                        resetArea
                        Text("Sürüm 1.0")
                            .font(.ui(FontSize.sm))
                            .foregroundStyle(ThemeColor.textSubtle.color)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, Space.s4)
                .padding(.top, Space.s2)
                .padding(.bottom, Space.s8)
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
        let m = model.settings.reminderMinute
        Task { @MainActor in
            if await Reminder.enable(hour: h, minute: m) {
                model.settings.reminder = true
                reminderMsg = ""
            } else {
                reminderMsg = "Bildirim izni verilmedi. iPhone Ayarlar → Solvato → Bildirimler bölümünden açabilirsin."
            }
        }
    }

    /// Kartların altında ortalı kırmızı "İlerlemeyi sıfırla"; dokununca onay alanı
    @ViewBuilder
    private var resetArea: some View {
        if !confirmReset {
            Button { confirmReset = true } label: {
                Text("İlerlemeyi sıfırla")
                    .font(.ui(FontSize.md, .semibold))
                    .foregroundStyle(ThemeColor.redText.color)
                    .frame(maxWidth: .infinity)
                    .padding(Space.s3)
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
