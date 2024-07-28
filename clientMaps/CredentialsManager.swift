//
//  CredentialsManager.swift
//  ClientMaps
//
//  Created by alfa on 28/7/24.
//

import Foundation

class CredentialsManager {
    static let shared = CredentialsManager()
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
}
