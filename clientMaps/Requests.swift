//
//  Requests.swift
//  ClientMaps
//
//  Created by alfa on 28/7/24.
//

import UIKit
import Network
class Requests{
    static let shared = Requests()
    
    func uploadImage(image: UIImage, clientID: String!, completion: @escaping (Bool, String?) -> Void) {
        guard let PASSWORD = CredentialsManager.shared.PASSWORD else {
            completion(false, "Missing password")
            return
        }
        
        guard let clientID = clientID else {
            completion(false, "Missing client ID")
            return
        }
        
        let urlString = "\(CredentialsManager.shared.UPLOAD_ENDPOINT)\(CredentialsManager.shared.PASSWORD!)/\(clientID)"
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
    
    func downloadImage(clientID: String, completion: @escaping (UIImage?, String?) -> Void) {
        let urlString = "\(CredentialsManager.shared.DOWNLOAD_ENDPOINT)\(CredentialsManager.shared.PASSWORD!)/\(clientID)"
        guard let url = URL(string: urlString) else {
            completion(nil, "Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil, "Invalid Data")
                return
            }
            completion(image, nil)
        }
        task.resume()
    }
    
    public func editClient(data: Client, viewController: UIViewController, completion: @escaping (Bool,String?) -> Void) {
        let encoder = JSONEncoder()
        guard let JSONData = try? encoder.encode(data) else {
            completion(false,"Failed to encode data")
            return
        }
        
        guard let url = URL(string: CredentialsManager.shared.EDIT_ENDPOINT + data.id! + "/" + CredentialsManager.shared.PASSWORD!) else {
            completion(false,"Invalid Password")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = JSONData
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(false,error.localizedDescription)
                return
            }
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    completion(false,"Κάτι πήγε στραβά: \(response.statusCode)")
                } else {
                    completion(true,nil)
                }
            } else {
                completion(false, "Request failed")
            }
        }
        task.resume()
    }
    public func addClient(client: Client, completion: @escaping (Bool, String?) -> Void) {
        let encoder = JSONEncoder()
        
        do {
            let jsonData = try encoder.encode(client)
            
            guard let url = URL(string: CredentialsManager.shared.ADD_ENDPOINT + CredentialsManager.shared.PASSWORD!) else {
                completion(false, "Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("Error occurred: \(error)")
                    Cache.shared.queueClient(client: client)
                    completion(false, "Network error")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(false, "Invalid response")
                    return
                }
                completion(httpResponse.statusCode == 200, httpResponse.statusCode == 409 ? "Αυτός ο πελάτης υπάρχει ήδη!" : "Κάτι πήγε στραβά")
            }
            task.resume()
            
        } catch {
            print("Encoding error: \(error)")
            completion(false, "Encoding error")
        }
    }
    func loadAllClients(completion: @escaping (Bool, [Client]?, String?) -> Void) {
        guard !CredentialsManager.shared.DATA_ENDPOINT.isEmpty, !CredentialsManager.shared.PASSWORD!.isEmpty else {
            completion(false, nil, "Credentials are missing")
            return
        }
        
        guard let url = URL(string: CredentialsManager.shared.DATA_ENDPOINT + CredentialsManager.shared.PASSWORD!) else {
            fatalError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                Cache.shared.retrieve(){success, Clients in
                    completion(success,Clients,success ? "offline" : "Server connection failed and couldn't retrieve cache")
                }
                return
            }
            
            if let data = data {
                let Clients = try? JSONDecoder().decode([Client].self, from: data)
                Cache.shared.save(clients: Clients!)
                completion(true,Clients,"online")
            }
            
        }
        task.resume()

    }
    public func deleteClient(client: Client,completion: @escaping (Bool,String?) -> Void){
        let url = URL(string: CredentialsManager.shared.DELETE_ENDPOINT + client.id! + "/" + CredentialsManager.shared.PASSWORD!)
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
                    completion(true,nil)
                    return
                }
                else {
                    completion(false,"Κάτι πήγε στραβά!")
                }
            }
        }
        task.resume()
    }
}


