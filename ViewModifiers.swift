import SwiftUI

// MARK: - View Modifiers for Handling API Changes

/// A view modifier that handles the deprecated onChange API
/// This allows us to use the new iOS 17 onChange syntax when available and fall back to the older syntax on earlier iOS versions
struct ChangeValueModifier<Value: Equatable>: ViewModifier {
    let value: Value
    let action: () -> Void
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            // Use the new two-parameter closure for iOS 17+
            content.onChange(of: value) { _, _ in
                action()
            }
        } else {
            // Use the older single-parameter closure for iOS 16 and earlier
            content.onChange(of: value) { _ in
                action()
            }
        }
    }
}
