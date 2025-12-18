import AppIntents

struct SimpleEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Simple Entity"
    static var defaultQuery = SimpleEntityQuery()

    var id: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(id)")
    }
}

struct SimpleEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SimpleEntity] {
        []
    }

    func suggestedEntities() async throws -> [SimpleEntity] {
        []
    }
}
