import UIKit

class XibViewController: UIViewController {
    // MARK: - IBOutlets (connected in XIB)
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var unusedOutlet: UILabel!

    // MARK: - IBActions (connected in XIB)
    @IBAction func click(_ sender: Any) {
        showAlert(title: "IBAction", message: "click(_:) - Connected via Interface Builder")
    }

    @IBAction func clickFromSubclass(_ sender: Any) {
        showAlert(title: "IBAction", message: "clickFromSubclass(_:) - Connected via Interface Builder")
    }

    // Unreferenced - not connected in XIB
    @IBAction func unusedAction(_ sender: Any) {
        showAlert(title: "Unused", message: "unusedAction(_:) - This should be reported as unused!")
    }

    // MARK: - IBInspectable
    @IBInspectable var controllerProperty: UIColor?
    @IBInspectable var unusedInspectable: CGFloat = 0

    // MARK: - Programmatic button for #selector test
    private var selectorButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // This reference retains selectorMethod even though it's never called
        _ = #selector(selectorMethod)

        // Create a separate button for testing addTarget/selector retention
        setupSelectorButton()

        // Verify IBInspectable was applied
        if controllerProperty != nil {
            view.backgroundColor = controllerProperty
        }
    }

    private func setupSelectorButton() {
        selectorButton = UIButton(type: .system)
        selectorButton.setTitle("Selector Button", for: .normal)
        selectorButton.translatesAutoresizingMaskIntoConstraints = false
        selectorButton.addTarget(self, action: #selector(addTargetMethod), for: .touchUpInside)
        view.addSubview(selectorButton)

        NSLayoutConstraint.activate([
            selectorButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectorButton.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 20)
        ])
    }

    // MARK: - Selector-referenced methods (retained via #selector)
    @objc private func selectorMethod() {}

    @objc private func addTargetMethod() {
        showAlert(title: "Selector", message: "addTargetMethod() - Connected via addTarget/#selector")
    }

    // MARK: - Alert helpers
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
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
