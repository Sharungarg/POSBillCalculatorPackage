import Foundation

public protocol Bill {
    var subtotal: Decimal { get }
    var taxTotal: Decimal { get }
    var discountTotal: Decimal { get }
    var grandTotal: Decimal { get }
    
    var itemizedTaxes: [UUID: Decimal] { get }
    var itemizedDiscounts: [UUID: Decimal] { get }
}


public struct BillOutput: Bill {
    public let subtotal: Decimal
    public let taxTotal: Decimal
    public let discountTotal: Decimal
    public let grandTotal: Decimal
    
    // Additional fields for detailed breakdown
    public let itemizedTaxes: [UUID: Decimal]
    public let itemizedDiscounts: [UUID: Decimal]
}
