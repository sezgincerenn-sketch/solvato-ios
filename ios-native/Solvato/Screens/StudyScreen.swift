// Çalışma sekmesi: konu arama, "Kaldığın yer" kartı ve bölüm bölüm ders listesi. Bir derse dokununca LessonScreen açılır.
// Web src/screens/study/StudyScreen.tsx; ders listesi ve arama kuralı SolvatoCore Lessons'ta (web'le altın tabloyla aynı).
import SolvatoCore
import SwiftUI

struct StudyScreen: View {
    let model: AppModel
    @State private var query = ""
    /// Ekran açıldığındaki son ders (web: useState(readLast))
    @State private var last: Lesson?
    @State private var loaded = false

    var body: some View {
        let groups = Lessons.groups(query: query)
        let searching = !Lessons.norm(query.trimmingCharacters(in: .whitespacesAndNewlines)).isEmpty
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s5) {
                VStack(alignment: .leading, spacing: Space.s3) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Çalışma")
                            .font(.ui(FontSize.xl, .heavy))
                            .tracking(em: Tracking.tight, size: FontSize.xl)
                            .foregroundStyle(ThemeColor.text.color)
                            .accessibilityAddTraits(.isHeader)
                        Text("Bir konu seç; notaları, ritmi ve akorları adım adım öğren.")
                            .font(.ui(FontSize.sm))
                            .foregroundStyle(ThemeColor.textMuted.color)
                            .lineHeight(1.5, size: FontSize.sm)
                    }
                    searchField
                }

                if let last, !searching {
                    lastCard(last)
                }

                ForEach(groups, id: \.section) { g in
                    VStack(alignment: .leading, spacing: Space.s2) {
                        Text(g.section.rawValue.uppercased(with: Locale(identifier: "tr")))
                            .font(.ui(FontSize.xs, .bold))
                            .tracking(em: Tracking.label, size: FontSize.xs)
                            .foregroundStyle(ThemeColor.textSubtle.color)
                            .padding(.horizontal, 2)
                        VStack(spacing: 0) {
                            ForEach(Array(g.items.enumerated()), id: \.element.id) { i, l in
                                row(l, first: i == 0)
                            }
                        }
                        .background(ThemeColor.fill.color)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                        .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(ThemeColor.border.color, lineWidth: 1))
                    }
                }

                if groups.isEmpty {
                    Text(Lessons.emptyText(query))
                        .font(.ui(FontSize.md))
                        .foregroundStyle(ThemeColor.textMuted.color)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(Space.s6)
                }
            }
            .padding(.horizontal, Space.s4)
            .padding(.top, 32)
            .padding(.bottom, Space.s8)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(ThemeColor.bg.color)
        .onAppear {
            if !loaded {
                last = model.lastLesson
                loaded = true
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: Space.s2) {
            Icon(.search, size: 18).foregroundStyle(ThemeColor.textMuted.color)
            TextField("", text: $query, prompt: Text("Konu ara: legato, Fa anahtarı…").foregroundStyle(ThemeColor.textMuted.color))
                .font(.ui(FontSize.md))
                .foregroundStyle(ThemeColor.text.color)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .accessibilityLabel("Konu ara")
                .frame(maxHeight: .infinity)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Icon(.x, size: 16)
                        .foregroundStyle(ThemeColor.textMuted.color)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Aramayı temizle")
            }
        }
        .padding(.leading, Space.s3)
        .padding(.trailing, Space.s2)
        .frame(height: 46)
        .background(RoundedRectangle(cornerRadius: Radius.md).fill(ThemeColor.fill.color))
        .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(ThemeColor.border.color, lineWidth: 1))
    }

    private func lastCard(_ l: Lesson) -> some View {
        Button { model.openLesson(l.id) } label: {
            HStack(spacing: Space.s3) {
                Icon(l.icon, size: 20)
                    .foregroundStyle(l.color.color)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(l.color.opacity(0.16)))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text("KALDIĞIN YER")
                        .font(.ui(FontSize.xs, .bold))
                        .tracking(em: Tracking.label, size: FontSize.xs)
                        .foregroundStyle(ThemeColor.violetText.color)
                        .lineHeight(1.5, size: FontSize.xs)
                    Text(l.title).font(.ui(FontSize.md, .bold)).foregroundStyle(ThemeColor.text.color)
                        .lineHeight(1.5, size: FontSize.md)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("›").font(.ui(FontSize.xl)).foregroundStyle(ThemeColor.violetText.color).accessibilityHidden(true)
            }
            .padding(.vertical, Space.s3)
            .padding(.horizontal, Space.s4)
            .background(RoundedRectangle(cornerRadius: Radius.lg).fill(PaletteColor.violet500.opacity(0.12)))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(PaletteColor.violet500.opacity(0.3), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func row(_ l: Lesson, first: Bool) -> some View {
        Button { model.openLesson(l.id) } label: {
            HStack(spacing: Space.s3) {
                Icon(l.icon, size: 18)
                    .foregroundStyle(l.color.color)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: Radius.md).fill(l.color.opacity(0.14)))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(l.title).font(.ui(FontSize.md, .semibold)).foregroundStyle(ThemeColor.text.color)
                        .lineHeight(1.5, size: FontSize.md)
                    Text(l.sub).font(.ui(FontSize.sm)).foregroundStyle(ThemeColor.textMuted.color).lineLimit(1).truncationMode(.tail)
                        .lineHeight(1.5, size: FontSize.sm)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("›").font(.ui(FontSize.lg)).foregroundStyle(ThemeColor.textFaint.color).accessibilityHidden(true)
            }
            .padding(.vertical, Space.s3)
            .padding(.horizontal, Space.s4)
            .overlay(alignment: .top) { if !first { ThemeColor.border.color.frame(height: 1) } }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Tek bir ders: başlık, alt yazı ve dersin içeriği (web LessonScreen.tsx)
struct LessonScreen: View {
    let model: AppModel

    var body: some View {
        let lesson = Lessons.byId(model.lessonId)
        VStack(spacing: 0) {
            ScreenHeader(title: lesson?.title ?? "") { model.back() }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let lesson {
                        Text(lesson.sub)
                            .font(.ui(FontSize.sm))
                            .foregroundStyle(ThemeColor.textMuted.color)
                            .padding(.horizontal, 2)
                            .padding(.bottom, Space.s4)
                    }
                    if let lesson { LessonContent(lesson: lesson, chordLevel: model.settings.effectiveChordLevel) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Space.s4)
                .padding(.top, Space.s2)
                .padding(.bottom, Space.s8)
            }
            .scrollIndicators(.hidden)
        }
        .background(ThemeColor.bg.color)
    }
}

/// Dersin içeriği (web lessons.tsx `render`)
private struct LessonContent: View {
    let lesson: Lesson
    /// Majör/minör dersindeki formül listesi öğrencinin akor seviyesine göre uzar (web effectiveChordLevel)
    let chordLevel: Int

    var body: some View {
        switch lesson.id {
        case "rhythm-values": RhythmValuesLesson()
        case "rhythm-rests": RestsCard()
        case "rhythm-dotted": DottedCard()
        case "chords-build": ChordBuildLesson(level: chordLevel)
        case "chords-1": ChordCardsLesson(level: 1)
        case "chords-2": ChordCardsLesson(level: 2)
        case "chords-3": ChordCardsLesson(level: 3)
        case "chords-4": ChordCardsLesson(level: 4)
        default:
            if let g = Terms.groups.first(where: { "terms-\($0.group)" == lesson.id }) {
                TermsLesson(group: g)
            } else {
                Text("Bu ders native sürüme henüz taşınmadı.")
                    .font(.ui(FontSize.sm))
                    .foregroundStyle(ThemeColor.textSubtle.color)
            }
        }
    }
}
