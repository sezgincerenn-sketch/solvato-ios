// Günlük hatırlatma bildirimi.
import { Capacitor } from "@capacitor/core"
import { LocalNotifications } from "@capacitor/local-notifications"

const ID = 1001

// Her gün seçilen saatte yerel bildirim planlar. Web'de hiçbir şey yapmaz.
export async function enableReminder(hour: number, minute = 0): Promise<boolean> {
  if (!Capacitor.isNativePlatform()) return false
  try {
    const perm = await LocalNotifications.requestPermissions()
    if (perm.display !== "granted") return false
    await LocalNotifications.cancel({ notifications: [{ id: ID }] })
    await LocalNotifications.schedule({
      notifications: [
        {
          id: ID,
          title: "Piyano zamanı 🎹",
          body: "Serini kaybetme: bugün 5 dakika nota çalış.",
          schedule: { on: { hour, minute }, allowWhileIdle: true },
        },
      ],
    })
    return true
  } catch {
    return false
  }
}

export async function disableReminder() {
  if (!Capacitor.isNativePlatform()) return
  try {
    await LocalNotifications.cancel({ notifications: [{ id: ID }] })
  } catch {
    /* yoksay */
  }
}

/** "19:00'da", "07:45'te", "20:00'de": saat ve okunuşuna uyan bulunma eki (dakika sıfırsa saat, değilse dakika) */
export function timeText(hour: number, minute: number): string {
  const p = (n: number) => String(n).padStart(2, "0")
  const n = minute === 0 ? hour : minute
  const ones = ["da", "de", "de", "te", "te", "te", "da", "de", "de", "da"] // sıfır bir iki üç dört beş altı yedi sekiz dokuz
  const tens = ["da", "da", "de", "da", "ta", "de"] // sıfır on yirmi otuz kırk elli
  return `${p(hour)}:${p(minute)}'${n % 10 !== 0 ? ones[n % 10] : tens[Math.floor(n / 10) % 6]}`
}
