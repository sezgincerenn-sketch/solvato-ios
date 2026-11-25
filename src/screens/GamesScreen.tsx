// Oyunlar: önce oyun seçilir (liste), sonra o oyunun ekranı açılır.
//   GamesScreen          — üç oyunun listesi
//   DailyGameScreen      — günün meydan okuması
//   ChallengeGameScreen  — kodla arkadaşa meydan okuma (başlat / kodu gir)
// Akor düellosu kendi ekranında (ChordDuel). Oyun sonucu: GameResultScreen.
import { formatCode, readClipboard } from "../utils/codeFormat"
import { useState } from "react"
import { LEVEL_LABELS } from "../data/questions"
import { category, colors, font, palette, radius, space } from "../design/tokens"
import { Button, Card, Chip, IconBadge, ScreenHeader, useToast } from "../ui"
import { getSettings } from "../utils/settings"
import {
  GAME_CATS,
  GAME_LENGTH,
  catLabel,
  dailyInfo,
  dailyStreak,
  decodeChallenge,
  fmtSec,
  loadDaily,
  newSeed,
  todayStr,
  type GameCat,
} from "../utils/games"
import { dailyShareText, shareWithToast, type GameCtx } from "./gameShared"

const stack = { display: "flex", flexDirection: "column", gap: space[3] } as const
const muted = { fontSize: font.size.sm, color: colors.textMuted, lineHeight: 1.5 } as const
const page = {
  position: "relative",
  height: "100%",
  display: "flex",
  flexDirection: "column",
  fontFamily: font.family.ui,
} as const
const body = {
  flex: 1,
  minHeight: 0,
  overflowY: "auto",
  padding: `${space[2]}px ${space[4]}px ${space[6]}px`,
  ...stack,
} as const

// ─── Liste ───────────────────────────────────────────────────────────────────
function GameRow({
  icon,
  color,
  title,
  sub,
  status,
  onClick,
}: {
  icon: "calendar" | "users" | "flame"
  color: string
  title: string
  sub: string
  status?: string
  onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      style={{
        display: "flex",
        alignItems: "center",
        gap: space[3],
        width: "100%",
        textAlign: "left",
        padding: space[4],
        borderRadius: radius.lg,
        cursor: "pointer",
        background: `${color}0F`,
        border: `1px solid ${color}4D`,
        fontFamily: font.family.ui,
      }}
    >
      <IconBadge name={icon} color={color} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <p style={{ fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.text }}>{title}</p>
        <p style={{ fontSize: font.size.sm, color: colors.textMuted }}>{sub}</p>
        {status && (
          <p
            style={{
              fontSize: font.size.xs,
              fontWeight: font.weight.bold,
              color: colors.textSubtle,
              marginTop: 4,
              fontFamily: font.family.mono,
            }}
          >
            {status}
          </p>
        )}
      </div>
      <span aria-hidden="true" style={{ color: colors.textMuted, fontSize: font.size.lg }}>
        ›
      </span>
    </button>
  )
}

export default function GamesScreen({
  onBack,
  onOpen,
}: {
  onBack: () => void
  onOpen: (game: "daily" | "challenge" | "duel") => void
}) {
  const today = dailyInfo(todayStr())
  const played = loadDaily()[today.date]
  return (
    <div style={page}>
      <ScreenHeader title="Oyunlar" onBack={onBack} />
      <div style={body}>
        <p style={muted}>Bir oyun seç.</p>
        <GameRow
          icon="calendar"
          color={category.games.base}
          title="Günün meydan okuması"
          sub={`Herkese aynı ${GAME_LENGTH} soru · bugün ${catLabel(today.cat)}`}
          status={played ? `Bugün oynandı · ${played.correct}/${GAME_LENGTH}` : "Bugün henüz oynanmadı"}
          onClick={() => onOpen("daily")}
        />
        <GameRow
          icon="users"
          color={palette.violet500}
          title="Arkadaşına meydan oku"
          sub="Oyna, kodu gönder; o da aynı soruları çözsün. Sana kod geldiyse buradan gir."
          onClick={() => onOpen("challenge")}
        />
        <GameRow
          icon="flame"
          color={palette.amber500}
          title="Akor düellosu"
          sub="İki kişi, tek telefon: akoru ilk bilen kazanır"
          onClick={() => onOpen("duel")}
        />
      </div>
    </div>
  )
}

// ─── Günün meydan okuması ────────────────────────────────────────────────────
export function DailyGameScreen({ onBack, onPlay }: { onBack: () => void; onPlay: (ctx: GameCtx) => void }) {
  const today = dailyInfo(todayStr())
  const played = loadDaily()[today.date]
  const streak = dailyStreak()
  const toast = useToast()
  return (
    <div style={page}>
      <ScreenHeader title="Günün meydan okuması" onBack={onBack} />
      <div style={body}>
        <Card tone={category.games.base} style={stack}>
          <p
            style={{
              fontSize: font.size.xs,
              fontWeight: font.weight.bold,
              color: colors.textSubtle,
              letterSpacing: font.tracking.label,
              textTransform: "uppercase",
            }}
          >
            Bugün · #{today.no}
          </p>
          <p style={{ fontSize: font.size.lg, fontWeight: font.weight.heavy, color: colors.text }}>
            {catLabel(today.cat)}
          </p>
          {played ? (
            <>
              <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", gap: space[2] }}>
                <span
                  style={{
                    fontSize: font.size.xl,
                    fontWeight: font.weight.heavy,
                    color: colors.text,
                    fontFamily: font.family.mono,
                  }}
                >
                  {played.correct}/{GAME_LENGTH}
                </span>
                <span style={muted}>{fmtSec(played.sec)}</span>
              </div>
              <p style={{ fontSize: font.size.md, letterSpacing: 1 }}>{played.marks}</p>
              <p style={muted}>
                Yarın yeni sorular gelecek.{streak > 1 ? ` ${streak} gündür üst üste oynuyorsun.` : ""}
              </p>
              <Button
                variant="success"
                onClick={() => shareWithToast(dailyShareText(today.no, today.cat, played), toast.show)}
              >
                Sonucu paylaş
              </Button>
            </>
          ) : (
            <>
              <p style={muted}>
                Herkes bugün aynı {GAME_LENGTH} soruyu çözüyor. Günde bir kez oynanır, ilk denemen sayılır. Bitince
                sonucunu arkadaşlarına gönder, kim daha iyi yapmış görün.
              </p>
              <Button variant="success" onClick={() => onPlay({ mode: "daily", ...today })}>
                Oyna
              </Button>
            </>
          )}
        </Card>
      </div>
      {toast.el}
    </div>
  )
}

// ─── Arkadaşına meydan oku ───────────────────────────────────────────────────
export function ChallengeGameScreen({ onBack, onPlay }: { onBack: () => void; onPlay: (ctx: GameCtx) => void }) {
  const lv = getSettings().level
  const [cat, setCat] = useState<GameCat>("all")
  const [code, setCode] = useState("")
  const [err, setErr] = useState("")

  const accept = () => {
    const ch = decodeChallenge(code)
    if (!ch) return setErr("Kod geçersiz. 8 karakteri kontrol et.")
    onPlay({ mode: "challenge", cat: ch.cat, level: ch.level, seed: ch.seed, opp: ch })
  }

  return (
    <div style={page}>
      <ScreenHeader title="Arkadaşına meydan oku" onBack={onBack} />
      <div style={body}>
        {/* 1) Yeni meydan okuma */}
        <Card as="section" style={stack}>
          <p style={{ fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.text }}>Yeni meydan okuma</p>
          <p style={muted}>Konuyu seç, {GAME_LENGTH} soruyu çöz. Sonunda arkadaşına göndereceğin bir kod çıkar.</p>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>
            {GAME_CATS.map((c) => (
              <Chip key={c.key} selected={cat === c.key} onClick={() => setCat(c.key)}>
                {c.label}
              </Chip>
            ))}
          </div>
          <p style={{ fontSize: font.size.xs, color: colors.textFaint }}>
            Sorular senin seviyende gelir ({LEVEL_LABELS[lv]}).
          </p>
          <Button onClick={() => onPlay({ mode: "challenge", cat, level: lv, seed: newSeed() })}>Başla</Button>
        </Card>

        {/* 2) Gelen kod */}
        <Card as="section" style={stack}>
          <p style={{ fontSize: font.size.md, fontWeight: font.weight.bold, color: colors.text }}>Sana kod mu geldi?</p>
          <p style={muted}>Arkadaşının gönderdiği 8 karakterlik kodu yaz; aynı soruları çöz, sonuçları karşılaştır.</p>
          <div style={{ display: "flex", gap: space[2] }}>
            <input
              value={code}
              onChange={(e) => {
                setCode(formatCode(e.target.value, 4, 8))
                setErr("")
              }}
              onKeyDown={(e) => e.key === "Enter" && accept()}
              placeholder="ABCD-EFGH"
              aria-label="Meydan okuma kodu"
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
            <Button variant="secondary" onClick={accept} disabled={!code.trim()}>
              Kabul et
            </Button>
          </div>
          <button
            type="button"
            onClick={async () => {
              const t = await readClipboard()
              if (t) {
                setCode(formatCode(t, 4, 8))
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
        </Card>
      </div>
    </div>
  )
}
