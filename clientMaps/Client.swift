import Foundation

public struct Client: Codable {
    public var name: String
    public var phone: String
    public var comments: String
    public var longitude: String
    public var latitude: String
    public var names: [String]
    public var place: String?
    public var has_image: Bool?
    public var id: String?

    public init(name: String, phone: String, comments: String, longitude: String, latitude: String, names: [String], place: String?,has_image: Bool?, id: String?) {
        self.name = name
        self.phone = phone
        self.comments = comments
        self.longitude = longitude
        self.latitude = latitude
        self.names = names
        self.has_image = has_image
        self.id = id
    }
}
