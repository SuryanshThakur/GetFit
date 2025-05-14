import SwiftUI
import Combine

// MARK: - Utilities
func defaultTime(hour: Int) -> Date {
    let cal = Calendar.current
    let now = Date()
    return cal.date(bySettingHour: hour, minute: 0, second: 0, of: now) ?? now
}

// Observer class to handle all settings changes
class SettingsObserver: ObservableObject {
    static let shared = SettingsObserver()
    private var cancellables = Set<AnyCancellable>()
    
    func startObserving(notificationManager: NotificationManager) {
        // Using a publisher to handle all setting changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { _ in
                notificationManager.scheduleAllNotifications()
            }
            .store(in: &cancellables)
    }
}

struct SettingsView: View {
    // Helper to update the app's appearance
    private func updateAppearance() {
        // Modern way to access the key window in iOS 15+
        if #available(iOS 15.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            windowScene?.windows.forEach { window in
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        } else {
            // Fallback for older iOS versions
            UIApplication.shared.windows.first?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        }
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
    
    // Fitness Stats
    @AppStorage("userHeight") private var userHeight: Double = 170.0 // in cm
    @AppStorage("userWeight") private var userWeight: Double = 70.0 // in kg
    @AppStorage("userAge") private var userAge: Int = 30
    @AppStorage("userGender") private var userGender: String = "Male"
    @AppStorage("stepTarget") private var stepTarget: Int = 10000

    // MARK: - View Components
    
    // Meal reminders section
    private var mealRemindersSection: some View {
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
    }
    
    // Workout reminder section
    private var workoutSection: some View {
        Section(header: Text("Workout Reminder")) {
            Toggle("Enable Workout Reminder", isOn: $notifyWorkout)
            if notifyWorkout {
                DatePicker("Workout Time", selection: $workoutTime, displayedComponents: .hourAndMinute)
            }
        }
    }
    
    // Hydration reminder section
    private var hydrationSection: some View {
        Section(header: Text("Hydration Reminder")) {
            Toggle("Enable Hydration Reminders", isOn: $notifyHydration)
            if notifyHydration {
                Stepper(value: $hydrationInterval, in: 30...180, step: 15) {
                    Text("Every \(hydrationInterval) min")
                }
            }
        }
    }
    
    // Sleep section
    private var sleepSection: some View {
        Section(header: Text("Sleep Reminder")) {
            Toggle("Enable Sleep Reminder", isOn: $notifySleep)
            if notifySleep {
                DatePicker("Sleep Time", selection: $sleepTime, displayedComponents: .hourAndMinute)
            }
        }
    }
    
    // Appearance section
    private var appearanceSection: some View {
        Section(header: Text("Appearance")) {
            Toggle(isOn: $isDarkMode) {
                Text("Dark Mode")
            }
        }
    }
    
    // Fitness information section
    private var fitnessInfoSection: some View {
        Section(header: Text("Fitness Information")) {
            VStack(alignment: .leading) {
                Text("Height (cm)")
                Slider(value: $userHeight, in: 120...220, step: 1) {
                    Text("\(Int(userHeight)) cm")
                }
                Text("\(Int(userHeight)) cm")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading) {
                Text("Weight (kg)")
                Slider(value: $userWeight, in: 30...150, step: 0.5) {
                    Text("\(String(format: "%.1f", userWeight)) kg")
                }
                Text("\(String(format: "%.1f", userWeight)) kg")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading) {
                Text("Age")
                Stepper("\(userAge) years", value: $userAge, in: 12...100)
            }
            
            Picker("Gender", selection: $userGender) {
                Text("Male").tag("Male")
                Text("Female").tag("Female")
                Text("Other").tag("Other")
            }
            
            VStack(alignment: .leading) {
                Text("Daily Step Target")
                Picker("Step Target", selection: $stepTarget) {
                    Text("5,000 steps").tag(5000)
                    Text("7,500 steps").tag(7500)
                    Text("10,000 steps").tag(10000)
                    Text("12,500 steps").tag(12500)
                    Text("15,000 steps").tag(15000)
                    Text("20,000 steps").tag(20000)
                }
            }
        }
    }
    
    // About section
    private var aboutSection: some View {
        Section(header: Text("About")) {
            Text("GetFit v1.0\nIndian Vegetarian Diet & Workout App\nAll data is stored locally on your device.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Main View Structure
    
    @StateObject private var settingsObserver = SettingsObserver.shared
    
    var body: some View {
        NavigationView {
            Form {
                mealRemindersSection
                workoutSection
                hydrationSection
                sleepSection
                appearanceSection
                fitnessInfoSection
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear {
                updateAppearance()
                // Start observing UserDefaults changes for notifications
                settingsObserver.startObserving(notificationManager: notificationManager)
            }
            // Just handle dark mode changes directly
            #if swift(>=5.9)
            .onChange(of: isDarkMode) { 
                updateAppearance()
            }
            #else
            .onChange(of: isDarkMode) { newValue in
                updateAppearance()
            }
            #endif
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
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
