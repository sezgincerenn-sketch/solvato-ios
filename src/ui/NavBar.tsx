// Alt menü (revize R13): yüzen kapsül, dört sekme — Ana sayfa · İlerleme · Öğren · Profil.
// Kapsül ekranın altında kenarlardan ayrık durur; seçili sekme mor zeminli.
import { alpha, colors, font, palette, radius, space } from "../design/tokens"
import type { NavTab } from "../types"

function NavIcon({ tab, col }: { tab: NavTab; col: string }) {
  const common = {
    width: 22,
    height: 22,
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: col,
    strokeWidth: 2,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
    "aria-hidden": true,
  }
  if (tab === "home")
    return (
      <svg {...common}>
        <path d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z" />
      </svg>
    )
  if (tab === "dashboard")
    return (
      <svg {...common}>
        <path d="M5 20V12M10 20V8M15 20v-5M20 20V5" />
      </svg>
    )
  if (tab === "study")
    return (
      <svg {...common}>
        <path d="M4 5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2z" />
        <path d="M4 19V5" />
      </svg>
    )
  return (
    <svg {...common}>
      <circle cx="12" cy="8" r="4" />
      <path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6" />
    </svg>
  )
}

export default function NavBar({ active, onChange }: { active: NavTab; onChange: (t: NavTab) => void }) {
  const tabs: { key: NavTab; label: string }[] = [
    { key: "home", label: "Ana sayfa" },
    { key: "dashboard", label: "İlerleme" },
    { key: "study", label: "Öğren" },
    { key: "profile", label: "Profil" },
  ]

  return (
    <div
      style={{
        flexShrink: 0,
        padding: `${space[2]}px ${space[4]}px calc(${space[3]}px + env(safe-area-inset-bottom, 0px))`,
        background: colors.bg,
      }}
    >
      <nav
        data-coach="nav"
        aria-label="Alt menü"
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(4, minmax(0, 1fr))",
          gap: space[1],
          padding: 6,
          borderRadius: radius.pill,
          background: colors.overlay,
          border: `1px solid ${colors.borderStrong}`,
          boxShadow: "0 12px 32px rgba(0,0,0,0.35)",
          backdropFilter: "blur(20px)",
          WebkitBackdropFilter: "blur(20px)",
        }}
      >
        {tabs.map((t) => {
          const isActive = active === t.key
          const col = isActive ? colors.violetText : colors.textMuted
          return (
            <button
              key={t.key}
              onClick={() => onChange(t.key)}
              aria-current={isActive ? "page" : undefined}
              style={{
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                gap: 2,
                minHeight: 52,
                borderRadius: radius.pill,
                background: isActive ? alpha(palette.violet500, 0.2) : "none",
                border: "none",
                cursor: "pointer",
                transition: "background 150ms",
              }}
            >
              <NavIcon tab={t.key} col={col} />
              <span
                style={{
                  fontSize: font.size.xs,
                  fontWeight: isActive ? font.weight.bold : font.weight.semibold,
                  color: col,
                  fontFamily: font.family.ui,
                }}
              >
                {t.label}
              </span>
            </button>
          )
        })}
      </nav>
    </div>
  )
}
