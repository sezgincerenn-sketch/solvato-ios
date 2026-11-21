// Piyano altın tablosu: React klavyelerini (QuizPiano, MultiPiano) sunucu tarafında HTML'e döker, her tuşu
// (konum, durum rengi, kenarlık, gölge, yazı) düz bir listeye çevirir. Ayrıca her nota sorusunun klavyedeki tam yeri
// ve klavyenin başlangıç oktavı (QuizSession.tsx). Native yerleşim (SolvatoCore/Piano) aynısını üretmeli.
import { createElement } from "react"
import { renderToStaticMarkup } from "react-dom/server"
import { QuizPiano } from "../../src/components/piano/QuizPiano"
import { MultiPiano, litKeys } from "../../src/components/piano/MultiPiano"
import { noteKeyOf } from "../../src/screens/QuizSession"
import { ALL_QUESTIONS } from "../../src/data/questions"
import { ALL_CHORDS } from "../../src/data/chords"

const hex2 = (n: number) => n.toString(16).padStart(2, "0").toUpperCase()
function color(v: string): string {
  const t = v.trim()
  if (t === "transparent") return "transparent"
  let m = t.match(/^#([0-9a-f]{6})([0-9a-f]{2})?$/i)
  if (m) return `#${m[1].toUpperCase()}${(m[2] ?? "FF").toUpperCase()}`
  m = t.match(/^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)$/)
  if (m) return `#${hex2(+m[1])}${hex2(+m[2])}${hex2(+m[3])}${hex2(Math.round((m[4] === undefined ? 1 : +m[4]) * 255))}`
  return `?${t}`
}
const decode = (s: string) =>
  s
    .replace(/&#x27;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")

function style(s: string | undefined) {
  const out: Record<string, string> = {}
  // gradyan içindeki virgüller ve noktalı virgül yok; ";" ile bölmek yeter
  for (const part of decode(s ?? "").split(";")) {
    const i = part.indexOf(":")
    if (i > 0) out[part.slice(0, i).trim()] = part.slice(i + 1).trim()
  }
  return out
}

/** "0 0 16px #10B981B3, inset 0 -4px 0 rgba(0,0,0,0.15)" → yapı */
function shadows(v: string | undefined) {
  if (!v) return []
  return v.split(/,(?![^(]*\))/).map((s) => {
    const parts = s.trim().match(/(rgba?\([^)]*\)|#[0-9a-fA-F]+|inset|-?[\d.]+(?:px)?)/g)!
    const inset = parts[0] === "inset"
    const nums = parts.filter((p) => /^-?[\d.]+(px)?$/.test(p)).map((p) => parseFloat(p))
    const c = parts.find((p) => p.startsWith("#") || p.startsWith("rgb"))!
    return { inset, x: nums[0], y: nums[1], blur: nums[2] ?? 0, color: color(c) }
  })
}

function look(st: Record<string, string>) {
  const g = st.background.match(/^linear-gradient\(180deg, ([^ ,]+)(?: 0%)?, ([^ ,]+)(?: 100%)?\)$/)!
  const border = st["border-color"] ?? st.border.replace(/^1px solid /, "")
  return { top: color(g[1]), bottom: color(g[2]), border: color(border), shadows: shadows(st["box-shadow"]) }
}

type Tag = { tag: string; attrs: Record<string, string>; inner: string }
/** Düz HTML'deki <button> öğeleri (iç içe button yok) */
function buttons(html: string): Tag[] {
  const out: Tag[] = []
  for (const m of html.matchAll(/<button((?:\s+[\w:-]+(?:="[^"]*")?)*)\s*>([\s\S]*?)<\/button>/g)) {
    const attrs: Record<string, string> = {}
    for (const a of m[1].matchAll(/([\w:-]+)(?:="([^"]*)")?/g)) attrs[a[1]] = decode(a[2] ?? "")
    out.push({ tag: "button", attrs, inner: m[2] })
  }
  return out
}

function spans(inner: string) {
  return [...inner.matchAll(/<span style="([^"]*)">([\s\S]*?)<\/span>/g)].map((m) => {
    const st = style(m[1])
    return {
      text: decode(m[2].replace(/<br\/>/g, "\n")),
      size: parseFloat(st["font-size"]),
      weight: +(st["font-weight"] ?? 400),
      color: color(st.color),
    }
  })
}

function keys(html: string) {
  return buttons(html).map((b) => {
    const st = style(b.attrs.style)
    const black = st.position === "absolute"
    return {
      black,
      aria: b.attrs["aria-label"] ?? null,
      disabled: "disabled" in b.attrs,
      left: black ? parseFloat(st.left) : null,
      width: black ? parseFloat(st.width) : null,
      ...look(st),
      labels: spans(b.inner),
      dot: b.inner.includes("<div"),
    }
  })
}

export function piyano() {
  // Her nota sorusunun klavyedeki yeri ve klavye penceresi (QuizSession.tsx 157–166 satırlarının kopyası)
  const notes = ALL_QUESTIONS.filter((q) => q.category === "note_identification").map((q) => {
    const target = noteKeyOf(q)
    const windows = [1, 2, 3].map((kbOctaves) => {
      const octaveMode = kbOctaves >= 2
      let kbStart = q.clef === "bass" ? 2 : kbOctaves >= 3 ? 3 : 4
      if (target) {
        if (target.octave < kbStart) kbStart = target.octave
        else if (target.octave > kbStart + kbOctaves - 1) kbStart = target.octave - kbOctaves + 1
      }
      if (!octaveMode) kbStart = 4
      return { kbOctaves, octaveMode, kbStart }
    })
    return { id: q.id, target, windows }
  })

  const quiz = []
  const answers = ["pending", "correct", "wrong"] as const
  let i = 0
  for (const octaves of [1, 2, 3])
    for (const startOctave of octaves === 1 ? [undefined, 4] : [2, 3, 4])
      for (const octaveMode of octaves === 1 ? [false] : [true, false])
        for (const answerState of answers)
          for (const showLabels of [false, true]) {
            i++
            const pick = (a: string[]) => a[i % a.length]
            const sel = octaveMode
              ? pick(["Do4", "Mi3", "Sol#4", "La5", "Fa2"])
              : pick(["Do", "Mi", "Sol#", "La#", "Si"])
            const cor = octaveMode ? pick(["Re4", "Do4", "Fa#3", "Si5"]) : pick(["Re", "Do#", "Mi", "Si"])
            const props = {
              onAnswer: () => {},
              octaves,
              startOctave,
              octaveMode,
              answerState,
              showLabels,
              selectedNote: answerState === "pending" ? undefined : sel,
              correctAnswer: cor,
              hintNote: i % 4 === 0 ? (octaveMode ? "Do4" : "Do") : undefined,
              tall: i % 2 === 0,
            }
            const html = renderToStaticMarkup(createElement(QuizPiano, props))
            const outer = style(html.match(/^<div[^>]*style="([^"]*)"/)![1])
            quiz.push({ props: { ...props, onAnswer: undefined }, height: outer.height, keys: keys(html) })
          }

  const multi = []
  const chords = [ALL_CHORDS[0], ALL_CHORDS[16], ALL_CHORDS[40], ALL_CHORDS[90]]
  for (const c of chords)
    for (const mode of ["lit", "select", "result", "resultWrong"] as const) {
      const selected = new Set(mode === "resultWrong" ? ["Do", "Re", c.keys[1]] : mode === "lit" ? [] : c.keys)
      const props = {
        selected,
        onToggle: () => {},
        disabled: mode === "lit" || mode.startsWith("result"),
        correctKeys: mode.startsWith("result") ? c.keys : [],
        showResult: mode.startsWith("result"),
        lit: mode === "lit" ? litKeys(c) : undefined,
      }
      const html = renderToStaticMarkup(createElement(MultiPiano, props))
      const markers = [...html.matchAll(/<div style="flex:7[^"]*">([^<]*)<\/div>/g)].map((m) => m[1])
      multi.push({
        chord: c.id,
        mode,
        selected: [...selected],
        lit: props.lit ? [...props.lit] : null,
        correctKeys: props.correctKeys,
        disabled: props.disabled,
        showResult: props.showResult,
        markers,
        keys: keys(html),
      })
    }
  return { notes, quiz, multi }
}
