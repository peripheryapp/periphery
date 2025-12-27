import UIKit

class XibViewController3: UIViewController {
    // Referenced via XIB (connected)
    @IBOutlet weak var button: UIButton!
    @IBAction func click(_ sender: Any) {}

    // Unreferenced - not connected in XIB
    @IBOutlet weak var unusedOutlet: UILabel!
    @IBAction func unusedAction(_ sender: Any) {}
}
