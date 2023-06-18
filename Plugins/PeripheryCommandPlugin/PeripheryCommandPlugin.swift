import PackagePlugin
import Foundation

@main
struct PeripheryCommandPlugin: CommandPlugin {
    func performCommand(
        context: PluginContext,
        arguments: [String]
    ) throws {
        let tool = try context.tool(named: "periphery")
        let toolExec = URL(fileURLWithPath: tool.path.string)
        let process = try Process.run(toolExec, arguments: ["scan"])
        process.waitUntilExit()
    }
}
