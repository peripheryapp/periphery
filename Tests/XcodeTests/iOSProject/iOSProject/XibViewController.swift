import SwiftUI

class XibViewController: UIViewController {
    @IBOutlet weak var button: UIButton!
    @IBAction func click(_ sender: Any) {}

    override func viewDidLoad() {
        super.viewDidLoad()
        _ = #selector(targetMethod)
    }

    @objc private func targetMethod() {}
}

struct XibViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        XibViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
