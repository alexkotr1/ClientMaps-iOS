//
//  ClientNamesTableViewCell.swift
//  ClientMaps
//
//  Created by alfa on 27/7/24.
//

import Foundation
import UIKit

class ClientNamesTableViewCell: UITableViewCell {
    static let identifier = "ClientNamesTableViewCell"
    @IBOutlet weak var clientName: UILabel!
    static func nib() -> UINib {
        return UINib(nibName: "ClientNamesTableViewCell", bundle: nil)
    }
}
