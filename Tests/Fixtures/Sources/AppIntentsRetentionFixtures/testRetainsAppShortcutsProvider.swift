import AppIntents

struct ShortcutIntent: AppIntent {
    static var title: LocalizedStringResource = "Shortcut Intent"

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct SimpleShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShortcutIntent(),
            phrases: ["Run shortcut"],
            shortTitle: "Shortcut",
            systemImageName: "star"
        )
    }
}
