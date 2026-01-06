import AppKit

public final class SPMXibViewController: NSViewController {
    // MARK: - Referenced via XIB (connected)

    @IBOutlet var button: NSButton!

    @IBAction func buttonTapped(_: Any) {
        showAlert(title: "SPMXibViewController", message: "buttonTapped(_:) action triggered!")
    }

    @IBInspectable var borderWidth: CGFloat = 0

    // MARK: - Unreferenced (not connected in XIB)

    @IBOutlet var unusedMacOutlet: NSTextField!

    @IBAction func unusedMacAction(_: Any) {
        showAlert(title: "SPMXibViewController", message: "unusedMacAction(_:) - this should be reported as unused!")
    }

    @IBInspectable var unusedMacInspectable: CGFloat = 0

    override public func viewDidLoad() {
        super.viewDidLoad()
        // Verify button outlet is connected
        button.title = "Tap Me!"
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
