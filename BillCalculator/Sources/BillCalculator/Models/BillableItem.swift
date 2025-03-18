import Foundation

public enum BillableItemCategory: String, Hashable {
    case Appetizer
    case Main
    case Dessert
    case Drink
    case Alcohol
    case Miscellaneous
    
    public static func allCases() -> [BillableItemCategory] {
        [.Appetizer, .Main, .Dessert, .Drink, .Alcohol, .Miscellaneous]
    }
    
    public static func foodCategories() -> [BillableItemCategory] {
        [.Appetizer, .Main, .Dessert]
    }
    
    public static func beverageCategories() -> [BillableItemCategory] {
        [.Drink, .Alcohol]
    }
    
    public static func allButAlcoholicBeverage() -> [BillableItemCategory] {
        [.Appetizer, .Main, .Dessert, .Drink]
    }
}

public protocol BillableItem: Identifiable {
    var id: UUID { get }
    var name: String { get }
    var price: Decimal { get }
    var isTaxExempt: Bool { get }
    var category: BillableItemCategory { get }
}
