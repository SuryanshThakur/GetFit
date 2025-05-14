import SwiftUI

struct WorkoutExercise: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let setsReps: String
    let isHIIT: Bool
}

struct WorkoutDay: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let focus: String
    let exercises: [WorkoutExercise]
    let isRest: Bool
}

struct WorkoutPlanView: View {
    @State private var selectedDayIndex: Int = Calendar.current.component(.weekday, from: Date()) - 1 // 0 = Sunday
    @State private var weights: [UUID: Double] = [:]
    @State private var doneExercises: [UUID: Bool] = [:]
    let workoutDays: [WorkoutDay] = [
        WorkoutDay(name: "Day 1", focus: "Chest & Triceps", exercises: [
            WorkoutExercise(name: "Bench Press", setsReps: "3 × 10", isHIIT: false),
            WorkoutExercise(name: "Incline Dumbbell Press", setsReps: "3 × 8", isHIIT: false),
            WorkoutExercise(name: "Push-Ups", setsReps: "3 × 15", isHIIT: false),
            WorkoutExercise(name: "Triceps Pushdown", setsReps: "3 × 12", isHIIT: false)
        ], isRest: false),
        WorkoutDay(name: "Day 2", focus: "Back & Biceps", exercises: [
            WorkoutExercise(name: "Pull-Ups", setsReps: "3 × 8", isHIIT: false),
            WorkoutExercise(name: "Barbell Row", setsReps: "3 × 10", isHIIT: false),
            WorkoutExercise(name: "Lat Pulldown", setsReps: "3 × 12", isHIIT: false),
            WorkoutExercise(name: "Biceps Curl", setsReps: "3 × 12", isHIIT: false)
        ], isRest: false),
        WorkoutDay(name: "Day 3", focus: "Legs & Core", exercises: [
            WorkoutExercise(name: "Squats", setsReps: "3 × 10", isHIIT: false),
            WorkoutExercise(name: "Lunges", setsReps: "3 × 12", isHIIT: false),
            WorkoutExercise(name: "Leg Press", setsReps: "3 × 10", isHIIT: false),
            WorkoutExercise(name: "Plank", setsReps: "3 × 45s", isHIIT: false)
        ], isRest: false),
        WorkoutDay(name: "Day 4", focus: "Shoulders & Traps", exercises: [
            WorkoutExercise(name: "Overhead Press", setsReps: "3 × 10", isHIIT: false),
            WorkoutExercise(name: "Lateral Raise", setsReps: "3 × 12", isHIIT: false),
            WorkoutExercise(name: "Shrugs", setsReps: "3 × 15", isHIIT: false)
        ], isRest: false),
        WorkoutDay(name: "Day 5", focus: "Functional & HIIT", exercises: [
            WorkoutExercise(name: "Kettlebell Swings", setsReps: "4 × 15s (30s rest)", isHIIT: true),
            WorkoutExercise(name: "Burpees", setsReps: "4 × 15s (30s rest)", isHIIT: true),
            WorkoutExercise(name: "Box Jumps", setsReps: "4 × 10", isHIIT: true),
            WorkoutExercise(name: "Sprints", setsReps: "6 × 30s (60s rest)", isHIIT: true)
        ], isRest: false),
        WorkoutDay(name: "Day 6", focus: "Full Body (Hypertrophy)", exercises: [
            WorkoutExercise(name: "Deadlift", setsReps: "3 × 8", isHIIT: false),
            WorkoutExercise(name: "Bench Press", setsReps: "3 × 8", isHIIT: false),
            WorkoutExercise(name: "Pull-Ups", setsReps: "3 × 8", isHIIT: false),
            WorkoutExercise(name: "Squats", setsReps: "3 × 10", isHIIT: false)
        ], isRest: false),
        WorkoutDay(name: "Rest", focus: "Rest & Recovery", exercises: [], isRest: true)
    ]
    let dayNames = ["Day 1", "Day 2", "Day 3", "Day 4", "Day 5", "Day 6", "Rest"]

    var body: some View {
        VStack(spacing: 12) {
            // Day Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<workoutDays.count, id: \.self) { idx in
                        Button(action: { selectedDayIndex = idx }) {
                            VStack {
                                Text(workoutDays[idx].name)
                                    .font(.headline)
                                    .foregroundColor(selectedDayIndex == idx ? .white : .primary)
                                    .padding(8)
                                    .background(selectedDayIndex == idx ? Color.orange : Color(.systemGray5))
                                    .cornerRadius(10)
                                Text(workoutDays[idx].focus)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            Divider()
            // Exercises for selected day
            if workoutDays[selectedDayIndex].isRest {
                VStack(spacing: 16) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    Text("Rest and Recovery")
                        .font(.title2).bold()
                    Text("Try light stretching, yoga, or a walk.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(workoutDays[selectedDayIndex].exercises) { exercise in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(exercise.name)
                                    .font(.headline)
                                Text(exercise.setsReps)
                                    .font(.subheadline)
                                    .foregroundColor(exercise.isHIIT ? .orange : .secondary)
                            }
                            Spacer()
                            TextField("kg", value: Binding(
                                get: { weights[exercise.id] ?? 0 },
                                set: { weights[exercise.id] = $0 }
                            ), formatter: NumberFormatter())
                                .keyboardType(.decimalPad)
                                .frame(width: 60)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .disabled(exercise.isHIIT)
                            Button(action: {
                                doneExercises[exercise.id, default: false].toggle()
                            }) {
                                Image(systemName: doneExercises[exercise.id, default: false] ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(doneExercises[exercise.id, default: false] ? .green : .gray)
                                    .font(.title2)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("Workout Plan")
        .padding(.top, 8)
    }
}

struct WorkoutPlanView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { WorkoutPlanView() }
    }
}
// Notification scheduling stub (implement in AppDelegate/SceneDelegate as needed)
// import UserNotifications and use UNUserNotificationCenter to schedule workout reminders
