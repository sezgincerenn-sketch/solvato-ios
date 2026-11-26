// Ayarlar › Çalışılacak notalar (docs/ozellikler/ayarlar.md): açıklama ve nota seçici (en az 3 nota, hazır seçimler).
// Geri oku ve kenardan kaydırma Ayarlar'a döner; Ayarlar kalınan yerden açılır.
import SolvatoCore
import SwiftUI

struct NotesSettingsScreen: View {
    let model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Çalışılacak notalar") { model.back() }
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s4) {
                    Text(SettingsText.notesSummary(model.settings.notes))
                        .font(.ui(FontSize.sm))
                        .foregroundStyle(ThemeColor.textMuted.color)
                        .fixedSize(horizontal: false, vertical: true)
                    NotesPicker(value: model.settings.notes) { model.settings.notes = $0 }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Space.s5)
                .padding(.top, Space.s2)
                .padding(.bottom, Space.s8)
            }
            .scrollIndicators(.hidden)
        }
        .background(ThemeColor.bg.color)
    }
}
