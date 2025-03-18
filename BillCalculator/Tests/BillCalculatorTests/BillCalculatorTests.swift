import XCTest
@testable import BillCalculator

// MARK: - Test Models
// Protocol implementations for testing
struct TestBillableItem: BillableItem {
    let id = UUID()
    let name: String
    let price: Decimal
    let category: BillableItemCategory
    let isTaxExempt: Bool
    
    init(name: String, price: Decimal, category: BillableItemCategory, isTaxExempt: Bool = false) {
        self.name = name
        self.price = price
        self.category = category
        self.isTaxExempt = isTaxExempt
    }
}

struct TestTax: Tax {
    let id = UUID()
    let name: String
    let rate: Decimal
    var isEnabled: Bool = true
    let applicableCategories: [BillableItemCategory]
    
    init(name: String, rate: Decimal, applicableCategories: [BillableItemCategory] = [], isEnabled: Bool = true) {
        self.name = name
        self.rate = rate
        self.applicableCategories = applicableCategories
        self.isEnabled = isEnabled
    }
    
    @discardableResult
    mutating func toggleEnabled() -> Bool {
        isEnabled.toggle()
        return isEnabled
    }
}

struct TestDiscount: Discount {
    let id = UUID()
    let name: String
    var isEnabled: Bool = true
    let type: DiscountType
    
    init(name: String, type: DiscountType, isEnabled: Bool = true) {
        self.name = name
        self.type = type
        self.isEnabled = isEnabled
    }
    
    @discardableResult
    mutating func toggleEnabled() -> Bool {
        isEnabled.toggle()
        return isEnabled
    }
}

// MARK: - Test Case
final class BillCalculatorTests: XCTestCase {
    
    var calculator: BillCalculator!
    
    override func setUp() {
        super.setUp()
        calculator = BillCalculator()
    }
    
    override func tearDown() {
        calculator = nil
        super.tearDown()
    }
    
    // MARK: - Basic Tests
    
    func testEmptyBill() {
        // When
        let bill = calculator.calculateBill(items: [], taxes: [], discounts: [])
        
        // Then
        XCTAssertEqual(bill.subtotal, 0)
        XCTAssertEqual(bill.taxTotal, 0)
        XCTAssertEqual(bill.discountTotal, 0)
        XCTAssertEqual(bill.grandTotal, 0)
        XCTAssertTrue(bill.itemizedTaxes.isEmpty)
        XCTAssertTrue(bill.itemizedDiscounts.isEmpty)
    }
    
    func testSubtotalCalculation() {
        // Given
        let items = [
            TestBillableItem(name: "Burger", price: 10.99, category: .Main),
            TestBillableItem(name: "Fries", price: 4.50, category: .Appetizer),
            TestBillableItem(name: "Soda", price: 2.99, category: .Drink)
        ]
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [], discounts: [])
        
        // Then
        XCTAssertEqual(bill.subtotal, 18.48)
        XCTAssertEqual(bill.grandTotal, 18.48)  // No taxes or discounts
    }
    
    // MARK: - Tax Tests
    
    func testBasicTaxCalculation() {
        // Given
        let items = [
            TestBillableItem(name: "Burger", price: 10.00, category: .Main)
        ]
        let salesTax = TestTax(name: "Sales Tax", rate: 8.0)
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [salesTax], discounts: [])
        
        // Then
        XCTAssertEqual(bill.subtotal, 10.00)
        XCTAssertEqual(bill.taxTotal, 0.80)
        XCTAssertEqual(bill.grandTotal, 10.80)
        XCTAssertEqual(bill.itemizedTaxes[salesTax.id], 0.80)
    }
    
    func testMultipleTaxes() {
        // Given
        let items = [
            TestBillableItem(name: "Burger", price: 10.00, category: .Main),
            TestBillableItem(name: "Beer", price: 5.00, category: .Alcohol)
        ]
        let salesTax = TestTax(name: "Sales Tax", rate: 8.0)
        let alcoholTax = TestTax(name: "Alcohol Tax", rate: 5.0, applicableCategories: [.Alcohol])
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [salesTax, alcoholTax], discounts: [])
        
        // Then
        XCTAssertEqual(bill.subtotal, 15.00)
        XCTAssertEqual(bill.taxTotal, 1.45)  // $1.20 (8% of $15) + $0.25 (5% of $5)
        XCTAssertEqual(bill.grandTotal, 16.45)
        XCTAssertEqual(bill.itemizedTaxes[salesTax.id], 1.20)
        XCTAssertEqual(bill.itemizedTaxes[alcoholTax.id], 0.25)
    }
    
    func testTaxExemptItems() {
        // Given
        let items = [
            TestBillableItem(name: "Regular Item", price: 10.00, category: .Miscellaneous),
            TestBillableItem(name: "Exempt Item", price: 10.00, category: .Main, isTaxExempt: true)
        ]
        let salesTax = TestTax(name: "Sales Tax", rate: 10.0)
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [salesTax], discounts: [])
        
        // Then
        XCTAssertEqual(bill.subtotal, 20.00)
        XCTAssertEqual(bill.taxTotal, 1.00)  // Only taxing the non-exempt item
        XCTAssertEqual(bill.grandTotal, 21.00)
    }
    
    func testCategorySpecificTaxes() {
        // Given
        let items = [
            TestBillableItem(name: "Food Item", price: 10.00, category: .Main),
            TestBillableItem(name: "Beverage Item", price: 10.00, category: .Drink)
        ]
        let foodTax = TestTax(name: "Food Tax", rate: 5.0, applicableCategories: [.Main, .Appetizer, .Dessert])
        let beverageTax = TestTax(name: "Beverage Tax", rate: 8.0, applicableCategories: [.Drink, .Alcohol])
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [foodTax, beverageTax], discounts: [])
        
        // Then
        XCTAssertEqual(bill.subtotal, 20.00)
        XCTAssertEqual(bill.taxTotal, 1.30)  // $0.50 (5% of $10) + $0.80 (8% of $10)
        XCTAssertEqual(bill.grandTotal, 21.30)
        XCTAssertEqual(bill.itemizedTaxes[foodTax.id], 0.50)
        XCTAssertEqual(bill.itemizedTaxes[beverageTax.id], 0.80)
    }
    
    func testDisabledTaxesAreNotApplied() {
        // Given
        let items = [
            TestBillableItem(name: "Burger", price: 10.00, category: .Main)
        ]
        var salesTax = TestTax(name: "Sales Tax", rate: 8.0, isEnabled: true)
        salesTax.toggleEnabled() // Disable the tax
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [salesTax], discounts: [])
        
        // Then
        XCTAssertEqual(bill.subtotal, 10.00)
        XCTAssertEqual(bill.taxTotal, 0.00) // Tax should not be applied
        XCTAssertEqual(bill.grandTotal, 10.00)
        XCTAssertNil(bill.itemizedTaxes[salesTax.id])
    }
    
    func testPredefinedCategoryGroups() {
        // Given
        let items = [
            TestBillableItem(name: "Appetizer", price: 10.00, category: .Appetizer),
            TestBillableItem(name: "Main Course", price: 20.00, category: .Main),
            TestBillableItem(name: "Dessert", price: 8.00, category: .Dessert),
            TestBillableItem(name: "Soft Drink", price: 5.00, category: .Drink),
            TestBillableItem(name: "Wine", price: 15.00, category: .Alcohol)
        ]
        
        // Apply tax only to food categories
        let foodTax = TestTax(name: "Food Tax", rate: 5.0, applicableCategories: BillableItemCategory.foodCategories())
        
        // Apply tax only to beverage categories
        let beverageTax = TestTax(name: "Beverage Tax", rate: 8.0, applicableCategories: BillableItemCategory.beverageCategories())
        
        // Apply tax to everything except alcohol
        let nonAlcoholTax = TestTax(name: "Non-Alcohol Tax", rate: 2.0, applicableCategories: BillableItemCategory.allButAlcoholicBeverage())
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [foodTax, beverageTax, nonAlcoholTax], discounts: [])
        
        // Then
        let foodItems = Decimal(10.00 + 20.00 + 8.00)
        let beverageItems = Decimal(5.00 + 15.00)
        let nonAlcoholItems = Decimal(10.00 + 20.00 + 8.00 + 5.00)
        
        let expectedFoodTax = foodItems * Decimal(0.05)
        let expectedBeverageTax = beverageItems * Decimal(0.08)
        let expectedNonAlcoholTax = nonAlcoholItems * Decimal(0.02)
        
        let expectedTotalTax = expectedFoodTax + expectedBeverageTax + expectedNonAlcoholTax
        
        XCTAssertEqual(bill.subtotal, 58.00)
        XCTAssertEqual(bill.taxTotal, expectedTotalTax)
        XCTAssertEqual(bill.itemizedTaxes[foodTax.id], expectedFoodTax)
        XCTAssertEqual(bill.itemizedTaxes[beverageTax.id], expectedBeverageTax)
        XCTAssertEqual(bill.itemizedTaxes[nonAlcoholTax.id], expectedNonAlcoholTax)
    }
    
    // MARK: - Discount Tests
    
    func testPercentageDiscount() {
        // Given
        let items = [
            TestBillableItem(name: "Item", price: 100.00, category: .Miscellaneous)
        ]
        let discount = TestDiscount(name: "Percentage Off", type: .percentage(10))
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [], discounts: [discount])
        
        // Then
        XCTAssertEqual(bill.subtotal, 100.00)
        XCTAssertEqual(bill.discountTotal, 10.00)
        XCTAssertEqual(bill.grandTotal, 90.00)
        XCTAssertEqual(bill.itemizedDiscounts[discount.id], 10.00)
    }
    
    func testFixedAmountDiscount() {
        // Given
        let items = [
            TestBillableItem(name: "Item", price: 100.00, category: .Miscellaneous)
        ]
        let discount = TestDiscount(name: "Fixed Amount", type: .amount(15.00))
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [], discounts: [discount])
        
        // Then
        XCTAssertEqual(bill.subtotal, 100.00)
        XCTAssertEqual(bill.discountTotal, 15.00)
        XCTAssertEqual(bill.grandTotal, 85.00)
        XCTAssertEqual(bill.itemizedDiscounts[discount.id], 15.00)
    }
    
    func testMultipleDiscounts() {
        // Given
        let items = [
            TestBillableItem(name: "Item", price: 100.00, category: .Miscellaneous)
        ]
        let percentageDiscount = TestDiscount(name: "10% Off", type: .percentage(10))
        let fixedDiscount = TestDiscount(name: "$5 Off", type: .amount(5.00))
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [], discounts: [percentageDiscount, fixedDiscount])
        
        // Then
        XCTAssertEqual(bill.subtotal, 100.00)
        XCTAssertEqual(bill.discountTotal, 15.00)  // $10 (10% of $100) + $5
        XCTAssertEqual(bill.grandTotal, 85.00)
        XCTAssertEqual(bill.itemizedDiscounts[percentageDiscount.id], 10.00)
        XCTAssertEqual(bill.itemizedDiscounts[fixedDiscount.id], 5.00)
    }
    
    func testDiscountOrderMatters() {
        // Given
        let items = [
            TestBillableItem(name: "Item", price: 100.00, category: .Miscellaneous)
        ]
        
        // When - Apply percentage discount first
        let bill1 = calculator.calculateBill(
            items: items,
            taxes: [],
            discounts: [
                TestDiscount(name: "10% Off", type: .percentage(10)),
                TestDiscount(name: "$20 Off", type: .amount(20.00))
            ]
        )
        
        // When - Apply fixed amount discount first
        let bill2 = calculator.calculateBill(
            items: items,
            taxes: [],
            discounts: [
                TestDiscount(name: "$20 Off", type: .amount(20.00)),
                TestDiscount(name: "10% Off", type: .percentage(10))
            ]
        )
        
        // Then
        XCTAssertEqual(bill1.grandTotal, 70.00)  // $100 - $10 - $20 = $70
        XCTAssertEqual(bill2.grandTotal, 72.00)  // $100 - $20 - $8 = $72 ($8 is 10% of $80)
        XCTAssertNotEqual(bill1.grandTotal, bill2.grandTotal)  // Order matters!
    }
    
    func testFixedDiscountCannotExceedTotal() {
        // Given
        let items = [
            TestBillableItem(name: "Small Item", price: 10.00, category: .Miscellaneous)
        ]
        let discount = TestDiscount(name: "Big Discount", type: .amount(20.00))
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [], discounts: [discount])
        
        // Then
        XCTAssertEqual(bill.subtotal, 10.00)
        XCTAssertEqual(bill.discountTotal, 10.00)  // Discount capped at total
        XCTAssertEqual(bill.grandTotal, 0.00)
        XCTAssertEqual(bill.itemizedDiscounts[discount.id], 10.00)
    }
    
    func testDisabledDiscountsAreNotApplied() {
        // Given
        let items = [
            TestBillableItem(name: "Item", price: 100.00, category: .Miscellaneous)
        ]
        var discount = TestDiscount(name: "Disabled Discount", type: .percentage(10), isEnabled: true)
        discount.toggleEnabled() // Disable the discount
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [], discounts: [discount])
        
        // Then
        XCTAssertEqual(bill.subtotal, 100.00)
        XCTAssertEqual(bill.discountTotal, 0.00) // Discount should not be applied
        XCTAssertEqual(bill.grandTotal, 100.00)
        XCTAssertNil(bill.itemizedDiscounts[discount.id])
    }
    
    // MARK: - Comprehensive Tests
    
    func testCompleteCalculationWithTaxesAndDiscounts() {
        // Given
        let items = [
            TestBillableItem(name: "Main Course", price: 50.00, category: .Main),
            TestBillableItem(name: "Drink", price: 10.00, category: .Drink),
            TestBillableItem(name: "Dessert", price: 20.00, category: .Dessert, isTaxExempt: true)
        ]
        
        let generalTax = TestTax(name: "General Tax", rate: 8.0)
        let foodTax = TestTax(name: "Food Tax", rate: 2.0, applicableCategories: [.Main, .Appetizer, .Dessert])
        
        let percentageDiscount = TestDiscount(name: "Member Discount", type: .percentage(10))
        let fixedDiscount = TestDiscount(name: "Coupon", type: .amount(5.00))
        
        // When
        let bill = calculator.calculateBill(
            items: items,
            taxes: [generalTax, foodTax],
            discounts: [percentageDiscount, fixedDiscount]
        )
        
        // Then
        let expectedSubtotal = Decimal(80.00)
        let expectedTaxTotal = Decimal(5.80)  // (50 + 10) * 0.08 + 50 * 0.02 = 4.80 + 1.00 = 5.80
        let preDiscountTotal = expectedSubtotal + expectedTaxTotal  // 85.80
        let expectedPercentDiscount = preDiscountTotal * Decimal(0.1)  // 8.58
        let expectedFixedDiscount = Decimal(5.00)
        let expectedTotalDiscount = expectedPercentDiscount + expectedFixedDiscount  // 13.58
        let expectedGrandTotal = preDiscountTotal - expectedTotalDiscount  // 85.80 - 13.58 = 72.22
        
        XCTAssertEqual(bill.subtotal, expectedSubtotal)
        XCTAssertEqual(bill.taxTotal, expectedTaxTotal)
        XCTAssertEqual(bill.discountTotal, expectedTotalDiscount)
        XCTAssertEqual(bill.grandTotal, expectedGrandTotal)
        
        // Check itemized taxes
        XCTAssertEqual(bill.itemizedTaxes[generalTax.id], 4.80)
        XCTAssertEqual(bill.itemizedTaxes[foodTax.id], 1.00)
        
        // Check itemized discounts
        XCTAssertEqual(bill.itemizedDiscounts[percentageDiscount.id], expectedPercentDiscount)
        XCTAssertEqual(bill.itemizedDiscounts[fixedDiscount.id], expectedFixedDiscount)
    }
    
    func testEnabledStateHandling() {
        // Given
        let items = [
            TestBillableItem(name: "Item", price: 100.00, category: .Main)
        ]
        
        let enabledTax = TestTax(name: "Enabled Tax", rate: 10.0, isEnabled: true)
        var disabledTax = TestTax(name: "Disabled Tax", rate: 5.0, isEnabled: true)
        disabledTax.toggleEnabled()
        
        let enabledDiscount = TestDiscount(name: "Enabled Discount", type: .percentage(20), isEnabled: true)
        var disabledDiscount = TestDiscount(name: "Disabled Discount", type: .percentage(10), isEnabled: true)
        disabledDiscount.toggleEnabled()
        
        // When
        let bill = calculator.calculateBill(
            items: items,
            taxes: [enabledTax, disabledTax],
            discounts: [enabledDiscount, disabledDiscount]
        )
        
        // Then
        XCTAssertEqual(bill.subtotal, 100.00)
        XCTAssertEqual(bill.taxTotal, 10.00)  // Only enabled tax applied
        XCTAssertEqual(bill.itemizedTaxes[enabledTax.id], 10.00)
        XCTAssertNil(bill.itemizedTaxes[disabledTax.id])
        
        // Only enabled discount should be applied
        let expectedPreDiscountTotal = Decimal(110.00)  // Subtotal + tax
        let expectedDiscount = expectedPreDiscountTotal * Decimal(0.2)  // 20% of 110
        
        XCTAssertEqual(bill.discountTotal, expectedDiscount)
        XCTAssertEqual(bill.itemizedDiscounts[enabledDiscount.id], expectedDiscount)
        XCTAssertNil(bill.itemizedDiscounts[disabledDiscount.id])
        
        XCTAssertEqual(bill.grandTotal, expectedPreDiscountTotal - expectedDiscount)
    }
    
    // MARK: - Edge Cases
    
    func testNoApplicableTaxes() {
        // Given
        let items = [
            TestBillableItem(name: "Item", price: 10.00, category: .Main)
        ]
        let beverageTax = TestTax(name: "Beverage Tax", rate: 5.0, applicableCategories: [.Drink, .Alcohol])
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [beverageTax], discounts: [])
        
        // Then
        XCTAssertEqual(bill.taxTotal, 0.00)  // No tax applied since item isn't in applicable category
    }
    
    func testAllItemsTaxExempt() {
        // Given
        let items = [
            TestBillableItem(name: "Item 1", price: 10.00, category: .Main, isTaxExempt: true),
            TestBillableItem(name: "Item 2", price: 15.00, category: .Drink, isTaxExempt: true)
        ]
        let salesTax = TestTax(name: "Sales Tax", rate: 10.0)
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [salesTax], discounts: [])
        
        // Then
        XCTAssertEqual(bill.subtotal, 25.00)
        XCTAssertEqual(bill.taxTotal, 0.00)  // All items are tax exempt
        XCTAssertEqual(bill.grandTotal, 25.00)
    }
    
    func testZeroRateTax() {
        // Given
        let items = [
            TestBillableItem(name: "Item", price: 10.00, category: .Main)
        ]
        let zeroTax = TestTax(name: "Zero Tax", rate: 0.0)
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [zeroTax], discounts: [])
        
        // Then
        XCTAssertEqual(bill.taxTotal, 0.00)
        XCTAssertEqual(bill.itemizedTaxes[zeroTax.id], 0.00)
    }
    
    func testZeroAmountDiscount() {
        // Given
        let items = [
            TestBillableItem(name: "Item", price: 10.00, category: .Main)
        ]
        let zeroDiscount = TestDiscount(name: "Zero Discount", type: .amount(0.00))
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [], discounts: [zeroDiscount])
        
        // Then
        XCTAssertEqual(bill.discountTotal, 0.00)
        XCTAssertEqual(bill.itemizedDiscounts[zeroDiscount.id], 0.00)
    }
    
    func testZeroPercentDiscount() {
        // Given
        let items = [
            TestBillableItem(name: "Item", price: 10.00, category: .Main)
        ]
        let zeroPercentDiscount = TestDiscount(name: "Zero Percent", type: .percentage(0))
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [], discounts: [zeroPercentDiscount])
        
        // Then
        XCTAssertEqual(bill.discountTotal, 0.00)
        XCTAssertEqual(bill.itemizedDiscounts[zeroPercentDiscount.id], 0.00)
    }
    
    func testDecimalPrecision() {
        // Given
        let items = [
            TestBillableItem(name: "Item", price: 0.01, category: .Main)  // 1 cent
        ]
        let tax = TestTax(name: "Tax", rate: 7.25)  // 7.25%
        
        // When
        let bill = calculator.calculateBill(items: items, taxes: [tax], discounts: [])
        
        // Then
        // 7.25% of $0.01 = $0.000725, which should be included in the tax total
        XCTAssertEqual(bill.taxTotal, Decimal(string: "0.000725")!)
        XCTAssertEqual(bill.grandTotal, Decimal(string: "0.010725")!)
    }
}
