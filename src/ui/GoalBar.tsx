// Bugün kartındaki günlük hedef çubuğu (revize R18): 10 bölme, her bölme hedefin onda biri.
// Portedeki notalar yerine; "bu notaları çalışacağız" gibi okunmasın diye nota yüksekliği yok.
import { colors, palette, radius } from "../design/tokens"

export default function GoalBar({ done, goal }: { done: number; goal: number }) {
  const filled = goal > 0 ? Math.min(10, Math.floor((Math.min(done, goal) * 10) / goal)) : 0
  return (
    <div
      role="img"
      aria-label={`${goal} soruluk hedefin ${Math.min(done, goal)} sorusu çözüldü`}
      style={{ display: "grid", gridTemplateColumns: "repeat(10, minmax(0, 1fr))", gap: 4 }}
    >
      {Array.from({ length: 10 }, (_, i) => (
        <span
          key={i}
          style={{
            height: 10,
            borderRadius: radius.xs,
            background: i < filled ? (done >= goal ? palette.green500 : palette.violet500) : colors.fillStronger,
            transition: "background 0.3s ease",
          }}
        />
      ))}
    </div>
  )
}
