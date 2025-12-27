import UIKit

class XibViewController2Base: UIViewController {
    // Referenced via XIB (connected)
    @IBAction func clickFromSubclass(_ sender: Any) {}

    // Unreferenced - not connected in XIB
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var unusedBaseOutlet: UILabel!
    @IBAction func unusedBaseAction(_ sender: Any) {}
}

class XibViewController2Subclass: XibViewController2Base {}
