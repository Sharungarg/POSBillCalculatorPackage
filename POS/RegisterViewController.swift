//
//  RegisterViewController.swift
//  POS
//
//  Created by Tayson Nguyen on 2019-04-23.
//  Copyright © 2019 TouchBistro. All rights reserved.
//

import UIKit
import BillCalculator

class RegisterViewController: UIViewController {
    let cellIdentifier = "Cell"
    
    @IBOutlet weak var menuTableView: UITableView!
    @IBOutlet weak var orderTableView: UITableView!
    
    @IBOutlet weak var subtotalLabel: UILabel!
    @IBOutlet weak var taxesLabel: UILabel!
    @IBOutlet weak var discountsLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    
    let viewModel = RegisterViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuTableView.dataSource = self
        orderTableView.dataSource = self
        menuTableView.delegate = self
        orderTableView.delegate = self
    }
    
    @IBAction func showTaxes() {
        let vc = TaxViewController(style: .grouped)
        vc.listener = self
        let navVc = UINavigationController(rootViewController: vc)
        navVc.modalPresentationStyle = .formSheet
        
        present(navVc, animated: true, completion: nil)
    }
    
    @IBAction func showDiscounts() {
        let vc = DiscountViewController(style: .grouped)
        vc.listener = self
        let navVc = UINavigationController(rootViewController: vc)
        navVc.modalPresentationStyle = .formSheet
        present(navVc, animated: true, completion: nil)
    }
    
    private func updateTotalBillFields() {
        let labels = viewModel.updatedBillLabels()
        subtotalLabel.text = labels.subtotal
        taxesLabel.text = labels.taxes
        discountsLabel.text = labels.discounts
        totalLabel.text = labels.grandTotal
    }
}

extension RegisterViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView == menuTableView {
            return viewModel.menuCategoryTitle(in: section)
            
        } else if tableView == orderTableView {
            return viewModel.orderTitle(in: section)
        }
        
        fatalError()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == menuTableView {
            return viewModel.numberOfMenuCategories()
        } else if tableView == orderTableView {
            return 1
        }
        
        fatalError()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == menuTableView {
            return viewModel.numberOfMenuItems(in: section)
            
        } else if tableView == orderTableView {
            return viewModel.numberOfOrderItems(in: section)
        }
        
        fatalError()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        
        if tableView == menuTableView {
            cell.textLabel?.text = viewModel.menuItemName(at: indexPath)
            cell.detailTextLabel?.text = viewModel.menuItemPrice(at: indexPath)
            
        } else if tableView == orderTableView {
            cell.textLabel?.text = viewModel.labelForOrderItem(at: indexPath)
            cell.detailTextLabel?.text = viewModel.orderItemPrice(at: indexPath)
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == menuTableView {
            let indexPaths = [viewModel.addItemToOrder(at: indexPath)]
            orderTableView.insertRows(at: indexPaths, with: .automatic)
        } else if tableView == orderTableView {
            viewModel.toggleTaxForOrderItem(at: indexPath)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        self.updateTotalBillFields()
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if tableView == menuTableView {
            return .none
        } else if tableView == orderTableView {
            return .delete
        }
        
        fatalError()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if tableView == orderTableView && editingStyle == .delete {
            viewModel.removeItemFromOrder(at: indexPath)
            orderTableView.deleteRows(at: [indexPath], with: .automatic)
            // calculate bill totals
            self.updateTotalBillFields()
        }
    }
}

extension RegisterViewController: DiscountHandler, TaxHandler {
    func handleUpdatedDiscounts() {
        viewModel.updateDiscounts()
        self.updateTotalBillFields()
    }
    
    func handleUpdatedTaxes() {
        viewModel.updateTaxes()
        self.updateTotalBillFields()
    }
}

class RegisterViewModel {
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    
    var orderItems: [Item] = []
    var applicableDiscounts: [any Discount] = []
    var applicableTaxes: [any Tax] = []
    var billCalculator: BillCalculator
    private var bill: Bill
    
    
    init(orderItems: [Item] = [], billCalculator: BillCalculator = BillCalculator()) {
        self.orderItems = orderItems
        self.applicableTaxes = taxes.filter { $0.isEnabled }
        self.applicableDiscounts = appliedDiscountsInOrder
        self.billCalculator = billCalculator
        self.bill = self.billCalculator.calculateBill(items: self.orderItems, taxes: [], discounts: [])
    }
    
    func menuCategoryTitle(in section: Int) -> String? {
        return categories[section].name
    }
    
    func orderTitle(in section: Int) -> String? {
        return "Bill"
    }
    
    func numberOfMenuCategories() -> Int {
        return categories.count
    }
    
    func numberOfMenuItems(in section: Int) -> Int {
        return categories[section].items.count
    }
    
    func numberOfOrderItems(in section: Int) -> Int {
        return orderItems.count
    }
    
    func menuItemName(at indexPath: IndexPath) -> String? {
        return categories[indexPath.section].items[indexPath.row].name
    }
    
    func menuItemPrice(at indexPath: IndexPath) -> String? {
        let price = categories[indexPath.section].items[indexPath.row].price as NSDecimalNumber
        return formatter.string(from: price)
    }
    
    func labelForOrderItem(at indexPath: IndexPath) -> String? {
        let item = orderItems[indexPath.row]
       
        if item.isTaxExempt {
            return "\(item.name) (No Tax)"
        } else {
            return item.name
        }
    }
    
    func orderItemPrice(at indexPath: IndexPath) -> String? {
        let price = orderItems[indexPath.row].price as NSDecimalNumber
        return formatter.string(from: price)
    }
    
    func addItemToOrder(at indexPath: IndexPath) -> IndexPath {
        let item = categories[indexPath.section].items[indexPath.row]
        orderItems.append(item)
        return IndexPath(row: orderItems.count - 1, section: 0)
    }
    
    func removeItemFromOrder(at indexPath: IndexPath) {
        orderItems.remove(at: indexPath.row)
    }
    
    func toggleTaxForOrderItem(at indexPath: IndexPath) {
        orderItems[indexPath.row].isTaxExempt = !orderItems[indexPath.row].isTaxExempt
    }
    
    func updatedBillLabels() -> (subtotal: String?, discounts: String?, taxes: String?, grandTotal: String?) {
        self.generateBill()
        return (formatter.string(from: bill.subtotal as NSDecimalNumber),
                formatter.string(from: -bill.discountTotal as NSDecimalNumber),
                formatter.string(from: bill.taxTotal as NSDecimalNumber),
                formatter.string(from: bill.grandTotal as NSDecimalNumber))
    }
    
    private func generateBill() {
        self.bill = self.billCalculator.calculateBill(items: self.orderItems, taxes: self.applicableTaxes, discounts: self.applicableDiscounts)
    }
    
    func updateTaxes() {
        self.applicableTaxes = taxes.filter { $0.isEnabled }
        generateBill()
    }
    
    func updateDiscounts() {
        self.applicableDiscounts = appliedDiscountsInOrder
        generateBill()
    }
}
