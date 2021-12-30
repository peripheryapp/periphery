import TargetA

RedundantPublicTypeRetainer().retain()
PublicDeclarationInInternalParentRetainer().retain()
PublicExtensionOnRedundantPublicKindRetainer().retain()
IgnoreCommentCommandRetainer().retain()
IgnoreAllCommentCommandRetainer().retain()

_ = PublicTypeUsedAsPublicPropertyTypeRetainer().retain1
_ = PublicTypeUsedAsPublicPropertyTypeRetainer().retain2
_ = PublicTypeUsedAsPublicPropertyTypeRetainer().retain3

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

_ = NotRedundantPublicTestableImportClass().testableProperty

// Enums

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

