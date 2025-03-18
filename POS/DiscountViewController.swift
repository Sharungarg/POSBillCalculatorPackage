//
//  DiscountViewController.swift
//  POS
//
//  Created by Tayson Nguyen on 2019-04-29.
//  Copyright © 2019 TouchBistro. All rights reserved.
//

import Foundation
import UIKit
import BillCalculator

protocol DiscountHandler {
    func handleUpdatedDiscounts()
}

class DiscountViewController: UITableViewController {
    let cellIdentifier = "Cell"
    
    let viewModel = DiscountViewModel()
    var listener: DiscountHandler? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Discounts"
        let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem = button
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        listener?.handleUpdatedDiscounts()
    }
    
    @objc func done() {
        dismiss(animated: true, completion: nil)
    }
}

extension DiscountViewController {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.title(for: section)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) ?? UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        
        cell.textLabel?.text = viewModel.labelForDiscount(at: indexPath)
        cell.accessoryType = viewModel.accessoryType(at: indexPath)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.toggleDiscount(at: indexPath)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

class DiscountViewModel {
    func title(for section: Int) -> String {
        return "Discounts"
    }
    
    func numberOfSections() -> Int {
        return 1
    }
    
    func numberOfRows(in section: Int) -> Int {
        return discounts.count
    }
    
    func labelForDiscount(at indexPath: IndexPath) -> String {
        let discount = discounts[indexPath.row]
        return discount.name
    }
    
    func accessoryType(at indexPath: IndexPath) -> UITableViewCell.AccessoryType {
        let discount = discounts[indexPath.row]
        if discount.isEnabled {
            return .checkmark
        } else {
            return .none
        }
    }
    
    func toggleDiscount(at indexPath: IndexPath) {
        let isEnabled = discounts[indexPath.row].toggleEnabled()
        if isEnabled {
            appliedDiscountsInOrder.append(discounts[indexPath.row])
        } else {
            appliedDiscountsInOrder.removeDiscount(discounts[indexPath.row])
        }
    }
}
