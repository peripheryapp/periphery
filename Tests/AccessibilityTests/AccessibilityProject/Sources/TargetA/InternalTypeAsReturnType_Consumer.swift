// InternalTypeAsReturnType_Consumer.swift
// Consumer that calls the function with internal return type from a different file.
// This creates the transitive exposure of InternalReturnTypeEnum.

class InternalReturnTypeConsumer {
    func consume() {
        let container = InternalReturnTypeContainer()
        // This call uses InternalReturnTypeEnum transitively through the return type
        let _ = container.getEnum()
    }
}
