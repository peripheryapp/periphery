@main
struct UnusedEntry {
    static func main() {
        let used = UsedSymbol()
        print(used.referenced())
    }
}

struct UsedSymbol {
    func referenced() -> Int { 42 }
}

// Intentionally never referenced. The harness asserts Periphery's report flags this symbol.
struct UnusedSymbol {
    func unused() -> Int { 0 }
}
