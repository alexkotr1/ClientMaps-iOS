//
//  ViewController.swift
//  test
//
//  Created by Alex on 26/3/23.
//

import UIKit
import Network
import ContactsUI
class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    let refreshControl = UIRefreshControl()
    var results = [TaskEntry]()
    @IBOutlet weak var table: UITableView!
    var searchResults = [TaskEntry]()
    var searching = false
    var selectedClient: TaskEntry?
    @IBOutlet weak var SearchBar: UISearchBar!
    
    @IBAction func Donezo(_ sender: Any) {
        (sender as AnyObject).resignFirstResponder()
    }
    
    override func viewDidLoad() {
        SearchBar.placeholder = "Αναζήτηση"
        SearchBar.enablesReturnKeyAutomatically = false
        navigationItem.titleView = SearchBar
        
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if (path.status == .satisfied){
                self.loadData()
                DispatchQueue.main.async {
                    if (!self.refreshControl.isDescendant(of: self.table)){
                        self.table.addSubview(self.refreshControl)
                    }
                }
                
            }
            else {
                DispatchQueue.main.async {
                    if (self.refreshControl.isDescendant(of: self.table)){
                        self.refreshControl.removeFromSuperview()
                    }
                }
                let folder = try! FileManager.default
                    .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                let fileURL = folder.appendingPathComponent("data.json")
                let data = try? String(contentsOf: fileURL)
                if (data != nil){
                    let response = try? JSONDecoder().decode([TaskEntry].self, from: (data?.data(using: .utf8))!)
                    self.appendData(data: response!)
                    
                }
                
            }
        }
        monitor.start(queue: DispatchQueue(label: "Monitor"))
        refreshControl.attributedTitle = NSAttributedString(string: "Τραβήξτε για ανανέωση")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        table.delegate = self
        table.dataSource = self
        
        table.register(ClientTableViewCell.nib(), forCellReuseIdentifier: ClientTableViewCell.identifier)
        SearchBar.delegate = self
        table.addSubview(refreshControl)
        super.viewDidLoad()
        SearchBar.delegate = self
        table.register(ClientTableViewCell.nib(), forCellReuseIdentifier: ClientTableViewCell.identifier)
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        table.addGestureRecognizer(longPressRecognizer)
    }
    @objc func refresh(_ sender: AnyObject) {
        loadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (searching) { return searchResults.count }
        return results.count
    }
    func cacheData(JSON: Data){
        let folder = try! FileManager.default
            .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let fileURL = folder.appendingPathComponent("data.json")
        try? JSON.write(to: fileURL)
    }
    func loadData(){
        let url = URL(string: Helper.shared.DATA_ENDPOINT + Helper.shared.PASSWORD!)
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if (error != nil){
                DispatchQueue.main.async {
                    alert(Message: "Δέν υπάρχει σύνδεση στο διαδίκτυο!", self: self)
                    self.refreshControl.endRefreshing()
                }
                return
            }
            if let data = data {
                self.cacheData(JSON: data)
                print(data)
                if let response = try? JSONDecoder().decode([TaskEntry].self, from: data) {
                    self.appendData(data: response)
                }
            }
        }
        task.resume()
    }
    func appendData(data: [TaskEntry]){
        DispatchQueue.main.async {
            self.results = data
            self.results.sort {
                $0.name < $1.name
            }
            self.table.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        SearchBar.endEditing(true)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let selectedClient : TaskEntry
        let cell =
        table.dequeueReusableCell(withIdentifier: ClientTableViewCell.identifier, for: indexPath)
        as! ClientTableViewCell
        if (searching){
            selectedClient = searchResults[indexPath.row]
        } else {
            selectedClient = results[indexPath.row]
        }
        cell.ClientName.text = selectedClient.name
        cell.placeText.text = selectedClient.place
        cell.hasImage.isHidden = !selectedClient.has_image
        
        if (selectedClient.phone.isEmpty){
            cell.callButton.isEnabled = false
            cell.saveContact.isEnabled = false
        } else {
            cell.callButton.isEnabled = true
            cell.callButton.tag = indexPath.row
            cell.saveContact.isEnabled = true
            cell.saveContact.tag = indexPath.row
            cell.callButton.tag = indexPath.row
            cell.callButton.addTarget(self, action: #selector(callButtonTapped(_:)), for: .touchUpInside)
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
    @objc func contactButtonTapped(_ sender: UIButton) {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        selectedClient = searching ? searchResults[sender.tag] : results[sender.tag]
        self.present(contactPicker, animated: true, completion: nil)
    }
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let location = gestureRecognizer.location(in: self.table)
            if let indexPath = self.table.indexPathForRow(at: location) {
                let selectedClient = searching ? searchResults[indexPath.row] : results[indexPath.row]
                Helper.shared.triggerImpactFeedback(style: .medium)
                if (!selectedClient.has_image){
                    if let cell = table.cellForRow(at: indexPath) as? ClientTableViewCell,
                       let imageView = cell.hasImage {
                        cell.hasImage.isHidden = false
                        applyWiggleAnimation(to: imageView)
                    }
                    return
                }
                let cell = self.table.cellForRow(at: indexPath)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let clientImageVC = storyboard.instantiateViewController(withIdentifier: "ClientImageViewController") as? ClientImageViewController {
                    Helper.shared.downloadImage(clientID: self.searching ? searchResults[indexPath.row].id : results[indexPath.row].id) { image, error in
                        if let error = error {
                            print("Failed to download image: \(error.localizedDescription)")
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
            var client : TaskEntry
            if self.searching {
                client = self.searchResults[indexPath.row]
            }
            else {
                client = self.results[indexPath.row]
            }
            let url = URL(string: Helper.shared.DELETE_ENDPOINT + client.id + "/" + Helper.shared.PASSWORD!)
            guard let requestUrl = url else { fatalError() }
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "POST"
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("Error took place \(error)")
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if (httpResponse.statusCode == 200){
                        self.searchResults = self.searchResults.filter { item in return item.id != client.id }
                        self.results = self.results.filter { item in return item.id != client.id }
                        DispatchQueue.main.async{
                            self.table.setEditing(false, animated: true)
                            self.table.reloadData()
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            alert(Message: "Κάτι πήγε στραβά", self: self)
                        }
                    }
                }
            }
            self.table.reloadData()
            task.resume()
            completionHandler(true)
        }
        let editAction = UIContextualAction(style: .normal, title: "Επεξεργασία") { (_, _, completionHandler) in
            var client : TaskEntry
            if self.searching {
                client = self.searchResults[indexPath.row]
            }
            else {
                client = self.results[indexPath.row]
            }
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let editController = storyBoard.instantiateViewController(withIdentifier: "EditController") as! EditController
            editController.Client = client
            self.present(editController, animated:true, completion:nil)
            self.table.setEditing(false, animated: true)
            
        }
        let takePhotoAction = UIContextualAction(style: .normal, title: "Λήψη Φωτογραφίας") { (_, _, completionHandler) in
            var client = self.searching ? self.searchResults[indexPath.row] : self.results[indexPath.row]
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
            Helper.shared.uploadImage(image: originalImage, clientID: self.selectedClient?.id) { success, errorMessage in
                if success {
                    DispatchQueue.main.async{
                        self.loadData()
                    }
                    
                } else {
                    print("Upload failed: \(errorMessage ?? "Unknown error")")
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
              let id = selectedClient?.id else {
            return
        }
        let Client = Helper.ClientData(name: name, phone: contactNumber, comments: comments, longitude: longitude, latitude: latitude, names: names, id: id)
        Helper.shared.updateData(data: Client, viewController: self) { success in
            if success {
                self.loadData()
            }
        }

    }

}
