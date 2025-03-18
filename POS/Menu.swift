//
//  Menu.swift
//  POS
//
//  Created by Tayson Nguyen on 2019-04-23.
//  Copyright © 2019 TouchBistro. All rights reserved.
//

import Foundation
import BillCalculator

struct Item: BillableItem {
    var id: UUID
    var name: String
    var price: Decimal
    var isTaxExempt: Bool
    var category: BillableItemCategory
    
    init(id: UUID = UUID(), name: String, price: Decimal, isTaxExempt: Bool, category: BillableItemCategory) {
        self.id = id
        self.name = name
        self.price = price
        self.isTaxExempt = isTaxExempt
        self.category = category
    }
    
    mutating func toggleTaxExempted() {
        isTaxExempt.toggle()
    }
}

func category(_ category: BillableItemCategory) -> (String, Decimal) -> Item {
    return { name, price in
        return Item(name: name, price: price, isTaxExempt: false, category: category)
    }
}

let appetizers = category(.Appetizer)
let mains = category(.Main)
let drinks = category(.Drink)
let alcohol = category(.Alcohol)

let appetizersCategory = [
    appetizers("Nachos", 13.99),
    appetizers("Calamari", 11.99),
    appetizers("Caesar Salad", 10.99),
]

let mainsCategory = [
    mains("Burger", 9.99),
    mains("Hotdog", 3.99),
    mains("Pizza", 12.99),
]

let drinksCategory = [
    drinks("Water", 0),
    drinks("Pop", 2.00),
    drinks("Orange Juice", 3.00),
]

let alcoholCategory = [
    alcohol("Beer", 5.00),
    alcohol("Cider", 6.00),
    alcohol("Wine", 7.00),
]

let tax1 = ServiceTax(name: "Service Tax - 10%", rate: 10.0)
let tax2 = FoodTax(name: "Food GST - 5%", rate: 5.00)
let alcoholTax = AlcoholTax(name: "Alcohol Tax - 15%", rate: 15.00)

let discount5Dollars = FlatRateDiscount(name: "Coupon - $5", type: .amount(5.0))
let discount10Percent = SampleDiscount(name: "Flat 10%", type: .percentage(10.0))
let discount20Percent = HappyHourDiscount(name: "Happy Hour - 5%", type: .percentage(5.0))

var discounts: [any Discount] = [
    discount5Dollars,
    discount10Percent,
    discount20Percent,
]

var appliedDiscountsInOrder: [any Discount] = [
    
]

var taxes: [any Tax] = [
    tax1,
    tax2,
    alcoholTax,
]

var categories = [
    (name: "Appetizers", items: appetizersCategory),
    (name: "Mains", items: mainsCategory),
    (name: "Drinks", items: drinksCategory),
    (name: "Alcohol", items: alcoholCategory),
]

extension Array where Element == any Discount {
    public mutating func removeDiscount(_ discount: any Discount) {
        self = self.filter { $0.id != discount.id }
    }
}
