import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var permissionGranted: Bool = false
    
    func requestPermission(completion: @escaping (Bool) -> Void = {_ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.permissionGranted = granted
                completion(granted)
            }
        }
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.permissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleDailyNotification(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleHydrationNotifications(intervalMinutes: Int, startHour: Int = 8, endHour: Int = 22) {
        cancelHydrationNotifications()
        let strideBy = max(1, intervalMinutes / 60)
        for hour in stride(from: startHour, through: endHour, by: strideBy) {
            let content = UNMutableNotificationContent()
            content.title = "Hydration Reminder"
            content.body = "Time to drink water!"
            content.sound = .default
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "hydration_\(hour)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func cancelHydrationNotifications() {
        let ids = (8...22).map { "hydration_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
    
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Schedule All Notifications
    func scheduleAllNotifications() {
        // Retrieve all settings from UserDefaults
        let defaults = UserDefaults.standard
        let cal = Calendar.current
        let now = Date()
        
        // Helper function to create a default time
        func createDefaultTime(hour: Int) -> Date {
            return cal.date(bySettingHour: hour, minute: 0, second: 0, of: now) ?? now
        }
        
        // Meal times
        let notifyEarlyMorning = defaults.bool(forKey: "notifyEarlyMorning")
        let earlyMorningTime = defaults.object(forKey: "earlyMorningTime") as? Date ?? createDefaultTime(hour: 6)
        
        let notifyBreakfast = defaults.bool(forKey: "notifyBreakfast")
        let breakfastTime = defaults.object(forKey: "breakfastTime") as? Date ?? createDefaultTime(hour: 8)
        
        let notifyMidMorning = defaults.bool(forKey: "notifyMidMorning")
        let midMorningTime = defaults.object(forKey: "midMorningTime") as? Date ?? createDefaultTime(hour: 10)
        
        let notifyLunch = defaults.bool(forKey: "notifyLunch")
        let lunchTime = defaults.object(forKey: "lunchTime") as? Date ?? createDefaultTime(hour: 13)
        
        let notifyEveningSnack = defaults.bool(forKey: "notifyEveningSnack")
        let eveningSnackTime = defaults.object(forKey: "eveningSnackTime") as? Date ?? createDefaultTime(hour: 17)
        
        let notifyPostWorkout = defaults.bool(forKey: "notifyPostWorkout")
        let postWorkoutTime = defaults.object(forKey: "postWorkoutTime") as? Date ?? createDefaultTime(hour: 19)
        
        let notifyDinner = defaults.bool(forKey: "notifyDinner")
        let dinnerTime = defaults.object(forKey: "dinnerTime") as? Date ?? createDefaultTime(hour: 20)
        
        let notifyBeforeBed = defaults.bool(forKey: "notifyBeforeBed")
        let beforeBedTime = defaults.object(forKey: "beforeBedTime") as? Date ?? createDefaultTime(hour: 22)
        
        // Workout
        let notifyWorkout = defaults.bool(forKey: "notifyWorkout")
        let workoutTime = defaults.object(forKey: "workoutTime") as? Date ?? createDefaultTime(hour: 18)
        
        // Hydration
        let notifyHydration = defaults.bool(forKey: "notifyHydration")
        let hydrationInterval = defaults.integer(forKey: "hydrationInterval")
        
        // Sleep
        let notifySleep = defaults.bool(forKey: "notifySleep")
        let sleepTime = defaults.object(forKey: "sleepTime") as? Date ?? createDefaultTime(hour: 23)
        
        // Configure all notifications
        let mealSettings: [(Bool, String, String, Date)] = [
            (notifyEarlyMorning, "meal_early", "Early Morning", earlyMorningTime),
            (notifyBreakfast, "meal_breakfast", "Breakfast", breakfastTime),
            (notifyMidMorning, "meal_midmorning", "Mid-Morning Snack", midMorningTime),
            (notifyLunch, "meal_lunch", "Lunch", lunchTime),
            (notifyEveningSnack, "meal_evening", "Evening Snack", eveningSnackTime),
            (notifyPostWorkout, "meal_postworkout", "Post-Workout", postWorkoutTime),
            (notifyDinner, "meal_dinner", "Dinner", dinnerTime),
            (notifyBeforeBed, "meal_bed", "Before Bed", beforeBedTime)
        ]
        
        for (enabled, id, title, time) in mealSettings {
            self.cancelNotification(id: id)
            if enabled {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
                self.scheduleDailyNotification(
                    id: id,
                    title: "Meal Time",
                    body: "It's time for \(title)!",
                    hour: comps.hour ?? 8,
                    minute: comps.minute ?? 0
                )
            }
        }
        
        self.cancelNotification(id: "workout")
        if notifyWorkout {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: workoutTime)
            self.scheduleDailyNotification(
                id: "workout",
                title: "Workout Time",
                body: "Time to get moving!",
                hour: comps.hour ?? 18,
                minute: comps.minute ?? 0
            )
        }
        
        self.cancelHydrationNotifications()
        if notifyHydration {
            self.scheduleHydrationNotifications(intervalMinutes: hydrationInterval)
        }
        
        self.cancelNotification(id: "sleep")
        if notifySleep {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: sleepTime)
            self.scheduleDailyNotification(
                id: "sleep",
                title: "Sleep Time",
                body: "Time to unwind and sleep.",
                hour: comps.hour ?? 23,
                minute: comps.minute ?? 0
            )
        }
    }
}
