// Ayarlar: profil, çalışma (hedef, seviye, anahtar, giriş), ses/titreşim, görünüm, daha fazla ayar.
import NotesPicker, { notesSummary } from "../components/NotesPicker"
import { Segmented } from "../ui"
import { ScreenHeader, TimeField } from "../ui"
import { useState } from "react"
import { updateSettings, useSettings } from "../utils/settings"
import { enableReminder, disableReminder } from "../utils/reminder"

import { alpha, colors, font, palette, radius } from "../design/tokens"
export type ThemeMode = "system" | "dark" | "light"

function Row({ title, sub, on, onToggle }: { title: string; sub?: string; on: boolean; onToggle: () => void }) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 12,
        padding: "14px 0",
        borderBottom: `1px solid ${colors.border}`,
      }}
    >
      <div style={{ flex: 1 }}>
        <p style={{ fontSize: font.size.md, fontWeight: font.weight.semibold, color: colors.text }}>{title}</p>
        {sub && <p style={{ fontSize: font.size.sm, color: colors.textMuted, marginTop: 2, lineHeight: 1.4 }}>{sub}</p>}
      </div>
      <button
        role="switch"
        aria-checked={on}
        aria-label={title}
        onClick={onToggle}
        style={{
          width: 52,
          height: 32,
          borderRadius: radius.pill,
          background: on ? palette.violet600 : colors.fillStronger,
          border: "none",
          position: "relative",
          flexShrink: 0,
          transition: "background 0.18s",
          cursor: "pointer",
        }}
      >
        <span
          style={{
            position: "absolute",
            top: 3,
            left: on ? 23 : 3,
            width: 26,
            height: 26,
            borderRadius: "50%",
            background: palette.white,
            transition: "left 0.18s",
          }}
        />
      </button>
    </div>
  )
}

const GOAL_TEXT: Record<number, string> = {
  10: "Günde 10 soru: rahat tempo.",
  20: "Günde 20 soru: düzenli çalışma.",
  30: "Günde 30 soru: hızlı ilerleme.",
  50: "Günde 50 soru: yoğun tempo.",
}

function Section({ children }: { children: React.ReactNode }) {
  return (
    <p
      style={{
        fontSize: font.size.xs,
        fontWeight: font.weight.bold,
        letterSpacing: "0.08em",
        textTransform: "uppercase",
        color: colors.violetText,
        margin: "26px 0 2px",
      }}
    >
      {children}
    </p>
  )
}

function Block({ title, sub, children }: { title: string; sub?: string; children: React.ReactNode }) {
  return (
    <div style={{ padding: "14px 0 16px", borderBottom: `1px solid ${colors.border}` }}>
      <p
        style={{
          fontSize: font.size.md,
          fontWeight: font.weight.semibold,
          color: colors.text,
          marginBottom: sub ? 2 : 10,
        }}
      >
        {title}
      </p>
      {sub && (
        <p style={{ fontSize: font.size.sm, color: colors.textMuted, lineHeight: 1.4, marginBottom: 10 }}>{sub}</p>
      )}
      {children}
    </div>
  )
}

// Başka ekrana götüren satır (› ile)
function LinkRow({ title, sub, onClick }: { title: string; sub?: string; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      style={{
        display: "flex",
        alignItems: "center",
        gap: 12,
        width: "100%",
        textAlign: "left",
        padding: "14px 0",
        background: "none",
        border: "none",
        borderBottom: `1px solid ${colors.border}`,
        cursor: "pointer",
        fontFamily: font.family.ui,
      }}
    >
      <span style={{ flex: 1 }}>
        <span
          style={{ display: "block", fontSize: font.size.md, fontWeight: font.weight.semibold, color: colors.text }}
        >
          {title}
        </span>
        {sub && (
          <span
            style={{ display: "block", fontSize: font.size.sm, color: colors.textMuted, marginTop: 2, lineHeight: 1.4 }}
          >
            {sub}
          </span>
        )}
      </span>
      <span aria-hidden="true" style={{ color: colors.textMuted, fontSize: font.size.lg }}>
        ›
      </span>
    </button>
  )
}

export default function SettingsScreen({
  themeMode,
  onThemeMode,
  onBack,
  onReset,
  onShowTutorial,
  onOpenPrivacy,
  onOpenLicenses,
}: {
  themeMode: ThemeMode
  onThemeMode: (m: ThemeMode) => void
  onBack: () => void
  onReset: () => void
  onShowTutorial: () => void
  onOpenPrivacy: () => void
  onOpenLicenses: () => void
}) {
  const s = useSettings()
  const [reminderMsg, setReminderMsg] = useState("")
  const [confirmReset, setConfirmReset] = useState(false)

  async function toggleReminder() {
    if (s.reminder) {
      await disableReminder()
      updateSettings({ reminder: false })
      setReminderMsg("")
      return
    }
    const ok = await enableReminder(s.reminderHour, s.reminderMinute)
    if (ok) {
      updateSettings({ reminder: true })
      setReminderMsg("")
    } else {
      setReminderMsg("Bildirim izni verilmedi. iPhone Ayarlar → Solvato → Bildirimler bölümünden açabilirsin.")
    }
  }

  async function changeTime(h: number, m: number) {
    updateSettings({ reminderHour: h, reminderMinute: m })
    if (s.reminder) await enableReminder(h, m)
  }

  return (
    <div
      style={{
        height: "100%",
        overflowY: "auto",
        background: colors.bg,
        fontFamily: font.family.ui,
        scrollbarWidth: "none",
      }}
    >
      <ScreenHeader title="Ayarlar" onBack={onBack} />

      <div style={{ padding: "0 20px 32px" }}>
        <Section>Çalışma</Section>
        <Block title="Günlük hedef" sub={GOAL_TEXT[s.dailyGoal] ?? ""}>
          <Segmented
            value={s.dailyGoal}
            options={[
              [10, "10"],
              [20, "20"],
              [30, "30"],
              [50, "50"],
            ]}
            onChange={(g) => updateSettings({ dailyGoal: g })}
          />
        </Block>
        <Block
          title="Seviye"
          sub={
            s.level < 3
              ? `Sonraki seviyeye: ${s.levelProgress.n}/50 soru${s.levelProgress.n > 0 ? ` · %${Math.round((s.levelProgress.c / s.levelProgress.n) * 100)} doğru` : ""}`
              : "Tüm sorular açık."
          }
        >
          <Segmented
            value={s.level}
            options={[
              [1, "Başlangıç"],
              [2, "Orta"],
              [3, "İleri"],
            ]}
            onChange={(v) => updateSettings({ level: v, levelProgress: { n: 0, c: 0 } })}
          />
        </Block>
        <Block title="Anahtar">
          <Segmented
            value={s.clef}
            options={[
              ["treble", "Sol"],
              ["bass", "Fa"],
              ["both", "İkisi de"],
            ]}
            onChange={(v) => updateSettings({ clef: v })}
          />
        </Block>

        <Block title="Çalışılacak notalar" sub={notesSummary(s.notes)}>
          <NotesPicker value={s.notes} onChange={(notes) => updateSettings({ notes })} />
        </Block>

        <Section>Soru ekranı</Section>
        <Block title="Cevap yöntemi">
          <Segmented
            value={s.inputMode}
            options={[
              ["piano", "Klavye"],
              ["choice", "Şıklar"],
            ]}
            onChange={(v) => updateSettings({ inputMode: v })}
          />
        </Block>
        <Row
          title="Tuş isimlerini göster"
          on={s.keyLabels}
          onToggle={() => updateSettings({ keyLabels: !s.keyLabels })}
        />
        <Row
          title="Zaman yarışı"
          sub="Her soru için süre verilir."
          on={s.timer}
          onToggle={() => updateSettings({ timer: !s.timer })}
        />

        <Section>Ses ve görünüm</Section>
        <Row
          title="Ses"
          sub="Telefon sessiz moddayken de çalar."
          on={s.soundKeys}
          onToggle={() => updateSettings({ soundKeys: !s.soundKeys })}
        />
        <Row title="Titreşim" on={s.haptics} onToggle={() => updateSettings({ haptics: !s.haptics })} />
        <Block title="Tema">
          <Segmented
            value={themeMode}
            options={[
              ["system", "Sistem"],
              ["dark", "Koyu"],
              ["light", "Açık"],
            ]}
            onChange={(m) => onThemeMode(m)}
          />
        </Block>

        <Section>Hatırlatma</Section>
        <Row
          title="Günlük hatırlatma"
          sub={
            s.reminder
              ? `Her gün ${String(s.reminderHour).padStart(2, "0")}:${String(s.reminderMinute).padStart(2, "0")}'de`
              : undefined
          }
          on={s.reminder}
          onToggle={toggleReminder}
        />
        {reminderMsg && (
          <p style={{ fontSize: font.size.sm, color: colors.redText, padding: "8px 0", lineHeight: 1.4 }}>
            {reminderMsg}
          </p>
        )}
        {s.reminder && (
          <div style={{ padding: "12px 0" }}>
            <TimeField hour={s.reminderHour} minute={s.reminderMinute} onChange={changeTime} />
          </div>
        )}

        <button
          onClick={onShowTutorial}
          style={{
            width: "100%",
            marginTop: 20,
            padding: 14,
            borderRadius: radius.md,
            fontSize: font.size.md,
            fontWeight: font.weight.semibold,
            cursor: "pointer",
            background: colors.fill,
            color: colors.textSecondary,
            border: `1px solid ${colors.border}`,
          }}
        >
          Tanıtımı tekrar göster
        </button>

        <div style={{ marginTop: 14 }}>
          {!confirmReset ? (
            <button
              onClick={() => setConfirmReset(true)}
              style={{
                width: "100%",
                padding: 14,
                borderRadius: radius.md,
                fontSize: font.size.md,
                fontWeight: font.weight.semibold,
                cursor: "pointer",
                background: alpha(palette.red500, 0.1),
                color: colors.redText,
                border: "1px solid rgba(239,68,68,0.25)",
              }}
            >
              İlerlemeyi sıfırla
            </button>
          ) : (
            <div
              style={{
                padding: 14,
                borderRadius: radius.md,
                background: alpha(palette.red500, 0.08),
                border: "1px solid rgba(239,68,68,0.25)",
              }}
            >
              <p style={{ fontSize: font.size.md, color: colors.redText, marginBottom: 12, lineHeight: 1.4 }}>
                XP, seri ve tüm istatistiklerin silinecek. Bu geri alınamaz.
              </p>
              <div style={{ display: "flex", gap: 10 }}>
                <button
                  onClick={() => setConfirmReset(false)}
                  style={{
                    flex: 1,
                    padding: 12,
                    borderRadius: radius.md,
                    fontSize: font.size.sm,
                    fontWeight: font.weight.bold,
                    background: colors.fillStrong,
                    color: colors.textSecondary,
                    border: `1px solid ${colors.border}`,
                    cursor: "pointer",
                  }}
                >
                  Vazgeç
                </button>
                <button
                  onClick={() => {
                    setConfirmReset(false)
                    onReset()
                  }}
                  style={{
                    flex: 1,
                    padding: 12,
                    borderRadius: radius.md,
                    fontSize: font.size.sm,
                    fontWeight: font.weight.bold,
                    background: palette.red600,
                    color: palette.white,
                    border: "none",
                    cursor: "pointer",
                  }}
                >
                  Sıfırla
                </button>
              </div>
            </div>
          )}
        </div>

        <Section>Hakkında</Section>
        <LinkRow title="Gizlilik" sub="Veri toplanmaz, her şey bu cihazda" onClick={onOpenPrivacy} />
        <LinkRow title="Lisanslar" sub="Kullanılan yazı tipleri ve açık kaynak yazılımlar" onClick={onOpenLicenses} />

        <p style={{ fontSize: font.size.sm, color: colors.textSubtle, textAlign: "center", marginTop: 28 }}>
          Sürüm 1.0
        </p>
      </div>
    </div>
  )
}
