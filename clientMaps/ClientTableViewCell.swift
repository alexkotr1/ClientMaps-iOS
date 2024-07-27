//
//  ClientTableViewCell.swift
//  test
//
//  Created by Alex on 28/3/23.
//

import UIKit

class ClientTableViewCell: UITableViewCell {
    static let identifier = "ClientTableViewCell"
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var ClientName: UILabel!
    @IBOutlet weak var saveContact: UIButton!
    @IBOutlet weak var contactPickButton: UIButton!
    @IBOutlet weak var placeText: UILabel!
    @IBOutlet weak var hasImage: UIImageView!
    @IBOutlet weak var phoneText: UILabel!
    static func nib() -> UINib {
        return UINib(nibName: "ClientTableViewCell", bundle: nil)
    }
}
