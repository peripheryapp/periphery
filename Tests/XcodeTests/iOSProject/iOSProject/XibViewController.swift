import SwiftUI

class XibViewController: UIViewController {
    @IBOutlet weak var button: UIButton!
    @IBAction func click(_ sender: Any) {}
    @IBAction func clickFromSubclass(_ sender: Any) {}
    @IBInspectable var controllerProperty: UIColor?

    override func viewDidLoad() {
        super.viewDidLoad()
        _ = #selector(selectorMethod)
        button.addTarget(self, action: #selector(addTargetMethod), for: .touchUpInside)
    }

    @objc private func selectorMethod() {}
    @objc private func addTargetMethod() {}
}

struct XibViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        XibViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

class XibView: UIView {
    @IBInspectable var viewProperty: UIColor?
}

extension UIView {
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
}
