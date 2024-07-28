import Foundation
import UIKit
import Contacts
import ContactsUI

class Helper {
    static let shared = Helper()

    public func callNumber(phoneNumber: String) {
        if let phoneURL = URL(string: "tel://\(phoneNumber)") {
            if UIApplication.shared.canOpenURL(phoneURL) {
                UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    public func saveContact(name: String, phoneNumber: String, viewController: UIViewController) {
        let contactStore = CNContactStore()
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
                        self.alert(Title: "Επιτυχία!", Message: "Η επαφή αποθηκεύτηκε με επιτυχία!", self: viewController)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.alert(Title: "Προσοχή!",Message: "Αποτυχία!", self: viewController)

                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.alert(Title: "Προσοχή!",Message: "Αποτυχία!", self: viewController)
                }
            }
        }
    }
    


    func triggerImpactFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func alert(Title: String, Message: String, self: Any){
        DispatchQueue.main.async{
            let alert = UIAlertController(title: Title, message: Message, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            (self as AnyObject).present(alert, animated: true, completion: nil)
        }
    }
}
