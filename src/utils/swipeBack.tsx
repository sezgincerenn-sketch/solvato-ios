// Geri hareketi (iOS / Instagram gibi): ekranın sol kenarından sağa kaydırınca
// ekran parmakla birlikte kayar, altından bir önceki ekran görünür. Turlarda da kayar (revize R34): cevap verildiyse
// bırakınca ekran yerine oturur ve ✕'e basılır (onay açılır). Onay açıkken kaydırma "Devam et"e basar.
// Android'de telefonun geri tuşu da aynı geri düğmesine basar.
import { useEffect, useRef, useState } from "react"
import { flushSync } from "react-dom"
import { Capacitor } from "@capacitor/core"

import { alpha, palette } from "../design/tokens"
const EDGE = 28 // kenardan bu kadar içeride başlayan dokunuşlar
const TRIGGER = 80 // ok modunda tetikleme mesafesi
const ANIM = 220

export function visibleBack(root: HTMLElement | null): HTMLElement | null {
  if (!root) return null
  const els = Array.from(root.querySelectorAll<HTMLElement>("[data-back]"))
  for (let i = els.length - 1; i >= 0; i--) {
    const r = els[i].getBoundingClientRect()
    if (r.width > 0 && r.height > 0 && !(els[i] as HTMLButtonElement).disabled) return els[i]
  }
  return null
}

export function useSwipeBack<V>(opts: {
  root: React.RefObject<HTMLElement | null>
  top: React.RefObject<HTMLElement | null> // kayan katman (şu anki ekran)
  under: React.RefObject<HTMLElement | null> // alttaki katman (önceki ekran)
  getTarget: () => V | null // kaydırarak dönülebilecek ekran, yoksa null
  commit: (v: V) => void
  // Turlar (revize R34): bırakınca geri dönmek yerine ekran yerine oturup ekranın geri düğmesine (✕) basılsın mı.
  // Turda cevap verildiyse ✕ "Turdan çıkılsın mı?" onayını açar.
  confirmOnRelease?: () => boolean
}) {
  const [underlay, setUnderlay] = useState<V | null>(null)
  const [drag, setDrag] = useState(0) // ok modu göstergesi 0..1
  const o = useRef(opts)
  o.current = opts
  const st = useRef<{
    x: number
    y: number
    t: number
    lastX: number
    lastT: number
    mode: "" | "slide" | "arrow"
    target: V | null
  } | null>(null)
  const busy = useRef(false)

  const pressBack = () => {
    const b = visibleBack(o.current.root.current)
    if (b) {
      b.click()
      return true
    }
    return false
  }

  const paint = (dx: number, w: number, anim: boolean) => {
    const top = o.current.top.current
    const under = o.current.under.current
    const p = Math.max(0, Math.min(1, dx / w))
    const tr = anim ? `transform ${ANIM}ms cubic-bezier(0.2,0.8,0.2,1)` : "none"
    if (top) {
      top.style.transition = tr
      top.style.transform = dx > 0 ? `translateX(${dx}px)` : ""
      top.style.boxShadow = dx > 0 ? "-8px 0 24px rgba(0,0,0,0.25)" : ""
    }
    if (under) {
      under.style.transition = anim ? `transform ${ANIM}ms cubic-bezier(0.2,0.8,0.2,1)` : "none"
      under.style.transform = `translateX(${-30 * (1 - p)}%)`
      const dim = under.querySelector<HTMLElement>("[data-dim]")
      if (dim) {
        dim.style.transition = anim ? `opacity ${ANIM}ms` : "none"
        dim.style.opacity = String(0.35 * (1 - p))
      }
    }
  }
  const reset = () => {
    const top = o.current.top.current
    if (top) {
      top.style.transition = "none"
      top.style.transform = ""
      top.style.boxShadow = ""
    }
  }

  useEffect(() => {
    const el = opts.root.current
    if (!el) return
    const width = () => el.getBoundingClientRect().width

    const start = (e: TouchEvent) => {
      if (busy.current || e.touches.length !== 1) return
      const t = e.touches[0]
      if (t.clientX - el.getBoundingClientRect().left > EDGE) return
      if ((e.target as HTMLElement).closest("[data-no-swipe]")) return
      st.current = {
        x: t.clientX,
        y: t.clientY,
        t: e.timeStamp,
        lastX: t.clientX,
        lastT: e.timeStamp,
        mode: "",
        target: null,
      }
    }
    const move = (e: TouchEvent) => {
      const s = st.current
      if (!s) return
      const t = e.touches[0]
      const dx = t.clientX - s.x
      const dy = Math.abs(t.clientY - s.y)
      if (!s.mode) {
        if (dy > 14 && dy > dx) {
          st.current = null
          return
        }
        if (dx > 10) {
          const target = o.current.getTarget()
          s.target = target
          s.mode = target !== null ? "slide" : "arrow"
          if (target !== null) flushSync(() => setUnderlay(target))
        }
      }
      if (s.mode === "slide") {
        if (e.cancelable) e.preventDefault()
        paint(Math.max(0, dx), width(), false)
      } else if (s.mode === "arrow") setDrag(Math.max(0, Math.min(1, dx / TRIGGER)))
      s.lastX = t.clientX
      s.lastT = e.timeStamp
    }
    const end = (e: TouchEvent) => {
      const s = st.current
      st.current = null
      if (!s || !s.mode) return
      const t = e.changedTouches[0]
      const dx = t.clientX - s.x
      const dy = Math.abs(t.clientY - s.y)
      if (s.mode === "arrow") {
        setDrag(0)
        if (dx >= TRIGGER && dy < dx * 0.7) pressBack()
        return
      }
      const w = width()
      const v = (t.clientX - s.lastX) / Math.max(1, e.timeStamp - s.lastT) // px/ms
      const go = dx > w * 0.35 || (v > 0.4 && dx > 40)
      busy.current = true
      if (go && o.current.confirmOnRelease?.()) {
        paint(0, w, true)
        setTimeout(() => {
          reset()
          setUnderlay(null)
          busy.current = false
          pressBack()
        }, ANIM)
      } else if (go) {
        paint(w, w, true)
        setTimeout(() => {
          flushSync(() => {
            o.current.commit(s.target as V)
            setUnderlay(null)
          })
          reset()
          busy.current = false
        }, ANIM)
      } else {
        paint(0, w, true)
        setTimeout(() => {
          reset()
          setUnderlay(null)
          busy.current = false
        }, ANIM)
      }
    }
    const cancel = () => {
      const s = st.current
      st.current = null
      setDrag(0)
      if (s?.mode === "slide") {
        paint(0, width(), true)
        setTimeout(() => {
          reset()
          setUnderlay(null)
        }, ANIM)
      }
    }
    el.addEventListener("touchstart", start, { passive: true })
    el.addEventListener("touchmove", move, { passive: false })
    el.addEventListener("touchend", end)
    el.addEventListener("touchcancel", cancel)
    return () => {
      el.removeEventListener("touchstart", start)
      el.removeEventListener("touchmove", move)
      el.removeEventListener("touchend", end)
      el.removeEventListener("touchcancel", cancel)
    }
  }, [opts.root])

  // Android geri tuşu
  useEffect(() => {
    if (Capacitor.getPlatform() !== "android") return
    let remove: (() => void) | undefined
    import("@capacitor/app").then(({ App }) => {
      App.addListener("backButton", () => {
        if (pressBack()) return
        const target = o.current.getTarget()
        if (target !== null) o.current.commit(target)
        else App.minimizeApp()
      }).then((h) => (remove = () => h.remove()))
    })
    return () => remove?.()
  }, [])

  return { underlay, drag }
}

// Kayamayan ekranlarda sol kenarda büyüyen ok
export function SwipeBackIndicator({ drag }: { drag: number }) {
  if (drag <= 0) return null
  const ready = drag >= 1
  const size = 44
  return (
    <div
      aria-hidden="true"
      style={{
        position: "absolute",
        left: -size / 2 + drag * (size / 2 + 6),
        top: "50%",
        transform: `translateY(-50%) scale(${0.6 + drag * 0.4})`,
        width: size,
        height: size,
        borderRadius: "50%",
        background: ready ? palette.violet600 : alpha(palette.violet600, 0.35),
        color: palette.white,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 200,
        pointerEvents: "none",
        boxShadow: ready ? "0 4px 16px rgba(124,58,237,0.5)" : "none",
        transition: "background 0.12s",
      }}
    >
      <svg
        width={20}
        height={20}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth={2.5}
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M15 18l-6-6 6-6" />
      </svg>
    </div>
  )
}
