//
//  ClientTableViewCell.swift
//  test
//
//  Created by Alex on 28/3/23.
//

import UIKit

class ClientTableViewCell: UITableViewCell {
    static let identifier = "ClientTableViewCell"
    @IBOutlet weak var ClientName: UILabel!
    static func nib() -> UINib {
        return UINib(nibName: "ClientTableViewCell", bundle: nil)
    }
}
