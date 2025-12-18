import AppIntents

enum SimpleAppEnum: String, AppEnum {
    case optionA
    case optionB

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Simple Enum"
    static var caseDisplayRepresentations: [SimpleAppEnum: DisplayRepresentation] = [
        .optionA: "Option A",
        .optionB: "Option B"
    ]
}
