import Configuration
import Logger
import Shared
@testable import SourceGraph
import SystemPackage
import XCTest

final class DeterminismRegressionTest: XCTestCase {
    private func makeGraph() -> SourceGraph {
        let configuration = Configuration()
        let logger = Logger(quiet: true, verbose: false, colorMode: .never)
        return SourceGraph(configuration: configuration, logger: logger)
    }

    private func makeSwiftVersion() -> SwiftVersion {
        let logger = Logger(quiet: true, verbose: false, colorMode: .never)
        let shell = ShellImpl(logger: logger)
        return SwiftVersion(shell: shell)
    }

    private func makeLocation(_ path: String, module: String, line: Int = 1, column: Int = 1) -> Location {
        let file = SourceFile(path: FilePath(path), modules: [module])
        return Location(file: file, line: line, column: column)
    }

    private func makeDeclaration(
        kind: Declaration.Kind,
        name: String,
        usr: String,
        location: Location
    ) -> Declaration {
        let declaration = Declaration(kind: kind, usrs: [usr], location: location)
        declaration.name = name
        return declaration
    }

    private func makeReference(
        kind: Reference.Kind,
        declarationKind: Declaration.Kind,
        usr: String,
        name: String,
        location: Location,
        parent: Declaration,
        role: Reference.Role = .unknown
    ) -> Reference {
        let reference = Reference(
            kind: kind,
            declarationKind: declarationKind,
            usr: usr,
            location: location
        )
        reference.name = name
        reference.parent = parent
        reference.role = role
        return reference
    }

    func testExtendedDeclarationReferenceUsesDeterministicSelection() throws {
        let graph = makeGraph()

        let extDecl = makeDeclaration(
            kind: .extensionClass,
            name: "Widget",
            usr: "ext_widget",
            location: makeLocation("/tmp/ext.swift", module: "Feature", line: 1)
        )

        let later = makeReference(
            kind: .normal,
            declarationKind: .class,
            usr: "class_later",
            name: "Widget",
            location: makeLocation("/tmp/widget.swift", module: "A", line: 20),
            parent: extDecl
        )
        let earlier = makeReference(
            kind: .normal,
            declarationKind: .class,
            usr: "class_earlier",
            name: "Widget",
            location: makeLocation("/tmp/widget.swift", module: "B", line: 10),
            parent: extDecl
        )

        extDecl.references = [later, earlier]

        let selected = try XCTUnwrap(graph.extendedDeclarationReference(forExtension: extDecl))
        XCTAssertEqual(selected.usr, "class_earlier")
    }

    func testBaseDeclarationUsesDeterministicSelection() {
        let graph = makeGraph()

        let overrideDecl = makeDeclaration(
            kind: .functionMethodInstance,
            name: "configure()",
            usr: "child_configure",
            location: makeLocation("/tmp/child.swift", module: "Feature", line: 30)
        )
        overrideDecl.modifiers.insert("override")

        let baseLater = makeDeclaration(
            kind: .functionMethodInstance,
            name: "configure()",
            usr: "base_later",
            location: makeLocation("/tmp/later.swift", module: "BaseA", line: 50)
        )
        let baseEarlier = makeDeclaration(
            kind: .functionMethodInstance,
            name: "configure()",
            usr: "base_earlier",
            location: makeLocation("/tmp/earlier.swift", module: "BaseB", line: 10)
        )

        let refToLater = makeReference(
            kind: .related,
            declarationKind: .functionMethodInstance,
            usr: "child_configure",
            name: "configure()",
            location: makeLocation("/tmp/ref_later.swift", module: "Feature", line: 1),
            parent: baseLater
        )
        let refToEarlier = makeReference(
            kind: .related,
            declarationKind: .functionMethodInstance,
            usr: "child_configure",
            name: "configure()",
            location: makeLocation("/tmp/ref_earlier.swift", module: "Feature", line: 2),
            parent: baseEarlier
        )

        graph.add(refToLater)
        graph.add(refToEarlier)

        let (base, resolved) = graph.baseDeclaration(fromOverride: overrideDecl)
        XCTAssertTrue(resolved)
        XCTAssertEqual(base.usrs, ["base_earlier"])
    }

    func testExternalOverrideRetainerRetainsWhenAnyMatchingRelatedReferenceIsExternal() {
        let graph = makeGraph()
        let configuration = Configuration()
        let swiftVersion = makeSwiftVersion()

        let overrideDecl = makeDeclaration(
            kind: .functionMethodInstance,
            name: "configure()",
            usr: "feature_configure",
            location: makeLocation("/tmp/feature.swift", module: "Feature", line: 100)
        )
        overrideDecl.modifiers.insert("override")

        let internalBase = makeDeclaration(
            kind: .functionMethodInstance,
            name: "configure()",
            usr: "internal_base",
            location: makeLocation("/tmp/base.swift", module: "Core", line: 10)
        )
        graph.add(internalBase)
        graph.add(overrideDecl)

        let matchingInternal = makeReference(
            kind: .related,
            declarationKind: .functionMethodInstance,
            usr: "internal_base",
            name: "configure()",
            location: overrideDecl.location,
            parent: overrideDecl
        )
        let matchingExternal = makeReference(
            kind: .related,
            declarationKind: .functionMethodInstance,
            usr: "external_base",
            name: "configure()",
            location: overrideDecl.location,
            parent: overrideDecl
        )
        overrideDecl.related = [matchingInternal, matchingExternal]

        ExternalOverrideRetainer(graph: graph, configuration: configuration, swiftVersion: swiftVersion).mutate()
        XCTAssertTrue(graph.isRetained(overrideDecl))
    }

    func testAssetReferenceRetainerHandlesAllMatchingSourcesForClassName() {
        let graph = makeGraph()
        let configuration = Configuration()

        let classDecl = makeDeclaration(
            kind: .class,
            name: "FixtureController",
            usr: "fixture_controller",
            location: makeLocation("/tmp/controller.swift", module: "UI", line: 1)
        )
        let outletDecl = makeDeclaration(
            kind: .varInstance,
            name: "submitButton",
            usr: "fixture_controller_submit_button",
            location: makeLocation("/tmp/controller.swift", module: "UI", line: 5)
        )
        outletDecl.attributes.insert(DeclarationAttribute(name: "IBOutlet", arguments: nil))
        outletDecl.parent = classDecl
        classDecl.declarations.insert(outletDecl)

        graph.add(classDecl)
        graph.add(outletDecl)
        graph.markRedundantPublicAccessibility(classDecl, modules: ["UI"])
        graph.markRedundantPublicAccessibility(outletDecl, modules: ["UI"])

        let xcDataModelRef = AssetReference(absoluteName: "FixtureController", source: .xcDataModel)
        let ibRef = AssetReference(
            absoluteName: "FixtureController",
            source: .interfaceBuilder,
            outlets: ["submitButton"],
            actions: [],
            runtimeAttributes: []
        )
        graph.add(xcDataModelRef)
        graph.add(ibRef)

        AssetReferenceRetainer(graph: graph, configuration: configuration, swiftVersion: makeSwiftVersion()).mutate()

        XCTAssertTrue(graph.isRetained(classDecl))
        XCTAssertTrue(graph.isRetained(outletDecl))
        XCTAssertNil(graph.redundantPublicAccessibility[classDecl])
        XCTAssertNil(graph.redundantPublicAccessibility[outletDecl])
    }

    func testProtocolConformanceReferenceBuilderDeterministicallySelectsSuperclassImplementation() {
        let graph = makeGraph()
        let configuration = Configuration()

        let proto = makeDeclaration(
            kind: .protocol,
            name: "Renderable",
            usr: "proto_renderable",
            location: makeLocation("/tmp/proto.swift", module: "Core", line: 1)
        )
        let requirement = makeDeclaration(
            kind: .functionMethodInstance,
            name: "configure()",
            usr: "proto_requirement_configure",
            location: makeLocation("/tmp/proto.swift", module: "Core", line: 2)
        )
        requirement.parent = proto
        proto.declarations.insert(requirement)

        let conformingClass = makeDeclaration(
            kind: .class,
            name: "FeatureWidget",
            usr: "feature_widget",
            location: makeLocation("/tmp/feature.swift", module: "Feature", line: 1)
        )

        let superLater = makeDeclaration(
            kind: .class,
            name: "BaseWidgetA",
            usr: "base_widget_a",
            location: makeLocation("/tmp/base.swift", module: "BaseA", line: 40)
        )
        let superEarlier = makeDeclaration(
            kind: .class,
            name: "BaseWidgetB",
            usr: "base_widget_b",
            location: makeLocation("/tmp/base.swift", module: "BaseB", line: 5)
        )
        let superLaterMethod = makeDeclaration(
            kind: .functionMethodInstance,
            name: "configure()",
            usr: "base_widget_a_configure",
            location: makeLocation("/tmp/base_method.swift", module: "BaseA", line: 41)
        )
        superLaterMethod.parent = superLater
        superLater.declarations.insert(superLaterMethod)

        let superEarlierMethod = makeDeclaration(
            kind: .functionMethodInstance,
            name: "configure()",
            usr: "base_widget_b_configure",
            location: makeLocation("/tmp/base_method.swift", module: "BaseB", line: 6)
        )
        superEarlierMethod.parent = superEarlier
        superEarlier.declarations.insert(superEarlierMethod)

        graph.add(proto)
        graph.add(requirement)
        graph.add(conformingClass)
        graph.add(superLater)
        graph.add(superEarlier)
        graph.add(superLaterMethod)
        graph.add(superEarlierMethod)

        let conformsRef = makeReference(
            kind: .related,
            declarationKind: .protocol,
            usr: "proto_renderable",
            name: "Renderable",
            location: makeLocation("/tmp/feature.swift", module: "Feature", line: 3),
            parent: conformingClass
        )
        let inheritsLater = makeReference(
            kind: .related,
            declarationKind: .class,
            usr: "base_widget_a",
            name: "BaseWidgetA",
            location: makeLocation("/tmp/feature.swift", module: "Feature", line: 4),
            parent: conformingClass
        )
        let inheritsEarlier = makeReference(
            kind: .related,
            declarationKind: .class,
            usr: "base_widget_b",
            name: "BaseWidgetB",
            location: makeLocation("/tmp/feature.swift", module: "Feature", line: 5),
            parent: conformingClass
        )

        graph.add(conformsRef, from: conformingClass)
        graph.add(inheritsLater, from: conformingClass)
        graph.add(inheritsEarlier, from: conformingClass)

        ProtocolConformanceReferenceBuilder(graph: graph, configuration: configuration, swiftVersion: makeSwiftVersion()).mutate()

        XCTAssertTrue(requirement.related.contains { $0.usr == "base_widget_b_configure" })
        XCTAssertFalse(requirement.related.contains { $0.usr == "base_widget_a_configure" })
    }

    func testProtocolExtensionReferenceBuilderDeterministicallySelectsMatchingRequirement() throws {
        let graph = makeGraph()
        let configuration = Configuration()

        let baseProtocol = makeDeclaration(
            kind: .protocol,
            name: "BaseWidget",
            usr: "base_protocol",
            location: makeLocation("/tmp/base_protocol.swift", module: "Core", line: 1)
        )
        let constrainingProtocol = makeDeclaration(
            kind: .protocol,
            name: "Configurable",
            usr: "constraining_protocol",
            location: makeLocation("/tmp/configurable.swift", module: "Core", line: 1)
        )
        let requirementLater = makeDeclaration(
            kind: .functionMethodInstance,
            name: "configure()",
            usr: "requirement_later",
            location: makeLocation("/tmp/configurable.swift", module: "A", line: 40)
        )
        requirementLater.parent = constrainingProtocol
        let requirementEarlier = makeDeclaration(
            kind: .functionMethodInstance,
            name: "configure()",
            usr: "requirement_earlier",
            location: makeLocation("/tmp/configurable.swift", module: "B", line: 5)
        )
        requirementEarlier.parent = constrainingProtocol
        constrainingProtocol.declarations = [requirementLater, requirementEarlier]

        let extensionDecl = makeDeclaration(
            kind: .extensionProtocol,
            name: "BaseWidget",
            usr: "base_protocol_extension",
            location: makeLocation("/tmp/base_protocol_ext.swift", module: "Feature", line: 1)
        )
        let member = makeDeclaration(
            kind: .functionMethodInstance,
            name: "configure()",
            usr: "extension_member_configure",
            location: makeLocation("/tmp/base_protocol_ext.swift", module: "Feature", line: 2)
        )
        member.parent = extensionDecl
        extensionDecl.declarations.insert(member)

        let extendsBaseProtocolRef = makeReference(
            kind: .normal,
            declarationKind: .protocol,
            usr: "base_protocol",
            name: "BaseWidget",
            location: makeLocation("/tmp/base_protocol_ext.swift", module: "Feature", line: 1),
            parent: extensionDecl
        )
        let whereConstraintRef = makeReference(
            kind: .normal,
            declarationKind: .protocol,
            usr: "constraining_protocol",
            name: "Configurable",
            location: makeLocation("/tmp/base_protocol_ext.swift", module: "Feature", line: 1),
            parent: extensionDecl,
            role: .genericRequirementType
        )
        extensionDecl.references = [extendsBaseProtocolRef, whereConstraintRef]

        graph.add(baseProtocol)
        graph.add(constrainingProtocol)
        graph.add(requirementLater)
        graph.add(requirementEarlier)
        graph.add(extensionDecl)
        graph.add(member)
        graph.add(extendsBaseProtocolRef, from: extensionDecl)
        graph.add(whereConstraintRef, from: extensionDecl)

        try ProtocolExtensionReferenceBuilder(graph: graph, configuration: configuration, swiftVersion: makeSwiftVersion()).mutate()

        XCTAssertTrue(member.related.contains { $0.usr == "requirement_earlier" })
        XCTAssertFalse(member.related.contains { $0.usr == "requirement_later" })
    }

    // MARK: - USR Conflict Resolution

    func testDuplicateUSRResolutionKeepsEarlierDeclaration() {
        let graph = makeGraph()

        let earlier = makeDeclaration(
            kind: .class,
            name: "MyClass",
            usr: "shared_usr",
            location: makeLocation("/tmp/a.swift", module: "A", line: 10)
        )
        let later = makeDeclaration(
            kind: .class,
            name: "MyClass",
            usr: "shared_usr",
            location: makeLocation("/tmp/b.swift", module: "B", line: 20)
        )

        // Add earlier first, then later. Before the fix, SourceGraph.add always
        // overwrote allDeclarationsByUsr unconditionally, so `later` would win.
        // After the fix, the declaration that sorts first is kept.
        graph.add(earlier)
        graph.add(later)

        XCTAssertIdentical(graph.declaration(withUsr: "shared_usr"), earlier)
    }

    func testDuplicateUSRResolutionIsDeterministicRegardlessOfInsertionOrder() {
        let earlier = makeDeclaration(
            kind: .class,
            name: "MyClass",
            usr: "shared_usr",
            location: makeLocation("/tmp/a.swift", module: "A", line: 10)
        )
        let later = makeDeclaration(
            kind: .class,
            name: "MyClass",
            usr: "shared_usr",
            location: makeLocation("/tmp/b.swift", module: "B", line: 20)
        )

        let graph1 = makeGraph()
        graph1.add(earlier)
        graph1.add(later)

        let graph2 = makeGraph()
        graph2.add(later)
        graph2.add(earlier)

        // Both graphs should resolve to the same declaration (the earlier-sorting one),
        // regardless of insertion order. Before the fix, graph1 would have `later` and
        // graph2 would have `earlier`, producing different results from the same input.
        XCTAssertIdentical(graph1.declaration(withUsr: "shared_usr"), earlier)
        XCTAssertIdentical(graph2.declaration(withUsr: "shared_usr"), earlier)
    }

    // MARK: - AncestralReferenceEliminator with Same-Location Declarations

    func testAncestralReferenceEliminatorWithSameLocationDeclarations() {
        // Models the real-world scenario: a struct and a macro-generated class exist at
        // the same source location. If a dangling reference (to the struct's own USR) is
        // associated with the struct itself (instead of the class), it becomes a
        // self-reference that AncestralReferenceEliminator removes, causing the struct to
        // appear unreferenced. The fix in associateDanglingReferences ensures deterministic
        // candidate selection so the reference is always associated with the parentless
        // declaration (the struct), not the class nested under it.
        let graph = makeGraph()
        let configuration = Configuration()

        let structDecl = makeDeclaration(
            kind: .struct,
            name: "FeatureRunner",
            usr: "feature_runner_struct",
            location: makeLocation("/tmp/feature.swift", module: "Feature", line: 7)
        )

        let classDecl = makeDeclaration(
            kind: .class,
            name: "$FeatureRunner",
            usr: "feature_runner_class",
            location: makeLocation("/tmp/feature.swift", module: "Feature", line: 7)
        )
        classDecl.parent = structDecl
        structDecl.declarations.insert(classDecl)

        // A reference TO the struct from an external declaration (the correct scenario).
        let externalParent = makeDeclaration(
            kind: .class,
            name: "AppRunner",
            usr: "app_runner",
            location: makeLocation("/tmp/app.swift", module: "App", line: 1)
        )
        let externalRef = makeReference(
            kind: .normal,
            declarationKind: .struct,
            usr: "feature_runner_struct",
            name: "FeatureRunner",
            location: makeLocation("/tmp/app.swift", module: "App", line: 5),
            parent: externalParent
        )

        graph.add(structDecl)
        graph.add(classDecl)
        graph.add(externalParent)
        graph.add(externalRef, from: externalParent)

        XCTAssertTrue(graph.hasReferences(to: structDecl))

        graph.indexingComplete()
        AncestralReferenceEliminator(graph: graph, configuration: configuration, swiftVersion: makeSwiftVersion()).mutate()

        // The external reference should survive since it's not a self-reference.
        XCTAssertTrue(graph.hasReferences(to: structDecl))
    }

    func testAncestralReferenceEliminatorRemovesSelfReferences() {
        // When a dangling reference is incorrectly associated with the declaration it
        // references (creating a self-reference), AncestralReferenceEliminator correctly
        // removes it. This test verifies the eliminator's behavior is correct — the fix
        // was in the indexer to prevent the self-reference from being created in the first
        // place.
        let graph = makeGraph()
        let configuration = Configuration()

        let structDecl = makeDeclaration(
            kind: .struct,
            name: "FeatureRunner",
            usr: "feature_runner_struct",
            location: makeLocation("/tmp/feature.swift", module: "Feature", line: 7)
        )

        // Self-reference: a reference to the struct's own USR, parented by the struct.
        let selfRef = makeReference(
            kind: .normal,
            declarationKind: .struct,
            usr: "feature_runner_struct",
            name: "FeatureRunner",
            location: makeLocation("/tmp/feature.swift", module: "Feature", line: 7),
            parent: structDecl
        )

        graph.add(structDecl)
        graph.add(selfRef, from: structDecl)

        XCTAssertTrue(graph.hasReferences(to: structDecl))

        graph.indexingComplete()
        AncestralReferenceEliminator(graph: graph, configuration: configuration, swiftVersion: makeSwiftVersion()).mutate()

        // Self-reference should be eliminated, leaving the struct unreferenced.
        XCTAssertFalse(graph.hasReferences(to: structDecl))
    }

    // MARK: - Protocol Conformance Inversion with Multiple Conformances

    func testProtocolConformanceInversionHandlesMultipleConformances() {
        // When multiple classes conform to the same protocol, the inversion must
        // process all conformances correctly. Before the batch mutation fix, graph
        // mutations during iteration could cause order-dependent skipping.
        let graph = makeGraph()
        let configuration = Configuration()

        let proto = makeDeclaration(
            kind: .protocol,
            name: "Runnable",
            usr: "proto_runnable",
            location: makeLocation("/tmp/proto.swift", module: "Core", line: 1)
        )
        let requirement = makeDeclaration(
            kind: .functionMethodInstance,
            name: "run()",
            usr: "proto_run",
            location: makeLocation("/tmp/proto.swift", module: "Core", line: 2)
        )
        requirement.parent = proto
        proto.declarations.insert(requirement)

        let classA = makeDeclaration(
            kind: .class,
            name: "RunnerA",
            usr: "class_a",
            location: makeLocation("/tmp/a.swift", module: "A", line: 1)
        )
        let implA = makeDeclaration(
            kind: .functionMethodInstance,
            name: "run()",
            usr: "impl_a_run",
            location: makeLocation("/tmp/a.swift", module: "A", line: 2)
        )
        implA.parent = classA
        classA.declarations.insert(implA)

        let classB = makeDeclaration(
            kind: .class,
            name: "RunnerB",
            usr: "class_b",
            location: makeLocation("/tmp/b.swift", module: "B", line: 1)
        )
        let implB = makeDeclaration(
            kind: .functionMethodInstance,
            name: "run()",
            usr: "impl_b_run",
            location: makeLocation("/tmp/b.swift", module: "B", line: 2)
        )
        implB.parent = classB
        classB.declarations.insert(implB)

        graph.add(proto)
        graph.add(requirement)
        graph.add(classA)
        graph.add(implA)
        graph.add(classB)
        graph.add(implB)

        // Related references from conforming implementations to the protocol requirement.
        let relatedA = makeReference(
            kind: .related,
            declarationKind: .functionMethodInstance,
            usr: "proto_run",
            name: "run()",
            location: implA.location,
            parent: implA
        )
        let relatedB = makeReference(
            kind: .related,
            declarationKind: .functionMethodInstance,
            usr: "proto_run",
            name: "run()",
            location: implB.location,
            parent: implB
        )

        // Conformance references from classes to protocol.
        let conformsA = makeReference(
            kind: .related,
            declarationKind: .protocol,
            usr: "proto_runnable",
            name: "Runnable",
            location: classA.location,
            parent: classA
        )
        let conformsB = makeReference(
            kind: .related,
            declarationKind: .protocol,
            usr: "proto_runnable",
            name: "Runnable",
            location: classB.location,
            parent: classB
        )

        graph.add(relatedA, from: implA)
        graph.add(relatedB, from: implB)
        graph.add(conformsA, from: classA)
        graph.add(conformsB, from: classB)

        ProtocolConformanceReferenceBuilder(graph: graph, configuration: configuration, swiftVersion: makeSwiftVersion()).mutate()

        // After inversion, the protocol requirement should reference both implementations.
        XCTAssertTrue(requirement.related.contains { $0.usr == "impl_a_run" })
        XCTAssertTrue(requirement.related.contains { $0.usr == "impl_b_run" })

        // The original related references should be removed from conforming declarations.
        XCTAssertFalse(implA.related.contains { $0.usr == "proto_run" })
        XCTAssertFalse(implB.related.contains { $0.usr == "proto_run" })
    }
}
