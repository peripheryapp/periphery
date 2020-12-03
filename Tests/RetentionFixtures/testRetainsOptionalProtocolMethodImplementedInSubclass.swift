#if os(macOS)
// It appears optional protocol members aren't supported on Linux?
import Foundation

open class FixtureClass125Base: NSObject, FileManagerDelegate {}

public class FixtureClass125: FixtureClass125Base {
    func fileManager(_ fileManager: FileManager, shouldRemoveItemAtPath path: String) -> Bool {
        false
    }
}
#endif
