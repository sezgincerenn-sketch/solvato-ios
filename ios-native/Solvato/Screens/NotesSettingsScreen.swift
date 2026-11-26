// Ayarlar › Çalışılacak notalar (docs/ozellikler/ayarlar.md): nota sorularında çıkacak notalar (en az 3) ve hazır
// seçimler; altında bugünkü açıklama. Seçim ayarlara hemen yazılır. Nota seçici NotesPicker (SettingsScreen.swift).
import SolvatoCore
import SwiftUI

struct NotesSettingsScreen: View {
    let model: AppModel

    var body: some View {
        let notes = model.settings.notes
        VStack(spacing: 0) {
            ScreenHeader(title: "Çalışılacak notalar") { model.back() }
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s4) {
                    NotesPicker(value: notes) { model.settings.notes = $0 }
                    Text(SettingsText.notesSummary(notes))
                        .font(.ui(FontSize.sm))
                        .foregroundStyle(ThemeColor.textMuted.color)
                        .lineHeight(1.5, size: FontSize.sm)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .padding(.top, Space.s2)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .background(ThemeColor.bg.color)
    }
}
