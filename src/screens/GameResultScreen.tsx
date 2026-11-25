// Oyun sonucu: günlük oyun, yeni meydan okuma (kod) ya da arkadaşla karşılaştırma.
import type { ReactNode } from "react"
import Icon from "../components/Icons"
import { alpha, colors, font, palette, radius, space } from "../design/tokens"
import type { RoundAnswer } from "../types"
import { Button, IconBadge, ScoreRing, StatTile, useToast } from "../ui"
import { GAME_LENGTH, catLabel, dailyStreak, encodeChallenge, fmtSec, summarize, type GameCat } from "../utils/games"
import { getSettings } from "../utils/settings"
import { dailyShareText, shareWithToast, type GameCtx } from "./gameShared"

/** Soru soru yeşil/kırmızı kutucuklar */
function Marks({ results }: { results: RoundAnswer[] }) {
  return (
    <div style={{ display: "flex", gap: 5, justifyContent: "center" }} aria-label="Soru soru sonuçlar">
      {results.map((r, i) => (
        <span
          key={i}
          style={{
            width: 18,
            height: 18,
            borderRadius: radius.xs,
            background: r.correct ? palette.green500 : palette.red500,
            opacity: r.correct ? 0.9 : 0.75,
          }}
        />
      ))}
    </div>
  )
}

function PlayerColumn({
  label,
  correct,
  sec,
  winner,
}: {
  label: string
  correct: number
  sec: number
  winner: boolean
}) {
  return (
    <div
      style={{
        flex: 1,
        padding: `${space[3]}px ${space[2]}px`,
        borderRadius: radius.lg,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 2,
        background: winner ? alpha(palette.violet500, 0.14) : colors.fill,
        border: `1px solid ${winner ? palette.violet500 : colors.border}`,
      }}
    >
      <p
        style={{
          fontSize: font.size.sm,
          fontWeight: font.weight.bold,
          color: winner ? colors.violetTextSoft : colors.textMuted,
        }}
      >
        {label}
      </p>
      <ScoreRing value={correct} max={GAME_LENGTH} size={104} caption="doğru" />
      <p style={{ fontSize: font.size.sm, color: colors.textMuted }}>{fmtSec(sec)}</p>
    </div>
  )
}

export default function GameResultScreen({
  ctx,
  results,
  onNewChallenge,
  onExit,
}: {
  ctx: GameCtx
  results: RoundAnswer[]
  onNewChallenge: (cat: GameCat) => void
  onExit: () => void
}) {
  const me = summarize(results)
  const name = getSettings().name.trim()
  const toast = useToast()
  const cat = catLabel(ctx.cat)
  const mine = (
    <>
      <ScoreRing value={me.correct} max={GAME_LENGTH} caption="doğru" />
      <Marks results={results} />
    </>
  )

  let badge: { icon: "calendar" | "users" | "trophy"; color: string } = { icon: "users", color: palette.violet500 }
  let title: string
  let body: ReactNode
  let share: { label: string; text: string }

  if (ctx.mode === "daily") {
    badge = { icon: "calendar", color: palette.green500 }
    title = `Günün meydan okuması #${ctx.no}`
    share = { label: "Sonucu paylaş", text: dailyShareText(ctx.no, ctx.cat, me) }
    body = (
      <>
        {mine}
        <div style={{ display: "flex", gap: 10, width: "100%", maxWidth: 360 }}>
          <StatTile label="Süre" value={fmtSec(me.sec)} />
          <StatTile label="Seri" value={`${dailyStreak()} gün`} />
        </div>
        <p style={{ fontSize: font.size.sm, color: colors.textMuted, textAlign: "center", maxWidth: 320 }}>
          Arkadaşların da bugün aynı soruları çözüyor. Sonucunu gönder, kim daha iyi yapmış görün.
        </p>
      </>
    )
  } else if (!ctx.opp) {
    const code = encodeChallenge({ cat: ctx.cat, level: ctx.level, seed: ctx.seed, correct: me.correct, sec: me.sec })
    title = "Meydan okuman hazır"
    share = {
      label: "Kodu gönder",
      // Revize R30/R32: kod tek başına ilk satırda, en altta indirme satırı
      text: `${code}\n\n${name || "Bir arkadaşın"} sana meydan okuyor! 🎹\n${cat}: ${me.correct}/${GAME_LENGTH} · ${fmtSec(me.sec)}\nGeçebilir misin? Solvato'da Oyunlar › "Sana kod mu geldi?" kısmına yapıştır.\n\nUygulamayı indir: App Store'da "Solvato" diye arat.`,
    }
    body = (
      <>
        {mine}
        <div
          style={{
            width: "100%",
            maxWidth: 360,
            padding: `14px ${space[4]}px`,
            borderRadius: radius.lg,
            textAlign: "center",
            background: alpha(palette.violet500, 0.1),
            border: `1px dashed ${alpha(palette.violet400, 0.55)}`,
          }}
        >
          <p
            style={{
              fontSize: font.size.xs,
              color: colors.violetText,
              fontWeight: font.weight.bold,
              letterSpacing: font.tracking.label,
              textTransform: "uppercase",
            }}
          >
            Meydan okuma kodu
          </p>
          <p
            style={{
              fontSize: font.size.xxl,
              fontWeight: font.weight.heavy,
              color: colors.text,
              fontFamily: font.family.mono,
              letterSpacing: 3,
              userSelect: "all",
              margin: "2px 0",
            }}
          >
            {code}
          </p>
          <p style={{ fontSize: font.size.sm, color: colors.textMuted }}>
            {fmtSec(me.sec)} · arkadaşın aynı soruları çözecek
          </p>
        </div>
      </>
    )
  } else {
    const o = ctx.opp
    // Önce doğru sayısı, eşitse süre; ikisi de eşitse berabere
    const win = me.correct !== o.correct ? me.correct > o.correct : me.sec !== o.sec ? me.sec < o.sec : null
    badge =
      win === false
        ? { icon: "users", color: palette.amber500 }
        : { icon: "trophy", color: win ? palette.amber400 : palette.violet500 }
    title = win === null ? "Berabere!" : win ? "Kazandın!" : "Bu sefer o kazandı"
    const score = (c: number, s: number) => `${c}/${GAME_LENGTH} (${fmtSec(s)})`
    share = {
      label: "Sonucu gönder",
      text:
        win === null
          ? `${cat} meydan okumasında berabere kaldık: ikimiz de ${me.correct}/${GAME_LENGTH}, ${fmtSec(me.sec)} 🤝`
          : win
            ? `${cat} meydan okumanı geçtim: ${score(me.correct, me.sec)}, sen ${score(o.correct, o.sec)} 😎`
            : `${cat} meydan okumanda ${score(me.correct, me.sec)} yaptım. Sen ${o.correct}/${GAME_LENGTH} ile kazandın, rövanş istiyorum!`,
    }
    body = (
      <>
        <div style={{ display: "flex", gap: 10, width: "100%", maxWidth: 360 }}>
          <PlayerColumn label="Sen" correct={me.correct} sec={me.sec} winner={win === true} />
          <PlayerColumn label="Arkadaşın" correct={o.correct} sec={o.sec} winner={win === false} />
        </div>
        <Marks results={results} />
        {win !== null && me.correct === o.correct && (
          <p style={{ fontSize: font.size.sm, color: colors.textMuted }}>Doğru sayısı eşit, hızlı olan kazandı.</p>
        )}
      </>
    )
  }

  return (
    <div style={{ position: "relative", height: "100%", overflowY: "auto", fontFamily: font.family.ui }}>
      <div
        style={{
          minHeight: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 14,
          padding: `36px ${space[5]}px ${space[6]}px`,
        }}
      >
        <IconBadge name={badge.icon} color={badge.color} size="lg" glow />
        <div style={{ textAlign: "center" }}>
          <h1
            style={{
              fontSize: font.size.xl,
              fontWeight: font.weight.heavy,
              color: colors.text,
              letterSpacing: font.tracking.tight,
              textWrap: "balance",
            }}
          >
            {title}
          </h1>
          <p
            style={{
              fontSize: font.size.sm,
              color: colors.textSubtle,
              fontWeight: font.weight.medium,
              marginTop: space[1],
            }}
          >
            {cat}
          </p>
        </div>
        {body}
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: space[2],
            width: "100%",
            maxWidth: 360,
            marginTop: "auto",
            paddingTop: space[2],
          }}
        >
          <Button block icon={<Icon name="share" size={18} />} onClick={() => shareWithToast(share.text, toast.show)}>
            {share.label}
          </Button>
          {ctx.mode === "challenge" && ctx.opp && (
            <Button block variant="secondary" onClick={() => onNewChallenge(ctx.cat)}>
              Sen de ona meydan oku
            </Button>
          )}
          <Button block variant="secondary" onClick={onExit} data-back>
            Kapat
          </Button>
        </div>
      </div>
      {toast.el}
    </div>
  )
}
