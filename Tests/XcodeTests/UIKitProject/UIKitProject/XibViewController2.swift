import UIKit

class XibViewController2Base: UIViewController {
    // Referenced via XIB (connected in XibViewController2Subclass.xib)
    @IBAction func clickFromSubclass(_ sender: Any) {
        showAlert(title: "XibViewController2Base", message: "clickFromSubclass(_:) action triggered from subclass XIB!")
    }

    // Unreferenced - not connected in XIB
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var unusedBaseOutlet: UILabel!

    @IBAction func unusedBaseAction(_ sender: Any) {
        showAlert(title: "XibViewController2Base", message: "unusedBaseAction(_:) - this should be reported as unused!")
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

class XibViewController2Subclass: XibViewController2Base {}
