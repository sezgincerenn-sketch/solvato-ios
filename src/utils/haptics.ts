// Titreşim geri bildirimi (ayarlardan kapatılabilir).
import { Capacitor } from "@capacitor/core"
import { Haptics, ImpactStyle, NotificationType } from "@capacitor/haptics"
import { getSettings } from "./settings"

function ok() {
  return getSettings().haptics && Capacitor.isNativePlatform()
}

export function hapticTap() {
  if (!ok()) return
  Haptics.impact({ style: ImpactStyle.Light }).catch(() => {})
}
/** Ritmi Tut dokunuşu: daha güçlü titreşim (revize R22) */
export function hapticTapStrong() {
  if (!ok()) return
  Haptics.impact({ style: ImpactStyle.Medium }).catch(() => {})
}
export function hapticSuccess() {
  if (!ok()) return
  Haptics.notification({ type: NotificationType.Success }).catch(() => {})
}
export function hapticError() {
  if (!ok()) return
  Haptics.notification({ type: NotificationType.Error }).catch(() => {})
}
