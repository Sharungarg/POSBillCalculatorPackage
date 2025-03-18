import Foundation

public final class BillCalculator {
    
    public init() {}

    public func calculateBill(items: [any BillableItem], taxes: [any Tax], discounts: [any Discount]) -> Bill {
        // Calculate subtotal (sum of all item prices)
        let subtotal = items.reduce(Decimal.zero) { $0 + $1.price }
        
        // Calculate taxes
        let (appliedTaxedAmount, itemizedTaxes) = calculateTaxes(items: items, taxes: taxes, originalSubtotal: subtotal)
        
        // Apply discounts
        let (discountedAmount, itemizedDiscounts) = calculateDiscounts(preDiscountTaxedTotal: subtotal + appliedTaxedAmount, discounts: discounts)
        
        // Calculate grand total
        let grandTotal = subtotal + appliedTaxedAmount - discountedAmount
        
        return BillOutput(
            subtotal: subtotal,
            taxTotal: appliedTaxedAmount,
            discountTotal: discountedAmount,
            grandTotal: grandTotal,
            itemizedTaxes: itemizedTaxes,
            itemizedDiscounts: itemizedDiscounts
        )
    }
    
    // MARK: - Private Helper Methods
    private func calculateTaxes(items: [any BillableItem], taxes: [any Tax], originalSubtotal: Decimal) -> (Decimal, [UUID: Decimal]) {
        // Early return if no items or zero subtotal
        guard !items.isEmpty || originalSubtotal != 0 else {
            return (0, [:])
        }

        let enabledTaxes = taxes.filter { $0.isEnabled }
        
        // Group items by category for tax calculation
        var categoryTotals: [BillableItemCategory: Decimal] = [:]
        var totalTaxableAmount: Decimal = 0
        
        // Calculate total by category and total taxable amount
        for item in items {
            if !item.isTaxExempt {
                categoryTotals[item.category, default: 0] += item.price
                totalTaxableAmount += item.price
            }
        }
        
        var totalTax: Decimal = 0
        var itemizedTaxes: [UUID: Decimal] = [:]
        
        // Calculate tax for each tax type
        for tax in enabledTaxes {
            var taxableAmount: Decimal = 0
            
            if !tax.applicableCategories.isEmpty {
                // Tax applies only to specific categories
                for category in tax.applicableCategories {
                    taxableAmount += categoryTotals[category, default: 0]
                }
            } else {
                // Tax applies to all non-exempt items
                taxableAmount = totalTaxableAmount
            }
            
            // Calculate tax amount
            let taxAmount = (taxableAmount * tax.rate) / 100
            
            totalTax += taxAmount
            itemizedTaxes[tax.id] = taxAmount
        }
        
        return (totalTax, itemizedTaxes)
    }
    
    private func calculateDiscounts(preDiscountTaxedTotal: Decimal, discounts: [any Discount]) -> (totalDiscount: Decimal, itemizedDiscounts: [UUID: Decimal]) {
        
        let enabledDiscounts = discounts.filter { $0.isEnabled }
        
        var remainingAmount = preDiscountTaxedTotal
        var totalDiscount: Decimal = 0
        var itemizedDiscounts: [UUID: Decimal] = [:]
        
        for discount in enabledDiscounts {
            let discountAmount: Decimal
            
            switch discount.type {
            case .percentage(let rate):
                discountAmount = (remainingAmount * rate) / 100
            case .amount(let amount):
                // For fixed amounts, don't discount more than the remaining amount
                discountAmount = min(amount, remainingAmount)
            }
            
            remainingAmount -= discountAmount
            totalDiscount += discountAmount
            itemizedDiscounts[discount.id] = discountAmount
        }
        
        return (totalDiscount, itemizedDiscounts)
    }
}
