@main
struct CleanEntry {
    static func main() {
        let helper = CleanHelper()
        print(helper.greet())
    }
}

struct CleanHelper {
    func greet() -> String { "hi" }
}
