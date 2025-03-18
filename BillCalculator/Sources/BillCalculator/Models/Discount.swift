import Foundation

public enum DiscountType {
    case percentage(Decimal) // Stored as a decimal (e.g., 0.15 for 15%)
    case amount(Decimal)     // Fixed amount in dollars
}

public protocol Discount: Identifiable {
    var id: UUID { get }
    var name: String { get }
    var isEnabled: Bool { get }
    var type: DiscountType { get }
    @discardableResult mutating func toggleEnabled() -> Bool
}

extension Discount {
    static public func == (lhs: any Discount, rhs: any Discount) -> Bool {
        lhs.id == rhs.id
    }
}
