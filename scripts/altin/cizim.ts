// Çizim altın tablosu: React nota bileşenlerini (Notation, MusicalStaff, ChordStaffSvg, GoalStaff, ClefIcon) sunucu
// tarafında SVG'ye döker ve SVG'yi düz bir çizim listesine çevirir (çizgi, dikdörtgen, daire, yol, Bravura sembolü,
// yazı). Native yerleşim motoru (SolvatoCore/Notation) aynı girdiyle aynı listeyi üretmek zorunda.
// uret.ts içinden çağrılır; src/ yalnızca okunur.
import { createElement } from "react"
import { renderToStaticMarkup } from "react-dom/server"
import Notation, { termScore } from "../../src/components/Notation"
import MusicalStaff from "../../src/components/MusicalStaff"
import ChordStaffSvg from "../../src/components/ChordStaffSvg"
import GoalStaff from "../../src/components/GoalStaff"
import { ClefIcon } from "../../src/components/Glyph"
import { KeyIntervals } from "../../src/components/MemoVisuals"
import { SMUFL } from "../../src/data/smufl"
import { ALL_QUESTIONS } from "../../src/data/questions"
import { ALL_CHORDS } from "../../src/data/chords"
import { RHYTHM_PATTERNS } from "../../src/data/rhythmTap"
import { palette } from "../../src/design/tokens"

const glyphByPath = new Map(Object.entries(SMUFL).map(([k, v]) => [v.d, k]))

const hex2 = (n: number) => n.toString(16).padStart(2, "0").toUpperCase()
/** Renk → "var:notation" ya da "#RRGGBBAA"; yoksa null */
function paint(v: string | undefined): string | null {
  if (!v || v === "none") return null
  if (v === "currentColor") return "current"
  const t = v.trim()
  let m = t.match(/^var\(--([\w-]+)(?:,.*)?\)$/)
  if (m) return `var:${m[1]}`
  m = t.match(/^#([0-9a-f]{6})([0-9a-f]{2})?$/i)
  if (m) return `#${m[1].toUpperCase()}${(m[2] ?? "FF").toUpperCase()}`
  m = t.match(/^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)$/)
  if (m) return `#${hex2(+m[1])}${hex2(+m[2])}${hex2(+m[3])}${hex2(Math.round((m[4] === undefined ? 1 : +m[4]) * 255))}`
  return `?${t}`
}

const alphaHex = (hex: string, op: number) => hex.slice(0, 7) + hex2(Math.round(op * 255))

const decode = (s: string) =>
  s
    .replace(/&#x27;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")

type El = { tag: string; attrs: Record<string, string>; children: (El | string)[] }

export function parseXml(xml: string): El {
  const root: El = { tag: "#root", attrs: {}, children: [] }
  const stack = [root]
  for (const m of xml.matchAll(/<(\/?)([\w:-]+)((?:\s+[\w:-]+="[^"]*")*)\s*(\/?)>|([^<]+)/g)) {
    const top = stack[stack.length - 1]
    if (m[5] !== undefined) {
      top.children.push(decode(m[5]))
      continue
    }
    if (m[1]) {
      stack.pop()
      continue
    }
    const attrs: Record<string, string> = {}
    for (const a of m[3].matchAll(/([\w:-]+)="([^"]*)"/g)) attrs[a[1]] = decode(a[2])
    const el: El = { tag: m[2], attrs, children: [] }
    top.children.push(el)
    if (!m[4]) stack.push(el)
  }
  return root
}

const num = (s: string | undefined) => (s === undefined ? undefined : Number(s))
function style(s: string | undefined): Record<string, string> {
  const out: Record<string, string> = {}
  for (const part of (s ?? "").split(";")) {
    const i = part.indexOf(":")
    if (i > 0) out[part.slice(0, i).trim()] = part.slice(i + 1).trim()
  }
  return out
}

/** SVG → { viewBox, svgStyle, items } (gruplar düzleştirilir, translate koordinatlara eklenir) */
export function flatten(svg: El) {
  const items: Record<string, unknown>[] = []
  const walk = (el: El, dx: number, dy: number, glow: string | null) => {
    const a = el.attrs
    const st = style(a.style)
    const op = num(a.opacity)
    switch (el.tag) {
      case "g": {
        const t = a.transform?.match(/^translate\(([-\d.]+)[ ,]([-\d.]+)\)$/)
        for (const c of el.children)
          if (typeof c !== "string") walk(c, dx + (t ? +t[1] : 0), dy + (t ? +t[2] : 0), glow)
        return
      }
      case "line":
        items.push({
          t: "line",
          x1: +a.x1 + dx,
          y1: +a.y1 + dy,
          x2: +a.x2 + dx,
          y2: +a.y2 + dy,
          stroke: paint(a.stroke),
          w: num(a["stroke-width"]),
          round: a["stroke-linecap"] === "round",
        })
        return
      case "rect":
        // opacity özniteliği dolgunun saydamlığına katılır (native tek renkle çizer)
        if (op !== undefined && a.fill?.startsWith("#")) a.fill = alphaHex(a.fill, op)
        items.push({
          t: "rect",
          x: +a.x + dx,
          y: +a.y + dy,
          w: +a.width,
          h: +a.height,
          rx: num(a.rx) ?? 0,
          fill: paint(a.fill),
          stroke: paint(a.stroke),
          sw: num(a["stroke-width"]) ?? 0,
        })
        return
      case "circle":
        items.push({ t: "circle", cx: +a.cx + dx, cy: +a.cy + dy, r: +a.r, fill: paint(a.fill) })
        return
      case "path": {
        const name = glyphByPath.get(a.d)
        const tm = a.transform?.match(/^translate\(([-\d.e]+) ([-\d.e]+)\) scale\(([-\d.e]+) ([-\d.e]+)\)$/)
        if (name && tm) {
          const sh = st.filter?.match(/^drop-shadow\(0 0 5px (#[0-9a-fA-F]{6,8})\)$/)
          items.push({
            t: "glyph",
            name,
            x: +tm[1] + dx,
            y: +tm[2] + dy,
            sp: +tm[3] * 250,
            fill: paint(a.fill),
            opacity: op ?? 1,
            glow: sh ? paint(sh[1]) : null,
          })
        } else
          items.push({
            t: "path",
            d: a.d,
            fill: paint(a.fill),
            stroke: paint(a.stroke),
            w: num(a["stroke-width"]) ?? 0,
            round: a["stroke-linejoin"] === "round",
          })
        return
      }
      case "text": {
        const fam = st["font-family"] ?? ""
        items.push({
          t: "text",
          s: el.children.filter((c) => typeof c === "string").join(""),
          x: +a.x + dx,
          y: +a.y + dy,
          size: +a["font-size"],
          weight: num(a["font-weight"]) ?? 400,
          italic: a["font-style"] === "italic",
          anchor: a["text-anchor"] ?? "start",
          font: fam.includes("Times") ? "serif" : "ui",
          fill: paint(a.fill),
        })
        return
      }
      default:
        throw new Error(`bilinmeyen öğe ${el.tag}`)
    }
  }
  for (const c of svg.children) if (typeof c !== "string") walk(c, 0, 0, null)
  const vb = svg.attrs.viewBox.split(" ").map(Number)
  return { viewBox: vb, style: svg.attrs.style ?? "", items }
}

function render(el: ReturnType<typeof createElement>) {
  const root = parseXml(renderToStaticMarkup(el))
  const find = (e: El): El | null => {
    if (e.tag === "svg") return e
    for (const c of e.children)
      if (typeof c !== "string") {
        const f = find(c)
        if (f) return f
      }
    return null
  }
  return flatten(find(root)!)
}

/** Bankada, terimlerde, Ritmi Tut'ta ve ekranlarda çizilen bütün nota metinleri + elle kenar durumları */
function scores() {
  const set = new Set<string>()
  for (const q of ALL_QUESTIONS) {
    if (q.score) set.add(q.score)
    for (const s of Object.values(q.optionScores ?? {})) set.add(s)
    if (q.category === "musical_terms" && !q.questionText.startsWith("Hangi") && q.displayText) {
      const t = termScore(q.displayText)
      if (t) set.add(t)
    }
    if (q.category === "rhythm" && q.displayText && /^\d+\/\d+$/.test(q.displayText)) set.add(`ts:${q.displayText}`)
  }
  for (const s of ["w", "h", "q", "e", "s", "wr", "hr", "qr", "er", "sr", "h. = h + q"]) set.add(s)
  for (const lv of [1, 2, 3] as const) for (const p of RHYTHM_PATTERNS[lv]) set.add(`ts:4/4 ${p} ||`)
  for (const s of [
    "ts:C q q h ||",
    "ts:¢ h h |",
    "ts:12/8 3eee 3eee",
    "ts:?/4 q ? q",
    "q ~ q h~ h",
    "(e e q) (q@2 q@-3)",
    "tx:Andante_con_moto q q end:Fine",
    "dyn:mf q q q hair:<",
    "dyn:xyz q q hair:>",
    "hair:< q q q q q q",
    "t:÷2 = q + e",
    "#q b h. #e@2 bs@-1 q#x qbd",
    "q!>- qd!>- h^ w. e.!",
    "ess sse e.s ses ssss eee",
    "q@5 q@-5 qd@4 hd@6",
    "zz q ( )",
  ])
    set.add(s)
  return [...set]
}

export function cizim() {
  const notation = scores().map((score) => ({
    score,
    maxW: [undefined, 170, 220][score.length % 3],
    ...render(createElement(Notation, { score, maxW: [undefined, 170, 220][score.length % 3] })),
  }))
  const staffKeys = new Map<
    string,
    { clef: "treble" | "bass"; noteY: number; ledgerLines: number[]; accidental?: "sharp" | "flat" }
  >()
  for (const q of ALL_QUESTIONS)
    if (q.category === "note_identification" && q.noteY !== undefined)
      staffKeys.set(`${q.clef}:${q.noteY}:${q.accidental ?? ""}:${q.ledgerLines}`, {
        clef: q.clef!,
        noteY: q.noteY,
        ledgerLines: q.ledgerLines ?? [],
        accidental: q.accidental,
      })
  const staff = [...staffKeys.values()].flatMap((p, i) =>
    [false, true].map((showLabel) => ({
      ...p,
      showLabel,
      maxHeight: i % 5 === 0 ? 130 : undefined,
      ...render(createElement(MusicalStaff, { ...p, showLabel, maxHeight: i % 5 === 0 ? 130 : undefined })),
    })),
  )
  const chords = ALL_CHORDS.flatMap((c, i) =>
    [undefined, palette.violet500, palette.green500].map((color) => ({
      id: c.id,
      color: color ?? null,
      maxWidth: [undefined, 230, 280][i % 3],
      ...render(createElement(ChordStaffSvg, { chord: c, color, maxWidth: [undefined, 230, 280][i % 3] })),
    })),
  )
  const goal = []
  for (const g of [0, 1, 5, 10, 20, 30, 50])
    for (const done of [...new Set([0, 1, Math.floor(g / 3), g - 1, g, g + 3])].filter((d) => d >= 0))
      goal.push({ goal: g, done, ...render(createElement(GoalStaff, { goal: g, done })) })
  const clefIcons = (["treble", "bass"] as const).flatMap((clef) =>
    [20, 24, 32, 34].map((size) => {
      const markup = renderToStaticMarkup(createElement(ClefIcon, { clef, size }))
      const svg = parseXml(markup).children[0] as El
      return { clef, size, width: +svg.attrs.width, height: +svg.attrs.height, ...flatten(svg) }
    }),
  )
  // Çalışma kartlarındaki şema klavye: dersteki örnekler + iki oktav, siyah kök, atla, kemersiz
  const ki: { semis: number[]; color: string; names?: string[]; gaps?: boolean; skip?: number[]; octaves?: 1 | 2 }[] = [
    { semis: [0, 4, 7], color: palette.violet500, names: ["Do", "Mi", "Sol"] },
    { semis: [0, 3, 7], color: palette.red400, names: ["Do", "Mi♭", "Sol"] },
    { semis: [1, 5, 8], color: palette.blue400 },
    { semis: [0, 4, 7, 10, 14], color: palette.amber500 },
    { semis: [2, 6, 9], color: palette.green400, gaps: false },
    { semis: [0, 7], color: palette.cyan400, skip: [2, 4], octaves: 2 },
    { semis: [10, 14, 17], color: palette.pink500, names: ["Si♭", "Re", "Fa"], gaps: false, octaves: 2 },
    { semis: [3, 6, 10, 13], color: palette.violet400 },
  ]
  const keyIntervals = ki.map((p) => ({ ...p, names: p.names ?? null, ...render(createElement(KeyIntervals, p)) }))
  return { notation, staff, chords, goal, clefIcons, keyIntervals }
}
