// İlk açılış tanıtımı: uygulamanın ne olduğu, örnek soru, öğretmen sorusu, anahtar ve seviye, hatırlatma.
// Revize önizlemesi: R27 ilk ekran, R28 geri oku, R5 öğretmen sorusu (kod istenmez), R9 saat seçici.
import { useState } from "react"
import MusicalStaff from "../components/MusicalStaff"
import { QuizPiano } from "../components/piano/QuizPiano"
import { hapticSuccess, hapticError } from "../utils/haptics"
import { playCorrectChime, playWrongBuzz } from "../utils/audio"
import { getSettings, updateSettings } from "../utils/settings"
import { SolfieSays } from "../components/Solfie"
import { ClefIcon } from "../components/Glyph"
import { ChoiceCard, Segmented, TimeField } from "../ui"
import Logo from "../components/Logo"
import { enableReminder } from "../utils/reminder"

import { colors, font, gradient, palette, radius } from "../design/tokens"
type Step = "intro" | "hello" | "try1" | "try2" | "teacher" | "clef" | "level" | "reminder" | "done"

const CARD: React.CSSProperties = {
  background: colors.fill,
  border: `1px solid ${colors.border}`,
  borderRadius: radius.lg,
  overflow: "hidden",
}

const PRIMARY: React.CSSProperties = {
  width: "100%",
  padding: 16,
  borderRadius: radius.lg,
  fontSize: font.size.md,
  fontWeight: font.weight.bold,
  cursor: "pointer",
  background: gradient.primaryFlat,
  color: palette.violet100,
  border: "none",
  boxShadow: "0 4px 20px rgba(124,58,237,0.45)",
}

// Canlı deneme: gerçek porte ve gerçek klavye. Kullanıcı notayı bulur.
function TryStep({
  note,
  noteY,
  ledger,
  title,
  helpWrong,
  onPass,
}: {
  note: string
  noteY: number
  ledger: number[]
  title: string
  helpWrong: string
  onPass: () => void
}) {
  const [state, setState] = useState<"pending" | "correct" | "wrong">("pending")
  const [picked, setPicked] = useState<string | undefined>()

  function answer(n: string) {
    if (state === "correct") return
    setPicked(n)
    if (n === note) {
      setState("correct")
      playCorrectChime()
      hapticSuccess()
    } else {
      setState("wrong")
      playWrongBuzz()
      hapticError()
      // Yanlışta kısa süre sonra tekrar denenebilsin
      setTimeout(() => {
        setState("pending")
        setPicked(undefined)
      }, 900)
    }
  }

  return (
    <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 14 }}>
      <h1
        style={{ fontSize: font.size.xl, fontWeight: font.weight.heavy, color: colors.text, letterSpacing: "-0.03em" }}
      >
        {title}
      </h1>
      <div style={{ ...CARD, minHeight: 170, display: "flex", alignItems: "center" }}>
        <MusicalStaff clef="treble" noteY={noteY} ledgerLines={ledger} showLabel={false} />
      </div>
      <div style={{ minHeight: 48 }}>
        {state === "correct" ? (
          <p style={{ fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.greenText }}>
            Doğru! Bu nota {note}.
          </p>
        ) : state === "wrong" ? (
          <p style={{ fontSize: font.size.md, color: colors.redText, lineHeight: 1.45 }}>{helpWrong}</p>
        ) : (
          <p style={{ fontSize: font.size.md, color: colors.textMuted, lineHeight: 1.45 }}>
            Piyano tuşlarından birine dokun.
          </p>
        )}
      </div>
      <div style={{ marginTop: "auto" }}>
        <QuizPiano
          onAnswer={answer}
          correctAnswer={undefined}
          answerState={state}
          selectedNote={picked}
          showLabels
          hintNote={undefined}
        />
        <button
          onClick={onPass}
          disabled={state !== "correct"}
          style={{
            ...PRIMARY,
            marginTop: 14,
            opacity: state === "correct" ? 1 : 0.35,
            cursor: state === "correct" ? "pointer" : "default",
          }}
        >
          Devam
        </button>
      </div>
    </div>
  )
}

const LEVELS: { label: string; sub: string; level: 1 | 2 | 3 }[] = [
  {
    label: "Yeni başladım",
    sub: "Temel notalar, ritim ve işaretler",
    level: 1,
  },
  { label: "Bir süredir çalıyorum", sub: "Tüm notalar, diyez/bemol, ek çizgiler", level: 2 },
  { label: "Uzun süredir çalıyorum", sub: "Tüm sorular, ileri ritim ve terimler", level: 3 },
]

const CLEFS: { key: "treble" | "bass" | "both"; label: string; sub: string; glyph: string }[] = [
  { key: "treble", label: "Sol anahtarı", sub: "Genelde sağ el", glyph: "𝄞" },
  { key: "bass", label: "Fa anahtarı", sub: "Genelde sol el", glyph: "𝄢" },
  { key: "both", label: "İkisi de", sub: "İki elle çalıyorum", glyph: "𝄞𝄢" },
]

// onDone(true): "Ben öğretmenim" yolu, tanıtım biter ve öğretmen kodu ekranı açılır (tanitim.md)
export default function Onboarding({ onDone }: { onDone: (openTeacher?: boolean) => void }) {
  const [step, setStep] = useState<Step>("intro")
  const [level, setLevel] = useState(0)
  const [goal, setGoal] = useState(10)
  const [remind, setRemind] = useState(true)
  const [hour, setHour] = useState(19)
  const [minute, setMinute] = useState(0)
  // Tekrar gösterilince önceki seçim işaretli açılır
  const [role, setRole] = useState<"student" | "self" | "teacher">(() => getSettings().teacherRole || "student")
  const [name, setName] = useState("")
  const [clef, setClef] = useState<"treble" | "bass" | "both">("treble")
  const order: Step[] = ["intro", "hello", "try1", "try2", "teacher", "clef", "level", "reminder", "done"]
  const idx = order.indexOf(step)
  const next = () => setStep(order[idx + 1])
  const back = () => setStep(order[Math.max(0, idx - 1)])

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Hoş geldin"
      style={{
        position: "absolute",
        inset: 0,
        zIndex: 100,
        background: colors.bg,
        display: "flex",
        flexDirection: "column",
        // Tablette içerik ortada en fazla 560 px; telefonda kenarlardan 20 px
        padding: "20px max(20px, calc((100% - 560px) / 2)) 24px",
        fontFamily: font.family.ui,
      }}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          minHeight: 44,
          marginBottom: 6,
        }}
      >
        {/* Geri (R28): ikinci adımdan itibaren */}
        <button
          onClick={back}
          aria-label="Geri"
          style={{
            width: 44,
            height: 44,
            borderRadius: radius.md,
            border: "none",
            background: idx > 0 ? colors.fillStrong : "none",
            color: colors.textSecondary,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            cursor: idx > 0 ? "pointer" : "default",
            visibility: idx > 0 ? "visible" : "hidden",
          }}
        >
          <svg
            width={18}
            height={18}
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth={2.5}
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
          >
            <path d="M19 12H5M12 5l-7 7 7 7" />
          </svg>
        </button>
        <div style={{ display: "flex", gap: 6 }}>
          {order.map((_, k) => (
            <span
              key={k}
              style={{
                width: k === idx ? 18 : 6,
                height: 6,
                borderRadius: radius.pill,
                background: k <= idx ? palette.violet500 : colors.fillStronger,
                transition: "all 0.2s",
              }}
            />
          ))}
        </div>
        {step !== "done" ? (
          <button
            onClick={() => onDone()}
            style={{
              padding: "10px 4px",
              fontSize: font.size.md,
              color: colors.textMuted,
              background: "none",
              border: "none",
              cursor: "pointer",
            }}
          >
            Atla
          </button>
        ) : (
          <span style={{ width: 44 }} />
        )}
      </div>

      {step === "intro" && (
        <>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "center", gap: 18 }}>
            <Logo size={48} />
            <h1
              style={{
                fontSize: font.size.xxl,
                fontWeight: font.weight.heavy,
                color: colors.text,
                letterSpacing: "-0.03em",
                lineHeight: 1.1,
              }}
            >
              Her gün birkaç dakika, nota okumak kolaylaşsın
            </h1>
            <p style={{ fontSize: font.size.md, color: colors.textSoft, lineHeight: 1.5 }}>
              Solvato, piyano öğrencileri için kısa pratik turları: nota, ritim, akor ve kulak. Ne kadar ilerlediğini de
              gösterir.
            </p>
            <div style={{ display: "grid", gridTemplateColumns: "repeat(2, minmax(0, 1fr))", gap: 8 }}>
              {[
                ["𝄞", "Nota okuma", palette.blue400],
                ["♩", "Ritim", palette.amber400],
                ["♬", "Akor", palette.green400],
                ["◉", "Kulak", palette.pink400],
              ].map(([g, t, c]) => (
                <span
                  key={t}
                  style={{
                    ...CARD,
                    display: "flex",
                    alignItems: "center",
                    gap: 8,
                    padding: "10px 12px",
                    fontSize: font.size.md,
                    fontWeight: font.weight.semibold,
                    color: colors.text,
                  }}
                >
                  <span style={{ color: c, fontSize: font.size.lg }}>{g}</span>
                  {t}
                </span>
              ))}
            </div>
          </div>
          <button onClick={next} style={PRIMARY}>
            Başlayalım
          </button>
        </>
      )}

      {step === "teacher" && (
        <>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 12 }}>
            <h1
              style={{
                fontSize: font.size.xl,
                fontWeight: font.weight.heavy,
                color: colors.text,
                letterSpacing: "-0.03em",
                marginBottom: 6,
              }}
            >
              Bir öğretmenle mi çalışıyorsun?
            </h1>
            <ChoiceCard
              selected={role === "student"}
              onClick={() => setRole("student")}
              title="Evet, öğretmenim var"
              sub="Öğretmeninle birlikte çalışıyorsun"
            />
            <ChoiceCard
              selected={role === "self"}
              onClick={() => setRole("self")}
              title="Hayır, kendi kendime"
              sub="Anahtar ve seviyeyi birlikte seçelim"
            />
            <ChoiceCard
              selected={role === "teacher"}
              onClick={() => setRole("teacher")}
              title="Ben öğretmenim"
              sub="Öğrencilerim için kullanacağım"
            />
          </div>
          <button
            onClick={() => {
              updateSettings({ teacherRole: role })
              // Öğretmen: anahtar, seviye, hatırlatma ve Hazırsın atlanır
              if (role === "teacher") onDone(true)
              else next()
            }}
            style={PRIMARY}
          >
            Devam
          </button>
        </>
      )}

      {step === "hello" && (
        <>
          <div
            style={{
              flex: 1,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              textAlign: "center",
            }}
          >
            <div style={{ marginBottom: 22 }}>
              <SolfieSays size={96} pose="wave">
                Merhaba, ben Solfie!
              </SolfieSays>
            </div>
            <h1
              style={{
                fontSize: font.size.xl,
                fontWeight: font.weight.heavy,
                color: colors.text,
                letterSpacing: "-0.03em",
                marginBottom: 12,
              }}
            >
              Hadi bir nota bulalım
            </h1>
            <p style={{ fontSize: font.size.md, color: colors.textMuted, lineHeight: 1.55, maxWidth: 300 }}>
              Portedeki notayı görüp piyano tuşunda bulacaksın. Önce iki küçük denemeyle başlıyoruz.
            </p>
            <input
              value={name}
              onChange={(e) => setName(e.target.value.slice(0, 24))}
              placeholder="Adın (isteğe bağlı)"
              aria-label="Adın (isteğe bağlı)"
              autoComplete="given-name"
              style={{
                marginTop: 22,
                width: "100%",
                maxWidth: 300,
                padding: "14px 16px",
                borderRadius: radius.lg,
                textAlign: "center",
                fontSize: font.size.md,
                fontFamily: font.family.ui,
                color: colors.text,
                background: colors.fillStrong,
                border: `1px solid ${colors.borderStrong}`,
                outline: "none",
              }}
            />
          </div>
          <button
            onClick={() => {
              updateSettings({ name: name.trim() })
              next()
            }}
            style={PRIMARY}
          >
            Devam
          </button>
        </>
      )}

      {step === "try1" && (
        <TryStep
          key="t1"
          note="Do"
          noteY={90}
          ledger={[90]}
          title="Bu nota Do. Tuşunu bul."
          helpWrong="Do, iki siyah tuşlu grubun solundaki beyaz tuştur. Bir daha dene."
          onPass={next}
        />
      )}

      {step === "try2" && (
        <TryStep
          key="t2"
          note="Sol"
          noteY={70}
          ledger={[]}
          title="Şimdi sen bul: bu hangi nota?"
          helpWrong="Sol anahtarının sarmal ortası ikinci çizgiyi sarar: bu çizgi Sol notasıdır. Tekrar dene."
          onPass={next}
        />
      )}

      {step === "clef" && (
        <>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 12 }}>
            <h1
              style={{
                fontSize: font.size.xl,
                fontWeight: font.weight.heavy,
                color: colors.text,
                letterSpacing: "-0.03em",
              }}
            >
              Hangi anahtarı okuyorsun?
            </h1>
            <p style={{ fontSize: font.size.md, color: colors.textMuted, lineHeight: 1.5, marginBottom: 6 }}>
              Karışık turlarda bu anahtarın notaları sorulur. Ayarlar'dan değiştirebilirsin.
            </p>
            {CLEFS.map((c) => (
              <ChoiceCard
                key={c.key}
                selected={clef === c.key}
                onClick={() => setClef(c.key)}
                title={c.label}
                sub={c.sub}
                leading={
                  <span style={{ width: 48, display: "inline-flex", justifyContent: "center", gap: 2 }}>
                    {c.key === "both" ? (
                      <>
                        <ClefIcon clef="treble" size={32} />
                        <ClefIcon clef="bass" size={32} />
                      </>
                    ) : (
                      <ClefIcon clef={c.key} size={34} />
                    )}
                  </span>
                }
              />
            ))}
          </div>
          <button
            onClick={() => {
              updateSettings({ clef })
              next()
            }}
            style={PRIMARY}
          >
            Devam
          </button>
        </>
      )}

      {step === "level" && (
        <>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 12 }}>
            <h1
              style={{
                fontSize: font.size.xl,
                fontWeight: font.weight.heavy,
                color: colors.text,
                letterSpacing: "-0.03em",
              }}
            >
              Piyanoda neredesin?
            </h1>
            <p style={{ fontSize: font.size.md, color: colors.textMuted, lineHeight: 1.5, marginBottom: 6 }}>
              Sorular seviyene göre gelir. Çalıştıkça yeni sorular açılır.
            </p>
            {LEVELS.map((l, k) => (
              <ChoiceCard
                key={l.label}
                selected={level === k}
                onClick={() => setLevel(k)}
                title={l.label}
                sub={l.sub}
              />
            ))}
            <p style={{ fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.text, marginTop: 10 }}>
              Günlük hedefin
            </p>
            <Segmented value={goal} options={[10, 20, 30].map((g) => [g, `${g} soru`] as const)} onChange={setGoal} />
          </div>
          <button
            onClick={() => {
              updateSettings({
                level: LEVELS[level].level,
                levelProgress: { n: 0, c: 0 },
                dailyGoal: goal,
              })
              next()
            }}
            style={PRIMARY}
          >
            Devam
          </button>
        </>
      )}

      {step === "reminder" && (
        <>
          <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 12 }}>
            <h1
              style={{
                fontSize: font.size.xl,
                fontWeight: font.weight.heavy,
                color: colors.text,
                letterSpacing: "-0.03em",
              }}
            >
              Her gün hatırlatalım mı?
            </h1>
            <p style={{ fontSize: font.size.md, color: colors.textMuted, lineHeight: 1.5, marginBottom: 6 }}>
              Nota okuma, her gün birkaç dakikayla yerleşir. Seçtiğin saatte bir bildirim gönderelim.
            </p>
            <ChoiceCard
              selected={remind}
              onClick={() => setRemind(true)}
              title="Evet, hatırlat"
              sub="Her gün aynı saatte"
            />
            {remind && (
              <TimeField
                hour={hour}
                minute={minute}
                onChange={(h, m) => {
                  setHour(h)
                  setMinute(m)
                }}
              />
            )}
            <ChoiceCard
              selected={!remind}
              onClick={() => setRemind(false)}
              title="Şimdi değil"
              sub="Ayarlar'dan istediğin zaman açabilirsin"
            />
          </div>
          <button
            onClick={async () => {
              updateSettings({ reminderHour: hour, reminderMinute: minute })
              // İzin yalnızca telefonda istenir; reddedilirse ya da önizlemedeyse kapalı kalır
              if (remind) updateSettings({ reminder: await enableReminder(hour, minute) })
              next()
            }}
            style={PRIMARY}
          >
            {remind ? "Hatırlat" : "Devam"}
          </button>
        </>
      )}

      {step === "done" && (
        <>
          <div
            style={{
              flex: 1,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              textAlign: "center",
            }}
          >
            <div style={{ marginBottom: 22 }}>
              <SolfieSays size={104} pose="cheer">
                Her gün birlikte çalışalım!
              </SolfieSays>
            </div>
            <h1
              style={{
                fontSize: font.size.xl,
                fontWeight: font.weight.heavy,
                color: colors.text,
                letterSpacing: "-0.03em",
                marginBottom: 12,
              }}
            >
              Hazırsın
            </h1>
            <p style={{ fontSize: font.size.md, color: colors.textMuted, lineHeight: 1.55, maxWidth: 300 }}>
              Günde {goal} soru yeter. Doğru cevapladıkça yeni sorular açılır.
            </p>
          </div>
          <button onClick={() => onDone()} style={PRIMARY}>
            Başlayalım
          </button>
        </>
      )}
    </div>
  )
}
