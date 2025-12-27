import UIKit

class XibViewController: UIViewController {
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var unusedOutlet: UILabel!
    @IBAction func click(_ sender: Any) {}
    @IBAction func clickFromSubclass(_ sender: Any) {}
    @IBAction func unusedAction(_ sender: Any) {}
    @IBInspectable var controllerProperty: UIColor?
    @IBInspectable var unusedInspectable: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        _ = #selector(selectorMethod)
        button.addTarget(self, action: #selector(addTargetMethod), for: .touchUpInside)
    }

    @objc private func selectorMethod() {}
    @objc private func addTargetMethod() {}
}

class XibView: UIView {
    @IBInspectable var viewProperty: UIColor?
}

extension UIView {
    // Referenced via XIB (used in userDefinedRuntimeAttributes)
    @IBInspectable var customBorderColor: UIColor? {
        get {
            if let borderColor = layer.borderColor {
                return UIColor(cgColor: borderColor)
            }

            return nil
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }

    // Unreferenced - not used in any XIB
    @IBInspectable var unusedExtensionInspectable: CGFloat {
        get { 0 }
        set { _ = newValue }
    }
}
