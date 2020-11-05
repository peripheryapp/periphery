import SwiftUI

class StoryboardViewController: UIViewController {
    @IBOutlet weak var button: UIButton!
    @IBAction func click(_ sender: Any) {}
}

struct StoryboardViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let storyboard = UIStoryboard(name: "StoryboardViewController", bundle: nil)
        return storyboard.instantiateInitialViewController()!
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
