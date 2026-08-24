import Foundation

public enum BellyTrackingStoreError: Error, Equatable, Sendable {
    case unsupportedImageFormat
    case imageProcessingFailed
    case invalidTrackingDirectory
    case invalidManifestFile
    case invalidImageFileName(String)
    case duplicateEntryIdentifier(UUID)
    case duplicateImageFileName(String)
    case unsupportedManifestSchema(Int)
    case rollbackFailed(operation: String, rollback: String)
}
