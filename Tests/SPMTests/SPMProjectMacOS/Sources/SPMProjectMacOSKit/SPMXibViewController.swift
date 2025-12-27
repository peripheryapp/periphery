import AppKit

public class SPMXibViewController: NSViewController {
    // Referenced via XIB (connected)
    @IBOutlet var button: NSButton!
    @IBAction func buttonTapped(_: Any) {}

    // Unreferenced - not connected in XIB
    @IBOutlet var unusedMacOutlet: NSTextField!
    @IBAction func unusedMacAction(_: Any) {}
}
