import Foundation

public struct ServiceTax: Tax {
    public var id: UUID
    public var name: String
    public var rate: Decimal
    public var isEnabled: Bool
    public var applicableCategories: [BillableItemCategory]
    
    public init(id: UUID = UUID(), name: String, rate: Decimal, isEnabled: Bool = true, applicableCategories: [BillableItemCategory] = BillableItemCategory.allButAlcoholicBeverage()) {
        self.id = id
        self.name = name
        self.rate = rate
        self.isEnabled = isEnabled
        self.applicableCategories = applicableCategories
    }
    
    @discardableResult public mutating func toggleEnabled() -> Bool {
        isEnabled.toggle()
        return isEnabled
    }
}
