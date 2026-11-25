// Öğretmen kodu ekranı (Ayarlar › Öğretmen kodu)
//   1) Öğrenci: öğretmeninin gönderdiği kodu girer, çalışma ayarları kurulur
//   2) Öğretmen: öğrencisi için ayarları seçer, kodu WhatsApp vb. ile gönderir
// Kodun biçimi: utils/teacherCode.ts
import { formatCode, readClipboard } from "../utils/codeFormat"
import { useMemo, useState } from "react"
import NotesPicker from "../components/NotesPicker"
import { LEVEL_LABELS } from "../data/questions"
import { colors, font, palette, radius, space } from "../design/tokens"
import { Button, Card, Chip, ScreenHeader, Segmented, useToast } from "../ui"
import { getSettings, updateSettings } from "../utils/settings"
import {
  GOALS,
  TOPICS,
  allTopics,
  decodeTeacher,
  describeTeacher,
  encodeTeacher,
  teacherShareText,
  type TeacherSetup,
} from "../utils/teacherCode"
import { shareWithToast } from "./gameShared"

const stack = { display: "flex", flexDirection: "column", gap: space[3] } as const
const muted = { fontSize: font.size.sm, color: colors.textMuted, lineHeight: 1.5 } as const
const title = { fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.text } as const
const label = { fontSize: font.size.sm, fontWeight: font.weight.semibold, color: colors.textSecondary } as const

function SetupList({ setup }: { setup: TeacherSetup }) {
  return (
    <ul style={{ margin: 0, paddingLeft: 18, ...muted }}>
      {describeTeacher(setup).map((l) => (
        <li key={l}>{l}</li>
      ))}
    </ul>
  )
}

export default function TeacherScreen({ onBack }: { onBack: () => void }) {
  const toast = useToast()
  const s = getSettings()

  // ── Öğrenci: kodu gir
  const [code, setCode] = useState("")
  const [err, setErr] = useState("")
  const [applied, setApplied] = useState<{ code: string; setup: TeacherSetup } | null>(null)
  const apply = () => {
    const setup = decodeTeacher(code)
    if (!setup) return setErr("Kod geçersiz. 6 karakteri kontrol et.")
    const levelChanged = setup.level !== getSettings().level
    const clean = encodeTeacher(setup)
    updateSettings({ ...setup, teacherCode: clean, ...(levelChanged ? { levelProgress: { n: 0, c: 0 } } : {}) })
    setApplied({ code: clean, setup })
    setCode("")
  }

  // ── Öğretmen: kod hazırla (başlangıçta kendi ayarlarıyla dolu)
  const [setup, setSetup] = useState<TeacherSetup>({
    notes: s.notes,
    clef: s.clef,
    level: s.level,
    dailyGoal: (GOALS as readonly number[]).includes(s.dailyGoal) ? s.dailyGoal : 10,
    keyLabels: s.keyLabels,
    topics: s.topics,
  })
  const set = (patch: Partial<TeacherSetup>) => setSetup((p) => ({ ...p, ...patch }))
  const teacherCode = useMemo(() => encodeTeacher(setup), [setup])

  return (
    <div style={{ height: "100%", display: "flex", flexDirection: "column", fontFamily: font.family.ui }}>
      <ScreenHeader title="Öğretmen kodu" onBack={onBack} />
      <div
        style={{
          flex: 1,
          minHeight: 0,
          overflowY: "auto",
          padding: `${space[2]}px ${space[4]}px ${space[6]}px`,
          ...stack,
        }}
      >
        <p style={muted}>
          Öğretmenin hangi notaları ve hangi seviyede çalışacağını bir kodla gönderir. Kodu girince uygulaman o
          ayarlarla kurulur.
        </p>

        {/* 1) Öğrenci */}
        <Card as="section" style={stack}>
          <p style={title}>Öğretmeninden kod mu geldi?</p>
          {applied ? (
            <>
              <p style={{ ...muted, color: colors.greenText, fontWeight: font.weight.semibold }}>
                Ayarların güncellendi ({applied.code})
              </p>
              <SetupList setup={applied.setup} />
              <p style={muted}>İstediğin zaman Ayarlar'dan değiştirebilirsin.</p>
            </>
          ) : (
            <>
              <div style={{ display: "flex", gap: space[2] }}>
                <input
                  value={code}
                  onChange={(e) => {
                    setCode(formatCode(e.target.value, 3, 6))
                    setErr("")
                  }}
                  onKeyDown={(e) => e.key === "Enter" && apply()}
                  placeholder="ABC-DEF"
                  aria-label="Öğretmen kodu"
                  autoCapitalize="characters"
                  autoCorrect="off"
                  spellCheck={false}
                  style={{
                    flex: 1,
                    minWidth: 0,
                    minHeight: 44,
                    padding: `${space[3]}px 14px`,
                    borderRadius: radius.md,
                    fontSize: font.size.md,
                    fontFamily: font.family.mono,
                    letterSpacing: 2,
                    color: colors.text,
                    background: colors.fillStrong,
                    border: `1.5px solid ${err ? palette.red500 : colors.borderStrong}`,
                    outline: "none",
                  }}
                />
                <Button variant="secondary" onClick={apply} disabled={!code.trim()}>
                  Uygula
                </Button>
              </div>
              <button
                type="button"
                onClick={async () => {
                  const t = await readClipboard()
                  if (t) {
                    setCode(formatCode(t, 3, 6))
                    setErr("")
                  } else setErr("Pano okunamadı; koda uzun basıp Yapıştır de.")
                }}
                style={{
                  alignSelf: "flex-start",
                  padding: "6px 0",
                  background: "none",
                  border: "none",
                  color: colors.violetText,
                  fontSize: font.size.sm,
                  fontWeight: font.weight.semibold,
                  fontFamily: font.family.ui,
                  cursor: "pointer",
                }}
              >
                Panodan yapıştır
              </button>
              {err && <p style={{ fontSize: font.size.sm, color: colors.redText }}>{err}</p>}
              {s.teacherCode && <p style={{ ...muted, fontSize: font.size.xs }}>Son uygulanan kod: {s.teacherCode}</p>}
            </>
          )}
        </Card>

        {/* 2) Öğretmen */}
        <Card as="section" style={stack}>
          <p style={title}>Öğretmensen: öğrencine kod hazırla</p>
          <p style={muted}>
            Seçimlerini yap, kodu öğrencine gönder. Her öğrenciye ya da her döneme ayrı kod verebilirsin.
          </p>

          <p style={label}>Konular</p>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
            <Chip selected={allTopics(setup.topics)} onClick={() => set({ topics: [] })}>
              Hepsi
            </Chip>
            {TOPICS.map((x) => {
              const on = !allTopics(setup.topics) && setup.topics.includes(x.key)
              return (
                <Chip
                  key={x.key}
                  selected={on}
                  onClick={() => {
                    const cur = allTopics(setup.topics) ? [] : setup.topics
                    const next = on ? cur.filter((k) => k !== x.key) : [...cur, x.key]
                    // Hiç konu kalmazsa "Hepsi"ne döner
                    set({ topics: TOPICS.map((t) => t.key as string).filter((k) => next.includes(k)) })
                  }}
                >
                  {x.label}
                </Chip>
              )
            })}
          </div>
          <p style={{ ...muted, fontSize: font.size.xs, marginTop: -4 }}>
            Seçilen konular öğrencinin ana sayfasında en üstte çıkar, günlük karışık tur da bunlardan gelir.
          </p>
          <p style={label}>Anahtar</p>
          <Segmented
            size="sm"
            value={setup.clef}
            options={[
              ["treble", "Sol"],
              ["bass", "Fa"],
              ["both", "İkisi de"],
            ]}
            onChange={(clef) => set({ clef })}
          />
          <p style={label}>Seviye</p>
          <Segmented
            size="sm"
            value={setup.level}
            options={([1, 2, 3] as const).map((l) => [l, LEVEL_LABELS[l]] as const)}
            onChange={(level) => set({ level })}
          />
          <p style={label}>Çalışılacak notalar</p>
          <NotesPicker value={setup.notes} onChange={(notes) => set({ notes })} />
          <p style={label}>Günlük hedef</p>
          <Segmented
            size="sm"
            value={setup.dailyGoal}
            options={GOALS.map((g) => [g, `${g} soru`] as const)}
            onChange={(dailyGoal) => set({ dailyGoal })}
          />
          <p style={label}>Tuşlarda nota adları</p>
          <Segmented
            size="sm"
            value={setup.keyLabels ? 1 : 0}
            options={[
              [0, "Gizli"],
              [1, "Görünür"],
            ]}
            onChange={(v) => set({ keyLabels: v === 1 })}
          />

          <div
            style={{
              marginTop: space[2],
              padding: space[4],
              borderRadius: radius.lg,
              background: colors.fillStrong,
              border: `1px dashed ${colors.borderStrong}`,
              textAlign: "center",
            }}
          >
            <p style={{ ...muted, fontSize: font.size.xs }}>Öğrencinin gireceği kod</p>
            <p
              aria-live="polite"
              style={{
                fontSize: font.size.xxl,
                fontWeight: font.weight.heavy,
                fontFamily: font.family.mono,
                letterSpacing: 4,
                color: colors.text,
                marginTop: 4,
              }}
            >
              {teacherCode}
            </p>
          </div>
          <Button onClick={() => shareWithToast(teacherShareText(teacherCode, setup), toast.show)}>Kodu gönder</Button>
        </Card>
      </div>
      {toast.el}
    </div>
  )
}
