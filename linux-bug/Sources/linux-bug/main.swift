@MainActor
class Main { // periphery:ignore
    var optionalProperty: String? = "Hello, World!"

    func bug() {
        if let optionalProperty {
            print(optionalProperty)
        }
    }
}
