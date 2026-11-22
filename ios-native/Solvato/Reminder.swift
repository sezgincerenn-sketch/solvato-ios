// Günlük hatırlatma bildirimi (web src/utils/reminder.ts): her gün seçilen saatte yerel bildirim. Sunucu yok, ağ yok;
// izin istenir, verilmezse kapalı kalır. Aynı kimlikle (1001) yeniden planlanır.
import UserNotifications

enum Reminder {
    static let id = "1001"

    /// İzin verildiyse planlar ve true döner
    static func enable(hour: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) == true else { return false }
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.title = "Piyano zamanı 🎹"
        content.body = "Serini kaybetme: bugün 5 dakika nota çalış."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: 0), repeats: true)
        do {
            try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            return true
        } catch {
            return false
        }
    }

    static func disable() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
