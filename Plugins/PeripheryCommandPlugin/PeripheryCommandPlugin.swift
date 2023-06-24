import PackagePlugin
import Foundation

@main
struct PeripheryCommandPlugin: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) throws {
        let tool = try context.tool(named: "periphery")
        let toolUrl = URL(fileURLWithPath: tool.path.string)
        let process = try Process.run(toolUrl, arguments: arguments)
        process.waitUntilExit()
    }
}
