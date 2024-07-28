//
//  ViewController.swift
//  test
//
//  Created by Alex on 26/3/23.
//

import UIKit
import ContactsUI
import Network
class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MainViewControllerDelegate {
    
    let refreshControl = UIRefreshControl()
    let networkManager = NetworkManager()
    var results = [Client]()
    var searchResults = [Client]()
    var searching = false
    var selectedClient: Client?
    var connectionMode:  Bool = false
    @IBOutlet weak var clientCount: UILabel!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var connectionIndicator: UIImageView!
    @IBOutlet weak var SearchBar: UISearchBar!
    
    @IBAction func Donezo(_ sender: Any) {
        (sender as AnyObject).resignFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIStuff()
        loadData()
        let monitor = NWPathMonitor()
        //Cache.shared.deleteClientQueue(completion: {_,_ in })
        monitor.pathUpdateHandler = {
            path in
            self.setConnectionMode(ConnectionMode: path.status == .satisfied)
            if path.status == .satisfied {
                Cache.shared.retrieveClientQueue(){
                    Clients in
                    if Clients?.count == 0 || Clients == nil { return }
                    for client in Clients! {
                        if (client != nil){
                            Requests.shared.addClient(client: client){success,errorMessage in
                                if success || errorMessage == "Αυτός ο πελάτης υπάρχει ήδη!" {
                                    print(client)
                                    Cache.shared.removeClientFromQueue(clientID: client.id!)
                                }
                                print("RESULT: \(success) \(errorMessage)")
                            }
                        }
                    }
                }
            }
            
        }
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
    @objc func refresh(_ sender: AnyObject) {
        loadData()
    }
    func UIStuff(){
        SearchBar.placeholder = "Αναζήτηση"
        SearchBar.enablesReturnKeyAutomatically = false
        navigationItem.titleView = SearchBar
        refreshControl.attributedTitle = NSAttributedString(string: "Τραβήξτε για ανανέωση")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        table.delegate = self
        table.dataSource = self
        
        table.register(ClientTableViewCell.nib(), forCellReuseIdentifier: ClientTableViewCell.identifier)
        SearchBar.delegate = self
        table.addSubview(refreshControl)
        SearchBar.delegate = self
        table.register(ClientTableViewCell.nib(), forCellReuseIdentifier: ClientTableViewCell.identifier)
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        table.addGestureRecognizer(longPressRecognizer)
    }
    func loadData(){
        Requests.shared.loadAllClients(){
            success,clients,mode in
            if (success){
                self.appendData(data: clients!)
            } else {
                Helper.shared.alert(Title: "Προσοχή", Message: "Κάτι πήγε στραβά", self: self)
            }
            DispatchQueue.main.async{
                self.connectionIndicator.image =  UIImage(systemName: success ? "wifi" : "wifi.slash")
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (searching) { return searchResults.count }
        return results.count
    }
    func setConnectionMode(ConnectionMode: Bool){
        connectionMode = ConnectionMode
        DispatchQueue.main.async{
            self.connectionIndicator.image =  UIImage(systemName: ConnectionMode ? "wifi" : "wifi.slash")
        }
        if (ConnectionMode){
            DispatchQueue.main.async{
                if (!self.refreshControl.isDescendant(of: self.table)){
                    self.table.addSubview(self.refreshControl)
                }
                self.loadData()
            }

        } else {
            
        }
    }


    func appendData(data: [Client]){
        DispatchQueue.main.async {
            self.results = data
            self.results.sort {
                $0.name < $1.name
            }
            self.table.reloadData()
            self.clientCount.text = "Συνολικοί Πελάτες: \(self.results.count)"
            self.refreshControl.endRefreshing()
        }
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        SearchBar.endEditing(true)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let selectedClient : Client
        let cell =
        table.dequeueReusableCell(withIdentifier: ClientTableViewCell.identifier, for: indexPath)
        as! ClientTableViewCell
        selectedClient = searching ? searchResults[indexPath.row] : results[indexPath.row]
        cell.ClientName.text = selectedClient.name
        cell.placeText.text = selectedClient.place
        cell.hasImage.isHidden = !selectedClient.has_image!
        
        if (selectedClient.phone.isEmpty){
            cell.callButton.isEnabled = false
            cell.saveContact.isEnabled = false
        } else {
            
            cell.callButton.isEnabled = true
            cell.callButton.tag = indexPath.row
            cell.callButton.addTarget(self, action: #selector(callButtonTapped(_:)), for: .touchUpInside)
            
            cell.saveContact.isEnabled = true
            cell.saveContact.tag = indexPath.row
            cell.saveContact.addTarget(self, action: #selector(saveButtonTapped(_:)), for: .touchUpInside)

        }
        cell.contactPickButton.tag = indexPath.row
        cell.contactPickButton.isEnabled = true
        cell.contactPickButton.addTarget(self, action: #selector(contactButtonTapped), for: .touchUpInside)
        
        
        return cell
    }
    @objc func callButtonTapped(_ sender: UIButton){
        Helper.shared.callNumber(phoneNumber: searching ? searchResults[sender.tag].phone : results[sender.tag].phone)
    }
    @objc func saveButtonTapped(_ sender: UIButton){
        Helper.shared.saveContact(name:searching ? searchResults[sender.tag].name : results[sender.tag].name, phoneNumber: searching ? searchResults[sender.tag].phone : results[sender.tag].phone,viewController: self)
    }
    private func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    private func noInternetIndication(){
        applyWiggleAnimation(to: connectionIndicator)
        Helper.shared.triggerImpactFeedback(style: .heavy)
    }
    @objc func contactButtonTapped(_ sender: UIButton) {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        selectedClient = searching ? searchResults[sender.tag] : results[sender.tag]
        self.present(contactPicker, animated: true, completion: nil)
    }
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if !connectionMode {
            noInternetIndication()
            return
        }
        if gestureRecognizer.state == .began {
            let location = gestureRecognizer.location(in: self.table)
            if let indexPath = self.table.indexPathForRow(at: location) {
                let selectedClient = searching ? searchResults[indexPath.row] : results[indexPath.row]
                Helper.shared.triggerImpactFeedback(style: .medium)
                if (!selectedClient.has_image!){
                    if let cell = table.cellForRow(at: indexPath) as? ClientTableViewCell,
                       let imageView = cell.hasImage {
                        cell.hasImage.isHidden = false
                        applyWiggleAnimation(to: imageView)
                    }
                    return
                }
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let clientImageVC = storyboard.instantiateViewController(withIdentifier: "ClientImageViewController") as? ClientImageViewController {
                    Requests.shared.downloadImage(clientID: (self.searching ? searchResults[indexPath.row].id : results[indexPath.row].id)!) { image, errorMessage in
                        if let error = errorMessage {
                            Helper.shared.alert(Title: "Προσοχή!", Message: error, self: self)
                            return
                        }
                        
                        guard let image = image else {
                            print("Failed to download image: Invalid image data")
                            return
                        }
                        DispatchQueue.main.async{
                            clientImageVC.image = image
                            Helper.shared.triggerImpactFeedback(style: .heavy)
                            self.present(clientImageVC, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Διαγραφή") { (_, _, completionHandler) in
            var client : Client
            client = self.searching ? self.searchResults[indexPath.row] : self.results[indexPath.row]
            Requests.shared.deleteClient(client: client){
                success,errorMessage in
                if (success){
                    self.searchResults = self.searchResults.filter { item in return item.id != client.id }
                    self.results = self.results.filter { item in return item.id != client.id }
                    DispatchQueue.main.async{
                        self.table.setEditing(false, animated: true)
                        self.table.reloadData()
                    }
                }
                else {
                    Helper.shared.alert(Title: "Προσοχή!", Message: errorMessage ?? "Κάτι πήγε στραβά!", self: self)
                }
                
            }
        }
        let editAction = UIContextualAction(style: .normal, title: "Επεξεργασία") { (_, _, completionHandler) in
            let client = self.searching ? self.searchResults[indexPath.row] : self.results[indexPath.row]
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let editController = storyBoard.instantiateViewController(withIdentifier: "EditController") as! EditController
            editController.client = client
            self.present(editController, animated:true, completion:nil)
            self.table.setEditing(false, animated: true)
            
        }
        let takePhotoAction = UIContextualAction(style: .normal, title: "Λήψη Φωτογραφίας") { (_, _, completionHandler) in
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.sourceType = .camera
            imagePickerController.allowsEditing = false
            self.present(imagePickerController, animated: true, completion: nil)
            self.table.setEditing(false, animated: true)
            self.selectedClient = self.searching ? self.searchResults[indexPath.row] : self.results[indexPath.row]
            
        }
        return UISwipeActionsConfiguration(actions: [editAction,deleteAction,takePhotoAction])
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searching {
            let selectedClient = searchResults[indexPath.row]
            let url = "maps://?q=\(selectedClient.name)&ll=\(selectedClient.latitude),\(selectedClient.longitude)"
            
            UIApplication.shared.open(NSURL(string:url.addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed) ?? "")! as URL)
        } else {
            let selectedClient = results[indexPath.row]
            let url = "maps://?q=\(selectedClient.name)&ll=\(selectedClient.latitude),\(selectedClient.longitude)"
            
            UIApplication.shared.open(NSURL(string:url.addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed) ?? "")! as URL)
            
        }
        self.SearchBar.searchTextField.endEditing(true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let originalImage = info[.originalImage] as? UIImage {
            Requests.shared.uploadImage(image: originalImage, clientID: self.selectedClient?.id) { success, errorMessage in
                if success {
                    DispatchQueue.main.async{
                        self.loadData()
                    }
                    
                } else {
                    Helper.shared.alert(Title: "Προσοχή!", Message: errorMessage ?? "Κάτι πήγε στραβά", self: self)
                }
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    func applyWiggleAnimation(to imageView: UIImageView) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.3
        animation.repeatCount = .infinity
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: imageView.center.x - 3, y: imageView.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: imageView.center.x + 3, y: imageView.center.y))
        imageView.layer.add(animation, forKey: "position")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            imageView.layer.removeAnimation(forKey: "position")
            UIView.animate(withDuration: 1.0, animations: {
                imageView.alpha = 0.0
            }) { _ in
                imageView.alpha = 1.0
                imageView.isHidden = true
            }
        }
    }
}


extension MainViewController: UISearchBarDelegate {
     
     func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
         if (searchText.isEmpty){
             searching = false
             table.reloadData()
             return
         }
         searchResults = results.filter { client in
             if client.name.lowercased().contains(searchText.lowercased()) {
                 return true
             }
             for name in client.names {
                 if name.lowercased().contains(searchText.lowercased()){
                     return true
                 }
             }
             return false
         }
         searching = true
         table.reloadData()
     }
     
     func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
         searching = false
         searchBar.text = ""
         table.reloadData()
     }
 }

extension MainViewController : CNContactPickerDelegate{
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        var contactNumber = ""
        if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
            contactNumber = phoneNumber
        }
        if (contactNumber.isEmpty) {
            return
        }
        guard let name = selectedClient?.name,
              let comments = selectedClient?.comments,
              let longitude = selectedClient?.longitude,
              let latitude = selectedClient?.latitude,
              let names = selectedClient?.names,
              let place = selectedClient?.place,
              let has_image = selectedClient?.has_image,
              let id = selectedClient?.id else {
            return
        }
        let Client = Client(name: name, phone: contactNumber, comments: comments, longitude: longitude, latitude: latitude, names: names,place:place, has_image: has_image, id: id)
        Requests.shared.editClient(data: Client, viewController: self) { success,errorMessage in
            if success {
                self.loadData()
            } else {
                Helper.shared.alert(Title: "Προσοχή!", Message: errorMessage ?? "Κάτι πηγε στραβά!", self: self)
            }
        }

    }

}
protocol MainViewControllerDelegate: AnyObject {
    func loadData()
}
