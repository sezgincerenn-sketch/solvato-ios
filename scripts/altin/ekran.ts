// Ekran metinleri altın tablosu: React ekranlarını farklı durumlarda (ayar, istatistik, saat) HTML'e döker ve ekranda
// görünen yazıları sırasıyla, düğmelerin erişilebilirlik adlarıyla birlikte çıkarır. Native ekran içeriği
// (SolvatoCore/App/*Content) aynı sırayla aynı yazıları üretmeli. uret.ts çağırır; NOW ve ayarlar oradan.
import { createElement } from "react"
import { renderToStaticMarkup } from "react-dom/server"
import HomeScreen from "../../src/screens/HomeScreen"
import type { AppStats } from "../../src/types"

const decode = (s: string) =>
  s
    .replace(/&#x27;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&")

/** Görünen yazılar (svg içi hariç) ve aria-label'lar, belge sırasıyla */
export function screenTexts(html: string) {
  const clean = html.replace(/<!-- -->/g, "").replace(/<svg[\s\S]*?<\/svg>/g, "")
  const texts: string[] = []
  const labels: string[] = []
  for (const m of clean.matchAll(/<([^>]+)>|([^<]+)/g)) {
    if (m[1]) {
      const a = m[1].match(/aria-label="([^"]*)"/)
      if (a) labels.push(decode(a[1]))
    } else {
      const t = decode(m[2]).trim()
      if (t) texts.push(t)
    }
  }
  return { texts, labels }
}

export function home(stats: AppStats, dailyGoal: number) {
  const html = renderToStaticMarkup(
    createElement(HomeScreen, {
      stats,
      dailyGoal,
      onStart: () => {},
      onChordQuiz: () => {},
      onRhythmTap: () => {},
      onGames: () => {},
      onOpenProfile: () => {},
      onOpenProgress: () => {},
    }),
  )
  return screenTexts(html)
}
