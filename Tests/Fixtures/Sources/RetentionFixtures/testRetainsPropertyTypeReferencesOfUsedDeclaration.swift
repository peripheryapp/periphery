import Foundation

struct FixtureItem222: Identifiable, Hashable {
    let id: UUID
    let name: String
}

public struct FixtureViewModel222 {
    struct FixtureSection222: Identifiable, Hashable {
        let id: UUID
        var equipment: [FixtureItem222]
    }
    var sections: [FixtureSection222] = []

    public mutating func addSection() {
        sections.append(FixtureSection222(id: UUID(), equipment: []))
    }
}
