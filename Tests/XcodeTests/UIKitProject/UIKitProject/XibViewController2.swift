import UIKit

class XibViewController2Base: UIViewController {
    @IBOutlet weak var button: UIButton!
    @IBAction func clickFromSubclass(_ sender: Any) {}
}

class XibViewController2Subclass: XibViewController2Base {}
