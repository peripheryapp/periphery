#if canImport(Combine)
import Combine
#endif

public class FixtureClass123 {
    struct CustomType {}

    var retainedSimpleProperty: CustomType?
    var notRetainedSimpleProperty: String?
    var retainedModulePrefixedProperty: Swift.Double?
    var notRetainedModulePrefixedProperty: Swift.Bool?
    var retainedTupleProperty: (CustomType, String)?
    var notRetainedTupleProperty: (Int, CustomType)?
    var (retainedDestructuredPropertyA, notRetainedDestructuredPropertyB): (CustomType, Swift.String) = (.init(), "2")
    var retainedMultipleBindingPropertyA: CustomType?, notRetainedMultipleBindingPropertyB: Int?

    #if canImport(Combine)
    var retainedAnyCancellable: AnyCancellable?
    #endif

    public func someFunc() {
        retainedSimpleProperty = CustomType()
        notRetainedSimpleProperty = ""

        retainedModulePrefixedProperty = 1
        notRetainedModulePrefixedProperty = true

        retainedTupleProperty = (.init(), "2")
        notRetainedTupleProperty = (1, .init())

        retainedDestructuredPropertyA = .init()
        notRetainedDestructuredPropertyB = ""

        retainedMultipleBindingPropertyA = .init()
        notRetainedMultipleBindingPropertyB = 1

        #if canImport(Combine)
        let subject = CurrentValueSubject<Bool, Never>(true)
        retainedAnyCancellable = subject.sink { _ in }
        #endif
    }
}
