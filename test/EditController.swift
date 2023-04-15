//
//  EditController.swift
//  test
//
//  Created by Alex on 3/4/23.
//

import UIKit

class EditController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    var Client : TaskEntry!
    var NewClient: TaskEntry!
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
    struct ClientData: Encodable {
        let name: String
        let phone: String
        let comments: String
        var longitude: String
        var latitude: String
        var names: [String]
    }
   
    var latitude: String? = ""
    var longitude: String? = ""

    @IBAction func EditButtonPressed(_ sender: Any) {
        if (ClientName.text == Client.name && Phone.text == Client.phone && Comments.text == Client.comments && !UseCurrentLocation.isOn && AddClient.text?.isEmpty == true){
            alert(Message: "Πρέπει να κάνετε κάποια αλλαγή!", self: self)
        }
        var clientData = ClientData(name: ClientName.text!, phone: Phone.text!, comments: Comments.text!, longitude: String(Client.longitude), latitude: String(Client.latitude),names: Client.names)
            if (UseCurrentLocation.isOn){
                clientData.longitude =  locationDataManager.locationManager.location?.coordinate.longitude.description ?? "Error"
                clientData.latitude = locationDataManager.locationManager.location?.coordinate.latitude.description ?? "Error"
            }
           
        if let name = AddClient.text, !name.isEmpty{
            Client.names.append(name)
            clientData.names.append(name)
            AddClient.text = ""
        }
        updateData(data: clientData)
      

    }
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

      
        if (Client != nil){
            Phone.keyboardType = UIKeyboardType.numberPad
            ClientName.text = Client.name
            Phone.text = Client.phone
            Comments.text = Client.comments
            NamesTable.delegate = self
            NamesTable.dataSource = self
            NamesTable.register(ClientTableViewCell.nib(), forCellReuseIdentifier: ClientTableViewCell.identifier)
        }
        
    }
    func updateData(data: ClientData){
        let encoder = JSONEncoder()
        let JSONData = try! encoder.encode(data)
        let jsonString = String(data: JSONData, encoding: .utf8)
            
            let url = URL(string: "http://159.223.16.89:3000/edit/\(Client.id)/6NaUPgrWuaZXVqYw2KQP" )
            guard let requestUrl = url else { fatalError() }
            var request = URLRequest(url: requestUrl)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
        request.httpBody = JSONData
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        alert(Message: "Κάτι πήγε στραβά!", self: self)
                    }
                    return
                }
                if let response = response as? HTTPURLResponse{
                    if (response.statusCode == 404){
                        DispatchQueue.main.async {
                            alert(Message: "Αυτό το όνομα υπάρχει ήδη!", self: self)
                        }
                        
                    }
                    else if (response.statusCode != 200){
                        DispatchQueue.main.async {
                            alert(Message: "Κάτι πήγε στραβά", self: self)
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "NavController") as? UINavigationController
                            self.present(nextViewController!, animated:true, completion:nil)
                        }
                    }
                }
            }
            task.resume()
    }
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Client.names.count
     }
     
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Διαγραφή") { (_, _, completionHandler) in
            var clientData = ClientData(name: self.ClientName.text!, phone: self.Phone.text!, comments: self.Comments.text!, longitude: String(self.Client.longitude), latitude: String(self.Client.latitude),names: self.Client.names)
            clientData.names.remove(at: indexPath.row)
            print(clientData)
            self.updateData(data: clientData)
            completionHandler(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
        
    }
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClientTableViewCell.identifier, for: indexPath)
        as! ClientTableViewCell
         let name = Client.names[indexPath.row]
        cell.ClientName.text = name
         return cell
     }
     
}
