import UIKit
import Foundation

class SettingsViewController: UIViewController {
    @IBOutlet weak var hostText: UITextField!
    @IBOutlet weak var userText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func Done(_ sender: Any) {
        (sender as AnyObject).resignFirstResponder()
    }
 
    @IBAction func onSaveButtonPressed(_ sender: Any) {
        if var text = hostText.text{
            if !text.hasSuffix("/"){
                text += "/"
            }
            if !text.hasPrefix("http://") || !text.hasPrefix("https://"){
                text = "http://" + text
            }
            UserDefaults.standard.setValue(text, forKey: "HOST")
 
        }
        if let text = userText.text{
            UserDefaults.standard.setValue(text, forKey: "USER")
        }
        if let text = passwordText.text{
            UserDefaults.standard.setValue(text, forKey: "PASSWORD")
        }
        return alert(Message: "ΟΚ!", self: self)
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        hostText.text = UserDefaults.standard.string(forKey: "HOST")
        passwordText.text = UserDefaults.standard.string(forKey: "PASSWORD")
        userText.text = UserDefaults.standard.string(forKey: "USER")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
