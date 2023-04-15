//
//  ViewController.swift
//  test
//
//  Created by Alex on 26/3/23.
//

import UIKit
import Network
class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
   
    let refreshControl = UIRefreshControl()
    var results = [TaskEntry]()
    @IBOutlet weak var table: UITableView!
    var searchResults = [TaskEntry]()
    var searching = false
    let SearchBar = UISearchBar()
    
    
    @IBAction func Donezo(_ sender: Any) {
        (sender as AnyObject).resignFirstResponder()
    }

    override func viewDidLoad() {
        let AddButton = UIButton(type: .custom)
        AddButton.setImage(UIImage(systemName: "plus"), for: .normal)
        AddButton.tintColor = UIColor.systemBlue
        AddButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
        SearchBar.placeholder = "Αναζήτηση"
        SearchBar.enablesReturnKeyAutomatically = false
        navigationItem.titleView = SearchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: AddButton)

        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if (path.status == .satisfied){
                self.loadData()
                DispatchQueue.main.async {
                    if (!self.refreshControl.isDescendant(of: self.table)){
                        self.table.addSubview(self.refreshControl)
                    }
                    AddButton.isEnabled = true
                }

            }
            else {
                DispatchQueue.main.async {
                    AddButton.isEnabled = false
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
        table.addSubview(refreshControl)
        super.viewDidLoad()
        SearchBar.delegate = self
        table.register(ClientTableViewCell.nib(), forCellReuseIdentifier: ClientTableViewCell.identifier)
        }
    @objc func refresh(_ sender: AnyObject) {
        loadData()
    }
    @objc func addButtonPressed() {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "AddController")
        navigationController?.pushViewController(nextViewController, animated:true)
        
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
        let url = URL(string: "http://159.223.16.89:3000/data/6NaUPgrWuaZXVqYw2KQP")
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        DispatchQueue.main.async{
            self.table.delegate = self
        }
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
            self.table.dataSource = self
            self.table.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        SearchBar.endEditing(true)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell =
        table.dequeueReusableCell(withIdentifier: ClientTableViewCell.identifier, for: indexPath)
        as! ClientTableViewCell
        if (searching){
            cell.ClientName.text = searchResults[indexPath.row].name
        }
        else {
        cell.ClientName.text = results[indexPath.row].name
      }

      return cell
    }
    private func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
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
            let url = URL(string: "http://159.223.16.89:3000/delete/" + client.id + "/6NaUPgrWuaZXVqYw2KQP")
            guard let requestUrl = url else { fatalError() }
            var request = URLRequest(url: requestUrl)
            request.httpMethod = "POST"
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("Error took place \(error)")
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                       print("statusCode: \(httpResponse.statusCode)")
                    if (httpResponse.statusCode == 200){
                        self.searchResults = self.searchResults.filter { item in return item.id != client.id }
                        self.results = self.results.filter { item in return item.id != client.id }
                        DispatchQueue.main.async{
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
            
        }
        return UISwipeActionsConfiguration(actions: [editAction,deleteAction])
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
  
   
    }


extension ViewController: UISearchBarDelegate {
     
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


