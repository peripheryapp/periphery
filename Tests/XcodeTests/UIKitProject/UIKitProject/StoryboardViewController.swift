import UIKit

class StoryboardViewController: UIViewController {
    // MARK: - Referenced via storyboard (connected)
    @IBOutlet weak var button: UIButton!

    @IBAction func click(_ sender: Any) {
        showAlert(title: "StoryboardViewController", message: "click(_:) action triggered!")
    }

    @IBInspectable var cornerRadius: CGFloat = 0

    // MARK: - Unreferenced (not connected in storyboard)
    @IBOutlet weak var unusedStoryboardOutlet: UILabel!

    @IBAction func unusedStoryboardAction(_ sender: Any) {
        showAlert(title: "StoryboardViewController", message: "unusedStoryboardAction(_:) - this should be reported as unused!")
    }

    @IBInspectable var unusedInspectable: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Button outlet is connected - title comes from storyboard
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
