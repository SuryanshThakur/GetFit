import SwiftUI
import CoreMotion
import Combine

// Activity data model for storing daily activity records
struct DailyActivity: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    var steps: Int
    var distance: Double
    var calories: Double
    
    // Calculate progress percentage (0.0 to 1.0) based on calorie target
    func calorieProgress(target: Int) -> Double {
        return min(Double(calories) / Double(target), 1.0)
    }
    
    // Generate random data for past days
    static func randomActivity(for date: Date) -> DailyActivity {
        let steps = Int.random(in: 2000...15000)
        let distance = Double.random(in: 0.8...7.0)
        let calories = Double.random(in: 100...600)
        return DailyActivity(date: date, steps: steps, distance: distance, calories: calories)
    }
    
    static func == (lhs: DailyActivity, rhs: DailyActivity) -> Bool {
        return Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date)
    }
}

class StepCountManager: ObservableObject {
    @Published var steps: Int = 0
    @Published var distance: Double = 0.0 // in kilometers
    @Published var calories: Double = 0.0
    @Published var isStepCountingAvailable: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedDate: Date = Date()
    @Published var activityHistory: [DailyActivity] = []
    @Published var selectedActivity: DailyActivity?
    @Published var currentWeekActivities: [DailyActivity] = [] // Current week activities
    
    private let pedometer = CMPedometer()
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Generate sample historical activity data for the past week
        generateHistoricalData()
        
        // Check if step counting is available on this device
        isStepCountingAvailable = CMPedometer.isStepCountingAvailable()
        
        // Setup publisher for date changes
        $selectedDate
            .removeDuplicates(by: { Calendar.current.isDate($0, inSameDayAs: $1) })
            .sink { [weak self] date in
                if Calendar.current.isDateInToday(date) {
                    self?.fetchStepsFromToday()
                } else {
                    self?.selectHistoricalData(for: date)
                }
            }
            .store(in: &cancellables)
        
        if isStepCountingAvailable {
            // Initial fetch for today
            if Calendar.current.isDateInToday(selectedDate) {
                fetchStepsFromToday()
            }
            
            // Setup timer to update steps periodically (only for today)
            updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                guard let self = self, Calendar.current.isDateInToday(self.selectedDate) else { return }
                self.fetchStepsFromToday()
            }
        } else {
            // Even without step counting, we can show historical/simulated data
            errorMessage = "Step counting is not available on this device. Showing simulated data."
            selectHistoricalData(for: selectedDate)
        }
        
        // Initialize the current week's data
        updateCurrentWeekActivities()
    }
    
    deinit {
        // Clean up timer and cancellables when this object is deallocated
        updateTimer?.invalidate()
        cancellables.forEach { $0.cancel() }
    }
    
    // Update the current week's activities
    func updateCurrentWeekActivities() {
        let calendar = Calendar.current
        let today = Date()
        
        // Find the start date of the current week (Monday)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        let weekStart = calendar.date(from: components)!
        
        currentWeekActivities = []
        
        // Create array of 7 activities for Monday through Sunday
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            
            // Check if we have existing data for this date
            if let existingActivity = activityHistory.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                currentWeekActivities.append(existingActivity)
            } else {
                // Future date (no data yet)
                let emptyActivity = DailyActivity(date: date, steps: 0, distance: 0, calories: 0)
                currentWeekActivities.append(emptyActivity)
                
                // Add to history as well if it's not already there
                if !activityHistory.contains(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                    activityHistory.append(emptyActivity)
                }
            }
        }
    }
    
    // Generate historical data for the past and current week
    private func generateHistoricalData() {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the current week (Monday)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        let currentWeekStart = calendar.date(from: components)!
        
        // Generate data for the current week
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart) else { continue }
            
            // If this date is in the future, create an empty activity
            if date > today {
                let emptyActivity = DailyActivity(date: date, steps: 0, distance: 0, calories: 0)
                activityHistory.append(emptyActivity)
            } 
            // Don't generate random data for today, we'll get real data if available
            else if calendar.isDateInToday(date) && isStepCountingAvailable {
                let placeholder = DailyActivity(date: date, steps: 0, distance: 0, calories: 0)
                activityHistory.append(placeholder)
            } else {
                activityHistory.append(DailyActivity.randomActivity(for: date))
            }
        }
        
        // Also generate data for the previous week
        guard let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) else { return }
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: previousWeekStart) else { continue }
            activityHistory.append(DailyActivity.randomActivity(for: date))
        }
        
        // Sort the history by date
        activityHistory.sort { $0.date < $1.date }
    }
    
    // Select historical data for a specific date
    func selectHistoricalData(for date: Date) {
        selectedActivity = activityHistory.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
        
        if let activity = selectedActivity {
            steps = activity.steps
            distance = activity.distance
            calories = activity.calories
        }
    }
    
    func fetchStepsFromToday() {
        let calendar = Calendar.current
        guard let startOfDay = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) else {
            errorMessage = "Could not determine start of day."
            return
        }
        
        if isStepCountingAvailable {
            // Use dispatch to avoid retain cycles
            pedometer.queryPedometerData(from: startOfDay, to: Date()) { data, error in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    if let error = error {
                        // Special handling for authorization errors
                        if (error as NSError).domain == CMErrorDomain && 
                           (error as NSError).code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
                            self.errorMessage = "Motion data access not authorized. Please enable in Settings > Privacy > Motion & Fitness."
                        } else {
                            self.errorMessage = "Error fetching step data."
                        }
                        print("Error fetching step count: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let data = data else {
                        self.errorMessage = "No step data available."
                        return
                    }
                    
                    self.errorMessage = nil
                    self.steps = data.numberOfSteps.intValue
                    if let distance = data.distance?.doubleValue {
                        // Convert distance from meters to kilometers
                        self.distance = distance / 1000
                    }
                    self.calculateCalories()
                    
                    // Update today's activity in the history
                    if let todayActivityIndex = self.activityHistory.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
                        var todayActivity = self.activityHistory[todayActivityIndex]
                        todayActivity.steps = self.steps
                        todayActivity.distance = self.distance
                        todayActivity.calories = self.calories
                        self.activityHistory[todayActivityIndex] = todayActivity
                        self.selectedActivity = todayActivity
                    }
                }
            }
        } else {
            // Fallback to simulated data
            selectHistoricalData(for: Date())
        }
    }
    
    func calculateCalories() {
        // Retrieve user stats from UserDefaults (set in SettingsView)
        let userDefaults = UserDefaults.standard
        let height = userDefaults.double(forKey: "userHeight") // in cm
        let weight = userDefaults.double(forKey: "userWeight") // in kg
        let gender = userDefaults.string(forKey: "userGender") ?? "Male"
        
        // Calculate stride length based on height and gender
        let strideMultiplier = (gender == "Male") ? 0.415 : 0.413
        let strideLength = height * strideMultiplier / 100 // in meters
        
        // Calculate distance based on steps and stride length
        let calculatedDistance = Double(steps) * strideLength / 1000 // in km
        
        // Use the distance from pedometer if available, otherwise use calculated distance
        let finalDistance = distance > 0 ? distance : calculatedDistance
        
        // Assuming a normal walking pace with MET value of 3.5
        let met = 3.5
        let timeHours = finalDistance / 5.0 // assuming 5 km/h walking speed
        
        // Calculate calories
        calories = met * weight * timeHours
    }
}

struct ActivityRing: View {
    var progress: Double
    var total: Int
    var current: Int
    var color: Color
    var size: CGFloat = 300
    var showValue: Bool = true
    var lineWidth: CGFloat = 20
    var showArrow: Bool = true
    var selectedDay: Bool = false
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.3)
                .foregroundColor(color)
            
            // Progress ring
            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.easeInOut, value: progress)
            
            // Progress indicator (arrow) at the end of the progress
            if showArrow && progress > 0 && progress < 1.0 {
                Image(systemName: "arrow.right")
                    .font(.system(size: size * 0.067, weight: .bold))
                    .foregroundColor(color)
                    .rotationEffect(Angle(degrees: progress * 360 - 90))
                    .offset(y: -size * 0.47)
                    .rotationEffect(Angle(degrees: progress * 360))
            }
            
            // Selected day indicator
            if selectedDay {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: size * 0.9, height: size * 0.9)
            }
            
            // Text in the center if showing values
            if showValue {
                VStack {
                    Text("\(current)")
                        .font(.system(size: size * 0.14, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("/\(total)CAL")
                        .font(.system(size: size * 0.053, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// A smaller version of the activity ring for weekly display
struct WeekdayActivityRing: View {
    var activity: DailyActivity
    var targetCalories: Int
    var dayLabel: String
    var isSelected: Bool
    var isToday: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
            
            ActivityRing(
                progress: activity.calorieProgress(target: targetCalories),
                total: targetCalories,
                current: Int(activity.calories),
                color: .red,
                size: 40,
                showValue: false,
                lineWidth: 6,
                showArrow: false,
                selectedDay: isSelected
            )
        }
        .padding(4)
        .background(isSelected ? Circle().fill(Color.gray.opacity(0.3)) : nil)
    }
}

struct StepTrackingView: View {
    @StateObject private var stepManager = StepCountManager()
    @AppStorage("stepTarget") private var stepTarget: Int = 10000
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @State private var showingPermissionAlert = false
    @State private var hourlyData: [Int] = Array(repeating: 0, count: 24) // For the hourly activity chart
    @State private var showingCalendarPicker = false
    
    // Calculate calories burned for the day based on step target
    private var targetCalories: Int {
        let userDefaults = UserDefaults.standard
        let weight = userDefaults.double(forKey: "userWeight") // in kg
        let height = userDefaults.double(forKey: "userHeight") // in cm
        let gender = userDefaults.string(forKey: "userGender") ?? "Male"
        
        // Calculate stride length based on height and gender
        let strideMultiplier = (gender == "Male") ? 0.415 : 0.413
        let strideLength = height * strideMultiplier / 100 // in meters
        
        // Calculate expected distance for target steps
        let targetDistance = Double(stepTarget) * strideLength / 1000 // in km
        
        // Assuming a normal walking pace with MET value of 3.5
        let met = 3.5
        let timeHours = targetDistance / 5.0 // assuming 5 km/h walking speed
        
        // Calculate target calories
        let targetCals = met * weight * timeHours
        return Int(targetCals)
    }
    
    // Create the background color based on dark mode setting
    private var backgroundColor: Color {
        return isDarkMode ? Color.black : Color(UIColor.systemBackground)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    // Error message if step counting is not available
                    if let errorMessage = stepManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .multilineTextAlignment(.center)
                    }
                    
                    // Header with date picker
                    HStack {
                        Button(action: {
                            // Go to previous day
                            if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: stepManager.selectedDate) {
                                stepManager.selectedDate = newDate
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.green)
                                .imageScale(.large)
                        }
                        
                        Spacer()
                        
                        // Date with calendar picker button
                        Button(action: {
                            showingCalendarPicker.toggle()
                        }) {
                            HStack {
                                Text(formattedDate(from: stepManager.selectedDate))
                                    .font(.title2.bold())
                                Image(systemName: "calendar")
                                    .imageScale(.medium)
                            }
                        }
                        
                        Spacer()
                        
                        // Share button (for visual match with reference)
                        Button(action: {
                            // Share functionality would go here
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.green)
                                .imageScale(.large)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Weekly activity rings
                    VStack(spacing: 12) {
                        // Day indicators for week view
                        HStack(spacing: 16) {
                            ForEach(stepManager.currentWeekActivities.indices, id: \.self) { index in
                                let activity = stepManager.currentWeekActivities[index]
                                let calendar = Calendar.current
                                let dayIndex = calendar.component(.weekday, from: activity.date) - 1
                                let weekdaySymbol = calendar.veryShortWeekdaySymbols[dayIndex]
                                let isSelected = calendar.isDate(activity.date, inSameDayAs: stepManager.selectedDate)
                                let isToday = calendar.isDateInToday(activity.date)
                                
                                Button(action: {
                                    stepManager.selectedDate = activity.date
                                }) {
                                    WeekdayActivityRing(
                                        activity: activity,
                                        targetCalories: targetCalories,
                                        dayLabel: weekdaySymbol,
                                        isSelected: isSelected,
                                        isToday: isToday
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Main Activity Ring
                        ActivityRing(
                            progress: Double(Int(stepManager.calories)) / Double(targetCalories),
                            total: targetCalories,
                            current: Int(stepManager.calories),
                            color: .red,
                            size: 250
                        )
                        .padding(.vertical, 15)
                        
                        // Move label
                        VStack(spacing: 2) {
                            Text("Move")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(stepManager.calories))/\(targetCalories)cal")
                                .font(.title2.bold())
                                .foregroundColor(.red)
                        }
                        
                        // Activity chart
                        VStack(alignment: .leading, spacing: 5) {
                            // 24-hour time labels
                            HStack {
                                Text("15CAL")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                            
                            // Generate hourly activity bars
                            HStack(alignment: .bottom, spacing: 1) {
                                ForEach(0..<24, id: \.self) { hour in
                                    let height = getRandomBarHeight(for: hour)
                                    Rectangle()
                                        .fill(Color.red)
                                        .frame(width: (UIScreen.main.bounds.width - 60) / 30, height: height)
                                }
                            }
                            .frame(height: 60)
                            
                            // Time range labels
                            HStack {
                                Text("12:00")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("6:00")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("12:00")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("6:00")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        Divider()
                            .padding(.vertical, 15)
                        
                        // Stats summary
                        HStack(spacing: 80) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Steps")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("\(stepManager.steps)")
                                    .font(.system(size: 34, weight: .bold))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Distance")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text(String(format: "%.2f", stepManager.distance * 0.621371)) // Convert km to miles
                                        .font(.system(size: 34, weight: .bold))
                                    Text("MI")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Bottom tab bar placeholder
                        HStack(spacing: 0) {
                            Spacer()
                            Button(action: {}) {
                                VStack {
                                    Image(systemName: "house")
                                        .imageScale(.large)
                                    Text("Home")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: {}) {
                                VStack {
                                    Image(systemName: "fork.knife")
                                        .imageScale(.large)
                                    Text("Diet")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button(action: {}) {
                                VStack {
                                    Image(systemName: "figure.walk.circle.fill")
                                        .imageScale(.large)
                                    Text("Activity")
                                        .font(.caption)
                                }
                                .foregroundColor(.orange)
                            }
                            Spacer()
                            Button(action: {}) {
                                VStack {
                                    Image(systemName: "gear")
                                        .imageScale(.large)
                                    Text("More")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.top, 20)
                    }
                }
                .padding()
                .background(backgroundColor)
            }
            .navigationTitle("Activity")
            .navigationBarHidden(true) // Hide the navigation bar to match reference image
            .onAppear {
                // Request motion permission if needed
                if CMMotionActivityManager.isActivityAvailable() {
                    let manager = CMMotionActivityManager()
                    manager.queryActivityStarting(from: Date(), to: Date(), to: .main) { _, error in
                        if let error = error as NSError?, error.code == CMErrorMotionActivityNotAuthorized.rawValue {
                            self.showingPermissionAlert = true
                        }
                        // Stop the manager as we just need to trigger the permission dialog
                        manager.stopActivityUpdates()
                    }
                }
                
                // Generate the hourly data for the chart (this is simulated for the demo)
                generateHourlyData()
                
                // Update the appearance based on dark mode setting
                updateAppearance()
                
                // Update the current week activities
                stepManager.updateCurrentWeekActivities()
            }
            .onChange(of: isDarkMode) { _ in
                updateAppearance()
            }
            .alert(isPresented: $showingPermissionAlert) {
                Alert(
                    title: Text("Motion Access Required"),
                    message: Text("Please enable motion and fitness activity access in Settings > Privacy to track your steps."),
                    primaryButton: .default(Text("Open Settings")) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    func formattedDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    // Update the app appearance based on dark mode setting
    func updateAppearance() {
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
    
    // Generate random hourly data for the activity chart
    func generateHourlyData() {
        // Simulate a realistic activity pattern throughout the day
        for hour in 0..<24 {
            // Less activity during early morning and late night hours
            if hour < 6 || hour >= 22 {
                hourlyData[hour] = Int.random(in: 0...10)
            }
            // Medium activity during morning and evening
            else if (hour >= 6 && hour < 9) || (hour >= 17 && hour < 22) {
                hourlyData[hour] = Int.random(in: 10...40)
            }
            // Higher activity during the day
            else {
                hourlyData[hour] = Int.random(in: 5...60)
            }
        }
    }
    
    // Get the height for each hourly bar in the chart
    func getRandomBarHeight(for hour: Int) -> CGFloat {
        return CGFloat(hourlyData[hour])
    }
}

struct StepTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        StepTrackingView()
            .preferredColorScheme(.dark)
    }
}
