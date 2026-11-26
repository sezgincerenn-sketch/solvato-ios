// Ayarlar (revize R36, docs/ozellikler/ayarlar.md, Taslak 1): dört kart — Çalışma, Sorular, Ses ve bildirim, Diğer;
// satırda o anki değer, dokununca alttan seçim penceresi. Çalışılacak notalar ayrı ekran (NotesSettings). En altta
// İlerlemeyi sıfırla ve sürüm. Öğretmen kodu Profil'de.
import NotesPicker, { notesSummary } from "../components/NotesPicker"
import { ScreenHeader } from "../ui"
import { useState } from "react"
import { updateSettings, useSettings } from "../utils/settings"
import { enableReminder, disableReminder } from "../utils/reminder"

import { alpha, colors, font, palette, radius } from "../design/tokens"
export type ThemeMode = "system" | "dark" | "light"

type Opt<T> = { value: T; label: string; sub?: string }

const GOALS: Opt<number>[] = [
  { value: 10, label: "10 soru", sub: "rahat tempo" },
  { value: 20, label: "20 soru", sub: "düzenli çalışma" },
  { value: 30, label: "30 soru", sub: "hızlı ilerleme" },
  { value: 50, label: "50 soru", sub: "yoğun tempo" },
]
const LEVELS: Opt<1 | 2 | 3>[] = [
  { value: 1, label: "Başlangıç" },
  { value: 2, label: "Orta" },
  { value: 3, label: "İleri" },
]
const CLEFS: Opt<"treble" | "bass" | "both">[] = [
  { value: "treble", label: "Sol" },
  { value: "bass", label: "Fa" },
  { value: "both", label: "İkisi de" },
]
const INPUTS: Opt<"piano" | "choice">[] = [
  { value: "piano", label: "Klavye" },
  { value: "choice", label: "Şıklar" },
]
const THEMES: Opt<ThemeMode>[] = [
  { value: "system", label: "Sistem" },
  { value: "dark", label: "Koyu" },
  { value: "light", label: "Açık" },
]
const ALL_NOTES = ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"]

/** Mor, büyük harfli grup adı ve altında kart */
function Group({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section style={{ marginTop: 20 }}>
      <p
        style={{
          fontSize: font.size.xs,
          fontWeight: font.weight.bold,
          letterSpacing: "0.08em",
          textTransform: "uppercase",
          color: colors.violetText,
          margin: "0 4px 6px",
        }}
      >
        {title}
      </p>
      <div
        style={{
          background: colors.fill,
          border: `1px solid ${colors.border}`,
          borderRadius: radius.lg,
          overflow: "hidden",
        }}
      >
        {children}
      </div>
    </section>
  )
}

const rowBase: React.CSSProperties = {
  display: "flex",
  alignItems: "center",
  gap: 10,
  width: "100%",
  minHeight: 50,
  boxSizing: "border-box",
  padding: "12px 14px",
  background: "none",
  border: "none",
  textAlign: "left",
  fontFamily: font.family.ui,
  color: colors.text,
}
const divider: React.CSSProperties = { borderTop: `1px solid ${colors.border}` }

function RowTitle({ title, sub }: { title: string; sub?: string }) {
  return (
    <span style={{ flex: 1, minWidth: 0 }}>
      <span style={{ display: "block", fontSize: font.size.md, fontWeight: font.weight.semibold, color: colors.text }}>
        {title}
      </span>
      {sub && (
        <span
          style={{ display: "block", fontSize: font.size.sm, color: colors.textMuted, marginTop: 2, lineHeight: 1.4 }}
        >
          {sub}
        </span>
      )}
    </span>
  )
}

function Chevron() {
  return (
    <span aria-hidden="true" style={{ color: colors.textSubtle, fontSize: font.size.lg }}>
      ›
    </span>
  )
}

/** Değer gösteren satır: dokununca seçim penceresi ya da başka ekran */
function ValueRow({
  title,
  sub,
  value,
  first,
  onClick,
}: {
  title: string
  sub?: string
  value?: string
  first?: boolean
  onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      aria-label={value ? `${title}, ${value}` : title}
      style={{ ...rowBase, ...(first ? {} : divider), cursor: "pointer" }}
    >
      <RowTitle title={title} sub={sub} />
      {value && (
        <span
          style={{
            color: colors.textMuted,
            fontSize: font.size.md,
            whiteSpace: "nowrap",
            overflow: "hidden",
            textOverflow: "ellipsis",
            maxWidth: "45%",
            fontVariantNumeric: "tabular-nums",
          }}
        >
          {value}
        </span>
      )}
      <Chevron />
    </button>
  )
}

/** Açma/kapama anahtarlı satır */
function ToggleRow({
  title,
  on,
  first,
  onToggle,
}: {
  title: string
  on: boolean
  first?: boolean
  onToggle: () => void
}) {
  return (
    <div style={{ ...rowBase, ...(first ? {} : divider), padding: "9px 14px" }}>
      <RowTitle title={title} />
      <button
        role="switch"
        aria-checked={on}
        aria-label={title}
        onClick={onToggle}
        style={{
          width: 52,
          height: 32,
          borderRadius: radius.pill,
          background: on ? palette.violet600 : colors.fillStronger,
          border: "none",
          position: "relative",
          flexShrink: 0,
          transition: "background 0.18s",
          cursor: "pointer",
        }}
      >
        <span
          style={{
            position: "absolute",
            top: 3,
            left: on ? 23 : 3,
            width: 26,
            height: 26,
            borderRadius: "50%",
            background: palette.white,
            transition: "left 0.18s",
          }}
        />
      </button>
    </div>
  )
}

/** Hatırlatma saati: sağda "19:00 ›"; dokununca telefonun saat çarkı (input type=time, görünmez) */
function TimeRow({
  hour,
  minute,
  onChange,
}: {
  hour: number
  minute: number
  onChange: (h: number, m: number) => void
}) {
  const p = (n: number) => String(n).padStart(2, "0")
  const value = `${p(hour)}:${p(minute)}`
  return (
    <label style={{ ...rowBase, ...divider, position: "relative", cursor: "pointer" }}>
      <RowTitle title="Hatırlatma saati" />
      <span style={{ color: colors.textMuted, fontSize: font.size.md, fontVariantNumeric: "tabular-nums" }}>
        {value}
      </span>
      <Chevron />
      <input
        type="time"
        aria-label={`Hatırlatma saati, ${value}`}
        value={value}
        onChange={(e) => {
          const [h, m] = e.target.value.split(":").map(Number)
          if (Number.isFinite(h) && Number.isFinite(m)) onChange(h, m)
        }}
        style={{ position: "absolute", inset: 0, opacity: 0, width: "100%", height: "100%", cursor: "pointer" }}
      />
    </label>
  )
}

/** Alttan açılan seçim penceresi: başlık ve seçenek kartları; seçili olan mor çerçeveli ve ✓'li */
function ChoiceSheet<T>({
  title,
  options,
  value,
  onPick,
  onClose,
}: {
  title: string
  options: Opt<T>[]
  value: T
  onPick: (v: T) => void
  onClose: () => void
}) {
  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={title}
      onClick={onClose}
      style={{
        position: "absolute",
        inset: 0,
        zIndex: 80,
        background: colors.scrim,
        display: "flex",
        flexDirection: "column",
        justifyContent: "flex-end",
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: colors.bg,
          borderRadius: `${radius.lg}px ${radius.lg}px 0 0`,
          padding: "10px 16px 24px",
          display: "flex",
          flexDirection: "column",
          gap: 8,
          maxWidth: 560,
          width: "100%",
          margin: "0 auto",
          boxSizing: "border-box",
        }}
      >
        <span
          aria-hidden="true"
          style={{
            width: 36,
            height: 5,
            borderRadius: 3,
            background: colors.fillStronger,
            alignSelf: "center",
            marginBottom: 6,
          }}
        />
        <p style={{ fontSize: font.size.lg, fontWeight: font.weight.bold, color: colors.text, marginBottom: 4 }}>
          {title}
        </p>
        {options.map((o) => {
          const on = o.value === value
          return (
            <button
              key={String(o.value)}
              aria-pressed={on}
              onClick={() => onPick(o.value)}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 10,
                padding: "12px 14px",
                borderRadius: radius.md,
                background: colors.fill,
                border: on ? `2px solid ${palette.violet600}` : `1px solid ${colors.border}`,
                fontFamily: font.family.ui,
                cursor: "pointer",
                textAlign: "left",
              }}
            >
              <span style={{ fontSize: font.size.md, fontWeight: font.weight.semibold, color: colors.text }}>
                {o.label}
              </span>
              {o.sub && <span style={{ fontSize: font.size.sm, color: colors.textMuted }}>{o.sub}</span>}
              <span style={{ flex: 1 }} />
              {on && <span style={{ color: colors.violetText, fontWeight: font.weight.heavy }}>✓</span>}
            </button>
          )
        })}
      </div>
    </div>
  )
}

type Sheet = "goal" | "level" | "clef" | "input" | "theme" | null

export default function SettingsScreen({
  themeMode,
  onThemeMode,
  onBack,
  onReset,
  onShowTutorial,
  onOpenPrivacy,
  onOpenLicenses,
  onOpenNotes,
}: {
  themeMode: ThemeMode
  onThemeMode: (m: ThemeMode) => void
  onBack: () => void
  onReset: () => void
  onShowTutorial: () => void
  onOpenPrivacy: () => void
  onOpenLicenses: () => void
  onOpenNotes: () => void
}) {
  const s = useSettings()
  const [reminderMsg, setReminderMsg] = useState("")
  const [confirmReset, setConfirmReset] = useState(false)
  const [sheet, setSheet] = useState<Sheet>(null)

  async function toggleReminder() {
    if (s.reminder) {
      await disableReminder()
      updateSettings({ reminder: false })
      setReminderMsg("")
      return
    }
    const ok = await enableReminder(s.reminderHour, s.reminderMinute)
    if (ok) {
      updateSettings({ reminder: true })
      setReminderMsg("")
    } else {
      setReminderMsg("Bildirim izni verilmedi. iPhone Ayarlar → Solvato → Bildirimler bölümünden açabilirsin.")
    }
  }

  async function changeTime(h: number, m: number) {
    updateSettings({ reminderHour: h, reminderMinute: m })
    if (s.reminder) await enableReminder(h, m)
  }

  const label = <T,>(opts: Opt<T>[], v: T) => opts.find((o) => o.value === v)?.label ?? ""
  const levelSub =
    s.level < 3
      ? `Sonraki seviyeye: ${s.levelProgress.n}/50 soru${s.levelProgress.n > 0 ? ` · %${Math.round((s.levelProgress.c / s.levelProgress.n) * 100)} doğru` : ""}`
      : "Tüm sorular açık."
  const notesValue =
    s.notes.length >= ALL_NOTES.length ? "Hepsi" : ALL_NOTES.filter((n) => s.notes.includes(n)).join(" ")

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
      <ScreenHeader title="Ayarlar" onBack={onBack} />

      <div style={{ padding: "0 20px 32px" }}>
        <Group title="Çalışma">
          <ValueRow first title="Günlük hedef" value={label(GOALS, s.dailyGoal)} onClick={() => setSheet("goal")} />
          <ValueRow title="Seviye" sub={levelSub} value={label(LEVELS, s.level)} onClick={() => setSheet("level")} />
          <ValueRow title="Anahtar" value={label(CLEFS, s.clef)} onClick={() => setSheet("clef")} />
          <ValueRow title="Çalışılacak notalar" value={notesValue} onClick={onOpenNotes} />
        </Group>

        <Group title="Sorular">
          <ValueRow first title="Cevap yöntemi" value={label(INPUTS, s.inputMode)} onClick={() => setSheet("input")} />
          <ToggleRow
            title="Tuş isimlerini göster"
            on={s.keyLabels}
            onToggle={() => updateSettings({ keyLabels: !s.keyLabels })}
          />
          <ToggleRow title="Zaman yarışı" on={s.timer} onToggle={() => updateSettings({ timer: !s.timer })} />
        </Group>

        <Group title="Ses ve bildirim">
          <ToggleRow first title="Ses" on={s.soundKeys} onToggle={() => updateSettings({ soundKeys: !s.soundKeys })} />
          <ToggleRow title="Titreşim" on={s.haptics} onToggle={() => updateSettings({ haptics: !s.haptics })} />
          <ToggleRow title="Günlük hatırlatma" on={s.reminder} onToggle={toggleReminder} />
          {s.reminder && <TimeRow hour={s.reminderHour} minute={s.reminderMinute} onChange={changeTime} />}
        </Group>
        {reminderMsg && (
          <p style={{ fontSize: font.size.sm, color: colors.redText, padding: "8px 4px 0", lineHeight: 1.4 }}>
            {reminderMsg}
          </p>
        )}

        <Group title="Diğer">
          <ValueRow first title="Tema" value={label(THEMES, themeMode)} onClick={() => setSheet("theme")} />
          <ValueRow title="Tanıtımı tekrar göster" onClick={onShowTutorial} />
          <ValueRow title="Gizlilik" onClick={onOpenPrivacy} />
          <ValueRow title="Lisanslar" onClick={onOpenLicenses} />
        </Group>

        <div style={{ marginTop: 18 }}>
          {!confirmReset ? (
            <button
              onClick={() => setConfirmReset(true)}
              style={{
                width: "100%",
                padding: 14,
                fontSize: font.size.md,
                fontWeight: font.weight.semibold,
                cursor: "pointer",
                background: "none",
                color: colors.redText,
                border: "none",
                fontFamily: font.family.ui,
              }}
            >
              İlerlemeyi sıfırla
            </button>
          ) : (
            <div
              style={{
                padding: 14,
                borderRadius: radius.md,
                background: alpha(palette.red500, 0.08),
                border: "1px solid rgba(239,68,68,0.25)",
              }}
            >
              <p style={{ fontSize: font.size.md, color: colors.redText, marginBottom: 12, lineHeight: 1.4 }}>
                XP, seri ve tüm istatistiklerin silinecek. Bu geri alınamaz.
              </p>
              <div style={{ display: "flex", gap: 10 }}>
                <button
                  onClick={() => setConfirmReset(false)}
                  style={{
                    flex: 1,
                    padding: 12,
                    borderRadius: radius.md,
                    fontSize: font.size.sm,
                    fontWeight: font.weight.bold,
                    background: colors.fillStrong,
                    color: colors.textSecondary,
                    border: `1px solid ${colors.border}`,
                    cursor: "pointer",
                  }}
                >
                  Vazgeç
                </button>
                <button
                  onClick={() => {
                    setConfirmReset(false)
                    onReset()
                  }}
                  style={{
                    flex: 1,
                    padding: 12,
                    borderRadius: radius.md,
                    fontSize: font.size.sm,
                    fontWeight: font.weight.bold,
                    background: palette.red600,
                    color: palette.white,
                    border: "none",
                    cursor: "pointer",
                  }}
                >
                  Sıfırla
                </button>
              </div>
            </div>
          )}
        </div>

        <p style={{ fontSize: font.size.sm, color: colors.textSubtle, textAlign: "center", marginTop: 10 }}>
          Sürüm 1.0
        </p>
      </div>

      {sheet === "goal" && (
        <ChoiceSheet
          title="Günlük hedef"
          options={GOALS}
          value={s.dailyGoal}
          onClose={() => setSheet(null)}
          onPick={(g) => {
            updateSettings({ dailyGoal: g })
            setSheet(null)
          }}
        />
      )}
      {sheet === "level" && (
        <ChoiceSheet
          title="Seviye"
          options={LEVELS}
          value={s.level as 1 | 2 | 3}
          onClose={() => setSheet(null)}
          onPick={(v) => {
            // Aynı seviye seçilirse sayaç sıfırlanmaz
            if (v !== s.level) updateSettings({ level: v, levelProgress: { n: 0, c: 0 } })
            setSheet(null)
          }}
        />
      )}
      {sheet === "clef" && (
        <ChoiceSheet
          title="Anahtar"
          options={CLEFS}
          value={s.clef}
          onClose={() => setSheet(null)}
          onPick={(v) => {
            updateSettings({ clef: v })
            setSheet(null)
          }}
        />
      )}
      {sheet === "input" && (
        <ChoiceSheet
          title="Cevap yöntemi"
          options={INPUTS}
          value={s.inputMode}
          onClose={() => setSheet(null)}
          onPick={(v) => {
            updateSettings({ inputMode: v })
            setSheet(null)
          }}
        />
      )}
      {sheet === "theme" && (
        <ChoiceSheet
          title="Tema"
          options={THEMES}
          value={themeMode}
          onClose={() => setSheet(null)}
          onPick={(v) => {
            onThemeMode(v)
            setSheet(null)
          }}
        />
      )}
    </div>
  )
}

/** Ayarlar › Çalışılacak notalar (revize R36): nota seçici, hazır seçimler ve açıklama; ayrı ekran */
export function NotesSettings({ onBack }: { onBack: () => void }) {
  const s = useSettings()
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
      <ScreenHeader title="Çalışılacak notalar" onBack={onBack} />
      <div style={{ padding: "8px 20px 32px", display: "flex", flexDirection: "column", gap: 16 }}>
        <NotesPicker value={s.notes} onChange={(notes) => updateSettings({ notes })} />
        <p style={{ fontSize: font.size.sm, color: colors.textMuted, lineHeight: 1.5 }}>{notesSummary(s.notes)}</p>
      </div>
    </div>
  )
}
