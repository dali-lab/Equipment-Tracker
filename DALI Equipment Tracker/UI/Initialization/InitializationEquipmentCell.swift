//
//  InitializationEquipmentCell.swift
//  DALI Equipment Tracker
//
//  Created by John Kotz on 2/22/19.
//  Copyright © 2019 DALI Lab. All rights reserved.
//

import Foundation
import UIKit
import DALI

class InitializationEquipmentCell: UITableViewCell {
    static let cellID = "initializationEquipmentCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    
    var equipment: DALIEquipment! {
        didSet {
            titleLabel.text = equipment.name
            idLabel.text = equipment.id
        }
    }
}
