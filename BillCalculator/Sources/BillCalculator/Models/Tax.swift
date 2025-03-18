import Foundation

public protocol Tax: Identifiable {
    var id: UUID { get }
    var name: String { get }
    var rate: Decimal { get }
    var isEnabled: Bool { get }
    var applicableCategories: [BillableItemCategory] { get }
    @discardableResult mutating func toggleEnabled() -> Bool
}

