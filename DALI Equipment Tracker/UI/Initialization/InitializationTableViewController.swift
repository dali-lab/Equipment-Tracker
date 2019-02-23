//
//  InitializationTableViewController.swift
//  DALI Equipment Tracker
//
//  Created by John Kotz on 2/22/19.
//  Copyright © 2019 DALI Lab. All rights reserved.
//

import Foundation
import UIKit
import DALI
import EmitterKit
import FutureKit

class InitializationTableViewController: UITableViewController, DALIViewProtocol, TableViewDiffControllerDelegate {
    var equipment: [DALIEquipment]? = nil
    var observation: Observation? =  nil
    var tableViewDiffController: TableViewDiffController<DALIEquipment>! = nil
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        let list = equipment != nil ? [equipment!] : [[]]
        
        tableViewDiffController = TableViewDiffController(tableView: tableView,
                                                          delegate: self,
                                                          initialData: list)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        _ = loadInitialData()
        observation = startObeserving()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        observation?.stop()
        observation = nil
    }
    
    // MARK: - Data
    
    func preloadView() -> Future<Any> {
        return loadInitialData().futureAny
    }
    
    /// Load the initial data for the view
    func loadInitialData() -> Future<[DALIEquipment]> {
        let future = DALIEquipment.allEquipment().mainThreadFuture
        
        return future.onSuccess(block: { (equipments) in
            self.equipmentDidUpdate(equipments)
            return equipments
        })
    }
    
    /// Start observing the data for changes
    func startObeserving() -> Observation {
        return DALIEquipment.observeAllEquipment { (equipment) in
            DispatchQueue.main.async {
                self.equipmentDidUpdate(equipment)
            }
        }
    }
    
    /// Handle an update to equipment
    func equipmentDidUpdate(_ equipment: [DALIEquipment]) {
        self.equipment = equipment.sorted(by: { (left, right) -> Bool in
            return left.name.lowercased() < right.name.lowercased()
        })
        _ = tableViewDiffController.update(with: [self.equipment!])
    }
    
    // MARK: - UITableViewController overrides
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - TableViewDiffControllerDelegate
    
    func tableViewDiffController(_ tableView: UITableView, cellForItem item: Any) -> UITableViewCell {
        guard let equipment = item as? DALIEquipment else {
            fatalError("No equipment for cells!")
        }
        
        // Get the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: InitializationEquipmentCell.cellID)
        
        if let cell = cell as? InitializationEquipmentCell {
            cell.equipment = equipment
        }
        
        return cell!
    }
}
