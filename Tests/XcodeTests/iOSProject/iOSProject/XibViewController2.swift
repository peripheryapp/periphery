import SwiftUI

class XibViewController2Base: UIViewController {
    @IBOutlet weak var button: UIButton!
    @IBAction func clickFromSubclass(_ sender: Any) {}
}

class XibViewController2Subclass: XibViewController2Base {}

struct XibViewController2SubclassWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        XibViewController2Subclass()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
