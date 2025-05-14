import Foundation
import CoreData
import SwiftUI

class DietPlanViewModel: ObservableObject {
    @Published var meals: [MealItem] = []
    private let context: NSManagedObjectContext
    private let calendar = Calendar.current
    
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchMealsForToday()
    }
    
    func fetchMealsForToday() {
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let request: NSFetchRequest<MealItem> = MealItem.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealItem.name, ascending: true)]
        do {
            let fetched = try context.fetch(request)
            if fetched.isEmpty {
                insertDefaultMeals(for: startOfDay)
                meals = try context.fetch(request)
            } else {
                meals = fetched
            }
        } catch {
            print("Fetch error: \(error)")
        }
    }
    
    func insertDefaultMeals(for date: Date) {
        let defaults = Self.getDefaultMeals(for: date)
        for m in defaults {
            let item = MealItem(context: context)
            item.id = UUID()
            item.name = m.name
            item.quantity = m.quantity
            item.date = date
            item.isChecked = false
            item.protein = Int16(m.protein)
            item.carbs = Int16(m.carbs)
            item.fat = Int16(m.fat)
        }
        try? context.save()
    }
    
    // Default meals for the Core Data entity
    static func getDefaultMeals(for date: Date) -> [MealItemDisplay] {
        return [
            // Early Morning
            MealItemDisplay(name: "Lukewarm water with lemon + chia seeds", quantity: "1 glass + 1 tsp chia", protein: 1, carbs: 2, fat: 1),
            MealItemDisplay(name: "Soaked almonds", quantity: "6 pcs", protein: 2, carbs: 2, fat: 4),
            MealItemDisplay(name: "Walnuts", quantity: "2 pcs", protein: 1, carbs: 2, fat: 9),
            MealItemDisplay(name: "Ashwagandha (tablet/powder)", quantity: "500mg", protein: 0, carbs: 0, fat: 0),
            // Breakfast
            MealItemDisplay(name: "Moong dal chilla with paneer", quantity: "2 large + 50g paneer", protein: 18, carbs: 28, fat: 8),
            MealItemDisplay(name: "Green chutney", quantity: "2 tbsp", protein: 1, carbs: 2, fat: 1),
            MealItemDisplay(name: "Curd (low-fat)", quantity: "150g", protein: 5, carbs: 6, fat: 2),
            MealItemDisplay(name: "Fruit (papaya/banana)", quantity: "100–150g", protein: 1, carbs: 18, fat: 0),
            // Mid-Morning
            MealItemDisplay(name: "Roasted chana", quantity: "30g", protein: 5, carbs: 15, fat: 1),
            MealItemDisplay(name: "Coconut water", quantity: "1 glass", protein: 0, carbs: 8, fat: 0),
            // Lunch
            MealItemDisplay(name: "Boiled Rajma/Chole", quantity: "200g cooked", protein: 14, carbs: 36, fat: 2),
            MealItemDisplay(name: "Brown rice or Quinoa", quantity: "100g cooked", protein: 3, carbs: 22, fat: 1),
            MealItemDisplay(name: "Mixed vegetable sabzi (dry)", quantity: "1 bowl", protein: 3, carbs: 10, fat: 2),
            MealItemDisplay(name: "Salad (cucumber, beetroot)", quantity: "1 bowl", protein: 1, carbs: 8, fat: 0),
            MealItemDisplay(name: "Ghee (for cooking)", quantity: "1 tsp", protein: 0, carbs: 0, fat: 5),
            // Evening Snack / Pre-Workout
            MealItemDisplay(name: "Sprouts salad (moong + veggies)", quantity: "100–150g", protein: 8, carbs: 16, fat: 1),
            MealItemDisplay(name: "Black coffee / Green tea", quantity: "1 cup", protein: 0, carbs: 0, fat: 0),
            MealItemDisplay(name: "Dates", quantity: "2 pcs", protein: 0, carbs: 12, fat: 0),
            MealItemDisplay(name: "Peanut butter toast (whole wheat)", quantity: "1 slice + 1 tsp PB", protein: 4, carbs: 16, fat: 5),
            // Post-Workout
            MealItemDisplay(name: "Boiled chickpeas (light masala)", quantity: "150g cooked", protein: 8, carbs: 24, fat: 2),
            MealItemDisplay(name: "Banana or boiled sweet potato", quantity: "1 medium (100g)", protein: 1, carbs: 23, fat: 0),
            MealItemDisplay(name: "Coconut water or lemon water", quantity: "1 glass", protein: 0, carbs: 8, fat: 0),
            // Dinner
            MealItemDisplay(name: "Paneer bhurji / tofu stir fry", quantity: "100g paneer/tofu", protein: 14, carbs: 4, fat: 10),
            MealItemDisplay(name: "Whole wheat roti", quantity: "1–2 pcs", protein: 6, carbs: 24, fat: 1),
            MealItemDisplay(name: "Light sabzi (lauki/tinda)", quantity: "1 bowl", protein: 2, carbs: 8, fat: 1),
            MealItemDisplay(name: "Curd or buttermilk", quantity: "1 small bowl/glass", protein: 4, carbs: 6, fat: 2),
            // Before Bed
            MealItemDisplay(name: "Turmeric milk (low-fat)", quantity: "150–200ml", protein: 6, carbs: 9, fat: 3),
            MealItemDisplay(name: "Soaked figs or date", quantity: "2 figs or 1 date", protein: 0, carbs: 10, fat: 0)
        ]
    }
    
    func toggleMeal(_ meal: MealItem) {
        meal.isChecked.toggle()
        try? context.save()
        fetchMealsForToday()
    }
    
    func resetMealsIfNeeded() {
        let lastDate = meals.first?.date ?? Date()
        if !calendar.isDateInToday(lastDate) {
            for meal in meals { meal.isChecked = false }
            try? context.save()
            fetchMealsForToday()
        }
    }
    
    static func defaultMeals(for date: Date) -> [(name: String, quantity: String, protein: Int, carbs: Int, fat: Int)] {
        [
            ("Soaked Almonds", "6 pcs", 2, 2, 4),
            ("Warm Lemon Water", "1 glass", 0, 1, 0),
            ("Oats Upma", "40g oats, 100ml milk", 6, 24, 3),
            ("Greek Yogurt", "100g", 8, 4, 0),
            ("Sprouts Salad", "100g", 9, 18, 1),
            ("Fruit (Apple)", "1 medium", 0, 19, 0),
            ("Dal (lentils)", "1 cup", 9, 27, 1),
            ("Brown Rice", "½ cup", 2, 22, 1),
            ("Mixed Veggies", "1 cup", 3, 13, 0),
            ("Paneer Bhurji", "100g", 14, 4, 10),
            ("Mixed Nuts", "30g", 6, 6, 14),
            ("Buttermilk", "1 glass", 3, 6, 1),
            ("Banana", "1 small", 1, 23, 0),
            ("Whey Protein", "1 scoop", 24, 3, 1),
            ("Quinoa Khichdi", "1 cup", 8, 30, 3),
            ("Tofu Stir Fry", "100g", 8, 4, 5),
            ("Low-fat Milk", "1 cup", 8, 12, 3)
        ]
    }
}
