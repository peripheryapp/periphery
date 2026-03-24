/// Maps module name strings to compact `ModuleID` integers and back.
/// Not thread-safe -- callers must serialize access externally
/// (e.g. via `SourceGraphMutex` during indexing, serial execution during mutation).
final class ModuleNameInterner {
    private var nameToID: [String: ModuleID] = [:]
    private var idToName: [String] = []

    init() {}

    var moduleCount: Int { idToName.count }

    var wordCount: Int { (moduleCount + 63) / 64 }

    func intern(_ name: String) -> ModuleID {
        if let id = nameToID[name] { return id }
        let id = ModuleID(idToName.count)
        nameToID[name] = id
        idToName.append(name)
        return id
    }

    func intern(_ names: Set<String>) -> Set<ModuleID> {
        Set(names.map { intern($0) })
    }

    func internBitset(_ names: Set<String>, wordCount: Int) -> ModuleBitset {
        var bitset = ModuleBitset(wordCount: wordCount)
        for name in names {
            bitset.insert(intern(name))
        }
        return bitset
    }
}
