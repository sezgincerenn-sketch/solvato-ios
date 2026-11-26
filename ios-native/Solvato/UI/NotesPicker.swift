// Çalışılacak notalar seçicisi (web components/NotesPicker.tsx): 7 nota düğmesi (en az 3 seçili) ve hazır seçimler.
// Ayarlar › Çalışılacak notalar ekranında ve öğretmen kodu hazırlarken kullanılır.
import SolvatoCore
import SwiftUI

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
