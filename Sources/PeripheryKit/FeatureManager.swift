import Foundation

enum Feature {
    case determineAccessibilityFromStructure
}

class FeatureManager: Singleton {
    static func make() -> Self {
        return self.init()
    }

    private let enabledFeatures: [Feature] = [
        .determineAccessibilityFromStructure
    ]

    required init() {}

    func isEnabled(_ feature: Feature) -> Bool {
        return enabledFeatures.contains(feature)
    }
}
