import AEXML
import Foundation
import SourceGraph
import SystemPackage

final class XibParser {
    private let path: FilePath

    required init(path: FilePath) {
        self.path = path
    }

    func parse() throws -> [AssetReference] {
        guard let data = FileManager.default.contents(atPath: path.string) else { return [] }
        let structure = try AEXMLDocument(xml: data)

        // Build a map of element id -> customClass for resolving action destinations
        var idToCustomClass: [String: String] = [:]
        buildIdToCustomClassMap(from: structure.root, into: &idToCustomClass)

        // Collect all references with their outlets, actions, and runtime attributes
        var referencesByClass: [String: (outlets: Set<String>, actions: Set<String>, runtimeAttributes: Set<String>)] = [:]
        collectReferences(from: structure.root, idToCustomClass: idToCustomClass, into: &referencesByClass)

        return referencesByClass.map { className, members in
            AssetReference(
                absoluteName: className,
                source: .interfaceBuilder,
                outlets: Array(members.outlets),
                actions: Array(members.actions),
                runtimeAttributes: Array(members.runtimeAttributes)
            )
        }
    }

    // MARK: - Private

    /// Builds a map of element id to customClass for resolving action destinations.
    private func buildIdToCustomClassMap(from element: AEXMLElement, into map: inout [String: String]) {
        if let id = element.attributes["id"], let customClass = element.attributes["customClass"] {
            map[id] = customClass
        }
        for child in element.children {
            buildIdToCustomClassMap(from: child, into: &map)
        }
    }

    /// Recursively collects class references, outlets, actions, and runtime attributes.
    private func collectReferences(
        from element: AEXMLElement,
        idToCustomClass: [String: String],
        into referencesByClass: inout [String: (outlets: Set<String>, actions: Set<String>, runtimeAttributes: Set<String>)]
    ) {
        // Check if this element has a customClass
        if let customClass = element.attributes["customClass"] {
            // Initialize entry for this class if needed
            if referencesByClass[customClass] == nil {
                referencesByClass[customClass] = (outlets: [], actions: [], runtimeAttributes: [])
            }

            // Collect outlets from this element's connections
            collectOutlets(from: element, forClass: customClass, into: &referencesByClass)

            // Collect runtime attributes from this element
            collectRuntimeAttributes(from: element, forClass: customClass, into: &referencesByClass)
        }

        // Collect actions - these reference a destination class
        collectActions(from: element, idToCustomClass: idToCustomClass, into: &referencesByClass)

        // Collect Cocoa Bindings (macOS) - these reference properties on destination objects
        collectBindings(from: element, idToCustomClass: idToCustomClass, into: &referencesByClass)

        // Recurse into children
        for child in element.children {
            collectReferences(from: child, idToCustomClass: idToCustomClass, into: &referencesByClass)
        }
    }

    /// Collects outlet property names from an element's connections.
    /// Handles both `<outlet>` and `<outletCollection>` elements.
    private func collectOutlets(
        from element: AEXMLElement,
        forClass customClass: String,
        into referencesByClass: inout [String: (outlets: Set<String>, actions: Set<String>, runtimeAttributes: Set<String>)]
    ) {
        for child in element.children where child.name == "connections" {
            for connection in child.children {
                // Handle both regular outlets and outlet collections (for @IBOutlet arrays like [UIButton])
                guard connection.name == "outlet" || connection.name == "outletCollection" else { continue }
                if let property = connection.attributes["property"] {
                    referencesByClass[customClass]?.outlets.insert(property)
                }
            }
        }
    }

    /// Collects action selectors and associates them with the destination class.
    private func collectActions(
        from element: AEXMLElement,
        idToCustomClass: [String: String],
        into referencesByClass: inout [String: (outlets: Set<String>, actions: Set<String>, runtimeAttributes: Set<String>)]
    ) {
        for child in element.children where child.name == "connections" {
            for connection in child.children where connection.name == "action" {
                guard let selector = connection.attributes["selector"] else { continue }

                // iOS uses "destination", macOS uses "target"
                guard let targetId = connection.attributes["destination"] ?? connection.attributes["target"]
                else { continue }

                // Resolve the target to a customClass
                if let customClass = idToCustomClass[targetId] {
                    if referencesByClass[customClass] == nil {
                        referencesByClass[customClass] = (outlets: [], actions: [], runtimeAttributes: [])
                    }
                    referencesByClass[customClass]?.actions.insert(selector)
                }
            }
        }
    }

    /// Collects user-defined runtime attribute key paths (IBInspectable).
    private func collectRuntimeAttributes(
        from element: AEXMLElement,
        forClass customClass: String,
        into referencesByClass: inout [String: (outlets: Set<String>, actions: Set<String>, runtimeAttributes: Set<String>)]
    ) {
        for child in element.children where child.name == "userDefinedRuntimeAttributes" {
            for attr in child.children where attr.name == "userDefinedRuntimeAttribute" {
                if let keyPath = attr.attributes["keyPath"] {
                    referencesByClass[customClass]?.runtimeAttributes.insert(keyPath)
                }
            }
        }
    }

    /// Collects Cocoa Bindings (macOS) which reference properties via keyPath.
    /// Bindings connect UI elements to controller properties, e.g., `<binding destination="..." keyPath="self.propertyName" ...>`.
    private func collectBindings(
        from element: AEXMLElement,
        idToCustomClass: [String: String],
        into referencesByClass: inout [String: (outlets: Set<String>, actions: Set<String>, runtimeAttributes: Set<String>)]
    ) {
        for child in element.children where child.name == "connections" {
            for connection in child.children where connection.name == "binding" {
                guard let keyPath = connection.attributes["keyPath"],
                      let destination = connection.attributes["destination"]
                else { continue }

                // Resolve the destination to a customClass
                if let customClass = idToCustomClass[destination] {
                    if referencesByClass[customClass] == nil {
                        referencesByClass[customClass] = (outlets: [], actions: [], runtimeAttributes: [])
                    }
                    // Extract the first component of the keyPath (e.g., "self.propertyName" -> "propertyName")
                    let propertyName = extractPropertyName(from: keyPath)
                    referencesByClass[customClass]?.outlets.insert(propertyName)
                }
            }
        }
    }

    /// Extracts the property name from a binding keyPath.
    /// Handles formats like "self.propertyName", "propertyName", "self.object.nestedProperty".
    private func extractPropertyName(from keyPath: String) -> String {
        var path = keyPath

        // Remove "self." prefix if present
        if path.hasPrefix("self.") {
            path = String(path.dropFirst(5))
        }

        // Return the first component (property name)
        if let dotIndex = path.firstIndex(of: ".") {
            return String(path[..<dotIndex])
        }

        return path
    }
}
