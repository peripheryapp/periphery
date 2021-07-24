import Foundation
import XCTest
import Shared
@testable import XcodeSupport
@testable import PeripheryKit

class XcodebuildTest: XCTestCase {
    var shell: ShellMock!
    var xcodebuild: Xcodebuild!
    var project: XcodeProject!

    override func setUp() {
        super.setUp()

        shell = ShellMock.make()
        xcodebuild = Xcodebuild(shell: shell)
        project = try! XcodeProject.make(path: UIKitProjectPath)
    }
}

class XcodebuildBuildProjectTest: XCTestCase {
    var shell: Shell!
    var xcodebuild: Xcodebuild!
    var project: XcodeProject!

    override func setUp() {
        super.setUp()

        shell = inject(Shell.self)
        xcodebuild = Xcodebuild(shell: shell)
        project = try! XcodeProject.make(path: UIKitProjectPath)
    }

    func testBuildSchemeWithWhitespace() throws {
        let scheme = try XcodeScheme.make(project: project, name: "Scheme With Spaces")
        try xcodebuild.build(project: project, scheme: scheme, allSchemes: [scheme])
    }
}

class XcodebuildSchemesTest: XcodebuildTest {
    func testParseSchemes() {
        for output in XcodebuildListOutputs {
            shell.output = output
            let schemes = try! xcodebuild.schemes(project: project)
            XCTAssertEqual(schemes, ["SchemeA", "SchemeB"])
        }
    }
}

class ShellMock: Shell {
    var output: String = ""

    override func exec(_ args: [String], stderr: Bool = true) throws -> String {
        return output
    }
}

private let XcodebuildListOutputs = [
    XcodebuildListOutputA,
    XcodebuildListOutputB,
    XcodebuildListOutputC
]

private let XcodebuildListOutputA = """
{
    "project" : {
        "schemes" : [
            "SchemeA",
            "SchemeB",
        ],
        "name" : "Periphery"
    }
}
"""

private let XcodebuildListOutputB = """
2018-06-02 20:49:14.055 xcodebuild[62679:970667]  DTDeviceKit: deviceType from caf916135a63496e6af846cb8b73eeca8ba63dbd was NULL
2018-06-02 20:49:14.082 xcodebuild[62679:970671]  DTDeviceKit: deviceType from caf916135a63496e6af846cb8b73eeca8ba63dbd was NULL
{
    "project" : {
        "schemes" : [
            "SchemeA",
            "SchemeB",
        ],
        "name" : "Periphery"
    }
}
"""

private let XcodebuildListOutputC = """
2018-05-29 10:29:11.199 xcodebuild[82596:2040519]  iPhoneConnect: ## Unable to mount developer disk image, (Error Domain=com.apple.dtdevicekit Code=-402652958 "Development cannot be enabled while your device is locked." UserInfo={NSLocalizedDescription=Development cannot be enabled while your device is locked., com.apple.dtdevicekit.stacktrace=(
0   DTDeviceKitBase                     0x000000011722ff4f DTDKCreateNSError + 113
1   DTDeviceKitBase                     0x0000000117230793 DTDK_AMDErrorToNSError + 1135
2   DTDeviceKitBase                     0x000000011726fb1a -[DTDKMobileDeviceToken mountDeveloperDiskImage:withError:] + 774
3   DTDeviceKitBase                     0x00000001172703d0 -[DTDKMobileDeviceToken mountDeveloperDiskImageWithError:] + 479
4   IDEiOSSupportCore                   0x0000000115f15922 __37-[DVTiOSDevice(Connect) hasConnected]_block_invoke_2 + 133
5   DVTFoundation                       0x000000010c8b6f28 __DVTDispatchGroupAsync_block_invoke + 806
6   libdispatch.dylib                   0x00007fff5dca264a _dispatch_call_block_and_release + 12
7   libdispatch.dylib                   0x00007fff5dc9ae08 _dispatch_client_callout + 8
8   libdispatch.dylib                   0x00007fff5dcadf50 _dispatch_continuation_pop + 599
9   libdispatch.dylib                   0x00007fff5dca5783 _dispatch_async_redirect_invoke + 703
10  libdispatch.dylib                   0x00007fff5dc9c9f9 _dispatch_root_queue_drain + 515
11  libdispatch.dylib                   0x00007fff5dc9c7a5 _dispatch_worker_thread3 + 101
12  libsystem_pthread.dylib             0x00007fff5dfec169 _pthread_wqthread + 1387
13  libsystem_pthread.dylib             0x00007fff5dfebbe9 start_wqthread + 13
), NSLocalizedRecoverySuggestion=Please unlock your device and reattach. (0xE80000E2)., NSLocalizedFailureReason=Please unlock your device and reattach. (0xE80000E2).}) {
NSLocalizedDescription = "Development cannot be enabled while your device is locked.";
NSLocalizedFailureReason = "Please unlock your device and reattach. (0xE80000E2).";
NSLocalizedRecoverySuggestion = "Please unlock your device and reattach. (0xE80000E2).";
"com.apple.dtdevicekit.stacktrace" = (
0   DTDeviceKitBase                     0x000000011722ff4f DTDKCreateNSError + 113
1   DTDeviceKitBase                     0x0000000117230793 DTDK_AMDErrorToNSError + 1135
2   DTDeviceKitBase                     0x000000011726fb1a -[DTDKMobileDeviceToken mountDeveloperDiskImage:withError:] + 774
3   DTDeviceKitBase                     0x00000001172703d0 -[DTDKMobileDeviceToken mountDeveloperDiskImageWithError:] + 479
4   IDEiOSSupportCore                   0x0000000115f15922 __37-[DVTiOSDevice(Connect) hasConnected]_block_invoke_2 + 133
5   DVTFoundation                       0x000000010c8b6f28 __DVTDispatchGroupAsync_block_invoke + 806
6   libdispatch.dylib                   0x00007fff5dca264a _dispatch_call_block_and_release + 12
7   libdispatch.dylib                   0x00007fff5dc9ae08 _dispatch_client_callout + 8
8   libdispatch.dylib                   0x00007fff5dcadf50 _dispatch_continuation_pop + 599
9   libdispatch.dylib                   0x00007fff5dca5783 _dispatch_async_redirect_invoke + 703
10  libdispatch.dylib                   0x00007fff5dc9c9f9 _dispatch_root_queue_drain + 515
11  libdispatch.dylib                   0x00007fff5dc9c7a5 _dispatch_worker_thread3 + 101
12  libsystem_pthread.dylib             0x00007fff5dfec169 _pthread_wqthread + 1387
13  libsystem_pthread.dylib             0x00007fff5dfebbe9 start_wqthread + 13
);
}
2018-05-29 10:29:12.224 xcodebuild[82596:2040519]  iPhoneConnect: ## Unable to mount developer disk image, (Error Domain=com.apple.dtdevicekit Code=-402652958 "Development cannot be enabled while your device is locked." UserInfo={NSLocalizedDescription=Development cannot be enabled while your device is locked., com.apple.dtdevicekit.stacktrace=(
0   DTDeviceKitBase                     0x000000011722ff4f DTDKCreateNSError + 113
1   DTDeviceKitBase                     0x0000000117230793 DTDK_AMDErrorToNSError + 1135
2   DTDeviceKitBase                     0x000000011726fb1a -[DTDKMobileDeviceToken mountDeveloperDiskImage:withError:] + 774
3   DTDeviceKitBase                     0x00000001172703d0 -[DTDKMobileDeviceToken mountDeveloperDiskImageWithError:] + 479
4   IDEiOSSupportCore                   0x0000000115f15922 __37-[DVTiOSDevice(Connect) hasConnected]_block_invoke_2 + 133
5   DVTFoundation                       0x000000010c8b6f28 __DVTDispatchGroupAsync_block_invoke + 806
6   libdispatch.dylib                   0x00007fff5dca264a _dispatch_call_block_and_release + 12
7   libdispatch.dylib                   0x00007fff5dc9ae08 _dispatch_client_callout + 8
8   libdispatch.dylib                   0x00007fff5dcadf50 _dispatch_continuation_pop + 599
9   libdispatch.dylib                   0x00007fff5dca5783 _dispatch_async_redirect_invoke + 703
10  libdispatch.dylib                   0x00007fff5dc9c9f9 _dispatch_root_queue_drain + 515
11  libdispatch.dylib                   0x00007fff5dc9c7a5 _dispatch_worker_thread3 + 101
12  libsystem_pthread.dylib             0x00007fff5dfec169 _pthread_wqthread + 1387
13  libsystem_pthread.dylib             0x00007fff5dfebbe9 start_wqthread + 13
), NSLocalizedRecoverySuggestion=Please unlock your device and reattach. (0xE80000E2)., NSLocalizedFailureReason=Please unlock your device and reattach. (0xE80000E2).}) {
NSLocalizedDescription = "Development cannot be enabled while your device is locked.";
NSLocalizedFailureReason = "Please unlock your device and reattach. (0xE80000E2).";
NSLocalizedRecoverySuggestion = "Please unlock your device and reattach. (0xE80000E2).";
"com.apple.dtdevicekit.stacktrace" = (
0   DTDeviceKitBase                     0x000000011722ff4f DTDKCreateNSError + 113
1   DTDeviceKitBase                     0x0000000117230793 DTDK_AMDErrorToNSError + 1135
2   DTDeviceKitBase                     0x000000011726fb1a -[DTDKMobileDeviceToken mountDeveloperDiskImage:withError:] + 774
3   DTDeviceKitBase                     0x00000001172703d0 -[DTDKMobileDeviceToken mountDeveloperDiskImageWithError:] + 479
4   IDEiOSSupportCore                   0x0000000115f15922 __37-[DVTiOSDevice(Connect) hasConnected]_block_invoke_2 + 133
5   DVTFoundation                       0x000000010c8b6f28 __DVTDispatchGroupAsync_block_invoke + 806
6   libdispatch.dylib                   0x00007fff5dca264a _dispatch_call_block_and_release + 12
7   libdispatch.dylib                   0x00007fff5dc9ae08 _dispatch_client_callout + 8
8   libdispatch.dylib                   0x00007fff5dcadf50 _dispatch_continuation_pop + 599
9   libdispatch.dylib                   0x00007fff5dca5783 _dispatch_async_redirect_invoke + 703
10  libdispatch.dylib                   0x00007fff5dc9c9f9 _dispatch_root_queue_drain + 515
11  libdispatch.dylib                   0x00007fff5dc9c7a5 _dispatch_worker_thread3 + 101
12  libsystem_pthread.dylib             0x00007fff5dfec169 _pthread_wqthread + 1387
13  libsystem_pthread.dylib             0x00007fff5dfebbe9 start_wqthread + 13
);
}
{
    "project" : {
        "schemes" : [
            "SchemeA",
            "SchemeB",
        ],
        "name" : "Periphery"
    }
}
"""
