// Öğren sekmesi (eski adı Çalışma, revize R13): konu arama, "Kaldığın yer" kartı ve konu başlıklarının listesi.
// Bir başlığa dokununca o ders kendi ekranında açılır (LessonScreen). Dersler lessons.tsx içinde tanımlı.
// Son açılan ders yalnızca bu cihazda hatırlanır (LAST_KEY); yedeklenen veriler arasında değil.
import { useState } from "react"
import Icon from "../../components/Icons"
import { alpha, colors, font, palette, radius, space } from "../../design/tokens"
import { LESSONS, type Lesson } from "./lessons"

const SECTIONS: Lesson["section"][] = ["Notalar", "Ritim", "Akorlar", "Terimler"]
const LAST_KEY = "solvato_last_lesson_v1"

const readLast = () => {
  try {
    const id = localStorage.getItem(LAST_KEY)
    return LESSONS.find((l) => l.id === id) ?? null
  } catch {
    return null
  }
}

// Türkçe büyük/küçük harf ve aksan farkı aramayı bozmasın: "fa anahtari" → "Fa anahtarı"
const norm = (s: string) => s.toLocaleLowerCase("tr").normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/ı/g, "i")

const sectionLabel = {
  fontSize: font.size.xs,
  fontWeight: font.weight.bold,
  color: colors.textSubtle,
  letterSpacing: font.tracking.label,
  textTransform: "uppercase",
  margin: `0 2px ${space[2]}px`,
} as const

function LessonRow({ l, first, onOpen }: { l: Lesson; first: boolean; onOpen: (id: string) => void }) {
  return (
    <button
      onClick={() => onOpen(l.id)}
      style={{
        display: "flex",
        alignItems: "center",
        gap: space[3],
        width: "100%",
        textAlign: "left",
        padding: `${space[3]}px ${space[4]}px`,
        background: "none",
        border: "none",
        borderTop: first ? "none" : `1px solid ${colors.border}`,
        cursor: "pointer",
        fontFamily: font.family.ui,
      }}
    >
      <span
        aria-hidden="true"
        style={{
          width: 36,
          height: 36,
          borderRadius: radius.md,
          flexShrink: 0,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: alpha(l.color, 0.14),
          color: l.color,
        }}
      >
        <Icon name={l.icon} size={18} />
      </span>
      <span style={{ flex: 1, minWidth: 0 }}>
        <span
          style={{ display: "block", fontSize: font.size.md, fontWeight: font.weight.semibold, color: colors.text }}
        >
          {l.title}
        </span>
        <span
          style={{
            display: "block",
            fontSize: font.size.sm,
            color: colors.textMuted,
            whiteSpace: "nowrap",
            overflow: "hidden",
            textOverflow: "ellipsis",
          }}
        >
          {l.sub}
        </span>
      </span>
      <span aria-hidden="true" style={{ color: colors.textFaint, fontSize: font.size.lg }}>
        ›
      </span>
    </button>
  )
}

export default function StudyScreen({ onOpen }: { onOpen: (id: string) => void }) {
  const [query, setQuery] = useState("")
  const [last] = useState(readLast)
  const open = (id: string) => {
    try {
      localStorage.setItem(LAST_KEY, id)
    } catch {
      /* hatırlanmazsa sorun değil */
    }
    onOpen(id)
  }
  const q = norm(query.trim())
  const match = (l: Lesson) => !q || norm(`${l.title} ${l.sub} ${l.section}`).includes(q)
  const groups = SECTIONS.map((sec) => ({ sec, items: LESSONS.filter((l) => l.section === sec && match(l)) })).filter(
    (g) => g.items.length > 0,
  )

  return (
    <div
      style={{
        height: "100%",
        overflowY: "auto",
        background: colors.bg,
        fontFamily: font.family.ui,
        scrollbarWidth: "none",
      }}
    >
      <div
        style={{
          padding: `max(32px, calc(env(safe-area-inset-top, 0px) + 12px)) ${space[4]}px ${space[8]}px`,
          display: "flex",
          flexDirection: "column",
          gap: space[5],
        }}
      >
        <div style={{ display: "flex", flexDirection: "column", gap: space[3] }}>
          <div>
            <h1
              style={{
                fontSize: font.size.xl,
                fontWeight: font.weight.heavy,
                color: colors.text,
                letterSpacing: font.tracking.tight,
              }}
            >
              Öğren
            </h1>
            <p style={{ fontSize: font.size.sm, color: colors.textMuted, marginTop: 2 }}>
              Bir konu seç; notaları, ritmi ve akorları adım adım öğren.
            </p>
          </div>

          {/* Konu arama: başlıkta ve alt yazıda arar (ör. "legato" → Artikülasyon) */}
          <label
            className="search-field"
            style={{
              display: "flex",
              alignItems: "center",
              gap: space[2],
              height: 46,
              padding: `0 ${space[2]}px 0 ${space[3]}px`,
              borderRadius: radius.md,
              background: colors.fill,
              border: `1px solid ${colors.border}`,
              color: colors.textMuted,
            }}
          >
            <Icon name="search" size={18} />
            <input
              id="study-search"
              type="text"
              inputMode="search"
              enterKeyHint="search"
              autoComplete="off"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Konu ara: legato, Fa anahtarı…"
              aria-label="Konu ara"
              style={{
                flex: 1,
                minWidth: 0,
                height: "100%",
                background: "none",
                border: "none",
                outline: "none",
                color: colors.text,
                fontSize: font.size.md,
                fontFamily: font.family.ui,
              }}
            />
            {query && (
              <button
                onClick={() => setQuery("")}
                aria-label="Aramayı temizle"
                style={{
                  width: 36,
                  height: 36,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  background: "none",
                  border: "none",
                  color: colors.textMuted,
                  cursor: "pointer",
                }}
              >
                <Icon name="x" size={16} />
              </button>
            )}
          </label>
        </div>

        {/* Kaldığın yer: son açılan ders (arama yokken) */}
        {last && !q && (
          <button
            onClick={() => open(last.id)}
            style={{
              display: "flex",
              alignItems: "center",
              gap: space[3],
              width: "100%",
              textAlign: "left",
              padding: `${space[3]}px ${space[4]}px`,
              borderRadius: radius.lg,
              background: alpha(palette.violet500, 0.12),
              border: `1px solid ${alpha(palette.violet500, 0.3)}`,
              cursor: "pointer",
              fontFamily: font.family.ui,
            }}
          >
            <span
              aria-hidden="true"
              style={{
                width: 40,
                height: 40,
                borderRadius: radius.md,
                flexShrink: 0,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                background: alpha(last.color, 0.16),
                color: last.color,
              }}
            >
              <Icon name={last.icon} size={20} />
            </span>
            <span style={{ flex: 1, minWidth: 0 }}>
              <span
                style={{
                  display: "block",
                  fontSize: font.size.xs,
                  fontWeight: font.weight.bold,
                  color: colors.violetText,
                  letterSpacing: font.tracking.label,
                  textTransform: "uppercase",
                }}
              >
                Kaldığın yer
              </span>
              <span
                style={{ display: "block", fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.text }}
              >
                {last.title}
              </span>
            </span>
            <span aria-hidden="true" style={{ color: colors.violetText, fontSize: font.size.xl }}>
              ›
            </span>
          </button>
        )}

        {groups.map(({ sec, items }) => (
          <section key={sec}>
            <p style={sectionLabel}>{sec}</p>
            <div
              style={{
                borderRadius: radius.lg,
                background: colors.fill,
                border: `1px solid ${colors.border}`,
                overflow: "hidden",
              }}
            >
              {items.map((l, i) => (
                <LessonRow key={l.id} l={l} first={i === 0} onOpen={open} />
              ))}
            </div>
          </section>
        ))}

        {groups.length === 0 && (
          <p style={{ fontSize: font.size.md, color: colors.textMuted, textAlign: "center", padding: space[6] }}>
            “{query.trim()}” için konu bulunamadı. Başka bir kelime dene.
          </p>
        )}
      </div>
    </div>
  )
}
