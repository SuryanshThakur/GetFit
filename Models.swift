import Foundation
import CoreData
import SwiftUI

// MARK: - MealItem (Core Data Entity)
// If using Core Data, this should be generated from your .xcdatamodeld, but here's a fallback struct for preview/testing.
// For Core Data, you will have a class like this (if not, you can use this struct for SwiftUI previews):

@objc(MealItem)
public class MealItem: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var quantity: String?
    @NSManaged public var protein: Int16
    @NSManaged public var carbs: Int16
    @NSManaged public var fat: Int16
    @NSManaged public var isChecked: Bool
    @NSManaged public var date: Date?
}

// MARK: - MealItem Fetch Request
extension MealItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MealItem> {
        return NSFetchRequest<MealItem>(entityName: "MealItem")
    }
}

// MARK: - Display models for UI that don't require Core Data
struct MealItemDisplay: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var quantity: String
    var protein: Int
    var carbs: Int
    var fat: Int
    var isChecked: Bool = false
    var date: Date = Date()
}

// MARK: - MealSection (for grouping meals in the UI)
struct MealSection: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var items: [MealItemDisplay]
}

// MARK: - Meal (for NutritionSheet, matches MealItem's properties)
struct Meal: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var quantity: String
    var protein: Int
    var carbs: Int
    var fat: Int
}

// MARK: - Other Models (for future use)


struct Settings: Identifiable, Hashable {
    let id = UUID()
    var reminderTimes: [Date]
    // Add other settings fields as needed
}
