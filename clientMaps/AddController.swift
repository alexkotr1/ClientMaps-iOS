
import UIKit
var locationDataManager = LocationDataManager()

class AddController: UIViewController {

    @IBAction func Done(_ sender: Any) {
        (sender as AnyObject).resignFirstResponder()
    }
 
    @IBOutlet weak var AddClientText: UILabel!
    @IBOutlet weak var Name: UITextField!
    @IBOutlet weak var AddButton: UIButton!
    @IBOutlet weak var Phone: UITextField!
    @IBOutlet weak var Comments: UITextField!
    var latitude: String? = ""
    var longitude: String? = ""
    override func viewDidLoad() {
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")


        navigationController?.setNavigationBarHidden(false, animated: false)
          let textTopConstraint = NSLayoutConstraint(item: AddClientText!, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 0.75, constant: 0)
          let textHorizontalConstraint = NSLayoutConstraint(item: AddClientText!, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
          NSLayoutConstraint.activate([textTopConstraint, textHorizontalConstraint])

          let nameTopConstraint = NSLayoutConstraint(item: Name!, attribute: .top, relatedBy: .equal, toItem: AddClientText!, attribute: .bottom, multiplier: 1, constant: 32)
          let nameHorizontalConstraint = NSLayoutConstraint(item: Name!, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
          NSLayoutConstraint.activate([nameTopConstraint, nameHorizontalConstraint])

          let phoneTopConstraint = NSLayoutConstraint(item: Phone!, attribute: .top, relatedBy: .equal, toItem: Name!, attribute: .bottom, multiplier: 1, constant: 16)
          let phoneHorizontalConstraint = NSLayoutConstraint(item: Phone!, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
          NSLayoutConstraint.activate([phoneTopConstraint, phoneHorizontalConstraint])

          let commentsTopConstraint = NSLayoutConstraint(item: Comments!, attribute: .top, relatedBy: .equal, toItem: Phone!, attribute: .bottom, multiplier: 1, constant: 16)
          let commentsHorizontalConstraint = NSLayoutConstraint(item: Comments!, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
          NSLayoutConstraint.activate([commentsTopConstraint, commentsHorizontalConstraint])

          let buttonTopConstraint = NSLayoutConstraint(item: AddButton, attribute: .top, relatedBy: .equal, toItem: Comments!, attribute: .bottom, multiplier: 1, constant: 32)
          let buttonHorizontalConstraint = NSLayoutConstraint(item: AddButton, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
          NSLayoutConstraint.activate([buttonTopConstraint, buttonHorizontalConstraint])
        
        latitude =
        locationDataManager.locationManager.location?.coordinate.latitude.description
        longitude =
        locationDataManager.locationManager.location?.coordinate.longitude.description
        Phone.keyboardType = UIKeyboardType.numberPad
        
    }
   
    @IBAction func AddButtonPressed(_ sender: Any) {
       if (!Name.hasText){
            return alert(Message: "Το πεδίο «Ονοματεπώνυμο» είναι υποχρεωτικό!", self: self)
        }
        if (Phone.text?.count != 0 && Phone.text?.count != 10){
            return alert(Message: "Το πεδίο «Τηλέφωνο» δεν είναι έγκυρο!", self: self)
        }
        if (latitude == nil || longitude == nil){
            return alert(Message: "Κάτι πήγε στραβά!", self: self)
        }
        let dictionary: [String: Any] = ["name" : Name.text!,
                                         "phone" : Phone.text!,
                                         "latitude" : latitude!,
                                         "longitude" : longitude!,
                                         "comments": Comments.text!,
                                         "names": []
        ];
        let JSONData = try! JSONSerialization.data(withJSONObject: dictionary, options: []);
        let url = URL(string: Helper.shared.ADD_ENDPOINT + Helper.shared.PASSWORD!)
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = JSONData
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("Error took place \(error)")
                    return
                }
            if let httpResponse = response as? HTTPURLResponse {
                   print("statusCode: \(httpResponse.statusCode)")
                if (httpResponse.statusCode == 200){
                    DispatchQueue.main.async {
                        self.Name.text = ""
                        self.Phone.text = ""
                        self.Comments.text = ""
                    }
                }
                else if (httpResponse.statusCode == 300){
                    print("B")
                    DispatchQueue.main.async {
                        alert(Message: "Αυτό το όνομα υπάρχει ήδη!", self: self)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        alert(Message: "Κάτι πήγε στραβά!", self: self)
                    }
                }
            }
        }
        task.resume()        
    }
}


func alert(Message: String, self: Any){
    let alert = UIAlertController(title: "Προσοχή!", message: Message, preferredStyle: UIAlertController.Style.alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
    (self as AnyObject).present(alert, animated: true, completion: nil)
}


