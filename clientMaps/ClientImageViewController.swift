import UIKit

class ClientImageViewController: UIViewController {
    static let identifier = "ClientImageViewController"
    @IBOutlet weak var imageView: UIImageView!
    var image: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
    }
}
