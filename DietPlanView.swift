import SwiftUI
import CoreData

struct DietPlanView: View {
    @StateObject private var viewModel = DietPlanViewModel(context: CoreDataStack.shared.context)
    @State private var showNutrition: MealItemDisplay? = nil
    @Environment(\.scenePhase) private var scenePhase

    // Use a computed property to initialize the meal sections array
    var mealSections: [MealSection] {
        // Early Morning Section
        let earlyMorningSection = MealSection(name: "Early Morning", items: [
            MealItemDisplay(name: "Soaked Almonds", quantity: "6 pcs", protein: 2, carbs: 2, fat: 4),
            MealItemDisplay(name: "Warm Lemon Water", quantity: "1 glass", protein: 0, carbs: 1, fat: 0)
        ])
        
        // Breakfast Section
        let breakfastSection = MealSection(name: "Breakfast", items: [
            MealItemDisplay(name: "Oats Upma", quantity: "40g oats, 100ml milk", protein: 6, carbs: 24, fat: 3),
            MealItemDisplay(name: "Greek Yogurt", quantity: "100g", protein: 8, carbs: 4, fat: 0)
        ])
        
        // Mid-Morning Section
        let midMorningSection = MealSection(name: "Mid-Morning Snack", items: [
            MealItemDisplay(name: "Sprouts Salad", quantity: "100g", protein: 9, carbs: 18, fat: 1),
            MealItemDisplay(name: "Fruit (Apple)", quantity: "1 medium", protein: 0, carbs: 19, fat: 0)
        ])
        
        // Lunch Section
        let lunchSection = MealSection(name: "Lunch", items: [
            MealItemDisplay(name: "Dal (lentils)", quantity: "1 cup", protein: 9, carbs: 27, fat: 1),
            MealItemDisplay(name: "Brown Rice", quantity: "½ cup", protein: 2, carbs: 22, fat: 1),
            MealItemDisplay(name: "Mixed Veggies", quantity: "1 cup", protein: 3, carbs: 13, fat: 0),
            MealItemDisplay(name: "Paneer Bhurji", quantity: "100g", protein: 14, carbs: 4, fat: 10)
        ])
        
        // Evening Snack Section
        let eveningSnackSection = MealSection(name: "Evening Snack", items: [
            MealItemDisplay(name: "Mixed Nuts", quantity: "30g", protein: 6, carbs: 6, fat: 14),
            MealItemDisplay(name: "Buttermilk", quantity: "1 glass", protein: 3, carbs: 6, fat: 1)
        ])
        
        // Post-Workout Section
        let postWorkoutSection = MealSection(name: "Post-Workout", items: [
            MealItemDisplay(name: "Banana", quantity: "1 small", protein: 1, carbs: 23, fat: 0),
            MealItemDisplay(name: "Whey Protein", quantity: "1 scoop", protein: 24, carbs: 3, fat: 1)
        ])
        
        // Dinner Section
        let dinnerSection = MealSection(name: "Dinner", items: [
            MealItemDisplay(name: "Quinoa Khichdi", quantity: "1 cup", protein: 8, carbs: 30, fat: 3),
            MealItemDisplay(name: "Tofu Stir Fry", quantity: "100g", protein: 8, carbs: 4, fat: 5)
        ])
        
        // Before Bed Section
        let beforeBedSection = MealSection(name: "Before Bed", items: [
            MealItemDisplay(name: "Turmeric milk (low-fat)", quantity: "150–200ml", protein: 6, carbs: 9, fat: 3),
            MealItemDisplay(name: "Soaked figs or date", quantity: "2 figs or 1 date", protein: 0, carbs: 10, fat: 0)
        ])

        // Supplements & Workout Plan as a note section
        let supplementsSection = MealSection(name: "Supplements & Workout Plan", items: [
            MealItemDisplay(name: "Ashwagandha (morning)", quantity: "500mg", protein: 0, carbs: 0, fat: 0),
            MealItemDisplay(name: "Shatavari (optional)", quantity: "As directed", protein: 0, carbs: 0, fat: 0),
            MealItemDisplay(name: "Triphala (before bed, optional)", quantity: "As needed", protein: 0, carbs: 0, fat: 0),
            MealItemDisplay(name: "WORKOUT SPLIT:", quantity: "6 days/week: Muscle gain + fat loss", protein: 0, carbs: 0, fat: 0),
            MealItemDisplay(name: "Day 1: Chest + Triceps", quantity: "", protein: 0, carbs: 0, fat: 0),
            MealItemDisplay(name: "Day 2: Back + Biceps", quantity: "", protein: 0, carbs: 0, fat: 0),
            MealItemDisplay(name: "Day 3: Legs + Core", quantity: "", protein: 0, carbs: 0, fat: 0),
            MealItemDisplay(name: "Day 4: Shoulders + Traps", quantity: "", protein: 0, carbs: 0, fat: 0),
            MealItemDisplay(name: "Day 5: Functional/HIIT", quantity: "", protein: 0, carbs: 0, fat: 0),
            MealItemDisplay(name: "Day 6: Full Body", quantity: "", protein: 0, carbs: 0, fat: 0),
            MealItemDisplay(name: "Day 7: Rest", quantity: "", protein: 0, carbs: 0, fat: 0)
        ])

        // Return combined array
        return [
            earlyMorningSection,
            breakfastSection,
            midMorningSection,
            lunchSection,
            eveningSnackSection,
            postWorkoutSection,
            dinnerSection,
            beforeBedSection,
            supplementsSection
        ]
    }
    
    var body: some View {
        List {
            ForEach(viewModel.meals) { meal in
                HStack {
                    Button(action: {
                        viewModel.toggleMeal(meal)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Image(systemName: meal.isChecked ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(meal.isChecked ? .accentDynamic : .gray)
                            .imageScale(.large)
                    }
                    .buttonStyle(PlainButtonStyle())
                    VStack(alignment: .leading) {
                        Text(meal.name ?? "Unknown Meal")
                            .font(.headline)
                        Text(meal.quantity ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { 
                        // Create a MealItemDisplay from Core Data MealItem
                        let displayItem = MealItemDisplay(
                            name: meal.name ?? "Unknown Meal",
                            quantity: meal.quantity ?? "",
                            protein: Int(meal.protein),
                            carbs: Int(meal.carbs),
                            fat: Int(meal.fat),
                            isChecked: meal.isChecked,
                            date: meal.date ?? Date()
                        )
                        showNutrition = displayItem
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.accentDynamic)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .contentShape(Rectangle())
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Diet Plan")
        .sheet(item: $showNutrition) { item in
            NutritionSheet(item: item)
        }
        .onAppear {
            viewModel.resetMealsIfNeeded()
        }
        // Use appropriate onChange based on iOS version
        #if swift(>=5.9)
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                viewModel.resetMealsIfNeeded()
            }
        }
        #else
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.resetMealsIfNeeded()
            }
        }
        #endif
    }
}

struct NutritionSheet: View {
    let item: MealItemDisplay
    var body: some View {
        VStack(spacing: 16) {
            Text(item.name)
                .font(.title2).bold()
            Text(item.quantity)
                .font(.headline)
                .foregroundColor(.secondary)
            Divider()
            HStack {
                VStack {
                    Text("Protein")
                        .font(.caption)
                    Text("\(item.protein)g")
                        .bold()
                        .foregroundColor(.green)
                }
                Spacer()
                VStack {
                    Text("Carbs")
                        .font(.caption)
                    Text("\(item.carbs)g")
                        .bold()
                        .foregroundColor(.orange)
                }
                Spacer()
                VStack {
                    Text("Fat")
                        .font(.caption)
                    Text("\(item.fat)g")
                        .bold()
                        .foregroundColor(.red)
                }
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}


