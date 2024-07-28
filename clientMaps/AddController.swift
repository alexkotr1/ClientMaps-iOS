
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
        UIStuff()
        latitude =
        locationDataManager.locationManager.location?.coordinate.latitude.description
        longitude =
        locationDataManager.locationManager.location?.coordinate.longitude.description
        Phone.keyboardType = UIKeyboardType.numberPad
        
    }
    
    @IBAction func AddButtonPressed(_ sender: Any) {
        if (!Name.hasText){
            return Helper.shared.alert(Title: "Προσοχή!", Message: "Το πεδίο «Ονοματεπώνυμο» είναι υποχρεωτικό!", self: self)
        }
        if (Phone.text?.count != 0 && Phone.text?.count != 10){
            return Helper.shared.alert(Title: "Προσοχή!", Message: "Το πεδίο «Τηλέφωνο» δεν είναι έγκυρο!", self: self)
        }
        if (latitude == nil || longitude == nil){
            return Helper.shared.alert(Title: "Προσοχή!", Message: "Κάτι πήγε στραβά!", self: self)
        }
        let client = Client(name: Name.text ?? "err", phone: Phone.text ?? "", comments: Comments.text ?? "", longitude: longitude ?? "", latitude: latitude ?? "", names: [], place: nil, has_image:false, id: nil)
        Requests.shared.addClient(client: client){success,errorMessage in
            if success{
                DispatchQueue.main.async {
                    self.Name.text = ""
                    self.Phone.text = ""
                    self.Comments.text = ""
                }
            } else {
                Helper.shared.alert(Title: "Προσοχή!", Message: errorMessage ?? "", self: self)
            }
            
        }
    }
    private func UIStuff(){
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
        
        let buttonTopConstraint = NSLayoutConstraint(item: AddButton as Any, attribute: .top, relatedBy: .equal, toItem: Comments!, attribute: .bottom, multiplier: 1, constant: 32)
        let buttonHorizontalConstraint = NSLayoutConstraint(item: AddButton as Any, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        NSLayoutConstraint.activate([buttonTopConstraint, buttonHorizontalConstraint])
    }
}





