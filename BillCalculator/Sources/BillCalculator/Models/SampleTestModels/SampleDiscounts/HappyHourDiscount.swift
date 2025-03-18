import Foundation

public struct HappyHourDiscount: Discount {
    public var id: UUID
    public var name: String
    public var isEnabled: Bool
    public var type: DiscountType
    
    public init(id: UUID = UUID(), name: String, isEnabled: Bool = false, type: DiscountType) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.type = type
    }
    
    @discardableResult public mutating func toggleEnabled() -> Bool {
        isEnabled.toggle()
        return isEnabled
    }
}
