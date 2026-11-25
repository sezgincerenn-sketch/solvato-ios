// Çalışma › Ritim: nota değerleri ve vuruş süreleri

import { alpha, colors, font, palette, radius } from "../../design/tokens"

// ─── Nota değerleri & vuruş süreleri ezber bölümü ─────────────────────────────
const VALUES = [
  {
    kind: "whole",
    name: "Birlik",
    en: "Whole",
    beats: 4,
    rest: "Birlik es (çizginin altına asılı)",
    color: palette.violet500,
  },
  {
    kind: "half",
    name: "İkilik",
    en: "Half",
    beats: 2,
    rest: "İkilik es (çizginin üstüne oturur)",
    color: palette.blue500,
  },
  { kind: "quarter", name: "Dörtlük", en: "Quarter", beats: 1, rest: "Dörtlük es (zigzag)", color: palette.cyan500 },
  {
    kind: "eighth",
    name: "Sekizlik",
    en: "Eighth",
    beats: 0.5,
    rest: "Sekizlik es (tek kanca)",
    color: palette.amber500,
  },
  {
    kind: "sixteenth",
    name: "Onaltılık",
    en: "Sixteenth",
    beats: 0.25,
    rest: "Onaltılık es (çift kanca)",
    color: palette.pink500,
  },
]

function NoteIcon({ kind, color }: { kind: string; color: string }) {
  const hollow = kind === "whole" || kind === "half"
  const stem = kind !== "whole"
  const flags = kind === "eighth" ? 1 : kind === "sixteenth" ? 2 : 0
  return (
    <svg width={34} height={40} viewBox="0 0 34 40" aria-hidden>
      <ellipse
        cx={13}
        cy={31}
        rx={8}
        ry={5.5}
        transform="rotate(-20 13 31)"
        fill={hollow ? "none" : color}
        stroke={color}
        strokeWidth={2.4}
      />
      {stem && <line x1={20.5} y1={29} x2={20.5} y2={4} stroke={color} strokeWidth={2.2} />}
      {Array.from({ length: flags }, (_, i) => (
        <path
          key={i}
          d={`M20.5 ${4 + i * 7} C 27 ${10 + i * 7}, 29 ${16 + i * 7}, 26 ${22 + i * 7}`}
          fill="none"
          stroke={color}
          strokeWidth={2.2}
        />
      ))}
    </svg>
  )
}

function beatText(b: number) {
  if (b === 0.5) return "½ vuruş"
  if (b === 0.25) return "¼ vuruş"
  return `${b} vuruş`
}

export function RhythmMemo({ part }: { part: "learn" | "memo" }) {
  const card = {
    background: colors.surface,
    borderRadius: radius.md,
    padding: "14px 16px",
    border: `1px solid ${colors.border}`,
  } as const
  const h = {
    color: colors.textMuted,
    fontSize: font.size.xs,
    fontFamily: font.family.ui,
    fontWeight: font.weight.bold,
    letterSpacing: "0.08em",
    textTransform: "uppercase",
    marginBottom: 10,
  } as const
  const t = {
    color: colors.textSecondary,
    fontSize: font.size.sm,
    fontFamily: font.family.ui,
    lineHeight: 1.6,
  } as const
  const title = { ...t, fontWeight: font.weight.bold, color: colors.textSoft } as const
  return (
    <div>
      <div style={h}>{part === "learn" ? "Nota Değerleri ve Vuruş Süreleri" : "Süre Hesabı ve Kolay Hatırla"}</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        {part === "learn" && (
          <>
            <div style={card}>
              <div style={title}>Temel fikir</div>
              <div style={t}>
                Her nota ne kadar süreceğini söyler. Süre “vuruş” ile sayılır. Her nota bir öncekinin <b>yarısı</b>{" "}
                kadar sürer. Aşağıdaki örneklerde dörtlük nota = 1 vuruş kabul edilir (4/4 ölçüde).
              </div>
            </div>

            {VALUES.map((v) => (
              <div key={v.kind} style={{ ...card, display: "flex", alignItems: "center", gap: 14 }}>
                <div style={{ width: 40, display: "flex", justifyContent: "center", flexShrink: 0 }}>
                  <NoteIcon kind={v.kind} color={v.color} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline", gap: 8 }}>
                    <span style={title}>{v.name}</span>
                    <span
                      style={{
                        color: v.color,
                        fontWeight: font.weight.heavy,
                        fontSize: font.size.sm,
                        fontFamily: font.family.ui,
                        whiteSpace: "nowrap",
                      }}
                    >
                      {beatText(v.beats)}
                    </span>
                  </div>
                  <div
                    style={{
                      height: 8,
                      borderRadius: radius.xs,
                      background: alpha(palette.slate400, 0.2),
                      marginTop: 8,
                      overflow: "hidden",
                    }}
                  >
                    <div
                      style={{
                        height: "100%",
                        width: `${(v.beats / 4) * 100}%`,
                        minWidth: 4,
                        background: v.color,
                        borderRadius: radius.xs,
                      }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </>
        )}
        {part === "memo" && (
          <>
            <div style={card}>
              <div style={title}>Es (sessizlik) işaretleri</div>
              <div style={{ display: "flex", flexDirection: "column", gap: 4, marginTop: 4 }}>
                {VALUES.map((v) => (
                  <div key={v.kind} style={t}>
                    {v.rest}
                  </div>
                ))}
              </div>
            </div>
            <div style={card}>
              <div style={title}>Eşitlikler</div>
              <div style={t}>1 birlik = 2 ikilik = 4 dörtlük = 8 sekizlik = 16 onaltılık</div>
            </div>

            <div style={card}>
              <div style={title}>Noktalı nota</div>
              <div style={t}>
                Notanın yanına konan nokta süreyi <b>yarısı kadar uzatır</b>.
              </div>
              <div style={{ ...t, marginTop: 6 }}>
                Noktalı ikilik = 2 + 1 = <b>3 vuruş</b>
                <br />
                Noktalı dörtlük = 1 + ½ = <b>1½ vuruş</b>
                <br />
                Noktalı birlik = 4 + 2 = <b>6 vuruş</b>
              </div>
            </div>

            <div style={card}>
              <div style={title}>4/4’lük ölçü = 4 vuruş</div>
              <div style={t}>Ölçüdeki notaların toplamı 4 vuruşu doldurmalı. Birkaç doğru örnek:</div>
              <div style={{ display: "flex", flexDirection: "column", gap: 6, marginTop: 8 }}>
                {[
                  { n: "1 birlik", d: "4" },
                  { n: "2 ikilik", d: "2 + 2" },
                  { n: "4 dörtlük", d: "1 + 1 + 1 + 1" },
                  { n: "1 ikilik + 2 dörtlük", d: "2 + 1 + 1" },
                  { n: "2 dörtlük + 4 sekizlik", d: "1 + 1 + ½×4" },
                ].map((r) => (
                  <div key={r.n} style={{ display: "flex", justifyContent: "space-between", gap: 8, ...t }}>
                    <span>{r.n}</span>
                    <span style={{ color: colors.violetText, fontWeight: font.weight.bold, whiteSpace: "nowrap" }}>
                      {r.d} = 4
                    </span>
                  </div>
                ))}
              </div>
            </div>

            <div style={card}>
              <div style={title}>Kolay hatırla</div>
              <div style={t}>
                Pizza gibi düşün: birlik tam pizza, ikilik yarım, dörtlük çeyrek, sekizlik 1/8 dilim. Dilimler
                küçüldükçe daha hızlı çalarsın, notanın ucuna kanca eklenir.
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  )
}
