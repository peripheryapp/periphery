import XCTest
import PathKit
import TSCBasic
@testable import PeripheryKit

class RetentionTest: XCTestCase {
    static var buildPlan: BuildPlan!
    static var target: Target!
    static var indexStore: IndexStore!

    static override func setUp() {
        super.setUp()

        let project = try! Project.make(path: PeripheryProjectPath)
        let xcodebuild: Xcodebuild = inject()
        try! xcodebuild.clearDerivedData(for: project)
        try! xcodebuild.build(project: project, scheme: "RetentionFixtures")
        let indexStorePath = try! xcodebuild.indexStorePath(project: project)

        target = project.targets.first { $0.name == "RetentionFixtures" }!
        buildPlan = try! BuildPlan.make(targets: [target])
        indexStore = try! IndexStore.open(
            store: AbsolutePath(indexStorePath), api: IndexStoreAPI.make()
        )
    }

    override func tearDown() {
        if (testRun?.failureCount ?? 0) > 0 {
            print("----------------------------------------")
            SourceGraphDebugger(graph: graph).describeGraph()
            print("----------------------------------------")
        }

        super.tearDown()
    }

    private var graph: SourceGraph!
    private let performKnownFailures = false

    func testNonReferencedClass() {
        analyze()
        XCTAssertNotReferenced((.class, "FixtureClass1"))
    }

    func testNonReferencedFreeFunction() {
        analyze()
        XCTAssertNotReferenced((.functionFree, "someFunction()"))
    }

    func testNonReferencedMethod() {
        analyze(retainPublic: true)
        XCTAssertReferenced((.class, "FixtureClass2"))
        XCTAssertNotReferenced((.functionMethodInstance, "someMethod()"))
    }

    func testNonReferencedProperty() {
        analyze(retainPublic: true)
        XCTAssertReferenced((.class, "FixtureClass3"))
        XCTAssertNotReferenced((.varStatic, "someStaticVar"))
        XCTAssertNotReferenced((.varInstance, "someVar"))
    }

    func testSimplePropertyAssignedButNeverRead() {
        analyze(retainPublic: true, aggressive: true)

        XCTAssertReferenced((.class, "FixtureClass70"))
        XCTAssertNotReferenced((.varInstance, "simpleUnreadVar"),
                               descendentOf: (.class, "FixtureClass70"))
        XCTAssertNotReferenced((.varStatic, "simpleStaticUnreadVar"),
                               descendentOf: (.class, "FixtureClass70"))
        XCTAssertReferenced((.varInstance, "complexUnreadVar1"),
                            descendentOf: (.class, "FixtureClass70"))
        XCTAssertReferenced((.varInstance, "complexUnreadVar2"),
                            descendentOf: (.class, "FixtureClass70"))
        XCTAssertReferenced((.varInstance, "readVar"),
                            descendentOf: (.class, "FixtureClass70"))

        // Without aggressive option
        analyze(retainPublic: true)

        XCTAssertReferenced((.varInstance, "simpleUnreadVar"),
                            descendentOf: (.class, "FixtureClass70"))
        XCTAssertReferenced((.varStatic, "simpleStaticUnreadVar"),
                            descendentOf: (.class, "FixtureClass70"))
        XCTAssertReferenced((.varInstance, "complexUnreadVar1"),
                            descendentOf: (.class, "FixtureClass70"))
        XCTAssertReferenced((.varInstance, "complexUnreadVar2"),
                            descendentOf: (.class, "FixtureClass70"))
        XCTAssertReferenced((.varInstance, "readVar"),
                            descendentOf: (.class, "FixtureClass70"))
    }

    func testNonReferencedMethodInClassExtension() {
        analyze(retainPublic: true)
        XCTAssertNotReferenced((.functionMethodInstance, "someMethod()"))
    }

    func testConformingProtocolReferencedByNonReferencedClass() {
        analyze()
        XCTAssertNotReferenced((.class, "FixtureClass6"))
        XCTAssertNotReferenced((.protocol, "FixtureProtocol1"))
    }

    func testSelfReferencedClass() {
        analyze()
        XCTAssertNotReferenced((.class, "FixtureClass8"))
    }

    func testSelfReferencedRecursiveMethod() {
        analyze()
        XCTAssertNotReferenced((.class, "FixtureClass9"))
        XCTAssertNotReferenced((.functionMethodInstance, "recursive()"))
    }

    func testSelfReferencedProperty() {
        analyze()
        XCTAssertNotReferenced((.class, "FixtureClass39"))
        XCTAssertNotReferenced((.varInstance, "someVar"))
    }

    func testRetainsInheritedClass() {
        analyze(retainPublic: true)
        XCTAssertReferenced((.class, "FixtureClass11"))
        XCTAssertReferenced((.class, "FixtureClass12"))
    }

    func testCrossReferencedClasses() {
        analyze()
        XCTAssertNotReferenced((.class, "FixtureClass14"))
        XCTAssertNotReferenced((.class, "FixtureClass15"))
        XCTAssertNotReferenced((.class, "FixtureClass16"))
    }

    func testDeeplyNestedClassReferences() {
        analyze()
        XCTAssertNotReferenced((.class, "FixtureClass17"))
        XCTAssertNotReferenced((.class, "FixtureClass18"))
        XCTAssertNotReferenced((.class, "FixtureClass19"))
    }

    func testNSApplicationMainEntryAnnotation() {
        analyze()
        XCTAssertReferenced((.class, "FixtureClass20"))
        XCTAssertReferenced((.functionMethodInstance, "applicationDidFinishLaunching(_:)"))
    }

    func testRetainsObjcAnnotatiedClass() {
        analyze(retainObjcAnnotated: true)
        XCTAssertReferenced((.class, "FixtureClass21"))
    }

    func testRetainsObjcAnnotatedMembers() {
        analyze(retainObjcAnnotated: true)
        XCTAssertReferenced((.class, "FixtureClass22"))
        XCTAssertReferenced((.varInstance, "someVar"))
        XCTAssertReferenced((.functionMethodInstance, "someMethod()"))
    }

    func testDoesNotRetainObjcAnnotatedWithoutOption() {
        analyze()
        XCTAssertNotReferenced((.class, "FixtureClass23"))
    }

    func testDoesNotRetainMembersOfObjcAnnotatedClass() {
        analyze(retainObjcAnnotated: true)
        XCTAssertReferenced((.class, "FixtureClass24"))
        XCTAssertNotReferenced((.functionMethodInstance, "someMethod()"))
        XCTAssertNotReferenced((.varInstance, "someVar"))
    }

    func testObjcMembersAnnotationRetainsMembers() {
        analyze(retainObjcAnnotated: true)
        XCTAssertReferenced((.class, "FixtureClass25"))
        XCTAssertReferenced((.varInstance, "someVar"))
        XCTAssertReferenced((.functionMethodInstance, "someMethod()"))
    }

    func testRetainPublicMembers() {
        analyze(retainPublic: true)
        XCTAssertReferenced((.class, "FixtureClass26"))
        XCTAssertReferenced((.functionMethodInstance, "funcPublic()"))
        XCTAssertNotReferenced((.functionMethodInstance, "funcPrivate()"))
        XCTAssertNotReferenced((.functionMethodInstance, "funcInternal()"))
        XCTAssertReferenced((.functionMethodInstance, "funcOpen()"))
    }

    func testConformanceToExternalProtocolIsRetained() {
        analyze()

        // Retained because it's a method from an external declaration (in this case, Equatable)
        XCTAssertReferenced((.functionOperatorInfix, "==(_:_:)"),
                            descendentOf: (.class, "FixtureClass55"))
    }

    func testProtocolVarReferencedByProtocolMethodInSameClassIsRetained() {
        // Despite the conforming class depending internally upon the protocol methods, the protocol
        // itself is unused. In a real situation the protocol could be removed and the conforming
        // class refactored.
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass51"))
        XCTAssertNotReferenced((.protocol, "FixtureProtocol51"))

        XCTAssertReferenced((.functionMethodInstance, "publicMethod()"),
                            descendentOf: (.class, "FixtureClass51"))
        XCTAssertReferenced((.functionMethodInstance, "protocolMethod()"),
                            descendentOf: (.class, "FixtureClass51"))
        XCTAssertReferenced((.varInstance, "protocolVar"),
                            descendentOf: (.class, "FixtureClass51"))
    }

    func testProtocolMethodCalledIndirectlyByProtocolIsRetained() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass52"))
        XCTAssertReferenced((.protocol, "FixtureProtocol52"))

        XCTAssertReferenced((.functionMethodInstance, "protocolMethod()"),
                            descendentOf: (.class, "FixtureClass52"))
    }

    func testProtocolConformedByClassButNeverDirectlyUsedIsNotRetained() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass54")) // because it's public
        XCTAssertNotReferenced((.protocol, "FixtureProtocol54")) // internal

        XCTAssertNotReferenced((.functionMethodInstance, "protocolMethod()"),
                               descendentOf: (.class, "FixtureClass54"))
        XCTAssertNotReferenced((.functionMethodInstance, "protocolMethod()"),
                               descendentOf: (.protocol, "FixtureProtocol54"))
    }

    func testDoesNotRetainProtocolMethodInSubclassWithDefaultImplementation() {
        // Protocol witness tables are only associated with the conforming class, and do not
        // descent to subclasses. Therefore, a protocol method that's only implemented in a subclass
        // and not the parent conforming class is actually unused.
        analyze(retainPublic: true)

        XCTAssertReferenced((.functionMethodInstance, "protocolMethod()"),
                            descendentOf: (.protocol, "FixtureProtocol83"))
        XCTAssertReferenced((.functionMethodInstance, "protocolMethod()"),
                            descendentOf: (.extensionProtocol, "FixtureProtocol83"))
        XCTAssertNotReferenced((.functionMethodInstance, "protocolMethod()"),
                               descendentOf: (.class, "FixtureClass84"))
    }

    func testRetainsProtocolExtension() {
        analyze(retainPublic: true)
        XCTAssertReferenced((.extensionProtocol, "FixtureProtocol81"))
    }

    func testUnusedProtocolWithExtension() {
        analyze(retainPublic: true)

        XCTAssertNotReferenced((.protocol, "FixtureProtocol82"))
        XCTAssertNotReferenced((.extensionProtocol, "FixtureProtocol82"))
    }

    func testRetainsProtocolMethodImplementedInExtension() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass80"))
        XCTAssertReferenced((.protocol, "FixtureProtocol80"))
        XCTAssertReferenced((.extensionProtocol, "FixtureProtocol80"))

        XCTAssertReferenced((.functionMethodInstance, "someMethod()"),
                            descendentOf: (.class, "FixtureClass80"))
        XCTAssertReferenced((.functionMethodInstance, "protocolMethod()"),
                            descendentOf: (.protocol, "FixtureProtocol80"))

        // The protocol extension contains a default implementation but it's unused because
        // the class also implements the function. Regardless, it needs to be retained.
        XCTAssertReferenced((.functionMethodInstance, "protocolMethodWithUnusedDefault()"),
                            descendentOf: (.protocol, "FixtureProtocol80"))
        XCTAssertReferenced((.functionMethodInstance, "protocolMethodWithUnusedDefault()"),
                            descendentOf: (.extensionProtocol, "FixtureProtocol80"))
        XCTAssertReferenced((.functionMethodInstance, "protocolMethodWithUnusedDefault()"),
                            descendentOf: (.class, "FixtureClass80"))
    }

    func testRetainsNonProtocolMethodDefinedInProtocolExtension() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass66"))
        XCTAssertReferenced((.protocol, "FixtureProtocol66"))
        XCTAssertReferenced((.extensionProtocol, "FixtureProtocol66"))

        XCTAssertReferenced((.functionMethodInstance, "someMethod()"),
                            descendentOf: (.class, "FixtureClass66"))
        XCTAssertReferenced((.functionMethodInstance, "nonProtocolMethod()"),
                            descendentOf: (.extensionProtocol, "FixtureProtocol66"))

        // Even though the protocol is retained because of the use of method declared
        // within the extension, the protocol method itself is not used.
        XCTAssertNotReferenced((.functionMethodInstance, "protocolMethod()"),
                            descendentOf: (.protocol, "FixtureProtocol66"))
    }

    func testDoesNotRetainUnusedProtocolMethodWithDefaultImplementation() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.functionMethodInstance, "usedMethod()"),
                            descendentOf: (.extensionProtocol, "FixtureProtocol84"))
        XCTAssertReferenced((.functionMethodInstance, "usedMethod()"),
                            descendentOf: (.protocol, "FixtureProtocol84"))

        XCTAssertNotReferenced((.functionMethodInstance, "unusedMethod()"),
                               descendentOf: (.extensionProtocol, "FixtureProtocol84"))
        XCTAssertNotReferenced((.functionMethodInstance, "unusedMethod()"),
                               descendentOf: (.protocol, "FixtureProtocol84"))
    }

    func testRetainedProtocolDoesNotRetainUnusedClass() {
        analyze(retainPublic: true)

        XCTAssertNotReferenced((.class, "FixtureClass57"))
        XCTAssertReferenced((.protocol, "FixtureProtocol57"))

        XCTAssertNotReferenced((.functionMethodInstance, "protocolMethod()"),
                               descendentOf: (.class, "FixtureClass57"))
    }

    func testRetainOverridingMethod() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass67"))
        XCTAssertReferenced((.class, "FixtureClass68"))

        XCTAssertReferenced((.functionMethodInstance, "someMethod()"),
                            descendentOf: (.class, "FixtureClass67"))
        XCTAssertReferenced((.functionMethodInstance, "someMethod()"),
                            descendentOf: (.class, "FixtureClass68"))
    }

    func testUnusedOverridenMethod() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass81Base"))
        XCTAssertReferenced((.class, "FixtureClass81Sub"))

        XCTAssertReferenced((.functionMethodInstance, "someMethod()"),
                            descendentOf: (.class, "FixtureClass81Sub"))

        XCTAssertNotReferenced((.functionMethodInstance, "someMethod()"),
                               descendentOf: (.class, "FixtureClass81Base"))
    }

    func testOverridenMethodRetainedBySuper() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass82Base"))
        XCTAssertReferenced((.class, "FixtureClass82Sub"))

        XCTAssertReferenced((.functionMethodInstance, "someMethod()"),
                            descendentOf: (.class, "FixtureClass82Sub"))
        XCTAssertReferenced((.functionMethodInstance, "someMethod()"),
                            descendentOf: (.class, "FixtureClass82Base"))
    }

    func testEnumCases() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.enumelement, "used"),
                            descendentOf: (.enum, "Fixture28Enum_Bare"))
        XCTAssertNotReferenced((.enumelement, "unused"),
                               descendentOf: (.enum, "Fixture28Enum_Bare"))

        let enumTypes = ["String", "Character", "Int", "Float", "Double", "RawRepresentable"]

        for enumType in enumTypes {
            let enumName = "Fixture28Enum_\(enumType)"

            XCTAssertReferenced((.enumelement, "used"),
                                descendentOf: (.enum, enumName))
            XCTAssertReferenced((.enumelement, "unused"),
                                descendentOf: (.enum, enumName))
        }

        analyze(retainPublic: true, aggressive: true)

        for enumType in enumTypes {
            let enumName = "Fixture28Enum_\(enumType)"

            XCTAssertReferenced((.enumelement, "used"),
                                descendentOf: (.enum, enumName))
            XCTAssertNotReferenced((.enumelement, "unused"),
                                   descendentOf: (.enum, enumName))
        }
    }

    func testRetainsDestructor() {
        analyze(retainPublic: true)
        XCTAssertReferenced((.class, "FixtureClass40"))
        XCTAssertReferenced((.functionDestructor, "deinit"))
    }

    func testRetainsDefaultConstructor() {
        analyze(retainPublic: true)
        XCTAssertReferenced((.class, "FixtureClass41"))
        XCTAssertReferenced((.functionConstructor, "init()"))
    }

    func testAccessibility() {
        analyze()

        let publicClass = find((.class, "FixtureClass31"))
        XCTAssertEqual(publicClass?.accessibility, .public)

        let publicClassInit = find((.functionConstructor, "init(arg:)"))
        XCTAssertEqual(publicClassInit?.accessibility, .public)

        let openFunc = find((.functionMethodInstance, "openFunc()"))
        XCTAssertEqual(openFunc?.accessibility, .open)

        let innerClass = find((.class, "FixtureClass31Inner"))
        XCTAssertEqual(innerClass?.accessibility, .public)

        let privateFunc = find((.functionMethodInstance, "privateFunc()"))
        XCTAssertEqual(privateFunc?.accessibility, .private)

        let publicVar = find((.varInstance, "publicVar"))
        XCTAssertEqual(publicVar?.accessibility, .public)

        let internalClass = find((.class, "FixtureClass33"))
        XCTAssertEqual(internalClass?.accessibility, .internal)

        let publicEnumFunc = find((.functionMethodInstance, "publicEnumFunc()"))
        XCTAssertEqual(publicEnumFunc?.accessibility, .public)

        let publicMethodInExtension = find((.functionMethodInstance, "publicMethodInExtension()"))
        XCTAssertEqual(publicMethodInExtension?.accessibility, .public)

        let methodInPublicExtension = find((.functionMethodInstance, "methodInPublicExtension()"))
        XCTAssertEqual(methodInPublicExtension?.accessibility, .public)

        let staticMethodInPublicExtension = find((.functionMethodStatic, "staticMethodInPublicExtension()"))
        XCTAssertEqual(staticMethodInPublicExtension?.accessibility, .public)

        let staticVarInExtension = find((.varStatic, "staticVarInExtension"))
        XCTAssertEqual(staticVarInExtension?.accessibility, .public)

        let privateMethodInPublicExtension = find((.functionMethodInstance, "privateMethodInPublicExtension()"))
        XCTAssertEqual(privateMethodInPublicExtension?.accessibility, .private)

        let internalMethodInPublicExtension = find((.functionMethodInstance, "internalMethodInPublicExtension()"))
        XCTAssertEqual(internalMethodInPublicExtension?.accessibility, .internal)

        let methodInExternalStructTypeExtension = find((.functionMethodInstance, "methodInExternalStructTypeExtension()"))
        XCTAssertEqual(methodInExternalStructTypeExtension?.accessibility, .public)

        let methodInExternalProtocolTypeExtension = find((.functionMethodInstance, "methodInExternalProtocolTypeExtension()"))
        XCTAssertEqual(methodInExternalProtocolTypeExtension?.accessibility, .public)

        let customNotification = find((.varStatic, "CustomNotification"))
        XCTAssertEqual(customNotification?.accessibility, .public)
    }

    func testXCTestCaseClassesAndMethodsAreRetained() {
        analyze()
        XCTAssertReferenced((.class, "FixtureClass34"))
        XCTAssertReferenced((.functionMethodInstance, "testSomething()"))
        XCTAssertReferenced((.functionMethodInstance, "setUp()"))
        XCTAssertReferenced((.functionMethodStatic, "setUp()"))

        XCTAssertReferenced((.class, "FixtureClass34Subclass"))
        XCTAssertReferenced((.functionMethodInstance, "testSubclass()"))
    }

    func testRetainsMethodDefinedInExtensionOnStandardType() {
        analyze(retainPublic: true)
        XCTAssertReferenced((.varInstance, "trimmed"))
        XCTAssertReferenced((.class, "FixtureClass35"))
        XCTAssertReferenced((.functionMethodInstance, "testSomething()"))
    }

    func testRetainsGenericType() {
        analyze(retainPublic: true)
        XCTAssertReferenced((.class, "FixtureClass37"))
        XCTAssertReferenced((.protocol, "FixtureProtocol37"))
    }

    func testMainFileEntryPoint() {
        analyze(isMainFile: true)
        XCTAssertReferenced((.class, "FixtureClass42"))
        XCTAssertReferenced((.varGlobal, "someVar"))
    }

    func testMainFileEntryPointReference() {
        analyze(isMainFile: true, supplementalFiles: ["testMainFileEntryPointReference_2"])
        XCTAssertReferenced((.class, "FixtureClass94"))
    }

    func testUnusedTypealias() {
        analyze()
        XCTAssertNotReferenced((.typealias, "UnusedAlias"))
    }

    func testRetainsConstructorOfGenericClassWithDefaultArgumentValue() {
        analyze(retainPublic: true)
        XCTAssertReferenced((.class, "FixtureClass61"))
        XCTAssertReferenced((.class, "FixtureClass62"))
        XCTAssertReferenced((.functionConstructor, "init(someVar:)"),
                            descendentOf: (.class, "FixtureClass61"))
    }

    func testFunctionAccessorsRetainReferences() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.varInstance, "referencedByGetter"))
        XCTAssertReferenced((.varInstance, "referencedBySetter"))
        XCTAssertReferenced((.varInstance, "referencedByDidSet"))
    }

    func testInstanceVarReferencedInClosure() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass69"))
        XCTAssertReferenced((.varInstance, "someVar"))
    }

    func testSelectorTarget() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass73"))
        XCTAssertReferenced((.functionMethodInstance, "someTargetMethod()"),
                            descendentOf: (.class, "FixtureClass73"))
    }

    func testCodingKeyEnum() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass74"))
        XCTAssertReferenced((.enum, "CodingKeys"),
                            descendentOf: (.class, "FixtureClass74"))

        XCTAssertReferenced((.class, "FixtureClass75"))
        XCTAssertReferenced((.enum, "CodingKeys"),
                            descendentOf: (.class, "FixtureClass75"))

        XCTAssertReferenced((.class, "FixtureClass76"))
        // Not referenced because the enclosing class does not conform to Decodable.
        XCTAssertNotReferenced((.enum, "CodingKeys"),
                               descendentOf: (.class, "FixtureClass76"))
    }

    func testRequiredInitInSubclass() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass77Base"))
        XCTAssertReferenced((.class, "FixtureClass77"))

        XCTAssertReferenced((.functionConstructor, "init(a:)"),
                            descendentOf: (.class, "FixtureClass77"))
        XCTAssertReferenced((.functionConstructor, "init(c:)"),
                            descendentOf: (.class, "FixtureClass77"))
        XCTAssertReferenced((.functionConstructor, "init(b:)"),
                            descendentOf: (.class, "FixtureClass77"))

        XCTAssertReferenced((.functionConstructor, "init(a:)"),
                            descendentOf: (.class, "FixtureClass77Base"))
        XCTAssertReferenced((.functionConstructor, "init(b:)"),
                            descendentOf: (.class, "FixtureClass77Base"))
    }

    func testRetainsExternalTypeExtension() {
        analyze()

        XCTAssertReferenced((.extensionProtocol, "Sequence")) // protocol
        XCTAssertReferenced((.extensionStruct, "Array")) // struct
        XCTAssertReferenced((.extensionClass, "NumberFormatter")) // class
    }

    func testRetainsAssociatedTypeTypeAlias() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass87Usage"))
        XCTAssertReferenced((.class, "Fixture87StateMachine"))
        XCTAssertReferenced((.struct, "Fixture87AssociatedType"))
        XCTAssertReferenced((.protocol, "Fixture87State"))
        XCTAssertReferenced((.enum, "Fixture87MyState"))

        XCTAssertReferenced((.functionMethodInstance, "somePublicFunction()"),
                            descendentOf: (.class, "FixtureClass87Usage"))
        XCTAssertReferenced((.functionMethodInstance, "someFunction(_:)"),
                            descendentOf: (.class, "Fixture87StateMachine"))

        XCTAssertReferenced((.associatedtype, "AssociatedType"),
                            descendentOf: (.protocol, "Fixture87State"))
        XCTAssertReferenced((.typealias, "AssociatedType"),
                            descendentOf: (.enum, "Fixture87MyState"))
    }

    func testUnusedAssociatedType() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass88Usage"))
        XCTAssertReferenced((.class, "Fixture88StateMachine"))
        XCTAssertReferenced((.protocol, "Fixture88State"))
        XCTAssertReferenced((.enum, "Fixture88MyState"))

        XCTAssertReferenced((.functionMethodInstance, "somePublicFunction()"),
                            descendentOf: (.class, "FixtureClass88Usage"))
        XCTAssertReferenced((.functionMethodInstance, "someFunction()"),
                            descendentOf: (.class, "Fixture88StateMachine"))

        XCTAssertNotReferenced((.struct, "Fixture88AssociatedType"))
        XCTAssertNotReferenced((.associatedtype, "AssociatedType"),
                               descendentOf: (.protocol, "Fixture88State"))
        XCTAssertNotReferenced((.typealias, "AssociatedType"),
                               descendentOf: (.enum, "Fixture88MyState"))
    }

    func testRedundantMethodRedeclarationInProtocolSubclass() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.functionMethodInstance, "protocolMethod()"),
                            descendentOf: (.protocol, "Fixture85ParentProtocol"))
        XCTAssertNotReferenced((.functionMethodInstance, "protocolMethod()"),
                               descendentOf: (.protocol, "Fixture85ChildProtocol"))
    }

    func testIsolatedCyclicRootReferences() {
        analyze(retainPublic: true)
        XCTAssertNotReferenced((.class, "FixtureClass90"))
        XCTAssertNotReferenced((.class, "FixtureClass91"))
    }

    func testRetainsUsedProtocolThatInheritsForeignProtocol() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.protocol, "FixtureProtocol96"))
        XCTAssertReferenced((.extensionProtocol, "FixtureProtocol96"))
        XCTAssertReferenced((.varInstance, "usedValue"),
                            descendentOf: (.protocol, "FixtureProtocol96"))
        XCTAssertReferenced((.functionOperatorInfix, "<(_:_:)"),
                            descendentOf: (.extensionProtocol, "FixtureProtocol96"))
        XCTAssertNotReferenced((.varInstance, "unusedValue"),
                               descendentOf: (.protocol, "FixtureProtocol96"))

        XCTAssertReferenced((.class, "FixtureClass96"))
        XCTAssertReferenced((.varInstance, "usedValue"),
                            descendentOf: (.class, "FixtureClass96"))
        XCTAssertNotReferenced((.varInstance, "unusedValue"),
                               descendentOf: (.class, "FixtureClass96"))
    }

    func testRetainsProtocolMethodsImplementedInSuperclasss() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.protocol, "FixtureProtocol97"))
        XCTAssertReferenced((.functionMethodInstance, "someProtocolMethod1()"),
                            descendentOf: (.protocol, "FixtureProtocol97"))
        XCTAssertReferenced((.functionMethodInstance, "someProtocolMethod2()"),
                            descendentOf: (.protocol, "FixtureProtocol97"))
        XCTAssertReferenced((.varInstance, "someProtocolVar"),
                            descendentOf: (.protocol, "FixtureProtocol97"))

        XCTAssertNotReferenced((.functionMethodInstance, "someUnusedProtocolMethod()"),
                               descendentOf: (.protocol, "FixtureProtocol97"))

        XCTAssertReferenced((.class, "FixtureClass97"))
        XCTAssertReferenced((.functionMethodInstance, "someProtocolMethod2()"),
                            descendentOf: (.class, "FixtureClass97Base2"))
        XCTAssertReferenced((.functionMethodInstance, "someProtocolMethod1()"),
                            descendentOf: (.class, "FixtureClass97Base1"))
        XCTAssertReferenced((.varInstance, "someProtocolVar"),
                            descendentOf: (.class, "FixtureClass97Base1"))

        XCTAssertNotReferenced((.functionMethodInstance, "someUnusedProtocolMethod()"),
                               descendentOf: (.class, "FixtureClass97Base2"))
    }

    func testProtocolImplementInClassAndExtension() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass98"))
        XCTAssertReferenced((.functionMethodInstance, "method1()"),
                            descendentOf: (.class, "FixtureClass98"))
        XCTAssertReferenced((.functionMethodInstance, "method2()"),
                            descendentOf: (.class, "FixtureClass98"))

        XCTAssertReferenced((.protocol, "FixtureProtocol98"))
        XCTAssertReferenced((.functionMethodInstance, "method1()"),
                            descendentOf: (.protocol, "FixtureProtocol98"))
        XCTAssertReferenced((.functionMethodInstance, "method2()"),
                            descendentOf: (.protocol, "FixtureProtocol98"))
    }

    func testDoesNotRetainDescendantsOfUnusedDeclaration() {
        analyze(retainPublic: true)

        XCTAssertNotReferenced((.class, "FixtureClass99"))
        XCTAssertNotReferenced((.functionMethodInstance, "someMethod()"))
        XCTAssertNotReferenced((.varInstance, "someVar"))

        XCTAssertIgnored((.functionMethodInstance, "someMethod()"))
        XCTAssertIgnored((.varInstance, "someVar"))
    }

    // MARK: - Unused Parameters

    func testRetainsParamUsedInOverriddenMethod() throws {
        analyze(retainPublic: true)

        // - FixtureClass101Base

        let baseFunc1Param = get("param", "func1(param:)", "FixtureClass101Base")
        // Not used and not overriden.
        try XCTAssertFalse(XCTUnwrap(baseFunc1Param).isRetained)

        let baseFunc2Param = get("param", "func2(param:)", "FixtureClass101Base")
        // Nil because the param is used.
        XCTAssertNil(baseFunc2Param)

        let baseFunc3Param = get("param", "func3(param:)", "FixtureClass101Base")
        // Used in override.
        try XCTAssertTrue(XCTUnwrap(baseFunc3Param).isRetained)

        let baseFunc4Param = get("param", "func4(param:)", "FixtureClass101Base")
        // Used in override.
        try XCTAssertTrue(XCTUnwrap(baseFunc4Param).isRetained)

        let baseFunc5Param = get("param", "func5(param:)", "FixtureClass101Base")
        // Not used in any function.
        try XCTAssertFalse(XCTUnwrap(baseFunc5Param).isRetained)

        // - FixtureClass101Subclass1

        let sub1Func2Param = get("param", "func2(param:)", "FixtureClass101Subclass1")
        // Used in base.
        try XCTAssertTrue(XCTUnwrap(sub1Func2Param).isRetained)

        let sub1Func3Param = get("param", "func3(param:)", "FixtureClass101Subclass1")
        // Nil because the param is used.
        XCTAssertNil(sub1Func3Param)

        // - FixtureClass101Subclass2

        let sub2Func4Param = get("param", "func4(param:)", "FixtureClass101Subclass2")
        // Nil because the param is used.
        XCTAssertNil(sub2Func4Param)

        let sub2Func5Param = get("param", "func5(param:)", "FixtureClass101Subclass2")
        // Not used in any function.
        try XCTAssertFalse(XCTUnwrap(sub2Func5Param).isRetained)

        // - FixtureClass101InheritForeignBase

        let foreignBaseFuncParam = get("object", "isEqual(_:)", "FixtureClass101InheritForeignBase")
        // Overrides foreign function.
        try XCTAssertTrue(XCTUnwrap(foreignBaseFuncParam).isRetained)

        // - FixtureClass101InheritForeignSubclass1

        let foreignSub1FuncParam = get("object", "isEqual(_:)", "FixtureClass101InheritForeignSubclass1")
        // Overrides foreign function.
        try XCTAssertTrue(XCTUnwrap(foreignSub1FuncParam).isRetained)
    }

    func testRetainsForeignProtocolParameters() throws {
        analyze(retainPublic: true)

        let decoderParam = get("decoder", "init(from:)", "FixtureClass103")
        try XCTAssertTrue(XCTUnwrap(decoderParam).isRetained)

        let encoderParam = get("encoder", "encode(to:)", "FixtureClass103")
        try XCTAssertTrue(XCTUnwrap(encoderParam).isRetained)
    }

    func testRetainUnusedProtocolFuncParams() {
        let configuration = inject(Configuration.self)
        configuration.retainUnusedProtocolFuncParams = true
        analyze(retainPublic: true)

        let protoParam = get("param", "myFunc(param:)", "FixtureProtocol107")
        try XCTAssertTrue(XCTUnwrap(protoParam).isRetained)

        let protoExtParam = get("param", "myFunc(param:)", "FixtureProtocol107", .extensionProtocol)
        try XCTAssertTrue(XCTUnwrap(protoExtParam).isRetained)

        let class1Param = get("param", "myFunc(param:)", "FixtureClass107Class1")
        try XCTAssertTrue(XCTUnwrap(class1Param).isRetained)

        let class2Param = get("param", "myFunc(param:)", "FixtureClass107Class2")
        try XCTAssertTrue(XCTUnwrap(class2Param).isRetained)
    }

    func testIgnoreUnusedParamInUnusedFunction() {
        analyze()

        XCTAssertNotReferenced((.class, "FixtureClass105"))
        XCTAssertNotReferenced((.functionMethodInstance, "unused(param:)"))
        XCTAssertIgnored((.varParameter, "param"))
    }

    func testNestedDeclarations() {
        analyze(retainPublic: true)

        XCTAssertReferenced((.functionMethodInstance, "nested1()"))
        XCTAssertReferenced((.functionMethodInstance, "nested2()"))
    }

    // MARK: - Known Failures

    func testProtocolConformingMembersAreRetained() {
        guard performKnownFailures else { return }

        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass27"))
        XCTAssertReferenced((.protocol, "FixtureProtocol27"))
        XCTAssertReferenced((.functionMethodInstance, "protocolMethod()"),
                            descendentOf: (.class, "FixtureClass27"))
        XCTAssertReferenced((.functionMethodClass, "staticProtocolMethod()"),
                            descendentOf: (.class, "FixtureClass27"))
        XCTAssertReferenced((.varClass, "staticProtocolVar"),
                            descendentOf: (.class, "FixtureClass27"))

        XCTAssertReferenced((.class, "FixtureClass28"))
        XCTAssertReferenced((.class, "FixtureClass28Base"))
        XCTAssertReferenced((.protocol, "FixtureProtocol28"))
        XCTAssertReferenced((.functionMethodClass, "overrideStaticProtocolMethod()"),
                            descendentOf: (.class, "FixtureClass28Base"))
        XCTAssertReferenced((.functionMethodStatic, "overrideStaticProtocolMethod()"),
                            descendentOf: (.class, "FixtureClass28"))
        XCTAssertReferenced((.varClass, "overrideStaticProtocolVar"),
                            descendentOf: (.class, "FixtureClass28Base"))
        XCTAssertReferenced((.varStatic, "overrideStaticProtocolVar"),
                            descendentOf: (.class, "FixtureClass28"))
    }

    func testRetainsProtocolParameters() {
        guard performKnownFailures else { return }

        analyze(retainPublic: true)

        // - FixtureProtocol104

        let protoFunc1Param1 = get("param1", "func1(param1:param2:)", "FixtureProtocol104")
        // Used in a conformance.
        try XCTAssertTrue(XCTUnwrap(protoFunc1Param1).isRetained)

        let protoFunc1Param2 = get("param2", "func1(param1:param2:)", "FixtureProtocol104")
        // Not used in any conformance.
        try XCTAssertFalse(XCTUnwrap(protoFunc1Param2).isRetained)

        let protoFunc2Param = get("param", "func2(param:)", "FixtureProtocol104")
        // Not used in any conformance.
        try XCTAssertFalse(XCTUnwrap(protoFunc2Param).isRetained)

        let protoFunc3Param = get("param", "func3(param:)", "FixtureProtocol104")
        // Used in the extension.
        try XCTAssertTrue(XCTUnwrap(protoFunc3Param).isRetained)

        let protoFunc4Param = get("param", "func4(param:)", "FixtureProtocol104")
        // Unused in extension, but used in conformance.
        try XCTAssertTrue(XCTUnwrap(protoFunc4Param).isRetained)

        let protoFunc5Param = get("param", "func5(param:)", "FixtureProtocol104")
        // Used in a conformance.
        try XCTAssertTrue(XCTUnwrap(protoFunc5Param).isRetained)

        let protoFunc6Param = get("param", "func6(param:)", "FixtureProtocol104")
        // Used in a override.
        try XCTAssertTrue(XCTUnwrap(protoFunc6Param).isRetained)

        // - FixtureProtocol104 (extension)

        let protoExtFunc3Param = get("param", "func3(param:)", "FixtureProtocol104", .extensionProtocol)
        // Nil because the param is used.
        XCTAssertNil(protoExtFunc3Param)

        let protoExtFunc4Param = get("param", "func4(param:)", "FixtureProtocol104", .extensionProtocol)
        // Used in a conformance by another class.
        try XCTAssertTrue(XCTUnwrap(protoExtFunc4Param).isRetained)

        // - FixtureClass104Class1

        let class1Func1Param1 = get("param1", "func1(param1:param2:)", "FixtureClass104Class1")
        // Used in a conformance by another class.
        try XCTAssertTrue(XCTUnwrap(class1Func1Param1).isRetained)

        let class1Func1Param2 = get("param2", "func1(param1:param2:)", "FixtureClass104Class1")
        // Not used in any conformance.
        try XCTAssertFalse(XCTUnwrap(class1Func1Param2).isRetained)

        let class1Func2Param = get("param", "func2(param:)", "FixtureClass104Class1")
        // Not used in any conformance.
        try XCTAssertFalse(XCTUnwrap(class1Func2Param).isRetained)

        let class1Func5Param = get("param", "func5(param:)", "FixtureClass104Class1")
        // Nil because the param is used.
        XCTAssertNil(class1Func5Param)

        let class1Func6Param = get("param", "func6(param:)", "FixtureClass104Class1")
        // Used in a override.
        try XCTAssertTrue(XCTUnwrap(class1Func6Param).isRetained)

        let class1Func7Param = get("_", "func7(_:)", "FixtureClass104Class1")
        // Nil because the param is explicitly ignored.
        XCTAssertNil(class1Func7Param)

        // - FixtureClass104Class2

        let class2Func1Param1 = get("param1", "func1(param1:param2:)", "FixtureClass104Class2")
        // Nil because the param is used.
        XCTAssertNil(class2Func1Param1)

        let class2Func1Param2 = get("param2", "func1(param1:param2:)", "FixtureClass104Class2")
        // Not used in any conformance.
        try XCTAssertFalse(XCTUnwrap(class2Func1Param2).isRetained)

        let class2Func2Param = get("param", "func2(param:)", "FixtureClass104Class2")
        // Not used in any conformance.
        try XCTAssertFalse(XCTUnwrap(class2Func2Param).isRetained)

        let class2Func4Param = get("param", "func4(param:)", "FixtureClass104Class2")
        // Nil because the param is used.
        XCTAssertNil(class2Func4Param)

        let class2Func5Param = get("param", "func5(param:)", "FixtureClass104Class2")
        // Nil because the param is used.
        XCTAssertNil(class2Func5Param)

        let class2Func6Param = get("param", "func6(param:)", "FixtureClass104Class2")
        // Used in a override.
        try XCTAssertTrue(XCTUnwrap(class2Func6Param).isRetained)

        let class2Func7Param = get("_", "func7(_:)", "FixtureClass104Class2")
        // Nil because the param is explicitly ignored.
        XCTAssertNil(class2Func7Param)

        // - FixtureClass104Class3

        let class3Func6Param = get("param", "func6(param:)", "FixtureClass104Class3")
        // Nil because the param is used.
        XCTAssertNil(class3Func6Param)
    }

    func testProtocolConformedByStaticMethodOutsideExtension() {
        guard performKnownFailures else { return }

        // Broken since Xcode 10.2
        // TODO: Report to Apple.
        analyze(retainPublic: true)
        XCTAssertReferenced((.class, "FixtureClass64")) // public
        XCTAssertReferenced((.class, "FixtureClass65")) // retained by FixtureClass64

        XCTAssertReferenced((.functionOperatorInfix, "==(_:_:)")) // Equatable

        analyze(retainPublic: true, aggressive: true)
        XCTAssertNotReferenced((.functionOperatorInfix, "==(_:_:)")) // Equatable
    }

    func testCustomConstructorithLiteral() {
        guard performKnownFailures else { return }

        // TODO: Report to Apple.
        analyze(retainPublic: true)
        XCTAssertReferenced((.functionConstructor, "init(title:)"))
    }

    func testRetainsProtocolParameters_IgnoredParam() {
        guard performKnownFailures else { return }

        // TODO: This fails because the '_' params are marked as used in order to be ignored/silenced.
        // Instead we need to not ignore them, and also associate each param with its position
        // in the param list so that we can identify if used.

        // Merge this back into testRetainsProtocolParameters once completed.

        let protoFunc7Param = get("param", "func7(_:)", "FixtureProtocol104")
        // Not used in any conformance.
        try XCTAssertFalse(XCTUnwrap(protoFunc7Param).isRetained)
    }

    // TODO: Need a way to handle this now that we're using the SPM.
    func testViewXibRetainsClass() {
        guard performKnownFailures else { return }

        analyze()
        XCTAssertReferenced((.class, "XibView"))

        XCTAssertReferenced((.varInstance, "button"),
                            descendentOf: (.class, "XibView"))
        XCTAssertReferenced((.functionMethodInstance, "click(_:)"),
                            descendentOf: (.class, "XibView"))
    }

    // TODO: Need a way to handle this now that we're using the SPM.
    func testStoryboardRetainsClass() {
        guard performKnownFailures else { return }

        analyze()
        XCTAssertReferenced((.class, "XibViewController"))
    }

    func testGetSetPropertyWithDefaultImplementation() {
        guard performKnownFailures else { return }

        // Broken as of Xcode 10.
        // https://bugreport.apple.com/web/?problemID=44703843
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass100"))
        XCTAssertReferenced((.protocol, "FixtureProtocol100"))

        XCTAssertReferenced((.varInstance, "someGetSetVar"),
                            descendentOf: (.class, "FixtureClass100"))

        XCTAssertReferenced((.varInstance, "someGetSetVar"),
                            descendentOf: (.protocol, "FixtureProtocol100"))
    }

    func testDuplicateGetterUSRBug() {
        guard performKnownFailures else { return }

        // Broken as of Xcode 10.
        // https://bugreport.apple.com/web/?problemID=44531531
        analyze(retainPublic: true, aggressive: true)
        XCTAssertReferenced((.varInstance, "someVar"))
        XCTAssertReferenced((.varStatic, "someVar"))
    }

    func testClassRetainedByUnusedInstanceVariable() {
        guard performKnownFailures else { return }

        // SourceKit structures the class reference as a descendent of the parent
        // class, not the var declaration.
        analyze(retainPublic: true)

        XCTAssertReferenced((.class, "FixtureClass71"))

        XCTAssertNotReferenced((.class, "FixtureProtocol72"))
        XCTAssertNotReferenced((.varInstance, "someVar"),
                               descendentOf: (.class, "FixtureClass71"))
    }

    func testStaticPropertyDeclaredWithCompositeValuesIsNotRetained() {
        guard performKnownFailures else { return }

        analyze(retainPublic: true)
        XCTAssertReferenced((.class, "FixtureClass38"))
        XCTAssertNotReferenced((.varStatic, "propertyA"))
        XCTAssertNotReferenced((.varStatic, "propertyB"))
    }

    func testDoesNotRetainLazyProperty() {
        guard performKnownFailures else { return }

        analyze(retainPublic: true)
        XCTAssertReferenced((.class, "FixtureClass36"))
        XCTAssertNotReferenced((.varInstance, "someLazyVar"))
        XCTAssertNotReferenced((.varInstance, "someVar"))
    }

    // MARK: - Private

    private func analyze(retainPublic: Bool = false, aggressive: Bool = false, retainObjcAnnotated: Bool = false, isMainFile: Bool = false, supplementalFiles: [String] = []) {
        var testName = String(name.split(separator: " ").last!)
        testName = testName.replacingOccurrences(of: "]", with: "")
        let testFixturePath = fixturePath(for: testName)
        let configuration = inject(Configuration.self)
        configuration.retainPublic = retainPublic
        configuration.aggressive = aggressive
        configuration.retainObjcAnnotated = retainObjcAnnotated

        if isMainFile {
            configuration.entryPointFilenames.append(testName.lowercased() + ".swift")
        }

        graph = SourceGraph()

        var sourceFiles: Set<SourceFile> = [SourceFile(path: testFixturePath)]
        let supplementalSourceFiles = supplementalFiles.map { SourceFile(path: fixturePath(for: $0)) }
        sourceFiles = sourceFiles.union(supplementalSourceFiles)

        sourceFiles.forEach {
            XCTAssertTrue($0.path.exists, "\($0.path.string) does not exist.")
        }

        RetentionTest.target.set(sourceFiles: sourceFiles)
        try! Indexer.perform(buildPlan: RetentionTest.buildPlan, indexStore: RetentionTest.indexStore, graph: graph)
        try! Analyzer.perform(graph: graph)
    }

    private func fixturePath(for file: String) -> Path {
        return ProjectRootPath + "Tests/RetentionFixtures/\(file).swift"
    }

    private func XCTAssertNotReferenced(_ description: DeclarationDescription, file: StaticString = #file, line: UInt = #line) {
        guard let declaration = graph.allDeclarations.first(where: {
            $0.kind == description.kind && $0.name == description.name
        }) else {
            XCTFail("Expected \(description) to exist.", file: file, line: line)
            return
        }

        // We don't check dereferencedDeclarations as it's pruned of certain redundant declarations.
        let isReferenced = graph.referencedDeclarations.contains(declaration)
        XCTAssertTrue(!isReferenced, "Expected \(description) to not be referenced.", file: file, line: line)
    }

    private func XCTAssertReferenced(_ description: DeclarationDescription, file: StaticString = #file, line: UInt = #line) {
        let isReferenced = graph.referencedDeclarations.contains {
            $0.kind == description.kind && $0.name == description.name
        }

        XCTAssertTrue(isReferenced, "Expected \(description) to be referenced.", file: file, line: line)
    }

    private func XCTAssertReferenced(_ declaration: Declaration, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(graph.referencedDeclarations.contains(declaration), "Expected \(declaration) to be referenced.", file: file, line: line)
    }

    private func XCTAssertReferenced(_ description: DeclarationDescription, descendentOf parentDescription: DeclarationDescription, file: StaticString = #file, line: UInt = #line) {
        let parentDeclaration = find(parentDescription)

        XCTAssertNotNil(parentDeclaration, "Parent declaration not found: \(parentDescription)", file: file, line: line)

        if let parentDeclaration = parentDeclaration {
            let descendent = find(description, in: parentDeclaration.descendentDeclarations)

            XCTAssertNotNil(descendent, "Descendent declaration not found: \(description)", file: file, line: line)

            if let descendent = descendent {
                XCTAssertReferenced(descendent, file: file, line: line)
            }
        }
    }

    private func XCTAssertNotReferenced(_ description: DeclarationDescription, descendentOf parentDescription: DeclarationDescription, file: StaticString = #file, line: UInt = #line) {
        let parentDeclaration = find(parentDescription)

        XCTAssertNotNil(parentDeclaration, "Parent declaration not found: \(parentDescription)", file: file, line: line)

        if let parentDeclaration = parentDeclaration {
            let referencedDescendents = parentDeclaration.descendentDeclarations.intersection(graph.referencedDeclarations)
            let descendent = find(description, in: referencedDescendents)

            XCTAssertNil(descendent, "Descendent declaration should not be referenced: \(description)", file: file, line: line)
        }
    }

    private func XCTAssertIgnored(_ description: DeclarationDescription, file: StaticString = #file, line: UInt = #line) {
        let declaration = find(description)

        XCTAssertNotNil(declaration, "Declaration not found: \(description)", file: file, line: line)

        if let declaration = declaration {
            XCTAssertTrue(graph.ignoredDeclarations.contains(declaration), "Expected \(declaration) to be ignored.", file: file, line: line)
        }
    }

    private func find(_ description: DeclarationDescription, in collection: Set<Declaration>? = nil) -> Declaration? {
        return (collection ?? graph.allDeclarations).first { $0.kind == description.kind && $0.name == description.name }
    }

    func get(_ param: String, _ function: String, _ cls: String, _ kind: Declaration.Kind = .class) -> Declaration? {
        let decl = find((kind, cls)) ?? find((.protocol, cls))
        let funcDecl = Declaration.Kind.functionKinds.mapFirst {
            find(($0, function), in: decl!.declarations)
        }
        return find((.varParameter, param), in: funcDecl!.unusedParameters)
    }

    typealias DeclarationDescription = (kind: Declaration.Kind, name: String)
}
