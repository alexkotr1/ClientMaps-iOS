import Foundation
import UIKit
import Contacts
import ContactsUI

class Helper {
    static let shared = Helper()
    private init() {
        updateEndpoints()
    }

    var HOST = UserDefaults.standard.string(forKey: "HOST") {
        didSet {
            updateEndpoints()
        }
    }
    var PASSWORD = UserDefaults.standard.string(forKey: "PASSWORD")
    var USER = UserDefaults.standard.string(forKey: "USER")
    
    struct ClientData: Encodable {
        let name: String
        let phone: String
        let comments: String
        var longitude: String
        var latitude: String
        var names: [String]
        var place: String?
        let id: String
    }

    private(set) var ADD_ENDPOINT: String = ""
    private(set) var EDIT_ENDPOINT: String = ""
    private(set) var DELETE_ENDPOINT: String = ""
    private(set) var DATA_ENDPOINT: String = ""
    private(set) var UPLOAD_ENDPOINT: String = ""
    private(set) var DOWNLOAD_ENDPOINT: String = ""

    private func updateEndpoints() {
        guard let host = HOST else { return }
        ADD_ENDPOINT = host + "add/"
        EDIT_ENDPOINT = host + "edit/"
        DELETE_ENDPOINT = host + "delete/"
        DATA_ENDPOINT = host + "data/"
        UPLOAD_ENDPOINT = host + "upload/"
        DOWNLOAD_ENDPOINT = host + "download/"
    }
    public func callNumber(phoneNumber: String) {
        if let phoneURL = URL(string: "tel://\(phoneNumber)") {
            if UIApplication.shared.canOpenURL(phoneURL) {
                UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    public func saveContact(name: String, phoneNumber: String, viewController: UIViewController) {
        let contactStore = CNContactStore()
        print(name,"---",phoneNumber)
        contactStore.requestAccess(for: .contacts) { (granted, error) in
            if granted {
                let contact = CNMutableContact()
                contact.givenName = name
                contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phoneNumber))]
                
                let saveRequest = CNSaveRequest()
                saveRequest.add(contact, toContainerWithIdentifier: nil)
                
                do {
                    try contactStore.execute(saveRequest)
                    DispatchQueue.main.async {
                        alert(Message: "Επιτυχία!", self: viewController)
                    }
                } catch {
                    DispatchQueue.main.async {
                        alert(Message: "Αποτυχία!", self: viewController)

                    }
                }
            } else {
                DispatchQueue.main.async {
                    alert(Message: "Αποτυχία!", self: viewController)
                }
            }
        }
    }
    
    public func updateData(data: ClientData, viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        let encoder = JSONEncoder()
        guard let JSONData = try? encoder.encode(data) else {
            DispatchQueue.main.async {
                alert(Message: "Failed to encode data!", self: viewController)
            }
            completion(false)
            return
        }

        guard let url = URL(string: EDIT_ENDPOINT + data.id + "/" + PASSWORD!) else {
            fatalError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = JSONData
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    alert(Message: "Κάτι πήγε στραβά: \(error.localizedDescription)", self: viewController)
                }
                completion(false)
                return
            }
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    DispatchQueue.main.async {
                        alert(Message: "Κάτι πήγε στραβά: \(response.statusCode)", self: viewController)
                    }
                    completion(false)
                } else {
                    completion(true)
                }
            } else {
                completion(false)
            }
        }
        task.resume()
    }
    func uploadImage(image: UIImage, clientID: String!, completion: @escaping (Bool, String?) -> Void) {
        guard let PASSWORD = Helper.shared.PASSWORD else {
            completion(false, "Missing password")
            return
        }
        
        guard let clientID = clientID else {
            completion(false, "Missing client ID")
            return
        }
        let urlString = "\(UPLOAD_ENDPOINT)\(PASSWORD)/\(clientID)"
        print(urlString)
        guard let url = URL(string: urlString) else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        let fieldName = "image"
        
        var body = Data()
        
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
        body.append("SampleName\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "Error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(false, "Server error")
                return
            }
            completion(true, nil)
        }
        task.resume()
    }
    func downloadImage(clientID: String, completion: @escaping (UIImage?, Error?) -> Void) {
        let urlString = "\(DOWNLOAD_ENDPOINT)\(PASSWORD!)/\(clientID)"
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "Invalid URL", code: 400, userInfo: nil))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil, NSError(domain: "Invalid data", code: 400, userInfo: nil))
                return
            }
            
            completion(image, nil)
        }
        
        task.resume()
    }
    func triggerImpactFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
