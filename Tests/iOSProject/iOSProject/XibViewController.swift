import SwiftUI

class XibViewController: UIViewController {
    @IBOutlet weak var button: UIButton!
    @IBAction func click(_ sender: Any) {}
}

struct XibViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        XibViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
