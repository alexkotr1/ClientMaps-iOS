//
//  EditController.swift
//  test
//
//  Created by Alex on 3/4/23.
//

import UIKit

class EditController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    var client : Client!
    weak var deletage: MainViewControllerDelegate?
    @IBOutlet weak var ClientName: UITextField!
    @IBOutlet weak var EditClientText: UILabel!
    @IBOutlet weak var Comments: UITextField!
    @IBOutlet weak var EditButton: UIButton!
    @IBOutlet weak var UseCurrentLocation: UISwitch!
    @IBOutlet weak var Phone: UITextField!
    @IBOutlet weak var UseCurrentLocationText: UILabel!
    @IBOutlet weak var AddClient: UITextField!
    @IBOutlet weak var NamesTable: UITableView!
    
    @IBAction func Done(_ sender: Any) {
        (sender as AnyObject).resignFirstResponder()
    }
    
    var latitude: String? = ""
    var longitude: String? = ""
    
    
    override func viewDidLoad(){
        
        let stackView = UIStackView()
        stackView.addArrangedSubview(UseCurrentLocationText)
        stackView.addArrangedSubview(UseCurrentLocation)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.distribution = .fill
        
        view.addSubview(stackView)
        AddClient.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        EditClientText.translatesAutoresizingMaskIntoConstraints = false
        ClientName.translatesAutoresizingMaskIntoConstraints = false
        Phone.translatesAutoresizingMaskIntoConstraints = false
        Comments.translatesAutoresizingMaskIntoConstraints = false
        UseCurrentLocationText.translatesAutoresizingMaskIntoConstraints = false
        UseCurrentLocation.translatesAutoresizingMaskIntoConstraints = false
        NamesTable.translatesAutoresizingMaskIntoConstraints = false
        EditButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            EditClientText.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            EditClientText.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            EditClientText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            ClientName.topAnchor.constraint(equalTo: EditClientText.bottomAnchor, constant: 16),
            ClientName.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ClientName.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ClientName.heightAnchor.constraint(equalToConstant: 40),
            
            Phone.topAnchor.constraint(equalTo: ClientName.bottomAnchor, constant: 16),
            Phone.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            Phone.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            Phone.heightAnchor.constraint(equalToConstant: 40),
            
            Comments.topAnchor.constraint(equalTo: Phone.bottomAnchor, constant: 16),
            Comments.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            Comments.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            AddClient.topAnchor.constraint(equalTo: Comments.bottomAnchor, constant: 16),
            AddClient.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            AddClient.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            AddClient.heightAnchor.constraint(equalToConstant: 40),
            
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: AddClient.bottomAnchor, constant: 16),
            
            UseCurrentLocationText.heightAnchor.constraint(equalToConstant: 40),
            UseCurrentLocation.widthAnchor.constraint(equalToConstant: 50),
            
            NamesTable.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16),
            NamesTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            NamesTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            NamesTable.bottomAnchor.constraint(equalTo: EditButton.topAnchor, constant: -16),
            
            EditButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            EditButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            EditButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            EditButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        
        if (client != nil){
            Phone.keyboardType = UIKeyboardType.numberPad
            ClientName.text = client.name
            Phone.text = client.phone
            Comments.text = client.comments
            NamesTable.delegate = self
            NamesTable.dataSource = self
            NamesTable.register(ClientNamesTableViewCell.nib(), forCellReuseIdentifier: ClientNamesTableViewCell.identifier)
        }
        
    }
    @IBAction func EditButtonPressed(_ sender: Any) {
        if (UseCurrentLocation.isOn){
            client.longitude =  locationDataManager.locationManager.location?.coordinate.longitude.description ?? "Error"
            client.latitude = locationDataManager.locationManager.location?.coordinate.latitude.description ?? "Error"
        }
        client.name = ClientName.text ?? "error"
        client.phone = Phone.text ?? ""
        client.comments = Comments.text ?? ""
        
        if let name = AddClient.text, !name.isEmpty{
            client.names.append(name)
        }
        Requests.shared.editClient(data: client, viewController: self) { [self] success, errorMessage in
            if success {
                DispatchQueue.main.async { [self] in
                    deletage?.loadData()
                    ClientName.text = ""
                    Phone.text = ""
                    Comments.text = ""
                    dismiss(animated: true)
                }
            } else {
                Helper.shared.alert(Title: "Προσοχή", Message: errorMessage ?? "Κάτι πήγε στραβά!", self: self)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return client.names.count
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Διαγραφή") { (_, _, completionHandler) in
            self.client.names.remove(at: indexPath.row)
            tableView.reloadData()
            completionHandler(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClientNamesTableViewCell.identifier, for: indexPath)
        as! ClientNamesTableViewCell
        let name = client.names[indexPath.row]
        cell.clientName.text = name
        return cell
    }
}

