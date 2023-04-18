import TargetA

RedundantPublicTypeRetainer().retain()
PublicDeclarationInInternalParentRetainer().retain()
PublicExtensionOnRedundantPublicKindRetainer().retain()
IgnoreCommentCommandRetainer().retain()
IgnoreAllCommentCommandRetainer().retain()

_ = PublicTypeUsedAsPublicPropertyTypeRetainer().retain

_ = PublicTypeUsedAsPublicInitializerParameterTypeRetainer()

_ = PublicTypeUsedAsPublicSubscriptParameterTypeRetainer()[]
_ = PublicTypeUsedAsPublicSubscriptReturnTypeRetainer()[]

PublicTypeUsedAsPublicFunctionParameterTypeRetainer().retain1()
PublicTypeUsedAsPublicFunctionParameterTypeRetainer().retain2()
PublicTypeUsedAsPublicFunctionParameterTypeRetainer().retain3()

_ = PublicTypeUsedAsPublicFunctionReturnTypeRetainer().retain1()
_ = PublicTypeUsedAsPublicFunctionReturnTypeRetainer().retain2()
_ = PublicTypeUsedAsPublicFunctionReturnTypeRetainer().retain3()

PublicTypeUsedInPublicFunctionBodyRetainer().retain()
PublicTypeUsedAsPublicFunctionGenericParameterRetainer().retain(PublicTypeUsedAsPublicFunctionGenericParameter_ConformingClass.self)
PublicTypeUsedAsPublicFunctionGenericRequirementRetainer().retain(PublicTypeUsedAsPublicFunctionGenericRequirement_ConformingClass.self)
_ = PublicTypeUsedAsPublicClassGenericParameterRetainer<PublicTypeUsedAsPublicClassGenericParameter_ConformingClass>()
_ = PublicTypeUsedAsPublicClassGenericRequirementRetainer<PublicTypeUsedAsPublicClassGenericRequirement_ConformingClass>()

_ = PublicTypeUsedAsPublicFunctionMetatypeParameterWithGenericReturnTypeRetainer().retain

_ = NotRedundantPublicTestableImportClass().testableProperty

// Typealias
let _: PublicTypealiasWithClosureType? = nil

// Enum
switch PublicEnumWithAssociatedValue.getSomeCase() {
case let .someCase(a, b):
    _ = a.value
    _ = b.value
}

// Inheritance
_ = PublicClassInheritingPublicClass()
_ = PublicClassInheritingPublicExternalClassRetainer()

// Conformance
_ = PublicClassAdoptingPublicProtocol()
_ = PublicClassAdoptingInternalProtocol()
_ = InternalClassAdoptingPublicProtocolRetainer()

// Refining
let _: PublicProtocolRefiningPublicProtocol? = nil
_ = InternalProtocolRefiningPublicProtocolRetainer()

// Closure
let _ = PublicTypeUsedInPublicClosureRetainer().closure

// Support for tests for items being overly public

_ = RedundantInternalClassComponents()
_ = NotRedundantInternalClassComponents()
_ = NotRedundantInternalClassComponents_Support()
_ = RedundantFilePrivateComponents()
_ = NotRedundantFilePrivateComponents()
