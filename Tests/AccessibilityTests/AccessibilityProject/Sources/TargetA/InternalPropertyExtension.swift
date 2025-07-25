// InternalPropertyExtension.swift
// Extension that uses the internal property from InternalPropertyUsedInExtension
// This should prevent the property from being flagged as redundant

extension InternalPropertyUsedInExtension {
    func useProperty() {
        print(propertyUsedInExtension) // This reference should prevent propertyUsedInExtension from being flagged as redundant
    }
} 