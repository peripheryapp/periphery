import Foundation

public class ClassReferencedFromPublicInlinableFunction {}

@usableFromInline
class ClassReferencedFromPublicInlinableFunction_UsableFromInline {}

@inlinable
public func inlinableFunction() {
    _ = ClassReferencedFromPublicInlinableFunction.self
    _ = ClassReferencedFromPublicInlinableFunction_UsableFromInline.self
}
