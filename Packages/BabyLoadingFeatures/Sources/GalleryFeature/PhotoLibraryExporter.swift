import Foundation
#if os(iOS)
    import Photos
#endif

public enum PhotoLibraryExportResult: Equatable, Sendable {
    case saved
    case permissionDenied
    case failed
}

public protocol PhotoLibraryExportingProtocol: Sendable {
    func saveImageData(_ data: Data) async -> PhotoLibraryExportResult
}

#if os(iOS)
public struct PhotoLibraryExporter: PhotoLibraryExportingProtocol {
    public init() {}

    public func saveImageData(_ data: Data) async -> PhotoLibraryExportResult {
        let authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            return .permissionDenied
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: data, options: nil)
            }
            return .saved
        } catch {
            return .failed
        }
    }
}
#endif
