import Foundation
struct TaskEntry: Codable  {
    let name: String
    let phone: String
    let latitude: String
    let longitude: String
    let comments: String
    let id: String
    let has_image: Bool
    let place: String?
    var names:	 [String]
}
