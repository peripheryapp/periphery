import Foundation
import Logger
import SystemPackage
@testable import XcodeSupport
import XCTest

final class XcodebuildIndexStoreTest: XCTestCase {
    private var xcodebuild: Xcodebuild!
    private var tmpDir: FilePath!

    override func setUp() {
        super.setUp()

        let logger = Logger(quiet: true, verbose: false, colorMode: .never)
        let shell = ShellMock(output: "")
        xcodebuild = Xcodebuild(shell: shell, logger: logger)
        tmpDir = FilePath(NSTemporaryDirectory()).appending("XcodebuildIndexStoreTest-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(atPath: tmpDir.string, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: tmpDir.string)
        xcodebuild = nil
        tmpDir = nil
        super.tearDown()
    }

    // MARK: - findIndexStorePath(in:)

    func testFindIndexStorePathFindsIndexNoindex() throws {
        let dataStore = tmpDir.appending("Index.noindex/DataStore")
        try FileManager.default.createDirectory(atPath: dataStore.string, withIntermediateDirectories: true)

        let result = xcodebuild.findIndexStorePath(in: tmpDir)
        XCTAssertEqual(result, dataStore)
    }

    func testFindIndexStorePathFindsLegacyIndex() throws {
        let dataStore = tmpDir.appending("Index/DataStore")
        try FileManager.default.createDirectory(atPath: dataStore.string, withIntermediateDirectories: true)

        let result = xcodebuild.findIndexStorePath(in: tmpDir)
        XCTAssertEqual(result, dataStore)
    }

    func testFindIndexStorePathPrefersIndexNoindex() throws {
        let noindex = tmpDir.appending("Index.noindex/DataStore")
        let legacy = tmpDir.appending("Index/DataStore")
        try FileManager.default.createDirectory(atPath: noindex.string, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: legacy.string, withIntermediateDirectories: true)

        let result = xcodebuild.findIndexStorePath(in: tmpDir)
        XCTAssertEqual(result, noindex)
    }

    func testFindIndexStorePathReturnsNilWhenNoneExist() {
        let result = xcodebuild.findIndexStorePath(in: tmpDir)
        XCTAssertNil(result)
    }

    // MARK: - findIndexStoreInDerivedData(projectName:derivedDataRoot:)

    func testFindIndexStoreInDerivedDataFindsMatchingProject() throws {
        let projectDir = tmpDir.appending("MyProject-abc123")
        let dataStore = projectDir.appending("Index.noindex/DataStore")
        try FileManager.default.createDirectory(atPath: dataStore.string, withIntermediateDirectories: true)

        let result = xcodebuild.findIndexStoreInDerivedData(projectName: "MyProject", derivedDataRoot: tmpDir)
        XCTAssertEqual(result, dataStore)
    }

    func testFindIndexStoreInDerivedDataReturnsNilForNonMatchingProject() throws {
        let projectDir = tmpDir.appending("OtherProject-abc123")
        let dataStore = projectDir.appending("Index.noindex/DataStore")
        try FileManager.default.createDirectory(atPath: dataStore.string, withIntermediateDirectories: true)

        let result = xcodebuild.findIndexStoreInDerivedData(projectName: "MyProject", derivedDataRoot: tmpDir)
        XCTAssertNil(result)
    }

    func testFindIndexStoreInDerivedDataReturnsNilWhenRootDoesNotExist() {
        let nonexistent = tmpDir.appending("nonexistent")

        let result = xcodebuild.findIndexStoreInDerivedData(projectName: "MyProject", derivedDataRoot: nonexistent)
        XCTAssertNil(result)
    }

    func testFindIndexStoreInDerivedDataReturnsNilWhenNoIndexStore() throws {
        let projectDir = tmpDir.appending("MyProject-abc123")
        try FileManager.default.createDirectory(atPath: projectDir.string, withIntermediateDirectories: true)

        let result = xcodebuild.findIndexStoreInDerivedData(projectName: "MyProject", derivedDataRoot: tmpDir)
        XCTAssertNil(result)
    }

    func testFindIndexStoreInDerivedDataPrefersMostRecentlyModified() throws {
        let fm = FileManager.default

        // Create an older project directory with a valid index store
        let olderDir = tmpDir.appending("MyProject-older111")
        let olderDataStore = olderDir.appending("Index.noindex/DataStore")
        try fm.createDirectory(atPath: olderDataStore.string, withIntermediateDirectories: true)

        // Set its modification date to the past
        try fm.setAttributes(
            [.modificationDate: Date.distantPast],
            ofItemAtPath: olderDir.string
        )

        // Create a newer project directory with a valid index store
        let newerDir = tmpDir.appending("MyProject-newer222")
        let newerDataStore = newerDir.appending("Index.noindex/DataStore")
        try fm.createDirectory(atPath: newerDataStore.string, withIntermediateDirectories: true)

        // Set its modification date to now
        try fm.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: newerDir.string
        )

        let result = xcodebuild.findIndexStoreInDerivedData(projectName: "MyProject", derivedDataRoot: tmpDir)
        XCTAssertEqual(result, newerDataStore)
    }

    func testFindIndexStoreInDerivedDataDoesNotMatchExactName() throws {
        // A directory named exactly "MyProject" (no hash suffix) should not match
        let projectDir = tmpDir.appending("MyProject")
        let dataStore = projectDir.appending("Index.noindex/DataStore")
        try FileManager.default.createDirectory(atPath: dataStore.string, withIntermediateDirectories: true)

        let result = xcodebuild.findIndexStoreInDerivedData(projectName: "MyProject", derivedDataRoot: tmpDir)
        XCTAssertNil(result)
    }

    func testFindIndexStoreInDerivedDataDoesNotMatchPrefix() throws {
        // "MyProjectExtra-abc123" should not match project name "MyProject"
        let projectDir = tmpDir.appending("MyProjectExtra-abc123")
        let dataStore = projectDir.appending("Index.noindex/DataStore")
        try FileManager.default.createDirectory(atPath: dataStore.string, withIntermediateDirectories: true)

        let result = xcodebuild.findIndexStoreInDerivedData(projectName: "MyProject", derivedDataRoot: tmpDir)
        XCTAssertNil(result)
    }
}
