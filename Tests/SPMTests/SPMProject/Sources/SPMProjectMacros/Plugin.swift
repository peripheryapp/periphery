import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct TestPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MockMacro.self,
    ]
}
