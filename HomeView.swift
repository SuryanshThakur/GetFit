import SwiftUI
import CoreHaptics

struct HomeView: View {
    @State private var hydrationMl: Int = 1500
    @State private var sleepLogged: Bool = false
    @State private var meals: [String: Bool] = [
        "Breakfast": false,
        "Lunch": false,
        "Snack": false,
        "Dinner": false
    ]
    @State private var engine: CHHapticEngine?
    var accent: Color {
        Color.accentDynamic
    }
    var completedMeals: Int {
        meals.values.filter { $0 }.count
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Today's Summary")
                    .font(.largeTitle).bold()
                    .foregroundColor(accent)
                    .padding(.top)
                Text(completedMeals == meals.count ? "Great job! All meals logged." : "Keep it up! Your daily goals await.")
                    .font(.headline)
                    .foregroundColor(accent)
                HStack {
                    ProgressRing(progress: Double(completedMeals) / Double(meals.count), color: accent)
                        .frame(width: 60, height: 60)
                        .accessibilityLabel("Meal completion progress ring")
                    VStack(alignment: .leading) {
                        Text("Meals Completed")
                            .font(.headline)
                        Text("\(completedMeals) of \(meals.count)")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                }
                // Meals Today Card
                CardView {
                    VStack(alignment: .leading) {
                        Text("Meals Today")
                            .font(.title2).bold()
                        ForEach(meals.keys.sorted(), id: \.self) { meal in
                            HStack {
                                Text(meal)
                                    .font(.body)
                                Spacer()
                                Image(systemName: meals[meal]! ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(meals[meal]! ? accent : .gray)
                                    .font(.title2)
                                    .onTapGesture {
                                        meals[meal]!.toggle()
                                        playHaptic()
                                    }
                                    .accessibilityLabel(meals[meal]! ? "Meal completed" : "Meal not completed")
                            }
                        }
                    }
                }
                // Workout Today Card
                CardView {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Workout Today")
                                .font(.title2).bold()
                            Text("Upper Body Strength") // Placeholder
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundColor(.red)
                            .font(.title)
                    }
                }
                // Hydration Log Widget
                CardView {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Hydration")
                                .font(.title2).bold()
                            Text("\(Double(hydrationMl)/1000, specifier: "%.1f") L")
                                .font(.title3)
                        }
                        Spacer()
                        Button(action: {
                            hydrationMl = max(0, hydrationMl - 250)
                            playHaptic()
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title)
                        }
                        Button(action: {
                            hydrationMl += 250
                            playHaptic()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title)
                        }
                    }
                }
                // Sleep Logged Indicator
                CardView {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(.purple)
                        Text("Sleep Logged")
                            .font(.title2).bold()
                        Spacer()
                        Image(systemName: sleepLogged ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(sleepLogged ? .green : .red)
                            .onTapGesture {
                                sleepLogged.toggle()
                                playHaptic()
                            }
                            .accessibilityLabel(sleepLogged ? "Sleep logged" : "Sleep not logged")
                    }
                }
                // Progress Shortcut
                CardView {
                    NavigationLink(destination: ProgressViewScreen()) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Progress Overview")
                                    .font(.title2).bold()
                                Text("Weight: 68kg → 67kg") // Placeholder
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(accent)
                                .font(.title)
                        }
                    }
                }
            }
            .padding()
            .background(
                Color(
                    UITraitCollection.current.userInterfaceStyle == .dark ? .black : .systemBackground
                ).ignoresSafeArea()
            )
        }
        .onAppear { prepareHaptics() }
    }
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do { engine = try CHHapticEngine() } catch { engine = nil }
    }
    func playHaptic() {
        guard let engine = engine else { return }
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [sharpness, intensity], relativeTime: 0)
        do {
            try engine.start()
            try engine.makePlayer(with: CHHapticPattern(events: [event], parameters: [])).start(atTime: 0)
        } catch {}
    }
}

struct ProgressRing: View {
    var progress: Double
    var color: Color
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 8)
                .opacity(0.15)
                .foregroundColor(color)
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeOut, value: progress)
            Text("\(Int(progress * 100))%")
                .font(.caption).bold()
                .foregroundColor(color)
        }
    }
}

struct CardView<Content: View>: View {
    let content: () -> Content
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            content()
                .padding()
        }
        .padding(.vertical, 4)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.colorScheme, .light)
        HomeView()
            .environment(\.colorScheme, .dark)
    }
}
