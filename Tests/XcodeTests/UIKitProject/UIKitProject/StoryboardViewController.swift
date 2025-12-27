import UIKit

class StoryboardViewController: UIViewController {
    // Referenced via storyboard (connected)
    @IBOutlet weak var button: UIButton!
    @IBAction func click(_ sender: Any) {}

    // Unreferenced - not connected in storyboard
    @IBOutlet weak var unusedStoryboardOutlet: UILabel!
    @IBAction func unusedStoryboardAction(_ sender: Any) {}
    @IBInspectable var unusedStoryboardInspectable: CGFloat = 0
}
