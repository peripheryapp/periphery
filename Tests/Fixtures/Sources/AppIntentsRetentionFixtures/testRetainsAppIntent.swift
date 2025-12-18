import AppIntents

struct SimpleIntent: AppIntent {
    static var title: LocalizedStringResource = "Simple Intent"

    func perform() async throws -> some IntentResult {
        .result()
    }
}
