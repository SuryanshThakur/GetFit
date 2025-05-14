import SwiftUI

// MARK: - Utilities
func defaultTime(hour: Int) -> Date {
    let cal = Calendar.current
    let now = Date()
    return cal.date(bySettingHour: hour, minute: 0, second: 0, of: now) ?? now
}

struct SettingsView: View {
    // Helper to update the app's appearance
    private func updateAppearance() {
        UIApplication.shared.windows.first?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
    }

    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showPermissionAlert = false

    // Meal Times
    @AppStorage("notifyEarlyMorning") private var notifyEarlyMorning = true
    @AppStorage("earlyMorningTime") private var earlyMorningTime = defaultTime(hour: 6)

    @AppStorage("notifyBreakfast") private var notifyBreakfast = true
    @AppStorage("breakfastTime") private var breakfastTime = defaultTime(hour: 8)

    @AppStorage("notifyMidMorning") private var notifyMidMorning = true
    @AppStorage("midMorningTime") private var midMorningTime = defaultTime(hour: 10)

    @AppStorage("notifyLunch") private var notifyLunch = true
    @AppStorage("lunchTime") private var lunchTime = defaultTime(hour: 13)

    @AppStorage("notifyEveningSnack") private var notifyEveningSnack = true
    @AppStorage("eveningSnackTime") private var eveningSnackTime = defaultTime(hour: 17)

    @AppStorage("notifyPostWorkout") private var notifyPostWorkout = true
    @AppStorage("postWorkoutTime") private var postWorkoutTime = defaultTime(hour: 19)

    @AppStorage("notifyDinner") private var notifyDinner = true
    @AppStorage("dinnerTime") private var dinnerTime = defaultTime(hour: 20)

    @AppStorage("notifyBeforeBed") private var notifyBeforeBed = true
    @AppStorage("beforeBedTime") private var beforeBedTime = defaultTime(hour: 22)

    // Workout
    @AppStorage("notifyWorkout") private var notifyWorkout = true
    @AppStorage("workoutTime") private var workoutTime = defaultTime(hour: 18)

    // Hydration
    @AppStorage("notifyHydration") private var notifyHydration = false
    @AppStorage("hydrationInterval") private var hydrationInterval = 60

    // Sleep
    @AppStorage("notifySleep") private var notifySleep = false
    @AppStorage("sleepTime") private var sleepTime = defaultTime(hour: 23)

    // Theme
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    var body: some View {
        NavigationView {
            Form {
                // Meal Section
                Section(header: Text("Meal Reminders")) {
                    mealSettingRow("Early Morning", $notifyEarlyMorning, $earlyMorningTime)
                    mealSettingRow("Breakfast", $notifyBreakfast, $breakfastTime)
                    mealSettingRow("Mid-Morning Snack", $notifyMidMorning, $midMorningTime)
                    mealSettingRow("Lunch", $notifyLunch, $lunchTime)
                    mealSettingRow("Evening Snack", $notifyEveningSnack, $eveningSnackTime)
                    mealSettingRow("Post-Workout", $notifyPostWorkout, $postWorkoutTime)
                    mealSettingRow("Dinner", $notifyDinner, $dinnerTime)
                    mealSettingRow("Before Bed", $notifyBeforeBed, $beforeBedTime)
                }

                // Workout Section
                Section(header: Text("Workout Reminder")) {
                    Toggle("Enable Workout Reminder", isOn: $notifyWorkout)
                    if notifyWorkout {
                        DatePicker("Workout Time", selection: $workoutTime, displayedComponents: .hourAndMinute)
                    }
                }

                // Hydration Section
                Section(header: Text("Hydration Reminder")) {
                    Toggle("Enable Hydration Reminders", isOn: $notifyHydration)
                    if notifyHydration {
                        Stepper(value: $hydrationInterval, in: 30...180, step: 15) {
                            Text("Every \(hydrationInterval) min")
                        }
                    }
                }

                // Sleep Section
                Section(header: Text("Sleep Reminder")) {
                    Toggle("Enable Bedtime Reminder", isOn: $notifySleep)
                    if notifySleep {
                        DatePicker("Bedtime Goal", selection: $sleepTime, displayedComponents: .hourAndMinute)
                    }
                }

                // Appearance Section
                Section(header: Text("Appearance")) {
                    Toggle(isOn: $isDarkMode) {
                        Text("Dark Mode")
                    }
                }

                // About Section
                Section(header: Text("About")) {
                    Text("GetFit v1.0\nIndian Vegetarian Diet & Workout App\nAll data is stored locally on your device.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                updateAppearance()
            }
            .onChange(of: isDarkMode) { _ in
                updateAppearance()
            }
            .onChange(of: notifyEarlyMorning) { _ in scheduleAllNotifications() }
            .onChange(of: earlyMorningTime) { _ in scheduleAllNotifications() }
            .onChange(of: notifyBreakfast) { _ in scheduleAllNotifications() }
            .onChange(of: breakfastTime) { _ in scheduleAllNotifications() }
            .onChange(of: notifyMidMorning) { _ in scheduleAllNotifications() }
            .onChange(of: midMorningTime) { _ in scheduleAllNotifications() }
            .onChange(of: notifyLunch) { _ in scheduleAllNotifications() }
            .onChange(of: lunchTime) { _ in scheduleAllNotifications() }
            .onChange(of: notifyEveningSnack) { _ in scheduleAllNotifications() }
            .onChange(of: eveningSnackTime) { _ in scheduleAllNotifications() }
            .onChange(of: notifyPostWorkout) { _ in scheduleAllNotifications() }
            .onChange(of: postWorkoutTime) { _ in scheduleAllNotifications() }
            .onChange(of: notifyDinner) { _ in scheduleAllNotifications() }
            .onChange(of: dinnerTime) { _ in scheduleAllNotifications() }
            .onChange(of: notifyBeforeBed) { _ in scheduleAllNotifications() }
            .onChange(of: beforeBedTime) { _ in scheduleAllNotifications() }
            .onChange(of: notifyWorkout) { _ in scheduleAllNotifications() }
            .onChange(of: workoutTime) { _ in scheduleAllNotifications() }
            .onChange(of: notifyHydration) { _ in scheduleAllNotifications() }
            .onChange(of: hydrationInterval) { _ in scheduleAllNotifications() }
            .onChange(of: notifySleep) { _ in scheduleAllNotifications() }
            .onChange(of: sleepTime) { _ in scheduleAllNotifications() }
        }
    }

    // MARK: - Helper Views
    func mealSettingRow(_ title: String, _ toggle: Binding<Bool>, _ time: Binding<Date>) -> some View {
        VStack(alignment: .leading) {
            Toggle(title, isOn: toggle)
            if toggle.wrappedValue {
                DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)
            }
        }
    }

    // MARK: - Schedule Notifications
    func scheduleAllNotifications() {
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
            notificationManager.cancelNotification(id: id)
            if enabled {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
                notificationManager.scheduleDailyNotification(
                    id: id,
                    title: "Meal Time",
                    body: "It's time for \(title)!",
                    hour: comps.hour ?? 8,
                    minute: comps.minute ?? 0
                )
            }
        }

        notificationManager.cancelNotification(id: "workout")
        if notifyWorkout {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: workoutTime)
            notificationManager.scheduleDailyNotification(
                id: "workout",
                title: "Workout Time",
                body: "Time to get moving!",
                hour: comps.hour ?? 18,
                minute: comps.minute ?? 0
            )
        }

        notificationManager.cancelHydrationNotifications()
        if notifyHydration {
            notificationManager.scheduleHydrationNotifications(intervalMinutes: hydrationInterval)
        }

        notificationManager.cancelNotification(id: "sleep")
        if notifySleep {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: sleepTime)
            notificationManager.scheduleDailyNotification(
                id: "sleep",
                title: "Sleep Time",
                body: "Time to unwind and sleep.",
                hour: comps.hour ?? 23,
                minute: comps.minute ?? 0
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
