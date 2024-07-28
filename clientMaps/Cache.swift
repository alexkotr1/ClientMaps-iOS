import Foundation

class Cache {
    static let shared = Cache()

    // Retrieve clients from "data.json"
    func retrieve(completion: @escaping (Bool, [Client]?) -> Void) {
        let folder = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = folder.appendingPathComponent("data.json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            let clients = try JSONDecoder().decode([Client].self, from: data)
            completion(true, clients)
        } catch {
            print("Error retrieving clients: \(error.localizedDescription)")
            completion(false, nil)
        }
    }
    
    // Save clients to "data.json"
    func save(clients: [Client]) {
        let folder = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = folder.appendingPathComponent("data.json")
        
        do {
            let jsonData = try JSONEncoder().encode(clients)
            try jsonData.write(to: fileURL)
            print("SUCCESS")
        } catch {
            print("Error saving clients: \(error.localizedDescription)")
        }
    }
    
    // Queue a single client into "data.json"
    func queueClient(client: Client) {
        let folder = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = folder.appendingPathComponent("clientQueue.json")
        
        do {
            var clients: [Client] = []
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                clients = try JSONDecoder().decode([Client].self, from: data)
            }
            for client_ in clients{
                if client_.id == client.id { return }
            }
            var clientWithID = client
            clientWithID.id = String(clients.count + 1)
            clients.append(clientWithID)
            let jsonData = try JSONEncoder().encode(clients)
            try jsonData.write(to: fileURL)
            print("Client queued successfully")
        } catch {
            print("Error queuing client: \(error.localizedDescription)")
        }
    }
    func deleteClientQueue(completion: @escaping (Bool, String?) -> Void) {
        guard let folder = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            completion(false, "Failed to get the caches directory URL.")
            return
        }
        
        let fileURL = folder.appendingPathComponent("clientQueue.json")
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                completion(true, "File deleted successfully.")
            } else {
                completion(false, "File does not exist.")
            }
        } catch {
            completion(false, "Failed to delete file: \(error.localizedDescription)")
        }
    }
    
    // Retrieve clients from "clientQueue.json"
    func retrieveClientQueue(completion: @escaping ([Client]?) -> Void) {
        let folder = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = folder.appendingPathComponent("clientQueue.json")
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            completion(nil)
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let clients = try JSONDecoder().decode([Client].self, from: data)
            completion(clients)
        } catch {
            print("Error retrieving client queue: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    // Remove a client from "clientQueue.json" by clientID
    func removeClientFromQueue(clientID: String) {
        print("Client ID:\(clientID)")
        let folder = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileURL = folder.appendingPathComponent("clientQueue.json")
        
        do {
            var clients: [Client] = []
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                clients = try JSONDecoder().decode([Client].self, from: data)
            }
            clients.removeAll { $0.id == clientID }
            let jsonData = try JSONEncoder().encode(clients)
            try jsonData.write(to: fileURL)
            print("Client removed successfully")
        } catch {
            print("Error removing client from queue: \(error.localizedDescription)")
        }
    }
}
