import Foundation
import SwiftUI

// MARK: - Shared Utilities
func defaultTime(hour: Int) -> Date {
    let cal = Calendar.current
    let now = Date()
    return cal.date(bySettingHour: hour, minute: 0, second: 0, of: now) ?? now
}
