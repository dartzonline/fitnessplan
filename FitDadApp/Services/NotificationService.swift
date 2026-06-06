import Foundation
import UserNotifications

final class NotificationService: ObservableObject {
    @Published var permissionGranted = false

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async { self?.permissionGranted = granted }
            if granted { self?.scheduleDaily() }
        }
    }

    func scheduleDaily() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let reminders: [(hour: Int, minute: Int, title: String, body: String)] = [
            (7,  0,  "Good morning, FitDad! 💪",    "Check today's workout and hit your protein goal."),
            (12, 0,  "Midday check-in 🥗",           "Log your lunch and drink some water."),
            (18, 0,  "Evening habit check ✅",        "How many habits have you completed today?"),
            (20, 30, "Log your weight tomorrow 📊",  "Quick reminder: weigh in first thing after waking."),
        ]

        for (i, r) in reminders.enumerated() {
            let content        = UNMutableNotificationContent()
            content.title      = r.title
            content.body       = r.body
            content.sound      = .default

            var comps          = DateComponents()
            comps.hour         = r.hour
            comps.minute       = r.minute
            let trigger        = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let request        = UNNotificationRequest(identifier: "fitdad_\(i)", content: content, trigger: trigger)
            center.add(request)
        }
    }

    func scheduleWorkoutReminder(at date: Date, workoutName: String) {
        let content       = UNMutableNotificationContent()
        content.title     = "Workout time! 🔥"
        content.body      = "Today is \(workoutName). Let's go!"
        content.sound     = .default
        let trigger       = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false)
        let request       = UNNotificationRequest(identifier: "workout_\(date.timeIntervalSince1970)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
