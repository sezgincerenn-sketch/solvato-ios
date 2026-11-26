// Kullanıcı ayarları (ses, titreşim, hatırlatma, ilk açılış, quiz giriş modu)
// localStorage'a yazılır; persist.ts bu anahtarları cihaz depolamasına da kopyalar.
import { useSyncExternalStore } from "react"

export const SETTINGS_KEY = "pianote_settings_v1"

export interface Settings {
  soundKeys: boolean // tüm sesler (tuş, doğru/yanlış, kutlama)
  // Nota sorularında çıkacak notalar (öğretmen önerisi: ör. bir süre sadece Do Re Mi). Varsayılan: hepsi.
  notes: string[]
  timer: boolean // zaman yarışı: soru başına süre
  haptics: boolean
  reminder: boolean
  reminderHour: number
  onboarded: boolean
  inputMode: "piano" | "choice"
  keyLabels: boolean // piyano tuşlarında nota adları görünsün
  dailyGoal: number // günde çözülecek soru
  level: 1 | 2 | 3 // soru seviyesi: Başlangıç / Orta / İleri
  clef: "treble" | "bass" | "both" // karışık turlarda hangi anahtar
  // Mevcut seviyede çözülen ve doğru bilinen soru sayısı (seviye atlamak için)
  levelProgress: { n: number; c: number }
  name: string // isteğe bağlı, karşılama için
  avatarColor: string // profil rengi (palet adı: violet, blue, green, amber, pink, cyan)
  joinedAt: string // ilk açılış (YYYY-MM-DD)
  coachDone: boolean // ana sayfa tanıtımı gösterildi
  teacherCode: string // son uygulanan öğretmen kodu (utils/teacherCode.ts), yoksa ""
  topics: string[] // öğretmenin seçtiği konular (TOPICS); boş = hepsi
  showRestTopics: boolean // öğretmen kodu varken diğer konular da Ana sayfada açık (revize R20)
  reminderMinute: number // hatırlatma dakikası (revize R9: saat seçici)
  teacherRole: "" | "student" | "self" | "teacher" // tanıtımdaki öğretmen sorusu (revize R5)
  startChecklistDone: boolean // İlerleme'deki başlangıç listesi bitti, bir daha gösterilmez (revize R7)
  streakReminderOffered: boolean // ilk seri gününde "Serini koru" kartı bir kez gösterildi (revize R8)
}

export const ALL_NOTES = ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si"]

const DEFAULTS: Settings = {
  soundKeys: true,
  notes: ALL_NOTES,
  timer: false,
  haptics: true,
  reminder: false,
  reminderHour: 20,
  onboarded: false,
  inputMode: "piano",
  keyLabels: false,
  dailyGoal: 10,
  level: 1,
  clef: "both",
  levelProgress: { n: 0, c: 0 },
  name: "",
  avatarColor: "violet",
  joinedAt: "",
  coachDone: false,
  teacherCode: "",
  topics: [],
  showRestTopics: false,
  startChecklistDone: false,
  streakReminderOffered: false,
  reminderMinute: 0,
  teacherRole: "",
}

let cache: Settings | null = null
const listeners = new Set<() => void>()

export function getSettings(): Settings {
  if (cache) return cache
  try {
    const raw = localStorage.getItem(SETTINGS_KEY)
    const saved = raw ? JSON.parse(raw) : {}
    // Eski tek 'sound' ayarını iki yeni ayara taşı
    if (typeof saved.sound === "boolean") {
      saved.soundKeys ??= saved.sound
      saved.soundFx ??= saved.sound
      delete saved.sound
    }
    cache = { ...DEFAULTS, ...saved }
  } catch {
    cache = { ...DEFAULTS }
  }
  return cache!
}

export function updateSettings(patch: Partial<Settings>) {
  cache = { ...getSettings(), ...patch }
  try {
    localStorage.setItem(SETTINGS_KEY, JSON.stringify(cache))
  } catch {
    /* yoksay */
  }
  listeners.forEach((l) => l())
}

export function subscribeSettings(fn: () => void) {
  listeners.add(fn)
  return () => {
    listeners.delete(fn)
  }
}

export function effectiveChordLevel(s: Settings = getSettings()): 1 | 2 | 3 | 4 {
  return Math.min(s.level, 3) as 1 | 2 | 3
}

/** Ayarları okuyan ve değişince yeniden çizen hook */
export function useSettings(): Settings {
  return useSyncExternalStore(subscribeSettings, getSettings)
}
