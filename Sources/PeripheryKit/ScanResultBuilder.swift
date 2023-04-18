import Foundation
import Shared

public struct ScanResultBuilder {
    public static func build(for graph: SourceGraph) -> [ScanResult] {
        let logger = Logger()
        let interval = logger.beginInterval("scan:result:build")

        let assignOnlyProperties = graph.assignOnlyProperties
        let removableDeclarations = graph.unusedDeclarations.subtracting(assignOnlyProperties)
        let redundantProtocols = graph.redundantProtocols.filter { !removableDeclarations.contains($0.0) }
        let redundantPublicAccessibility = graph.redundantPublicAccessibility.filter { !removableDeclarations.contains($0.0) }
        let redundantInternalAccessibility = graph.redundantInternalAccessibility.filter { !removableDeclarations.contains($0.0) }
        let redundantFilePrivateAccessibility = graph.redundantFilePrivateAccessibility.filter { !removableDeclarations.contains($0.0) }

        let annotatedRemovableDeclarations: [ScanResult] = removableDeclarations.map {
            .init(declaration: $0, annotation: .unused)
        }
        let annotatedAssignOnlyProperties: [ScanResult] = assignOnlyProperties.map {
            .init(declaration: $0, annotation: .assignOnlyProperty)
        }
        let annotatedRedundantProtocols: [ScanResult] = redundantProtocols.map {
            .init(declaration: $0.0, annotation: .redundantProtocol(references: $0.1))
        }
        let annotatedRedundantPublicAccessibility: [ScanResult] = redundantPublicAccessibility.map {
            .init(declaration: $0.0, annotation: .redundantPublicAccessibility(modules: $0.1))
        }
        let annotatedRedundantInternalAccessibility: [ScanResult] = redundantInternalAccessibility.map {
            .init(declaration: $0.0, annotation: .redundantInternalAccessibility(file: $0.1))
        }
        let annotatedRedundantFilePrivateAccessibility: [ScanResult] = redundantFilePrivateAccessibility.map {
            .init(declaration: $0.0, annotation: .redundantFilePrivateAccessibility(file: $0.1))
        }
        let allAnnotatedDeclarations = annotatedRemovableDeclarations +
            annotatedAssignOnlyProperties +
            annotatedRedundantProtocols +
            annotatedRedundantPublicAccessibility +
			annotatedRedundantInternalAccessibility +
			annotatedRedundantFilePrivateAccessibility

        let result = allAnnotatedDeclarations
            .filter {
                !$0.declaration.isImplicit &&
                !$0.declaration.kind.isAccessorKind &&
                !graph.ignoredDeclarations.contains($0.declaration)
            }

        logger.endInterval(interval)

        return result
    }
}
