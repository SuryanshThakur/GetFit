import SwiftUI

extension Color {
    static let cardBackground = Color(.secondarySystemBackground)
    static let accentDynamic: Color = {
        let key = UserDefaults.standard.string(forKey: "accentColor") ?? "orange"
        switch key {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        default: return .orange
        }
    }()
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let progressRing = Color.accentDynamic
}
